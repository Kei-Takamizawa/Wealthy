import Foundation
import Testing
@testable import WealthyCore

@Suite("Preview undo and receipts")
@MainActor
struct UndoTests {
    let now = Date(timeIntervalSince1970: 1_791_158_400)
    var day: LedgerDay { try! LedgerDay(year: 2026, month: 10, day: 5) }
    var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }
    var image: Data {
        Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==")!
    }
    func core() throws -> LedgerCore {
        try LedgerCore(store: try LedgerStore(inMemory: true, seed: false), calendar: calendar)
    }
    func envelope(_ name: String = "Cash") -> EnvelopeValue {
        EnvelopeValue(id: name == "Cash" ? EnvelopeValue.householdID : UUID(), kind: name == "Cash" ? .household : .child, name: name, createdAt: name == "Cash" ? Date(timeIntervalSince1970: 0) : now)
    }
    func entry(_ envelope: EnvelopeValue, amount: Int = 100) -> EntryValue {
        EntryValue(kind: .expense, amount: amount, currencyCode: "JPY", day: day,
                   envelopeID: envelope.id, timestamp: now, title: "Receipt", note: "Original note",
                   reviewFlags: [.amountUncertain], createdAt: now, updatedAt: now)
    }
    func receipt(_ name: String = "receipt.png") -> ReceiptInput {
        ReceiptInput(metadata: ReceiptValue(fileName: name, capturedAt: now), image: image)
    }

    @Test("U1 undo add update and delete preserves every entry field and receipt")
    func entryUndoExact() throws {
        let core = try core(), a = envelope(), attachment = receipt()
        try core.run(.updateEnvelope(a), now: now)
        core.clearUndoHistory()
        let empty = try core.snapshot()
        var e = entry(a)
        try core.run(.addEntry(e, receipt: attachment), now: now)
        let added = try core.snapshot()
        e = try #require(added.entries.first)
        e.amount = 350; e.note = "Changed"; e.title = "Changed title"; e.reviewFlags = []
        try core.run(.updateEntry(e), now: now.addingTimeInterval(60))
        let updated = try core.snapshot()
        try core.run(.deleteEntry(e.id), now: now)
        #expect(FileManager.default.fileExists(atPath: core.store.receiptsDirectory.appendingPathComponent("receipt.png").path))
        #expect(try core.undo(now: now) != nil)
        #expect(try core.snapshot() == updated)
        try core.undo(now: now)
        #expect(try core.snapshot() == added)
        try core.undo(now: now)
        #expect(try core.snapshot() == empty)
        #expect(try Data(contentsOf: core.store.receiptsDirectory.appendingPathComponent("receipt.png")) == image)
    }

    @Test("U1 undo envelope reassignment fixed classification and category deletion restores relations")
    func relationalUndoExact() throws {
        let core = try core(), a = envelope(), b = envelope("Bank")
        let c = CategoryValue(kind: .expense, customName: "Food")
        var state = LedgerState(envelopes: [a, b], categories: [c])
        state.entries = [entry(a)]
        state.entries[0].categoryID = c.id
        state.rules = [RuleValue(amount: 50, currencyCode: "JPY", envelopeID: a.id, categoryID: c.id,
                                schedule: .monthly(day: 5), startDay: day, createdAt: now)]
        state.targets = [TargetValue(categoryID: c.id, currencyCode: "JPY", amountMinor: 500, effectiveMonth: LedgerMonth(day: day))]
        try core.store.replace(state)
        try core.reload()
        var moved = entry(b); moved.isFixedCost = true
        try core.run(.addEntry(moved), now: now)
        try core.undo(now: now)
        #expect(try core.snapshot() == state)
        var changed = state.entries[0]; changed.isFixedCost = true
        try core.run(.updateEntry(changed), now: now)
        try core.undo(now: now)
        #expect(try core.snapshot() == state)
        try core.run(.deleteCategory(c.id), now: now)
        try core.undo(now: now)
        #expect(try core.snapshot() == state)
    }

    @Test("U2 empty undo bounded history and reverse order")
    func boundedHistory() throws {
        let core = try core(), a = envelope()
        #expect(try core.undo(now: now) == nil)
        try core.run(.updateEnvelope(a), now: now)
        core.clearUndoHistory()
        for amount in 1...25 { try core.run(.addEntry(entry(a, amount: amount)), now: now) }
        #expect(core.undoCount == 20)
        for count in stride(from: 24, through: 5, by: -1) {
            try core.undo(now: now)
            #expect(try core.snapshot().entries.count == count)
        }
        #expect(core.undoCount == 0)
        #expect(try core.undo(now: now) == nil)
        #expect(try core.snapshot().entries.map(\.amount) == [1, 2, 3, 4, 5])
    }

    @Test("U2 outside mutation makes undo fail without changes")
    func undoConflict() throws {
        let core = try core(), a = envelope("Child")
        try core.run(.createEnvelope(a), now: now)
        var state = try core.snapshot()
        state.entries.append(entry(a))
        try core.store.replace(state)
        try core.reload()
        #expect(throws: CoreError.undoConflict) { try core.undo(now: now) }
        #expect(try core.snapshot() == state)
        #expect(core.undoCount == 1)
    }

    @Test("U3 preview status and monthly target effects without store or file writes")
    func previewTargetAndReceipt() throws {
        let core = try core(), a = envelope(), c = CategoryValue(kind: .expense, customName: "Food")
        let overall = TargetValue(currencyCode: "JPY", amountMinor: 1_000, effectiveMonth: LedgerMonth(day: day))
        let category = TargetValue(categoryID: c.id, currencyCode: "JPY", amountMinor: 400, effectiveMonth: LedgerMonth(day: day))
        let before = LedgerState(envelopes: [a], categories: [c], targets: [overall, category])
        try core.store.replace(before)
        try core.reload()
        var e = entry(a); e.categoryID = c.id
        let preview = core.preview(.addEntry(e, receipt: receipt()), now: now)
        #expect(preview.errors.isEmpty)
        let summary = try #require(preview.summary)
        let overallImpact = try #require(summary.targets.first { $0.categoryID == nil && $0.period.end.day == 31 })
        let categoryImpact = try #require(summary.targets.first { $0.categoryID == c.id && $0.period.end.day == 31 })
        #expect(overallImpact.beforeRemaining == 1_000 && overallImpact.afterRemaining == 900)
        #expect(categoryImpact.beforeRemaining == 400 && categoryImpact.afterRemaining == 300)
        #expect(overallImpact.period.start.year == 2026 && overallImpact.period.start.month == 10)
        #expect(try core.snapshot() == before)
        #expect(core.undoCount == 0)
        #expect(try FileManager.default.contentsOfDirectory(atPath: core.store.receiptsDirectory.path).isEmpty)
        let result = try core.run(.addEntry(e, receipt: receipt()), now: now)
        #expect(result.summary == summary)
        #expect(result.affectedIDs.contains(e.id))
    }

    @Test("U3 failed preview returns structured errors and metadata includes envelope impact")
    func failedAndMetadataPreview() throws {
        let core = try core(), a = envelope()
        try core.store.replace(LedgerState(envelopes: [a]))
        try core.reload()
        let before = try core.snapshot()
        let invalid = entry(a, amount: 0)
        let preview = core.preview(.addEntry(invalid), now: now)
        #expect(preview.errors == [.invalidField("amount", invalid.id)])
        #expect(preview.summary == nil)
        var renamed = a; renamed.name = "Renamed"
        let metadata = core.preview(.updateEnvelope(renamed), now: now)
        #expect(metadata.isValid && metadata.summary?.targets.isEmpty == true)
        #expect(try core.snapshot() == before)
    }

    @Test("S2 orphan cleanup protects referenced images and legacy directories")
    func orphanCleanup() throws {
        let core = try core(), a = envelope(), attachment = receipt()
        try core.run(.updateEnvelope(a), now: now)
        try core.run(.addEntry(entry(a), receipt: attachment), now: now)
        let receipts = core.store.receiptsDirectory
        try image.write(to: receipts.appendingPathComponent("cancelled.png"))
        let legacy = receipts.deletingLastPathComponent().appendingPathComponent("legacy.png")
        try image.write(to: legacy)
        #expect(throws: CoreError.historyNotEmpty) { try core.cleanupOrphanReceipts() }
        core.clearUndoHistory()
        #expect(try core.cleanupOrphanReceipts() == ["cancelled.png"])
        #expect(try Data(contentsOf: receipts.appendingPathComponent("receipt.png")) == image)
        #expect(try Data(contentsOf: legacy) == image)
        try core.run(.deleteEntry(try #require(core.snapshot().entries.first?.id)), now: now)
        core.clearUndoHistory()
        #expect(try core.cleanupOrphanReceipts() == ["receipt.png"])
        #expect(core.state.receipts.isEmpty)
    }

    @Test("Save failure preserves receipt bytes state and history")
    func receiptSaveFailure() throws {
        let core = try core(), a = envelope()
        try core.store.replace(LedgerState(envelopes: [a]))
        try core.reload()
        let before = try core.snapshot()
        let receipts = core.store.receiptsDirectory
        try image.write(to: receipts.appendingPathComponent("existing.png"))
        core.store.failNextSave = true
        #expect(throws: CoreError.saveFailed) { try core.run(.addEntry(entry(a), receipt: receipt()), now: now) }
        #expect(try core.snapshot() == before)
        #expect(try FileManager.default.contentsOfDirectory(atPath: receipts.path) == ["existing.png"])
        #expect(try Data(contentsOf: receipts.appendingPathComponent("existing.png")) == image)
        #expect(core.undoCount == 0)
        try core.run(.addEntry(entry(a)), now: now)
        let added = try core.snapshot()
        core.store.failNextSave = true
        #expect(throws: CoreError.saveFailed) { try core.undo(now: now) }
        #expect(try core.snapshot() == added && core.undoCount == 1)
    }

    @Test("Receipt filesystem failure leaves ledger and blocking file unchanged")
    func receiptFileFailure() throws {
        let core = try core(), a = envelope()
        try core.store.replace(LedgerState(envelopes: [a]))
        try core.reload()
        let before = try core.snapshot(), directory = core.store.receiptsDirectory
        try FileManager.default.removeItem(at: directory)
        let blocking = Data("Blocking file".utf8)
        try blocking.write(to: directory)
        do {
            try core.run(.addEntry(entry(a), receipt: receipt()), now: now)
            Issue.record("Expected receipt filesystem failure")
        } catch let error as CoreError {
            if case .fileFailure = error {} else { Issue.record("Unexpected typed error: \(error)") }
        }
        #expect(try core.snapshot() == before)
        #expect(try Data(contentsOf: directory) == blocking)
        #expect(core.undoCount == 0)
    }
}
