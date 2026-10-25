import Foundation

/// Saved native names remain stable across releases; English is the default.
nonisolated enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "English"
    case japanese = "日本語"
    case spanish = "Español"
    case korean = "한국어"

    var id: String { rawValue }
    var nativeName: String { rawValue }
    var languageIdentifier: String {
        switch self {
        case .english: "en"
        case .japanese: "ja"
        case .spanish: "es"
        case .korean: "ko"
        }
    }
    var englishName: String {
        switch self {
        case .english: "English"
        case .japanese: "Japanese"
        case .spanish: "Spanish"
        case .korean: "Korean"
        }
    }
    var locale: Locale { Locale(identifier: languageIdentifier) }
    var isRTL: Bool { false }
    static var saved: AppLanguage {
        guard let value = UserDefaults.standard.string(forKey: "selectedLanguage") else { return .english }
        return AppLanguage(rawValue: value) ?? .english
    }
    static func from(identifier: String) -> AppLanguage {
        if let exact = AppLanguage(rawValue: identifier) { return exact }
        return switch identifier.lowercased().replacingOccurrences(of: "_", with: "-").split(separator: "-").first {
        case "ja": .japanese
        case "es": .spanish
        case "ko": .korean
        default: .english
        }
    }
}

nonisolated enum L10n: String, CaseIterable {
    // 列挙型で使う選択肢として、totalAssets, scan, deposit, history, wallets, analysis, calendar, settingsを定義します。
    case totalAssets, scan, deposit, history, wallets, analysis, calendar, settings
    // 列挙型で使う選択肢として、income, expense, category, date, save, cancel, edit, recurring, add, deleteを定義します。
    case income, expense, category, date, save, cancel, edit, recurring, add, delete
    // 列挙型で使う選択肢として、homeを定義します。
    case home
    // 列挙型で使う選択肢として、noExpenses, noExpensesDesc, noDataを定義します。
    case noExpenses, noExpensesDesc, noData

    // New Keys
    // 列挙型で使う選択肢として、tapToExpand, loadingを定義します。
    case tapToExpand, loading
    // 列挙型で使う選択肢として、shopName, amount, wallet, selectWalletを定義します。
    case shopName, amount, wallet, selectWallet
    // レシートの合計額が未確定で、画像確認と手入力が必要な場合の案内を識別します。
    case receiptAmountUnclear
    // 列挙型で使う選択肢として、editTitle, done, closeを定義します。
    case editTitle, done, close
    // 列挙型で使う選択肢として、depositTitle, depositInfo, details, dateLabelを定義します。
    case depositTitle, depositInfo, details, dateLabel
    // 列挙型で使う選択肢として、categorySettings, newCategory, categoryName, icon, color, basicInfoを定義します。
    case categorySettings, newCategory, categoryName, icon, color, basicInfo
    // 列挙型で使う選択肢として、recurringSettings, noRecurringItems, recurringDesc, newRule, type, monthlyDate, targetWalletを定義します。
    case recurringSettings, noRecurringItems, recurringDesc, newRule, type, monthlyDate, targetWallet
    // 列挙型で使う選択肢として、unclassified, unselectedを定義します。
    case unclassified, unselected
    // Default Category Names (for translation mapping)
    // 列挙型で使う選択肢として、catFood, catTransport, catDaily, catHobby, catClothing, catOthersを定義します。
    case catFood, catTransport, catDaily, catHobby, catClothing, catOthers

    // Manual Input & Settings Keys
    case manualInput, languageSettings, languageAlertTitle, languageAlertMessage

    // AI Butler Keys
    // 列挙型で使う選択肢として、aiButler, aiButlerWelcome, askAnythingを定義します。
    case aiButler, aiButlerWelcome, askAnything

    // Backup Keys
    // 列挙型で使う選択肢として、dataManagement, backup, restore, backupDesc, backupSuccess, restoreSuccess, errorを定義します。
    case dataManagement, backup, restore, backupDesc, backupSuccess, restoreSuccess, error

    // Category Customization
    // 列挙型で使う選択肢として、emoji, customColor, selectFromPaletteを定義します。
    case emoji, customColor, selectFromPalette

// ここまでの処理またはデータ定義を閉じます。
}
