import Foundation
import Testing
@testable import WealthyCore

@MainActor
@Suite("Foundation and isolated persistence")
struct FoundationTests {
    @Test("S1: ten default categories are seeded once without wallets")
    func seedingIsIdempotent() throws {
        let store = try LedgerStore()
        let before = try store.read()
        #expect(before.categories.count == 10)
        #expect(before.categories.filter { $0.kind == .expense }.count == 7)
        #expect(before.categories.filter { $0.kind == .income }.count == 3)
        #expect(before.wallets.isEmpty)
        try store.seedDefaults()
        #expect(try store.read() == before)
    }

    @Test("S1: a new disk store and receipts directory never alter legacy files")
    func diskStoreIsSeparateAndPersists() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let legacyStore = directory.appendingPathComponent("default.store")
        let legacyReceipts = directory.appendingPathComponent("Documents", isDirectory: true)
        try FileManager.default.createDirectory(at: legacyReceipts, withIntermediateDirectories: true)
        let legacyImage = legacyReceipts.appendingPathComponent("old-receipt.jpg")
        let bytes = Data([3, 2, 1])
        try bytes.write(to: legacyStore)
        try bytes.write(to: legacyImage)
        let store = try LedgerStore(inMemory: false, directory: directory, seed: false)
        #expect(store.storeURL?.lastPathComponent == "WealthyLedger.store")
        #expect(store.storeURL != legacyStore)
        #expect(store.receiptsDirectory != legacyReceipts)
        let state = LedgerState(wallets: [WalletValue(name: "Bank", currencyCode: "USD")])
        try store.replace(state)
        let reopened = try LedgerStore(inMemory: false, directory: directory, seed: false)
        #expect(try reopened.read() == state)
        #expect(try Data(contentsOf: legacyStore) == bytes)
        #expect(try Data(contentsOf: legacyImage) == bytes)
    }

    @Test("All seven V1 models preserve every value through persistence")
    func allRecordsRoundTrip() throws {
        let day = try LedgerDay(year: 2026, month: 10, day: 5)
        let wallet = WalletValue(name: "Cash", currencyCode: "JPY", paymentMethodKey: "cash", isProvisional: true)
        let category = CategoryValue(kind: .expense, systemKey: "catFood", customName: "Meals")
        let receipt = ReceiptValue(fileName: "receipt.jpg")
        let rule = RuleValue(title: "Lunch", amount: 100, currencyCode: "JPY", walletID: wallet.id,
                             categoryID: category.id, schedule: .weekly(weekday: 2), startDay: day,
                             endDay: day, lastPostedDay: day, lastProcessedDay: day)
        let entry = EntryValue(kind: .expense, amount: 100, currencyCode: "JPY", day: day, walletID: wallet.id,
                               categoryID: category.id, title: "Lunch", note: "Note", source: .recurring,
                               reviewFlags: [.amountUncertain, .dateFromCaptureTime], receiptID: receipt.id,
                               recurringRuleID: rule.id, occurrenceDay: day)
        let state = LedgerState(wallets: [wallet], categories: [category], entries: [entry], receipts: [receipt],
                                rules: [rule], budgets: [BudgetValue(currencyCode: "JPY", categoryID: category.id, monthlyAmount: 1000)],
                                pointCards: [PointCardValue(name: "Points", memberNumber: "1234", points: 99, expiryDay: day)])
        let store = try LedgerStore(seed: false)
        try store.replace(state)
        #expect(try store.read() == state)
    }

    @Test("L12: failure injection rolls back an entire replacement")
    func replacementFailureIsAtomic() throws {
        let store = try LedgerStore(seed: false)
        let original = LedgerState(wallets: [WalletValue(name: "Original", currencyCode: "JPY")])
        try store.replace(original)
        store.failNextSave = true
        #expect(throws: CoreError.saveFailed) {
            try store.replace(LedgerState(wallets: [WalletValue(name: "Other", currencyCode: "USD")]))
        }
        #expect(try store.read() == original)
        #expect(!store.failNextSave)
    }

    @Test("Civil days validate leap dates during initialization and decoding")
    func dayValidationAndArithmetic() throws {
        #expect(throws: CoreError.invalidField("day", nil)) { try LedgerDay(year: 2027, month: 2, day: 29) }
        #expect(throws: CoreError.invalidField("day", nil)) { try LedgerDay(year: 2026, month: 4, day: 31) }
        #expect(throws: CoreError.invalidField("day", nil)) {
            try JSONDecoder().decode(LedgerDay.self, from: Data("{\"year\":2027,\"month\":2,\"day\":29}".utf8))
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let leap = try LedgerDay(year: 2028, month: 2, day: 29)
        #expect(try leap.adding(days: 1, calendar: calendar) == LedgerDay(year: 2028, month: 3, day: 1))
        #expect(try LedgerDay(date: leap.date(calendar: calendar), calendar: calendar) == leap)
        var japanese = Calendar(identifier: .japanese)
        japanese.timeZone = calendar.timeZone
        #expect(try LedgerDay(date: leap.date(calendar: calendar), calendar: japanese) == leap)
    }

    @Test("Currency scales, exact parsing, overflow and unsupported codes")
    func currencyPrimitives() throws {
        let locale = Locale(identifier: "en_US")
        #expect(try CoreCurrency.minorUnits(for: "JPY") == 0)
        #expect(try CoreCurrency.minorUnits(for: "usd") == 2)
        #expect(try CoreCurrency.minorUnits(for: "KWD") == 3)
        #expect(try CoreCurrency.parseMinorUnits("1,234.56", currencyCode: "USD", locale: locale) == 123456)
        #expect(try CoreCurrency.parseMinorUnits("1.234", currencyCode: "USD", locale: locale) == nil)
        #expect(try CoreCurrency.parseMinorUnits("9223372036854775808", currencyCode: "JPY", locale: locale) == nil)
        #expect(try CoreCurrency.parseMinorUnits(String(Int.max), currencyCode: "JPY", locale: locale) == Int.max)
        #expect(try CoreCurrency.parseMinorUnits(String(Int.min), currencyCode: "JPY", locale: locale) == Int.min)
        #expect(try CoreCurrency.inputText(123, currencyCode: "USD", locale: locale) == "1.23")
        #expect(throws: CoreError.unsupportedCurrency("XYZ")) { try CoreCurrency.minorUnits(for: "XYZ") }
        #expect(throws: CoreError.unsupportedCurrency("XYZ")) { try CoreCurrency.parseMinorUnits("1", currencyCode: "XYZ", locale: locale) }
        #expect(CoreCurrency.sum([Int.max, Int.max]) == Decimal(string: "18446744073709551614"))
    }
}
