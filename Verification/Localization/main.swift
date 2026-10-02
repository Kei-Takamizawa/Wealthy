import Foundation

@main
struct VerifyLocalization {
    @MainActor
    static func main() throws {
        var checks = 0
        func expect(_ condition: Bool, _ label: String) {
            checks += 1
            guard condition else { fatalError("FAIL: \(label)") }
        }
        let oldChoice = UserDefaults.standard.object(forKey: "selectedLanguage")
        defer {
            if let oldChoice { UserDefaults.standard.set(oldChoice, forKey: "selectedLanguage") }
            else { UserDefaults.standard.removeObject(forKey: "selectedLanguage") }
        }
        UserDefaults.standard.removeObject(forKey: "selectedLanguage")
        expect(AppLanguage.saved == .english, "new installations default to English")
        UserDefaults.standard.set("not-a-language", forKey: "selectedLanguage")
        expect(AppLanguage.saved == .english, "invalid saved choices fall back to English")
        expect(AppLanguage(rawValue: "English") == .english, "existing English preference remains readable")
        expect(AppLanguage(rawValue: "日本語") == .japanese, "existing Japanese preference remains readable")
        expect(AppLanguage.allCases.count == 11, "eleven display languages")
        expect(AppLanguage.allCases.filter(\.isRTL) == [.arabic], "Arabic layout direction")

        let catalogs = [CoreTranslations.strings, UITranslations.strings, FinanceTranslations.strings]
        let placeholders = try NSRegularExpression(pattern: "%([0-9]+\\$)?([-+0 #]*[0-9]*(\\.[0-9]+)?)?(ll|l)?([@diuf])")
        func signature(_ value: String) -> [String] {
            placeholders.matches(in: value, range: NSRange(value.startIndex..., in: value)).map {
                (value as NSString).substring(with: $0.range(at: 5))
            }.sorted()
        }
        for (index, catalog) in catalogs.enumerated() {
            let reference = catalog[.english]!
            expect(Set(catalog.keys) == Set(AppLanguage.allCases), "catalog \(index) contains every language")
            for language in AppLanguage.allCases {
                let entries = catalog[language]!
                expect(Set(entries.keys) == Set(reference.keys), "complete catalog \(index)/\(language.languageIdentifier)")
                for (key, value) in entries {
                    expect(!value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "nonempty \(key)/\(language.languageIdentifier)")
                    expect(signature(value) == signature(reference[key]!), "format arguments \(key)/\(language.languageIdentifier)")
                    expect(AppLocalization.text(key, language: language) == value, "lookup \(key)/\(language.languageIdentifier)")
                }
            }
        }
        let englishKeys = Set(CoreTranslations.strings[.english]!.keys).union(UITranslations.strings[.english]!.keys).union(FinanceTranslations.strings[.english]!.keys)
        expect(Set(L10n.allCases.map(\.rawValue)).isSubset(of: englishKeys), "all existing UI keys remain translated")
        let food = "RECEIPT grocery supermarket coffee bread TOTAL 1000 JPY"
        for language in AppLanguage.allCases {
            let manager = LanguageManager()
            manager.currentLanguage = language
            expect(AppLanguage.saved == language, "saved preference \(language.languageIdentifier)")
            expect(LanguageManager().currentLanguage == language, "reloaded preference \(language.languageIdentifier)")
            expect(AppLanguage.from(identifier: language.languageIdentifier) == language, "locale mapping \(language.languageIdentifier)")
            let amount = AppLocalization.jpyAmount(123_456, language: language)
            expect(!amount.isEmpty, "currency text \(language.languageIdentifier)")
            expect(manager.translateCategory(name: "固定費") == manager.text("categoryFixedCosts"), "legacy fixed-cost category display \(language.languageIdentifier)")
            let standardFood = manager.t(.catFood)
            expect(manager.translateCategory(name: "食費") == standardFood, "standard category display \(language.languageIdentifier)")
            expect(manager.translateCategory(name: "My custom grocery category") == "My custom grocery category", "custom names are preserved \(language.languageIdentifier)")
            expect(ReceiptCategoryPolicy.evidenceBasedCategory(text: food, existingCategories: [standardFood], language: language.languageIdentifier) == standardFood, "reuse translated category \(language.languageIdentifier)")
        }
        expect(AppLanguage.from(identifier: "zh_CN") == .chinese, "Chinese locale variant")
        expect(AppLanguage.from(identifier: "pt-BR") == .portuguese, "Portuguese locale variant")
        print("PASS: \(checks) localization checks; \(englishKeys.count) keys in 11 languages. Catalog completeness is not native-speaker review or device interaction.")
    }
}
