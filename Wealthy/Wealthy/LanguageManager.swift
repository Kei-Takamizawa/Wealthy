import Foundation
import Combine

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    @Published var currentLanguage: AppLanguage
    private var cancellables = Set<AnyCancellable>()

    init() {
        currentLanguage = .saved
        $currentLanguage.dropFirst().sink { language in
            UserDefaults.standard.set(language.rawValue, forKey: "selectedLanguage")
        }.store(in: &cancellables)
    }

    func t(_ key: L10n) -> String { text(key.rawValue) }
    func text(_ key: String) -> String { AppLocalization.text(key, language: currentLanguage) }
    func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: currentLanguage.locale, arguments: arguments)
    }
    func translateCategory(name: String) -> String {
        guard let key = AppLocalization.standardCategoryKey(for: name) else { return name }
        return text(key)
    }
    // Records are integer JPY; selecting a display language never converts the currency.
    var currencySymbol: String { "¥" }
}
