import Foundation
import ImageIO
import Testing
@testable import WealthyCore

@Suite("Versioned ledger backup")
@MainActor
struct BackupTests {
    let now = Date(timeIntervalSince1970: 1_791_158_400.125)
    var day: LedgerDay { try! LedgerDay(year: 2026, month: 10, day: 5) }
    var image: Data { Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==")! }
    var alternateImage: Data { Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgYPj/HwADAgH/5ncLrgAAAABJRU5ErkJggg==")! }
    var animatedImage: Data { Data(base64Encoded: "R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAICRAEAIfkEAQAAAAAsAAAAAAEAAQAAAgJEAQA7")! }
    func core() throws -> LedgerCore {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return LedgerCore(store: try LedgerStore(inMemory: true, seed: false), calendar: calendar)
    }
    func fixture() -> LedgerState {
        let cash = WalletValue(name: "Cash", currencyCode: "JPY", kind: .cash,
                               paymentMethodKey: "cash", colorKey: "coral", iconKey: "banknote",
                               sortOrder: 2, createdAt: now, isProvisional: true)
        let bank = WalletValue(name: "Bank", currencyCode: "JPY", kind: .bankAccount, createdAt: now)
        let category = CategoryValue(kind: .expense, systemKey: "catFood", customName: "Dining",
                                     iconKey: "fork.knife", colorKey: "green", sortOrder: 3)
        let receipt = ReceiptValue(fileName: "shared.png", capturedAt: now)
        var rule = RuleValue(title: "Lunch", amount: 200, currencyCode: "JPY", walletID: cash.id,
                             categoryID: category.id, schedule: .weekly(weekday: 2), startDay: day,
                             isPaused: true, lastPostedDay: day, lastProcessedDay: day, createdAt: now)
        rule.startDay = try! LedgerDay(year: 2026, month: 9, day: 1)
        rule.pauseStartedDay = day
        rule.pausedPeriods = [try! LedgerPeriod(start: LedgerDay(year: 2026, month: 9, day: 1),
                                               end: LedgerDay(year: 2026, month: 9, day: 2))]
        var expense = EntryValue(kind: .expense, amount: 200, currencyCode: "JPY", day: day,
                                 walletID: cash.id, timestamp: now, categoryID: category.id,
                                 title: "Restaurant", note: "All fields", source: .recurring,
                                 reviewFlags: [.paymentMethodUncertain, .dateFromCaptureTime], receiptID: receipt.id,
                                 recurringRuleID: rule.id, occurrenceDay: day, createdAt: now, updatedAt: now)
        expense.updatedAt = now.addingTimeInterval(0.25)
        let second = EntryValue(kind: .income, amount: 500, currencyCode: "JPY", day: day,
                                walletID: cash.id, timestamp: now.addingTimeInterval(0.5), title: "Refund",
                                source: .receipt, receiptID: receipt.id, createdAt: now, updatedAt: now)
        let transfer = EntryValue(kind: .transfer, amount: 100, currencyCode: "JPY", day: day,
                                  walletID: cash.id, timestamp: now, counterpartWalletID: bank.id,
                                  title: "Deposit", createdAt: now, updatedAt: now)
        return LedgerState(wallets: [cash, bank], categories: [category], entries: [expense, second, transfer],
                           receipts: [receipt], rules: [rule],
                           budgets: [BudgetValue(currencyCode: "JPY", monthlyAmount: 2_000),
                                     BudgetValue(currencyCode: "JPY", categoryID: category.id, monthlyAmount: 500)],
                           pointCards: [PointCardValue(name: "Rewards", memberNumber: "0001", points: 42,
                                                       expiryDay: day, colorKey: "gold", sortOrder: 7)])
    }
    func archive(_ state: LedgerState? = nil, withImages: Bool = false) -> LedgerBackupArchive {
        LedgerBackupArchive(exportDate: now, appVersion: "0.1.1", coreVersion: "1",
                            state: state ?? fixture(), receiptImagesIncluded: withImages,
                            images: withImages ? [BackupImage(fileName: "shared.png", data: image)] : [])
    }
    func destination() throws -> LedgerCore {
        let core = try core()
        let wallet = WalletValue(name: "Existing", currencyCode: "USD", createdAt: now)
        try core.run(.createWallet(wallet, openingBalance: 123), now: now)
        try image.write(to: core.store.receiptsDirectory.appendingPathComponent("existing.png"))
        return core
    }
    func files(_ core: LedgerCore) throws -> [String: Data] {
        var result: [String: Data] = [:]
        for name in try FileManager.default.contentsOfDirectory(atPath: core.store.receiptsDirectory.path) {
            result[name] = try Data(contentsOf: core.store.receiptsDirectory.appendingPathComponent(name))
        }
        return result
    }
    func reject(_ data: Data, error: CoreError) throws {
        let core = try destination(), before = try core.snapshot(), oldFiles = try files(core), count = core.undoCount
        #expect(throws: error) { try LedgerBackup.restore(data, into: core) }
        #expect(try core.snapshot() == before)
        #expect(try files(core) == oldFiles)
        #expect(core.undoCount == count)
    }
    func reject(_ archive: LedgerBackupArchive, error: CoreError) throws {
        try reject(JSONEncoder().encode(archive), error: error)
    }

    @Test("K1 all seven record types round trip with and without shared images")
    func roundTrip() throws {
        for included in [false, true] {
            let source = try core(), state = fixture()
            try source.store.replace(state)
            try image.write(to: source.store.receiptsDirectory.appendingPathComponent("shared.png"))
            let size = try LedgerBackup.size(in: source)
            #expect(size.count == 1 && size.bytes == image.count)
            let data = try LedgerBackup.export(source, includeImages: included, now: now, appVersion: "0.1.1", coreVersion: "1")
            let decoded = try JSONDecoder().decode(LedgerBackupArchive.self, from: data)
            #expect(decoded.format == "wealthy-ledger" && decoded.version == 1)
            #expect(decoded.state == state && decoded.exportDate == now)
            #expect(decoded.images.count == (included ? 1 : 0))
            #expect(decoded.receiptImagesIncluded == included)
            let destination = try core()
            try LedgerBackup.restore(data, into: destination)
            #expect(try destination.snapshot() == state)
            for wallet in state.wallets {
                #expect(LedgerMath.balance(wallet.id, in: try destination.snapshot()) == LedgerMath.balance(wallet.id, in: state))
            }
            if included {
                #expect(try Data(contentsOf: destination.store.receiptsDirectory.appendingPathComponent("shared.png")) == image)
            } else {
                #expect(try files(destination).isEmpty)
            }
        }
    }

    @Test("U2 successful replace restore clears undo history")
    func restoreClearsHistory() throws {
        let core = try destination()
        #expect(core.undoCount == 1)
        let incoming = archive()
        try LedgerBackup.restore(JSONEncoder().encode(incoming), into: core)
        #expect(try core.snapshot() == incoming.state)
        #expect(core.undoCount == 0)
        #expect(try core.undo(now: now) == nil)
    }

    @Test("K2 malformed legacy and unknown format versions reject atomically")
    func headers() throws {
        try reject(Data("{invalid json".utf8), error: .malformedBackup)
        for version in 1...4 {
            try reject(Data("{\"schemaVersion\":\(version),\"expenses\":[]}".utf8), error: .legacyBackupNotSupported)
        }
        var unknown = archive(); unknown.version = 99
        try reject(unknown, error: .unsupportedBackupVersion(99))
        unknown = archive(); unknown.format = "foreign-ledger"
        try reject(unknown, error: .invalidBackupFormat("foreign-ledger"))
    }

    @Test("K2 duplicate IDs dangling references currencies and amounts reject atomically")
    func records() throws {
        var incoming = archive()
        incoming.state.wallets[1].id = incoming.state.wallets[0].id
        try reject(incoming, error: .duplicateID(incoming.state.wallets[0].id))
        incoming = archive(); let missing = UUID(); incoming.state.entries[0].walletID = missing
        try reject(incoming, error: .danglingReference("walletID", missing))
        incoming = archive(); incoming.state.entries[0].receiptID = missing
        try reject(incoming, error: .danglingReference("receiptID", missing))
        incoming = archive(); incoming.state.wallets[0].currencyCode = "ZZZ"
        try reject(incoming, error: .unsupportedCurrency("ZZZ"))
        incoming = archive(); incoming.state.entries[0].currencyCode = "USD"
        try reject(incoming, error: .currencyMismatch(incoming.state.wallets[0].id))
        for amount in [0, -1] {
            incoming = archive(); incoming.state.entries[0].amount = amount
            try reject(incoming, error: .invalidField("amount", incoming.state.entries[0].id))
        }
    }

    @Test("K2 unsafe file names apply to metadata and embedded images")
    func unsafeNames() throws {
        for name in ["", ".", "..", "../receipt.png", "a/b.png", "bad name.png", String(repeating: "a", count: 256)] {
            var incoming = archive(); incoming.state.receipts[0].fileName = name
            try reject(incoming, error: .unsafeFilename(name))
            incoming = archive(withImages: true); incoming.images[0].fileName = name
            try reject(incoming, error: .unsafeFilename(name))
        }
    }

    @Test("K2 undecodable truncated and multiframe images reject atomically")
    func invalidImages() throws {
        let animation = try #require(CGImageSourceCreateWithData(animatedImage as CFData, nil))
        #expect(CGImageSourceGetCount(animation) == 2)
        for bytes in [Data("not an image".utf8), Data(image.prefix(40)), animatedImage] {
            var incoming = archive(withImages: true); incoming.images[0].data = bytes
            try reject(incoming, error: .invalidImage("shared.png"))
        }
    }

    @Test("K2 embedded image membership flag and duplicates reject atomically")
    func imageMembership() throws {
        var incoming = archive(withImages: true)
        incoming.images.append(incoming.images[0])
        try reject(incoming, error: .invalidField("duplicateImage", nil))
        incoming = archive(withImages: true); incoming.images = []
        try reject(incoming, error: .invalidImage("shared.png"))
        incoming = archive(withImages: true); incoming.images.append(BackupImage(fileName: "unknown.png", data: image))
        try reject(incoming, error: .invalidImage("unknown.png"))
        incoming = archive(withImages: true); incoming.receiptImagesIncluded = false
        try reject(incoming, error: .invalidField("receiptImagesIncluded", nil))
    }

    @Test("K2 incoming recurring rules budgets and point cards are fully validated")
    func planningRecords() throws {
        var incoming = archive(); incoming.state.rules[0].amount = 0
        try reject(incoming, error: .invalidField("amount", incoming.state.rules[0].id))
        incoming = archive(); incoming.state.rules[0].schedule = .monthly(day: 32)
        try reject(incoming, error: .invalidField("scheduleDay", incoming.state.rules[0].id))
        incoming = archive(); let missing = UUID(); incoming.state.rules[0].categoryID = missing
        try reject(incoming, error: .danglingReference("categoryID", missing))
        incoming = archive(); incoming.state.budgets[0].monthlyAmount = -1
        try reject(incoming, error: .invalidField("monthlyAmount", incoming.state.budgets[0].id))
        incoming = archive(); incoming.state.budgets.append(BudgetValue(currencyCode: "JPY", monthlyAmount: 100))
        try reject(incoming, error: .invalidField("duplicateBudget", incoming.state.budgets.last!.id))
        incoming = archive(); incoming.state.pointCards[0].points = -1
        try reject(incoming, error: .invalidField("points", incoming.state.pointCards[0].id))
    }

    @Test("K2 failed restore rolls back overwritten images new images records and undo")
    func restoreSaveFailure() throws {
        let core = try destination(), before = try core.snapshot(), count = core.undoCount
        try image.write(to: core.store.receiptsDirectory.appendingPathComponent("shared.png"))
        let oldFiles = try files(core)
        var incoming = archive(withImages: true)
        incoming.images[0].data = alternateImage
        let additional = ReceiptValue(fileName: "new.png", capturedAt: now)
        incoming.state.receipts.append(additional)
        incoming.state.entries[1].receiptID = additional.id
        incoming.images.append(BackupImage(fileName: "new.png", data: image))
        core.store.failNextSave = true
        #expect(throws: CoreError.saveFailed) { try LedgerBackup.restore(JSONEncoder().encode(incoming), into: core) }
        #expect(try core.snapshot() == before)
        #expect(try files(core) == oldFiles)
        #expect(core.undoCount == count)
    }
    @Test("Records-only restore removes stale filename collision atomically")
    func recordsOnlyCollision() throws {
        let core = try destination()
        let directory = core.store.receiptsDirectory
        try alternateImage.write(to: directory.appendingPathComponent("shared.png"))
        let before = try core.snapshot(), oldFiles = try files(core), history = core.undoCount
        let incoming = archive()
        let encoded = try JSONEncoder().encode(incoming)
        core.store.failNextSave = true
        #expect(throws: CoreError.saveFailed) { try LedgerBackup.restore(encoded, into: core) }
        #expect(try core.snapshot() == before)
        #expect(try files(core) == oldFiles)
        #expect(core.undoCount == history)
        try LedgerBackup.restore(encoded, into: core)
        #expect(try core.snapshot() == incoming.state)
        #expect(try core.snapshot().receipts == incoming.state.receipts)
        #expect(!FileManager.default.fileExists(atPath: directory.appendingPathComponent("shared.png").path))
        #expect(try Data(contentsOf: directory.appendingPathComponent("existing.png")) == image)
        #expect(core.undoCount == 0)
    }

}
