import Foundation
import SwiftData

@main
struct VerifyPayments {
    @MainActor
    static func main() throws {
        var checks = 0
        func expect(_ condition: Bool, _ label: String) {
            checks += 1
            guard condition else { fatalError("FAIL: \(label)") }
        }
        for method in ReceiptPaymentPolicy.methods {
            let label = ReceiptPaymentPolicy.displayName(method, language: .english)
            expect(ReceiptPaymentPolicy.detect("Payment method: \(label)\nTOTAL JPY 1200").method == method, "explicit payment \(method)")
        }
        let cases: [(String, String?, Bool)] = [
            ("レシート\n合計 1200円", "cash", false),
            ("PayPay 1,200", "paypay", false),
            ("楽天ポイント残高 900\n現金 1200", "cash", false),
            ("PayPayで100ポイント還元\n合計 1200", "cash", false),
            ("Visa accepted\n合計 1200", "cash", false),
            ("TRANSACTION ID: 123456\n合計 1200", "cash", false),
            ("支払方法 クレジット\nVISA ****1234", "visa", false),
            ("現金 500\nPayPay 700", nil, true),
            ("ポイント利用 200\n現金 1000", nil, true),
            ("ポイント利用 0\n現金 1200", "cash", false),
            ("支払い方法: みずほ銀行", "custom:みずほ銀行", false)
        ]
        for (text, method, review) in cases {
            let result = ReceiptPaymentPolicy.detect(text)
            expect(result.method == method && result.needsReview == review, "payment evidence \(text)")
        }
        expect(CurrencyPolicy.supportedCodes.count == 155, "155 current currency codes")
        expect(CurrencyPolicy.minorUnits(for: "JPY") == 0 && CurrencyPolicy.minorUnits(for: "KRW") == 0, "zero-decimal currencies")
        expect(CurrencyPolicy.minorUnits(for: "USD") == 2 && CurrencyPolicy.minorUnits(for: "IDR") == 2, "two-decimal currencies")
        expect(CurrencyPolicy.minorUnits(for: "KWD") == 3, "three-decimal currency")
        expect(CurrencyPolicy.parseMinorUnits("12.34", currencyCode: "USD", locale: Locale(identifier: "en_US")) == 1234, "dollars to cents")
        expect(CurrencyPolicy.parseMinorUnits("12,34", currencyCode: "EUR", locale: Locale(identifier: "fr_FR")) == 1234, "localized decimal comma")
        expect(CurrencyPolicy.parseMinorUnits("١٢٫٣٤", currencyCode: "USD", locale: Locale(identifier: "ar_SA")) == 1234, "Arabic decimal digits")
        expect(CurrencyPolicy.parseMinorUnits("12.345", currencyCode: "USD", locale: Locale(identifier: "en_US")) == nil, "excess decimals rejected without rounding")
        expect(CurrencyPolicy.parseMinorUnits("12.1", currencyCode: "JPY", locale: Locale(identifier: "en_US")) == nil, "yen fractions rejected")
        expect(CurrencyPolicy.parseMinorUnits("1,23", currencyCode: "USD", locale: Locale(identifier: "en_US")) == nil, "malformed grouping rejected")
        expect(CurrencyPolicy.parseMinorUnits(String(Int.max), currencyCode: "JPY", locale: Locale(identifier: "en_US")) == Int.max, "Int upper bound exact")
        expect(CurrencyPolicy.parseMinorUnits(String(Int.min), currencyCode: "JPY", locale: Locale(identifier: "en_US")) == Int.min, "Int lower bound exact")
        expect(CurrencyPolicy.parseMinorUnits(String(Int.max) + "0", currencyCode: "JPY", locale: Locale(identifier: "en_US")) == nil, "overflow rejected")
        expect(CurrencyPolicy.parseMinorUnits("1e3", currencyCode: "USD", locale: Locale(identifier: "en_US")) == nil, "scientific notation rejected")
        expect(CurrencyPolicy.parseMinorUnits("12.345", currencyCode: "KWD", locale: Locale(identifier: "en_US")) == 12345, "three-place decimals parsed")
        for identifier in ["en_US", "ja_JP", "zh_CN", "hi_IN", "es_ES", "ar_SA", "fr_FR", "id_ID", "ko_KR", "ru_RU", "pt_BR"] {
            let locale = Locale(identifier: identifier)
            let input = CurrencyPolicy.inputText(12345, currencyCode: "USD", locale: locale)
            expect(CurrencyPolicy.parseMinorUnits(input, currencyCode: "USD", locale: locale) == 12345, "currency input roundtrip \(identifier)")
            expect(!CurrencyPolicy.format(12345, currencyCode: "USD", locale: locale).isEmpty, "currency output \(identifier)")
        }
        let schema = Schema([Asset.self, Expense.self, RecurringItem.self, Category.self, PointCard.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let emptyContainer = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let emptyContext = ModelContext(emptyContainer)
        let cashDraft = Expense(title: "First receipt", amount: 1200, date: Date(), assetName: nil, paymentMethod: ReceiptPaymentPolicy.detect("合計1200円").method, balanceApplied: false)
        expect(try emptyContext.fetchCount(FetchDescriptor<Asset>()) == 0, "discardable draft creates no asset")
        try ExpenseLedger.save(cashDraft, previous: nil, context: emptyContext)
        let autoCash = try emptyContext.fetch(FetchDescriptor<Asset>()).first!
        expect(autoCash.paymentMethod == "cash" && autoCash.balance == -1200 && autoCash.isAutoCreated, "no payment evidence creates negative cash wallet")
        let cash = Asset(name: "Cash", balance: 5000, paymentMethod: "cash")
        let paypay = Asset(name: "My PayPay", balance: 3000, paymentMethod: "paypay")
        context.insert(cash); context.insert(paypay); try context.save()
        let expense = Expense(title: "Lunch", amount: 1200, date: Date(), assetName: nil, paymentMethod: "paypay", balanceApplied: false)
        expect(paypay.balance == 3000, "draft never deducts money")
        try ExpenseLedger.save(expense, previous: nil, context: context)
        expect(paypay.balance == 1800 && cash.balance == 5000, "detected provider charges only matching wallet")
        try ExpenseLedger.save(expense, previous: nil, context: context)
        expect(paypay.balance == 1800, "repeated draft save does not double-charge")
        let cancelledDraft = ExpenseLedger.draft(for: expense)
        cancelledDraft.amount = 1; cancelledDraft.title = "Discarded edit"
        try context.save()
        expect(cancelledDraft.modelContext == nil && expense.amount == 1200 && expense.title == "Lunch" && paypay.balance == 1800, "unfinished edit survives autosave without changing record or wallet")
        let savedDraft = ExpenseLedger.draft(for: expense)
        savedDraft.amount = 1100
        try ExpenseLedger.saveDraft(savedDraft, replacing: expense, context: context)
        let recordCount = try context.fetchCount(FetchDescriptor<Expense>())
        expect(recordCount == 1 && expense.amount == 1100 && paypay.balance == 1900, "saving edited draft updates original once without inserting another record")
        let rejectedDraft = ExpenseLedger.draft(for: expense)
        rejectedDraft.amount = -100
        do { try ExpenseLedger.saveDraft(rejectedDraft, replacing: expense, context: context); fatalError("negative draft accepted") }
        catch { expect(expense.amount == 1100 && paypay.balance == 1900, "rejected edited draft restores original record and balance") }
        let previous = ExpenseLedger.Snapshot(expense)
        expense.amount = 700; expense.assetName = cash.name; expense.paymentMethod = "cash"
        try ExpenseLedger.save(expense, previous: previous, context: context)
        expect(cash.balance == 4300 && paypay.balance == 3000, "editing reverses previous wallet and charges new one")
        try ExpenseLedger.delete(expense, context: context)
        expect(cash.balance == 5000, "deleting restores charge")
        let unknown = Expense(title: "Transit", amount: 250, date: Date(), assetName: nil, paymentMethod: "suica", balanceApplied: false)
        try ExpenseLedger.save(unknown, previous: nil, context: context)
        let suica = try context.fetch(FetchDescriptor<Asset>()).first { $0.paymentMethod == "suica" }!
        expect(suica.balance == -250 && suica.isAutoCreated, "unregistered provider becomes negative provisional asset")
        let second = Expense(title: "Transit again", amount: 150, date: Date(), assetName: nil, paymentMethod: "suica", balanceApplied: false)
        try ExpenseLedger.save(second, previous: nil, context: context)
        let walletCount = try context.fetchCount(FetchDescriptor<Asset>())
        expect(suica.balance == -400 && walletCount == 3, "reuse auto-created wallet")
        let income = Expense(title: "Income", amount: 800, date: Date(), assetName: cash.name, isIncome: true, balanceApplied: false)
        try ExpenseLedger.save(income, previous: nil, context: context)
        expect(cash.balance == 5800, "income sign")
        let oldIncome = ExpenseLedger.Snapshot(income); income.amount = 1000
        try ExpenseLedger.save(income, previous: oldIncome, context: context)
        expect(cash.balance == 6000, "editing income uses income sign")
        try ExpenseLedger.delete(income, context: context)
        expect(cash.balance == 5000, "deleting income reverses credit")
        context.insert(PointCard(name: "Sample points", memberNumber: "test-only", points: 900))
        try context.save()
        let pointCount = try context.fetchCount(FetchDescriptor<PointCard>())
        expect(cash.balance == 5000 && pointCount == 1, "point balances stay separate from cash")
        context.insert(Asset(name: "Another PayPay", balance: 50, paymentMethod: "paypay")); try context.save()
        let ambiguous = Expense(title: "Ambiguous", amount: 100, date: Date(), assetName: nil, paymentMethod: "paypay", balanceApplied: false)
        do { try ExpenseLedger.save(ambiguous, previous: nil, context: context); fatalError("ambiguous wallet accepted") }
        catch { expect(paypay.balance == 3000, "ambiguous wallet never silently charges the first wallet") }
        let dollar = Expense(title: "USD cash", amount: 1234, date: Date(), assetName: nil, paymentMethod: "cash", balanceApplied: false, currencyCode: "USD")
        try ExpenseLedger.save(dollar, previous: nil, context: context)
        let dollarWallet = try context.fetch(FetchDescriptor<Asset>()).first { $0.effectiveCurrencyCode == "USD" }!
        expect(dollarWallet.balance == -1234 && dollarWallet.name.contains("USD") && cash.balance == 5000, "USD provisional wallet never deducts yen")
        let anotherDollar = Expense(title: "USD cash again", amount: 100, date: Date(), assetName: nil, paymentMethod: "cash", balanceApplied: false, currencyCode: "USD")
        try ExpenseLedger.save(anotherDollar, previous: nil, context: context)
        expect(dollarWallet.balance == -1334, "same-currency automatic wallet reused")
        let wrongCurrency = Expense(title: "USD into yen", amount: 500, date: Date(), assetName: cash.name, paymentMethod: "cash", balanceApplied: false, currencyCode: "USD")
        do { try ExpenseLedger.save(wrongCurrency, previous: nil, context: context); fatalError("mixed currency debit accepted") }
        catch { expect(cash.balance == 5000 && dollarWallet.balance == -1334 && wrongCurrency.modelContext == nil, "mixed currency debit rejected before insertion") }
        let dollarEdit = ExpenseLedger.draft(for: dollar)
        expect(dollarEdit.currencyCode == "USD", "draft preserves currency")
        dollarEdit.amount = 1200
        try ExpenseLedger.saveDraft(dollarEdit, replacing: dollar, context: context)
        expect(dollar.currencyCode == "USD" && dollarWallet.balance == -1300, "edit preserves minor units and currency")
        try ExpenseLedger.delete(dollar, context: context)
        expect(dollarWallet.balance == -100 && cash.balance == 5000, "delete reverses same currency")
        expect(cash.currencyCode == nil && cash.effectiveCurrencyCode == "JPY", "legacy nil means JPY")
        print("PASS: \(checks) payment and SwiftData ledger checks (synthetic OCR text; not image recognition or live account sync).")
    }
}
