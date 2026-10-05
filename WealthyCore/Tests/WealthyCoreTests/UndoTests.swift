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
        LedgerCore(store: try LedgerStore(inMemory: true, seed: false), calendar: calendar)
    }
    func wallet(_ name: String = "Cash") -> WalletValue {
        WalletValue(name: name, currencyCode: "JPY", createdAt: now)
    }
    func entry(_ wallet: WalletValue, amount: Int = 100) -> EntryValue {
        EntryValue(kind: .expense, amount: amount, currencyCode: "JPY", day: day,
                   walletID: wallet.id, timestamp: now, title: "Receipt", note: "Original note",
                   reviewFlags: [.amountUncertain], createdAt: now, updatedAt: now)
    }
    func receipt(_ name: String = "receipt.png") -> ReceiptInput {
        ReceiptInput(metadata: ReceiptValue(fileName: name, capturedAt: now), image: image)
    }

    @Test("U1 undo add update and delete preserves every entry field and receipt")
    func entryUndoExact() throws {
        let core = try core(), a = wallet(), attachment = receipt()
        try core.run(.createWallet(a), now: now)
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

    @Test("U1 undo transfer reconciliation and category deletion restores relations")
    func relationalUndoExact() throws {
        let core = try core(), a = wallet(), b = wallet("Bank")
        let c = CategoryValue(kind: .expense, customName: "Food")
        var state = LedgerState(wallets: [a, b], categories: [c])
        state.entries = [entry(a)]
        state.entries[0].categoryID = c.id
        state.rules = [RuleValue(amount: 50, currencyCode: "JPY", walletID: a.id, categoryID: c.id,
                                schedule: .monthly(day: 5), startDay: day, createdAt: now)]
        state.budgets = [BudgetValue(currencyCode: "JPY", categoryID: c.id, monthlyAmount: 500)]
        try core.store.replace(state)
        var transfer = entry(a); transfer.kind = .transfer; transfer.counterpartWalletID = b.id
        try core.run(.addEntry(transfer), now: now)
        try core.undo(now: now)
        #expect(try core.snapshot() == state)
        try core.run(.reconcileWallet(a.id, actualBalance: 500, day: day), now: now)
        try core.undo(now: now)
        #expect(try core.snapshot() == state)
        try core.run(.deleteCategory(c.id), now: now)
        try core.undo(now: now)
        #expect(try core.snapshot() == state)
    }

    @Test("U2 empty undo bounded history and reverse order")
    func boundedHistory() throws {
        let core = try core(), a = wallet()
        #expect(try core.undo(now: now) == nil)
        try core.run(.createWallet(a), now: now)
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
        let core = try core(), a = wallet()
        try core.run(.createWallet(a), now: now)
        var state = try core.snapshot()
        state.entries.append(entry(a))
        try core.store.replace(state)
        #expect(throws: CoreError.undoConflict) { try core.undo(now: now) }
        #expect(try core.snapshot() == state)
        #expect(core.undoCount == 1)
    }

    @Test("U3 preview balance and monthly budget effects without store or file writes")
    func previewBudgetAndReceipt() throws {
        let core = try core(), a = wallet(), c = CategoryValue(kind: .expense, customName: "Food")
        let overall = BudgetValue(currencyCode: "JPY", monthlyAmount: 1_000)
        let category = BudgetValue(currencyCode: "JPY", categoryID: c.id, monthlyAmount: 400)
        let before = LedgerState(wallets: [a], categories: [c], budgets: [overall, category])
        try core.store.replace(before)
        var e = entry(a); e.categoryID = c.id
        let preview = core.preview(.addEntry(e, receipt: receipt()), now: now)
        #expect(preview.errors.isEmpty)
        let summary = try #require(preview.summary)
        let impact = try #require(summary.wallets.first { $0.walletID == a.id })
        #expect(impact.before == 0 && impact.after == -100)
        let overallImpact = try #require(summary.budgets.first { $0.budgetID == overall.id })
        let categoryImpact = try #require(summary.budgets.first { $0.budgetID == category.id })
        #expect(overallImpact.beforeRemaining == 1_000 && overallImpact.afterRemaining == 900)
        #expect(categoryImpact.beforeRemaining == 400 && categoryImpact.afterRemaining == 300)
        #expect(overallImpact.year == 2026 && overallImpact.month == 10)
        #expect(try core.snapshot() == before)
        #expect(core.undoCount == 0)
        #expect(try FileManager.default.contentsOfDirectory(atPath: core.store.receiptsDirectory.path).isEmpty)
        let result = try core.run(.addEntry(e, receipt: receipt()), now: now)
        #expect(result.summary == summary)
        #expect(result.affectedIDs.contains(e.id))
    }

    @Test("U3 failed preview returns structured errors and metadata includes wallet impact")
    func failedAndMetadataPreview() throws {
        let core = try core(), a = wallet()
        try core.store.replace(LedgerState(wallets: [a]))
        let before = try core.snapshot()
        let invalid = entry(a, amount: 0)
        let preview = core.preview(.addEntry(invalid), now: now)
        #expect(preview.errors == [.invalidField("amount", invalid.id)])
        #expect(preview.summary == nil)
        var renamed = a; renamed.name = "Renamed"
        let metadata = core.preview(.updateWallet(renamed), now: now)
        let impact = try #require(metadata.summary?.wallets.first { $0.walletID == a.id })
        #expect(impact.before == 0 && impact.after == 0)
        #expect(try core.snapshot() == before)
    }

    @Test("S2 orphan cleanup protects referenced images and legacy directories")
    func orphanCleanup() throws {
        let core = try core(), a = wallet(), attachment = receipt()
        try core.run(.createWallet(a), now: now)
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
    }

    @Test("Save failure preserves receipt bytes state and history")
    func receiptSaveFailure() throws {
        let core = try core(), a = wallet()
        try core.store.replace(LedgerState(wallets: [a]))
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
        let core = try core(), a = wallet()
        try core.store.replace(LedgerState(wallets: [a]))
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
