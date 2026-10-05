import Darwin
import Foundation
import Testing
@testable import WealthyCore

/// Opt-in disk benchmarks share exactly the same fixtures and measurement boundaries across cycles.
@Suite("Disk ledger benchmarks", .serialized,
       .enabled(if: ProcessInfo.processInfo.environment["WEALTHY_BENCHMARK"] == "1"))
@MainActor
struct BenchmarkTests {
    private let repetitions = 20
    private var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(secondsFromGMT: 0)!
        return result
    }
    private var today: LedgerDay { try! LedgerDay(year: 2027, month: 1, day: 31) }
    private var now: Date { try! today.date(calendar: calendar) }

    private struct Sample: Codable {
        var entries: Int
        var operation: String
        var milliseconds: [Double]
        var medianMilliseconds: Double {
            let sorted = milliseconds.sorted()
            return (sorted[sorted.count / 2 - 1] + sorted[sorted.count / 2]) / 2
        }
    }
    private struct MemorySample: Codable {
        var entries: Int
        var undoSteps: Int
        var beforeBytes: UInt64
        var afterBytes: UInt64
        var growthBytes: Int64
    }
    private struct Report: Codable {
        var label: String
        var operatingSystem: String
        var architecture: String
        var repetitions: Int
        var samples: [Sample]
        var memory: MemorySample?
        var methodology: String
    }

    private func fixture(entries count: Int) throws -> LedgerState {
        let start = try LedgerDay(year: 2027, month: 1, day: 1)
        let wallets = (0..<10).map { WalletValue(name: "Wallet \($0)", currencyCode: "JPY", createdAt: now) }
        let categories = (0..<12).map { CategoryValue(kind: .expense, customName: "Category \($0)", sortOrder: $0) }
        let entries = (0..<count).map { index in
            EntryValue(kind: .expense, amount: 100 + index % 900, currencyCode: "JPY", day: start,
                       walletID: wallets[index % 10].id, timestamp: now, categoryID: categories[index % 12].id,
                       title: "Entry \(index)", createdAt: now, updatedAt: now)
        }
        let rules = (0..<10).map { index in
            RuleValue(title: "Monthly \(index)", amount: 100, currencyCode: "JPY", walletID: wallets[index].id,
                      categoryID: categories[index].id, schedule: .monthly(day: 31), startDay: start, createdAt: now)
        }
        let budgets = (0..<5).map { BudgetValue(currencyCode: "JPY", categoryID: categories[$0].id, monthlyAmount: 100_000) }
        return LedgerState(wallets: wallets, categories: categories, entries: entries, rules: rules, budgets: budgets)
    }

    private func newEntry(_ state: LedgerState) -> EntryValue {
        EntryValue(kind: .expense, amount: 321, currencyCode: "JPY", day: today, walletID: state.wallets[0].id,
                   timestamp: now, categoryID: state.categories[0].id, title: "Benchmark addition", createdAt: now, updatedAt: now)
    }

    /// Reads the physical process footprint, which includes allocator and SwiftData overhead as well as history.
    private func footprint() throws -> UInt64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let status = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        guard status == KERN_SUCCESS else { throw CoreError.fileFailure("task_info \(status)") }
        return info.phys_footprint
    }

    private func elapsed(_ action: () throws -> Void) rethrows -> Double {
        let start = ContinuousClock.now
        try action()
        let duration = start.duration(to: .now).components
        return Double(duration.seconds) * 1_000 + Double(duration.attoseconds) / 1e15
    }

    private func seed(_ state: LedgerState, directory: URL) throws {
        let store = try LedgerStore(inMemory: false, directory: directory, seed: false)
        try CoreValidation.validate(state)
        try store.replace(state)
    }

    private func trial(operation: String, state: LedgerState, directory: URL) throws -> Double {
        if operation == "openStore" {
            return try elapsed {
                let core = try LedgerCore(store: try LedgerStore(inMemory: false, directory: directory, seed: false), calendar: calendar)
                let loaded = try core.snapshot()
                #expect(loaded.entries.count == state.entries.count)
            }
        }
        let core = try LedgerCore(store: try LedgerStore(inMemory: false, directory: directory, seed: false), calendar: calendar)
        _ = try core.snapshot()
        let entry = newEntry(state)
        var update = state.entries[state.entries.count / 2]
        update.amount += 1
        if operation == "undo" { try core.run(.addEntry(entry), now: now) }
        return try elapsed {
            switch operation {
            case "addEntry": try core.run(.addEntry(entry), now: now)
            case "updateEntry": try core.run(.updateEntry(update), now: now)
            case "deleteEntry": try core.run(.deleteEntry(state.entries[state.entries.count / 2].id), now: now)
            case "undo": #expect(try core.undo(now: now) != nil)
            case "previewAddEntry": #expect(core.preview(.addEntry(entry), now: now).errors.isEmpty)
            case "postRecurring":
                let result = try core.postRecurring(through: today, now: now)
                #expect(result.posted.count == 10 && result.failures.isEmpty)
            default: Issue.record("Unknown benchmark operation: \(operation)")
            }
        }
    }

    private func memoryTrial(state: LedgerState, directory: URL) throws -> MemorySample {
        let core = try LedgerCore(store: try LedgerStore(inMemory: false, directory: directory, seed: false), calendar: calendar)
        _ = try core.snapshot()
        let before = try footprint()
        for _ in 0..<20 { try core.run(.addEntry(newEntry(state)), now: now) }
        let after = try footprint()
        #expect(core.undoCount == 20)
        return MemorySample(entries: state.entries.count, undoSteps: core.undoCount, beforeBytes: before,
                            afterBytes: after, growthBytes: Int64(after) - Int64(before))
    }

    @Test("PERF opt-in release disk latency and full-history footprint")
    func diskMeasurements() throws {
        let environment = ProcessInfo.processInfo.environment
        let label = environment["WEALTHY_BENCHMARK_LABEL"] ?? "unlabelled"
        let output = URL(fileURLWithPath: environment["WEALTHY_BENCHMARK_OUTPUT"] ?? "/private/tmp/wealthy-c1-1-logs/\(label).json")
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("WealthyBenchmark-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        var report = Report(label: label, operatingSystem: ProcessInfo.processInfo.operatingSystemVersionString,
                            architecture: "arm64", repetitions: repetitions, samples: [], memory: nil,
                            methodology: "Release build, disk stores, UTC Gregorian January 2027; 20 measured runs after one warm-up. Each run opens a fresh copy of the same closed seeded store, outside timing except openStore (creation and first snapshot). OS file caches are not flushed. Setup, copying, validation and disposal are excluded. Recurring consumes exactly one January occurrence per 10 monthly rules. Undo reverses one prepared add. Physical footprint uses TASK_VM_INFO.phys_footprint before/after 20 additions, retaining 20 undo steps; includes SwiftData and allocator growth, not just history. Memory is measured first at 10k to avoid prior mutation high-water marks.")
        func saveReport() throws {
            try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(report).write(to: output, options: .atomic)
        }
        for size in [10_000, 50_000] {
            let state = try fixture(entries: size)
            let template = root.appendingPathComponent("template-\(size)")
            try seed(state, directory: template)
            if size == 10_000 {
                let working = root.appendingPathComponent("memory")
                try FileManager.default.copyItem(at: template, to: working)
                report.memory = try memoryTrial(state: state, directory: working)
                try FileManager.default.removeItem(at: working)
                try saveReport()
                print("BENCHMARK \(label) memory: \(report.memory!.growthBytes) bytes")
            }
            for operation in ["addEntry", "updateEntry", "deleteEntry", "undo", "previewAddEntry", "postRecurring", "openStore"] {
                var milliseconds: [Double] = []
                for iteration in 0...repetitions {
                    let working = root.appendingPathComponent("trial-\(size)-\(operation)-\(iteration)")
                    try FileManager.default.copyItem(at: template, to: working)
                    let sample = try autoreleasepool { try trial(operation: operation, state: state, directory: working) }
                    if iteration > 0 { milliseconds.append(sample) }
                    try FileManager.default.removeItem(at: working)
                }
                let sample = Sample(entries: size, operation: operation, milliseconds: milliseconds)
                report.samples.append(sample)
                try saveReport()
                print("BENCHMARK \(label) \(size) \(operation): median \(sample.medianMilliseconds) ms (n=\(milliseconds.count))")
            }
        }
    }
}
