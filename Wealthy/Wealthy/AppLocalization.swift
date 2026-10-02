import Foundation

/// Foundation-only lookup, also used by non-UI services and verification tools.
nonisolated enum AppLocalization {
    static func text(_ key: String, language: AppLanguage) -> String {
        CoreTranslations.strings[language]?[key]
            ?? UITranslations.strings[language]?[key]
            ?? FinanceTranslations.strings[language]?[key]
            ?? CoreTranslations.strings[.english]?[key]
            ?? UITranslations.strings[.english]?[key]
            ?? FinanceTranslations.strings[.english]?[key]
            ?? key
    }

    static func format(_ key: String, language: AppLanguage, _ arguments: CVarArg...) -> String {
        String(format: text(key, language: language), locale: language.locale, arguments: arguments)
    }

    static func jpyAmount(_ amount: Int, language: AppLanguage) -> String {
        let formatter = NumberFormatter()
        formatter.locale = language.locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let result = "¥" + (formatter.string(from: NSNumber(value: amount)) ?? String(amount))
        return language.isRTL ? "\u{2066}" + result + "\u{2069}" : result
    }

    static func amount(_ amount: Int, currencyCode: String, language: AppLanguage) -> String {
        let result = CurrencyPolicy.format(amount, currencyCode: currencyCode, locale: language.locale)
        return language.isRTL ? "\u{2066}" + result + "\u{2069}" : result
    }
    static func amount(_ amount: Decimal, currencyCode: String, language: AppLanguage) -> String {
        let result = CurrencyPolicy.format(amount, currencyCode: currencyCode, locale: language.locale)
        return language.isRTL ? "\u{2066}" + result + "\u{2069}" : result
    }

    static let standardCategoryKeys = ["catFood", "catTransport", "catDaily", "catHobby", "catClothing", "catOthers", "categoryBooks", "categoryHomeDIY", "categoryHealthcare", "categoryShopping", "categoryFixedCosts", "unclassified"]

    static func categoryAliases(for key: String) -> [String] {
        let legacy: [String: [String]] = [
            "catFood": ["食品", "外食", "カフェ", "groceries", "dining", "cafe", "restaurants", "Cibo"],
            "catTransport": ["交通", "transportation", "travel", "Trasporti"],
            "catDaily": ["生活用品", "daily necessities", "household", "household goods", "Diario", "Quotidiano", "يومي"],
            "catHobby": ["hobbies", "entertainment", "Afición", "هواية"],
            "catClothing": ["衣類", "clothes", "Vestiti"],
            "catOthers": ["other", "miscellaneous", "Altro"],
            "categoryBooks": ["本", "book"],
            "categoryHomeDIY": ["住居", "住宅", "diy", "home", "housing"],
            "categoryHealthcare": ["医療", "health", "medical"],
            "categoryFixedCosts": ["固定費", "fixed costs", "fixed expenses"],
            "unclassified": ["unknown", "none", "n/a"]
        ]
        let relatedKey = ["catDaily": "categoryHousehold", "catTransport": "categoryTransportation"][key]
        let related = relatedKey.map { other in AppLanguage.allCases.compactMap { CoreTranslations.strings[$0]?[other] } } ?? []
        return AppLanguage.allCases.map { text(key, language: $0) } + related + (legacy[key] ?? [])
    }

    static func standardCategoryKey(for name: String) -> String? {
        let value = normalized(name)
        return standardCategoryKeys.first { key in categoryAliases(for: key).contains { normalized($0) == value } }
    }

    static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.widthInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }
}
