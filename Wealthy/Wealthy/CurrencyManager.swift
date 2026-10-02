import Foundation
import Combine

/// Selection affects new entries and totals, never relabels existing records or converts balances.
@MainActor
final class CurrencyManager: ObservableObject {
    static let shared = CurrencyManager()
    private let defaults: UserDefaults
    static let defaultsKey = "selectedCurrency"
    static let selectedCodesDefaultsKey = "selectedCurrencies"
    @Published var selectedCodes: [String] {
        didSet {
            let sanitized = Self.sanitize(selectedCodes)
            if selectedCodes != sanitized { selectedCodes = sanitized }
            defaults.set(sanitized, forKey: Self.selectedCodesDefaultsKey)
            if !sanitized.contains(selectedCode) { selectedCode = sanitized[0] }
        }
    }
    /// Active currency supplies the default for new records and single-currency charts.
    @Published var selectedCode: String {
        didSet {
            let normalized = CurrencyPolicy.normalizedCode(selectedCode)
            if selectedCode != normalized { selectedCode = normalized }
            if !selectedCodes.contains(normalized) { selectedCodes.append(normalized) }
            defaults.set(normalized, forKey: Self.defaultsKey)
        }
    }
    let supportedCodes = CurrencyPolicy.supportedCodes
    private static func sanitize(_ codes: [String]) -> [String] {
        var seen = Set<String>()
        let result = codes.compactMap { code -> String? in
            let normalized = code.uppercased()
            return CurrencyPolicy.isSupported(normalized) && seen.insert(normalized).inserted ? normalized : nil
        }
        return result.isEmpty ? [CurrencyPolicy.defaultCode] : result
    }
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let active = CurrencyPolicy.normalizedCode(defaults.string(forKey: Self.defaultsKey))
        let stored = defaults.stringArray(forKey: Self.selectedCodesDefaultsKey) ?? [active]
        let selected = Self.sanitize(stored)
        selectedCodes = selected
        selectedCode = selected.contains(active) ? active : selected[0]
    }
    func format(_ amount: Int, currencyCode: String? = nil, locale: Locale = .current) -> String {
        CurrencyPolicy.format(amount, currencyCode: currencyCode ?? selectedCode, locale: locale)
    }
    func parse(_ text: String, locale: Locale = .current) -> Int? {
        CurrencyPolicy.parseMinorUnits(text, currencyCode: selectedCode, locale: locale)
    }
}
