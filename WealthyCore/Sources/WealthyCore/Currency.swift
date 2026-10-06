import Foundation

/// Integer amounts are ISO 4217 minor units. Unsupported currencies throw.
/// Source: SIX List One, published 2026-09-17. Fund/accounting units are excluded.
/// https://www.six-group.com/dam/download/financial-information/data-center/iso-currrency/lists/list-one.xml
public enum CoreCurrency {
    public static let defaultCode = "JPY"
    private static let scales: [String: Int] = [
        "AED": 2, "AFN": 2, "ALL": 2, "AMD": 2, "AOA": 2, "ARS": 2, "AUD": 2, "AWG": 2,
        "AZN": 2, "BAM": 2, "BBD": 2, "BDT": 2, "BHD": 3, "BIF": 0, "BMD": 2, "BND": 2,
        "BOB": 2, "BRL": 2, "BSD": 2, "BTN": 2, "BWP": 2, "BYN": 2, "BZD": 2, "CAD": 2,
        "CDF": 2, "CHF": 2, "CLP": 0, "CNY": 2, "COP": 2, "CRC": 2, "CUP": 2, "CVE": 2,
        "CZK": 2, "DJF": 0, "DKK": 2, "DOP": 2, "DZD": 2, "EGP": 2, "ERN": 2, "ETB": 2,
        "EUR": 2, "FJD": 2, "FKP": 2, "GBP": 2, "GEL": 2, "GHS": 2, "GIP": 2, "GMD": 2,
        "GNF": 0, "GTQ": 2, "GYD": 2, "HKD": 2, "HNL": 2, "HTG": 2, "HUF": 2, "IDR": 2,
        "ILS": 2, "INR": 2, "IQD": 3, "IRR": 2, "ISK": 0, "JMD": 2, "JOD": 3, "JPY": 0,
        "KES": 2, "KGS": 2, "KHR": 2, "KMF": 0, "KPW": 2, "KRW": 0, "KWD": 3, "KYD": 2,
        "KZT": 2, "LAK": 2, "LBP": 2, "LKR": 2, "LRD": 2, "LSL": 2, "LYD": 3, "MAD": 2,
        "MDL": 2, "MGA": 2, "MKD": 2, "MMK": 2, "MNT": 2, "MOP": 2, "MRU": 2, "MUR": 2,
        "MVR": 2, "MWK": 2, "MXN": 2, "MYR": 2, "MZN": 2, "NAD": 2, "NGN": 2, "NIO": 2,
        "NOK": 2, "NPR": 2, "NZD": 2, "OMR": 3, "PAB": 2, "PEN": 2, "PGK": 2, "PHP": 2,
        "PKR": 2, "PLN": 2, "PYG": 0, "QAR": 2, "RON": 2, "RSD": 2, "RUB": 2, "RWF": 0,
        "SAR": 2, "SBD": 2, "SCR": 2, "SDG": 2, "SEK": 2, "SGD": 2, "SHP": 2, "SLE": 2,
        "SOS": 2, "SRD": 2, "SSP": 2, "STN": 2, "SVC": 2, "SYP": 2, "SZL": 2, "THB": 2,
        "TJS": 2, "TMT": 2, "TND": 3, "TOP": 2, "TRY": 2, "TTD": 2, "TWD": 2, "TZS": 2,
        "UAH": 2, "UGX": 0, "USD": 2, "UYU": 2, "UZS": 2, "VED": 2, "VES": 2, "VND": 0, "VUV": 0,
        "WST": 2, "XAF": 0, "XCD": 2, "XCG": 2, "XOF": 0, "XPF": 0, "YER": 2, "ZAR": 2,
        "ZMW": 2, "ZWG": 2,
    ]
    public static let supportedCodes = scales.keys.sorted()
    public static func isSupported(_ code: String) -> Bool { scales[code.uppercased()] != nil }
    public static func normalizedCode(_ code: String) throws -> String {
        guard isSupported(code) else { throw CoreError.unsupportedCurrency(code) }
        return code.uppercased()
    }
    public static func minorUnits(for code: String) throws -> Int {
        let normalized = try normalizedCode(code)
        return scales[normalized]!
    }
    public static func localizedName(for code: String, locale: Locale = .current) -> String {
        locale.localizedString(forCurrencyCode: code) ?? code
    }
    private static func decimalAmount(_ amount: Decimal, currencyCode: String) throws -> NSDecimalNumber {
        let scale = try minorUnits(for: currencyCode)
        return NSDecimalNumber(decimal: amount).dividing(by: NSDecimalNumber(mantissa: 1, exponent: Int16(scale), isNegative: false))
    }
    /// Historical totals may exceed a single record's Int range.
    public static func sum<S: Sequence>(_ amounts: S) -> Decimal where S.Element == Int {
        amounts.reduce(Decimal.zero) { $0 + Decimal(string: String($1))! }
    }
    public static func format(_ amount: Int, currencyCode: String, locale: Locale = .current) throws -> String {
        try format(Decimal(string: String(amount))!, currencyCode: currencyCode, locale: locale)
    }
    public static func format(_ amount: Decimal, currencyCode: String, locale: Locale = .current) throws -> String {
        let code = try normalizedCode(currencyCode)
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.minimumFractionDigits = try minorUnits(for: code)
        formatter.maximumFractionDigits = try minorUnits(for: code)
        let value = try decimalAmount(amount, currencyCode: code)
        return formatter.string(from: value) ?? "\(code) \(value.stringValue)"
    }
    /// The approved four-language UI uses a yen symbol and grouping even below 10,000 in Spanish.
    public static func formatForDisplay(_ amount: Int, currencyCode: String, locale: Locale = .current) throws -> String {
        let code = try normalizedCode(currencyCode)
        guard code == "JPY" else { return try format(amount, currencyCode: code, locale: locale) }
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = locale.groupingSeparator ?? ","
        let number = formatter.string(from: NSNumber(value: amount)) ?? String(amount)
        let language = locale.language.languageCode?.identifier
        if language == "es" { return number + " ¥" }
        let symbol = language == "ko" ? "JP¥" : "¥"
        if number.hasPrefix("-") { return "-" + symbol + number.dropFirst() }
        return symbol + number
    }
    public static func inputText(_ amount: Int, currencyCode: String, locale: Locale = .current) throws -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = try minorUnits(for: currencyCode)
        formatter.maximumFractionDigits = try minorUnits(for: currencyCode)
        return formatter.string(from: try decimalAmount(Decimal(string: String(amount))!, currencyCode: currencyCode)) ?? String(amount)
    }
    /// Reject excess precision and overflow; never round user money or parse through Double.
    public static func parseMinorUnits(_ text: String, currencyCode: String, locale: Locale = .current) throws -> Int? {
        _ = try normalizedCode(currencyCode)
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        let decimal = formatter.decimalSeparator ?? "."
        let grouping = formatter.groupingSeparator ?? ","
        // NumberFormatter emits directional marks for some RTL locales.
        var value = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\u{061c}", with: "")
            .replacingOccurrences(of: "\u{200e}", with: "")
            .replacingOccurrences(of: "\u{200f}", with: "")
        var negative = false
        if value.hasPrefix("-") || value.hasPrefix("−") { negative = true; value.removeFirst() }
        else if value.hasPrefix("+") { value.removeFirst() }
        guard !value.isEmpty else { return nil }
        // A canonical ASCII dot is accepted unless the locale uses it for grouping.
        let separator = decimal != "." && grouping != "." && !value.contains(decimal) && value.contains(".") ? "." : decimal
        let pieces = value.components(separatedBy: separator)
        guard pieces.count <= 2 else { return nil }
        var integer = pieces[0]
        let fraction = pieces.count == 2 ? pieces[1] : ""
        guard !integer.isEmpty, pieces.count == 1 || !fraction.isEmpty else { return nil }
        if integer.contains(grouping) {
            let groups = integer.components(separatedBy: grouping)
            let primary = max(1, formatter.groupingSize)
            let secondary = formatter.secondaryGroupingSize > 0 ? formatter.secondaryGroupingSize : primary
            guard groups.count > 1, (1...secondary).contains(groups[0].count), groups.last?.count == primary,
                  groups.dropFirst().dropLast().allSatisfy({ $0.count == secondary }) else { return nil }
            integer = groups.joined()
        }
        let scale = try minorUnits(for: currencyCode)
        guard fraction.count <= scale else { return nil }
        let digits = integer + fraction + String(repeating: "0", count: scale - fraction.count)
        let limit = UInt(Int.max) + (negative ? 1 : 0)
        var result: UInt = 0
        for character in digits {
            guard let digit = character.wholeNumberValue, (0...9).contains(digit) else { return nil }
            let product = result.multipliedReportingOverflow(by: 10)
            let sum = product.partialValue.addingReportingOverflow(UInt(digit))
            guard !product.overflow, !sum.overflow, sum.partialValue <= limit else { return nil }
            result = sum.partialValue
        }
        if negative { return result == UInt(Int.max) + 1 ? Int.min : -Int(result) }
        return Int(result)
    }
}
