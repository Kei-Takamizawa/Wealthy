import Foundation

@main
struct VerifyCurrency {
    @MainActor static func main() {
        var checks = 0
        func expect(_ condition: Bool, _ label: String) {
            checks += 1
            precondition(condition, label)
        }
        for code in ["JPY", "USD", "KWD"] {
            for identifier in ["en_US", "fr_FR", "ar_SA"] {
                let locale = Locale(identifier: identifier)
                for amount in [Int.max, Int.min, 1234] {
                    let text = CurrencyPolicy.inputText(amount, currencyCode: code, locale: locale)
                    expect(CurrencyPolicy.parseMinorUnits(text, currencyCode: code, locale: locale) == amount,
                           "exact amount roundtrip \(code) \(identifier) \(amount)")
                }
            }
        }
        let suite = "wealthy-currency-checks-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let manager = CurrencyManager(defaults: defaults)
        expect(manager.selectedCodes == ["JPY"] && manager.selectedCode == "JPY", "first run defaults to JPY")
        manager.selectedCode = "usd"
        expect(manager.selectedCode == "USD" && manager.selectedCodes.contains("USD"), "active code normalized and selected")
        expect(CurrencyManager(defaults: defaults).selectedCode == "USD", "active code saved across manager initialization")
        manager.selectedCode = "bad"
        expect(manager.selectedCode == "JPY", "invalid active code defaults to JPY")
        manager.selectedCodes = ["usd", "USD", "XXX", "EUR"]
        expect(manager.selectedCodes == ["USD", "EUR"] && manager.selectedCode == "USD", "selection is valid unique and keeps an active member")
        manager.selectedCode = "EUR"
        let reopened = CurrencyManager(defaults: defaults)
        expect(reopened.selectedCodes == ["USD", "EUR"] && reopened.selectedCode == "EUR", "multiple selections persisted")
        manager.selectedCodes = ["USD"]
        expect(manager.selectedCode == "USD", "removing active selects remaining currency")
        manager.selectedCodes = []
        expect(manager.selectedCodes == ["JPY"] && manager.selectedCode == "JPY", "empty selection retains a valid currency")
        expect(CurrencyPolicy.supportedCodes.count == 155, "155 currency codes excluding fund units")
        expect(CurrencyPolicy.minorUnits(for: "VED") == 2 && CurrencyPolicy.isSupported("VED"), "both listed bolivar codes supported")
        let huge = CurrencyPolicy.sum([Int.max, 1])
        expect(huge == Decimal(string: "9223372036854775808")!, "totals exceed the record integer range without trapping")
        expect(CurrencyPolicy.sum([Int.min, -1]) == Decimal(string: "-9223372036854775809")!, "negative totals exceed integer range")
        expect(!CurrencyPolicy.format(huge, currencyCode: "JPY", locale: Locale(identifier: "en_US")).isEmpty, "oversized total remains displayable")
        print("PASS: \(checks) exact amount and persisted currency selection checks.")
    }
}
