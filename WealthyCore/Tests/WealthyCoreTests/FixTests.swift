import CryptoKit
import Foundation
import Observation
import Testing
@testable import WealthyCore

/// Observation callbacks may run outside the actor; the lock protects every counter access.
private final class FixObservationCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    func increment() { lock.lock(); defer { lock.unlock() }; count += 1 }
    var value: Int { lock.lock(); defer { lock.unlock() }; return count }
}

/// Independent regressions for the Cycle 1.1 behavior changes.
@Suite("Cycle 1.1 correctness fixes")
@MainActor
struct FixTests {
    var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    var image: Data {
        Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==")!
    }
    func day(_ month: Int = 1, _ date: Int = 5) throws -> LedgerDay {
        try LedgerDay(year: 2027, month: month, day: date)
    }
    func makeCore() throws -> LedgerCore {
        try LedgerCore(store: LedgerStore(inMemory: true, seed: false), calendar: calendar)
    }
    func makeWallet(_ name: String = "Cash") -> WalletValue {
        WalletValue(name: name, currencyCode: "JPY", createdAt: now)
    }
    func entry(_ wallet: WalletValue, source: EntrySource = .manual) throws -> EntryValue {
        EntryValue(kind: .expense, amount: 100, currencyCode: "JPY", day: try day(), walletID: wallet.id,
                   timestamp: now, title: "Test", source: source, createdAt: now, updatedAt: now)
    }
    @discardableResult
    func execute(_ core: LedgerCore, _ command: LedgerCommand, now: Date? = nil) throws -> CommandResult {
        let result = try core.run(command, now: now ?? self.now)
        try CoreValidation.validate(core.state)
        #expect(try core.snapshot() == core.state)
        return result
    }
    func rejectsInvalidField(_ core: LedgerCore, _ command: LedgerCommand) throws {
        let state = core.state, persisted = try core.store.read(), history = core.undoCount, revision = core.revision
        let preview = core.preview(command, now: now)
        #expect(!preview.isValid)
        #expect(preview.errors.contains { if case .invalidField = $0 { return true }; return false })
        do {
            try core.run(command, now: now)
            Issue.record("The invalid command succeeded")
        } catch let error as CoreError {
            if case .invalidField = error { } else { Issue.record("Expected invalidField, received \(error)") }
        }
        #expect(core.state == state && core.undoCount == history && core.revision == revision)
        #expect(try core.store.read() == persisted)
    }
    func receipt(_ name: String = "receipt.png") -> ReceiptInput {
        ReceiptInput(metadata: ReceiptValue(fileName: name, capturedAt: now), image: image)
    }
    func addReceipt(_ core: LedgerCore, name: String = "receipt.png") throws -> (WalletValue, EntryValue) {
        let wallet = makeWallet()
        try execute(core, .createWallet(wallet))
        let entry = try entry(wallet)
        try execute(core, .addEntry(entry, receipt: receipt(name)))
        return (wallet, try #require(core.state.entries.first { $0.id == entry.id }))
    }
    func recordsArchive(_ state: LedgerState) -> LedgerBackupArchive {
        LedgerBackupArchive(exportDate: now, appVersion: "test", coreVersion: "1", state: state)
    }

    @Test("C1 add rejects adjustment kind, every system source, and either recurring link field")
    func addCommandRestrictions() throws {
        let core = try makeCore(), wallet = makeWallet()
        try execute(core, .createWallet(wallet))
        let rule = RuleValue(amount: 100, currencyCode: "JPY", walletID: wallet.id,
            schedule: .monthly(day: 5), startDay: try day(), createdAt: now)
        try execute(core, .createRule(rule))
        var adjustment = try entry(wallet); adjustment.kind = .adjustment; adjustment.direction = .increase
        try rejectsInvalidField(core, .addEntry(adjustment))
        for source in [EntrySource.recurring, .openingBalance, .reconciliation] {
            var candidate = try entry(wallet); candidate.source = source
            try rejectsInvalidField(core, .addEntry(candidate))
        }
        var ruleOnly = try entry(wallet); ruleOnly.recurringRuleID = rule.id
        try rejectsInvalidField(core, .addEntry(ruleOnly))
        var dayOnly = try entry(wallet); dayOnly.occurrenceDay = try day()
        try rejectsInvalidField(core, .addEntry(dayOnly))
        var both = try entry(wallet); both.recurringRuleID = rule.id; both.occurrenceDay = try day()
        try rejectsInvalidField(core, .addEntry(both))
        for source in [EntrySource.manual, .receipt, .voice] {
            try execute(core, .addEntry(entry(wallet, source: source)))
        }
        #expect(core.state.entries.map(\.source) == [.manual, .receipt, .voice])
    }

    @Test("C1 update protects source and recurring provenance, permits amount and non-adjustment kind edits")
    func updateProvenanceRestrictions() throws {
        let core = try makeCore(), wallet = makeWallet(), target = makeWallet("Bank")
        try execute(core, .createWallet(wallet)); try execute(core, .createWallet(target))
        let expense = try entry(wallet)
        try execute(core, .addEntry(expense))
        var source = expense; source.source = .voice
        try rejectsInvalidField(core, .updateEntry(source))
        var adjustment = expense; adjustment.kind = .adjustment; adjustment.direction = .increase
        try rejectsInvalidField(core, .updateEntry(adjustment))
        let rule = RuleValue(amount: 100, currencyCode: "JPY", walletID: wallet.id,
            schedule: .monthly(day: 5), startDay: try day(), createdAt: now)
        let otherRule = RuleValue(amount: 50, currencyCode: "JPY", walletID: wallet.id,
            schedule: .monthly(day: 6), startDay: try day(), createdAt: now)
        try execute(core, .createRule(rule)); try execute(core, .createRule(otherRule))
        _ = try core.postRecurring(through: day(), now: now)
        let recurring = try #require(core.state.entries.first { $0.recurringRuleID == rule.id })
        var changedRule = recurring; changedRule.recurringRuleID = otherRule.id
        try rejectsInvalidField(core, .updateEntry(changedRule))
        var changedDay = recurring; changedDay.occurrenceDay = try day(1, 6)
        try rejectsInvalidField(core, .updateEntry(changedDay))
        var removedLink = recurring; removedLink.recurringRuleID = nil; removedLink.occurrenceDay = nil
        try rejectsInvalidField(core, .updateEntry(removedLink))
        var changedSource = recurring; changedSource.source = .manual
        try rejectsInvalidField(core, .updateEntry(changedSource))
        var changedAmount = recurring; changedAmount.amount = 110
        try execute(core, .updateEntry(changedAmount))
        let saved = try #require(core.state.entries.first { $0.id == recurring.id })
        #expect(saved.amount == 110 && saved.source == .recurring && saved.recurringRuleID == rule.id && saved.occurrenceDay == recurring.occurrenceDay)
        var transfer = expense; transfer.kind = .transfer; transfer.counterpartWalletID = target.id
        try execute(core, .updateEntry(transfer))
        #expect(LedgerMath.balance(target.id, in: core.state) == 100)
    }

    @Test("C1 adjustment entries can be edited without changing kind, but cannot become an expense")
    func adjustmentKindRestrictions() throws {
        let core = try makeCore(), wallet = makeWallet()
        try execute(core, .createWallet(wallet, openingBalance: 100, openingDay: day()))
        let original = try #require(core.state.entries.first)
        var expense = original; expense.kind = .expense; expense.direction = nil
        try rejectsInvalidField(core, .updateEntry(expense))
        var edited = original; edited.amount = 150; edited.title = "Opening corrected"
        try execute(core, .updateEntry(edited))
        #expect(LedgerMath.balance(wallet.id, in: core.state) == 150)
        #expect(core.state.entries.first?.source == .openingBalance)
    }

    @Test("Q2 last recorded uses createdAt before civil day, then timestamp and stable ID")
    func lastRecordedOrdering() throws {
        let wallet = makeWallet()
        var newerDay = try entry(wallet); newerDay.day = try day(1, 31); newerDay.createdAt = now
        var laterRecorded = try entry(wallet); laterRecorded.day = try day(1, 1); laterRecorded.createdAt = now.addingTimeInterval(1)
        laterRecorded.timestamp = now.addingTimeInterval(-100); laterRecorded.source = .receipt
        var state = LedgerState(wallets: [wallet], entries: [newerDay, laterRecorded])
        #expect(LedgerQueries.mostRecentEntry(in: state)?.id == laterRecorded.id)
        #expect(LedgerQueries.mostRecentEntry(in: state, source: .manual)?.id == newerDay.id)
        var timestampWinner = laterRecorded; timestampWinner.id = UUID(); timestampWinner.timestamp = now
        state.entries.append(timestampWinner)
        #expect(LedgerQueries.mostRecentEntry(in: state)?.id == timestampWinner.id)
        var tieA = timestampWinner; tieA.id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        var tieB = timestampWinner; tieB.id = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        state.entries = [tieB, tieA]
        #expect(LedgerQueries.mostRecentEntry(in: state)?.id == tieA.id)
        #expect(LedgerQueries.mostRecentEntry(in: LedgerState()) == nil)
    }

    @Test("R6 ended monthly rule catches up through its inclusive end, once")
    func endedRuleCatchUp() throws {
        let core = try makeCore(), wallet = makeWallet()
        try execute(core, .createWallet(wallet))
        let rule = RuleValue(amount: 100, currencyCode: "JPY", walletID: wallet.id,
            schedule: .monthly(day: 31), startDay: try day(1, 1), endDay: try day(1, 31), createdAt: now)
        try execute(core, .createRule(rule))
        let occurrences = try RecurringEngine.occurrences(rule: rule, from: day(1, 1), through: day(2, 28), calendar: calendar)
        #expect(occurrences == [try day(1, 31)])
        let posted = try core.postRecurring(through: day(2, 28), now: now)
        #expect(posted.posted.map(\.day) == [try day(1, 31)] && posted.failures.isEmpty)
        try CoreValidation.validate(core.state)
        let revision = core.revision
        #expect(try core.postRecurring(through: day(5, 10), now: now).posted.isEmpty)
        #expect(core.revision == revision)
    }

    @Test("R7 posting after the end catches February and March and honors a February pause")
    func cursorAndPausedEndCatchUp() throws {
        for paused in [false, true] {
            let core = try makeCore(), wallet = makeWallet()
            try execute(core, .createWallet(wallet))
            let rule = RuleValue(amount: 100, currencyCode: "JPY", walletID: wallet.id,
                schedule: .monthly(day: 31), startDay: try day(1, 1), endDay: try day(3, 31), createdAt: now)
            try execute(core, .createRule(rule))
            #expect(try core.postRecurring(through: day(1, 31), now: now).posted.map(\.day) == [try day(1, 31)])
            if paused {
                try execute(core, .pauseRule(rule.id, paused: true), now: day(2, 1).date(calendar: calendar))
                try execute(core, .pauseRule(rule.id, paused: false), now: day(3, 1).date(calendar: calendar))
            }
            let result = try core.postRecurring(through: day(5, 10), now: now)
            let expected = paused ? [try day(3, 31)] : [try day(2, 28), try day(3, 31)]
            #expect(result.posted.map(\.day) == expected && result.failures.isEmpty)
            #expect(core.state.rules.first?.lastPostedDay == (try day(3, 31)))
            try CoreValidation.validate(core.state)
            #expect(try core.postRecurring(through: day(6, 1), now: now).posted.isEmpty)
        }
    }

    @Test("K3 saved receipt hash is lowercase SHA-256 and records-only same-device restore preserves bytes")
    func matchingImageRecordsRestore() throws {
        let core = try makeCore()
        _ = try addReceipt(core)
        let expectedHash = SHA256.hash(data: image).map { String(format: "%02x", $0) }.joined()
        let metadata = try #require(core.state.receipts.first)
        #expect(metadata.imageSHA256 == expectedHash && expectedHash.count == 64)
        let exported = try LedgerBackup.export(core, includeImages: false, now: now, appVersion: "test", coreVersion: "1")
        let archived = try JSONDecoder().decode(LedgerBackupArchive.self, from: exported)
        #expect(archived.images.isEmpty && archived.state.receipts.first?.imageSHA256 == expectedHash)
        let revision = core.revision
        try LedgerBackup.restore(exported, into: core)
        #expect(core.state == archived.state && core.undoCount == 0 && core.revision == revision)
        #expect(try Data(contentsOf: core.store.receiptsDirectory.appendingPathComponent(metadata.fileName)) == image)
    }

    @Test("K3 records-only restore removes differing local bytes and unknown hashes, with rollback")
    func mismatchingAndUnknownImages() throws {
        for unknownHash in [false, true] {
            let core = try makeCore()
            _ = try addReceipt(core)
            var archive = recordsArchive(core.state)
            if unknownHash { archive.state.receipts[0].imageSHA256 = nil }
            let file = core.store.receiptsDirectory.appendingPathComponent("receipt.png")
            let localBytes = unknownHash ? image : Data([1, 2, 3, 4])
            try localBytes.write(to: file)
            let encoded = try JSONEncoder().encode(archive)
            let before = core.state, revision = core.revision, history = core.undoCount
            core.store.failNextSave = true
            #expect(throws: CoreError.saveFailed) { try LedgerBackup.restore(encoded, into: core) }
            #expect(core.state == before && core.revision == revision && core.undoCount == history)
            #expect(try Data(contentsOf: file) == localBytes)
            try LedgerBackup.restore(encoded, into: core)
            #expect(core.state == archive.state && core.undoCount == 0)
            #expect(!FileManager.default.fileExists(atPath: file.path))
            #expect(core.revision == revision + 1)
            let afterRevision = core.revision
            try LedgerBackup.restore(encoded, into: core)
            #expect(core.revision == afterRevision)
        }
    }

    @Test("K3 archives omitting the optional hash still decode and leave entries without an image")
    func omittedHashArchiveDecodes() throws {
        let source = try makeCore()
        _ = try addReceipt(source)
        let encoded = try LedgerBackup.export(source, includeImages: false, now: now, appVersion: "test", coreVersion: "1")
        var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        var state = try #require(object["state"] as? [String: Any])
        var receipts = try #require(state["receipts"] as? [[String: Any]])
        receipts[0].removeValue(forKey: "imageSHA256")
        state["receipts"] = receipts; object["state"] = state
        let legacy = try JSONSerialization.data(withJSONObject: object)
        let destination = try makeCore()
        let file = destination.store.receiptsDirectory.appendingPathComponent("receipt.png")
        try image.write(to: file)
        try LedgerBackup.restore(legacy, into: destination)
        #expect(destination.state.receipts.first?.imageSHA256 == nil)
        #expect(destination.state.entries.count == 1)
        #expect(!FileManager.default.fileExists(atPath: file.path))
        try CoreValidation.validate(destination.state)
    }

    @Test("K3 images-inclusive archive preserves hash, IDs, relationships and shared image bytes")
    func imageInclusiveRoundTrip() throws {
        let source = try makeCore()
        let (wallet, attached) = try addReceipt(source)
        var shared = try entry(wallet); shared.receiptID = attached.receiptID
        try execute(source, .addEntry(shared))
        let encoded = try LedgerBackup.export(source, includeImages: true, now: now, appVersion: "test", coreVersion: "1")
        let archive = try JSONDecoder().decode(LedgerBackupArchive.self, from: encoded)
        #expect(archive.images.count == 1 && archive.images.first?.data == image)
        let destination = try makeCore()
        try LedgerBackup.restore(encoded, into: destination)
        #expect(destination.state == source.state)
        #expect(try Data(contentsOf: destination.store.receiptsDirectory.appendingPathComponent("receipt.png")) == image)
        #expect(LedgerQueries.totalBalances(in: destination.state) == LedgerQueries.totalBalances(in: source.state))
    }

    @Test("S3 deleting retains metadata for undo; cleanup removes both orphan record and file")
    func orphanMetadataCleanup() throws {
        let core = try makeCore()
        let (_, expense) = try addReceipt(core)
        let metadata = try #require(core.state.receipts.first)
        try execute(core, .deleteEntry(expense.id))
        #expect(core.state.receipts == [metadata])
        #expect(throws: CoreError.historyNotEmpty) { try core.cleanupOrphanReceipts() }
        _ = try core.undo(now: now)
        #expect(core.state.entries.first?.receiptID == metadata.id)
        try execute(core, .deleteEntry(expense.id))
        core.clearUndoHistory()
        let file = core.store.receiptsDirectory.appendingPathComponent(metadata.fileName)
        let before = core.state, revision = core.revision
        core.store.failNextSave = true
        #expect(throws: CoreError.saveFailed) { try core.cleanupOrphanReceipts() }
        #expect(core.state == before && core.revision == revision)
        #expect(try core.store.read() == before)
        #expect(try Data(contentsOf: file) == image)
        #expect(try core.cleanupOrphanReceipts() == [metadata.fileName])
        #expect(core.state.receipts.isEmpty && !FileManager.default.fileExists(atPath: file.path))
        #expect(core.revision == revision + 1)
        try CoreValidation.validate(core.state)
        let afterRevision = core.revision
        #expect(try core.cleanupOrphanReceipts().isEmpty)
        #expect(core.revision == afterRevision)
    }

    @Test("S3 cleanup preserves shared referenced image and metadata while removing its unreferenced alias")
    func sharedReceiptCleanup() throws {
        let core = try makeCore()
        let (wallet, first) = try addReceipt(core)
        var alias = ReceiptValue(fileName: "receipt.png", capturedAt: now)
        alias.imageSHA256 = core.state.receipts.first?.imageSHA256
        var second = try entry(wallet)
        try execute(core, .addEntry(second, receipt: ReceiptInput(metadata: alias, image: image)))
        second = try #require(core.state.entries.first { $0.id == second.id })
        try execute(core, .deleteEntry(first.id))
        core.clearUndoHistory()
        #expect(try core.cleanupOrphanReceipts().isEmpty)
        #expect(core.state.receipts == [alias])
        #expect(core.state.entries == [second])
        #expect(try Data(contentsOf: core.store.receiptsDirectory.appendingPathComponent("receipt.png")) == image)
        try CoreValidation.validate(core.state)
    }

    @Test("P6 cleanup of a file-only orphan increments once and an empty cleanup is a no-op")
    func fileOnlyCleanupRevision() throws {
        let core = try makeCore()
        let file = core.store.receiptsDirectory.appendingPathComponent("cancelled.png")
        try image.write(to: file)
        let before = core.state, revision = core.revision
        #expect(try core.cleanupOrphanReceipts() == ["cancelled.png"])
        #expect(core.state == before && core.revision == revision + 1)
        #expect(try core.cleanupOrphanReceipts().isEmpty)
        #expect(core.revision == revision + 1)
    }

    @Test("P4/P6 a file-only entry update saves atomically, increments once and adds no model undo step")
    func fileOnlyEntryUpdate() throws {
        let core = try makeCore()
        let (_, entry) = try addReceipt(core)
        let metadata = try #require(core.state.receipts.first)
        let input = ReceiptInput(metadata: metadata, image: image)
        let file = core.store.receiptsDirectory.appendingPathComponent(metadata.fileName)
        try FileManager.default.removeItem(at: file)
        core.clearUndoHistory()
        let state = core.state, persisted = try core.store.read(), revision = core.revision
        core.store.failNextSave = true
        #expect(throws: CoreError.saveFailed) { try core.run(.updateEntry(entry, receipt: input), now: now) }
        #expect(core.state == state && core.revision == revision && core.undoCount == 0)
        #expect(try core.store.read() == persisted)
        #expect(!FileManager.default.fileExists(atPath: file.path))
        try execute(core, .updateEntry(entry, receipt: input))
        #expect(core.state == state && core.revision == revision + 1 && core.undoCount == 0)
        #expect(try Data(contentsOf: file) == image)
        try execute(core, .updateEntry(entry, receipt: input))
        #expect(core.revision == revision + 1 && core.undoCount == 0)
    }

    @Test("P6 Observation tracks cached state and revision without firing for preview, failure or no-op")
    func observableStateAndRevision() throws {
        let core = try makeCore(), wallet = makeWallet()
        try execute(core, .createWallet(wallet))
        core.clearUndoHistory()
        let counter = FixObservationCounter()
        withObservationTracking {
            _ = core.state
            _ = core.revision
        } onChange: {
            counter.increment()
        }
        let candidate = try entry(wallet)
        #expect(core.preview(.addEntry(candidate), now: now).isValid)
        try execute(core, .archiveWallet(wallet.id, archived: false))
        try core.reload()
        #expect(counter.value == 0)
        core.store.failNextSave = true
        #expect(throws: CoreError.saveFailed) { try core.run(.addEntry(candidate), now: now) }
        #expect(counter.value == 0)
        try execute(core, .addEntry(candidate))
        #expect(counter.value == 1)
        withObservationTracking {
            _ = core.revision
        } onChange: {
            counter.increment()
        }
        try execute(core, .deleteEntry(candidate.id))
        #expect(counter.value == 2)
    }

    @Test("S3 cleanup removes ordinary direct-child orphan filenames with spaces")
    func cleanupNonMetadataFilename() throws {
        let core = try makeCore()
        let name = "cancelled draft image.png"
        #expect(!ReceiptFiles.isSafeFilename(name))
        let file = core.store.receiptsDirectory.appendingPathComponent(name)
        try image.write(to: file)
        let state = core.state, revision = core.revision
        #expect(try core.cleanupOrphanReceipts() == [name])
        #expect(!FileManager.default.fileExists(atPath: file.path))
        #expect(core.state == state && core.revision == revision + 1)
        let wallet = makeWallet()
        try execute(core, .createWallet(wallet))
        let invalid = ReceiptInput(metadata: ReceiptValue(fileName: name, capturedAt: now), image: image)
        #expect(throws: CoreError.unsafeFilename(name)) { try core.run(.addEntry(entry(wallet), receipt: invalid), now: now) }
        #expect(core.state.receipts.isEmpty)
    }
}
