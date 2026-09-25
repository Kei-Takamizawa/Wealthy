//
//  LanguageManager.swift
//  Wealthy
//
//  Created by Harrison on 12/27/25.
//

// Foundationの機能を、このファイルから使えるように読み込みます。
import Foundation
// Combineの機能を、このファイルから使えるように読み込みます。
import Combine
// SwiftUIの機能を、このファイルから使えるように読み込みます。
import SwiftUI

// 言語の種類の定義
// アプリで選べる言語の型を定義します。
enum AppLanguage: String, CaseIterable, Identifiable {
    // 列挙型で使う選択肢として、japanese = "日本語"を定義します。
    case japanese = "日本語"
    // 列挙型で使う選択肢として、english = "English"を定義します。
    case english = "English"
    
    // 各データを識別するIDを保持するプロパティを定義します。
    var id: String { self.rawValue }
// ここまでの処理またはデータ定義を閉じます。
}

// 翻訳キー
// 翻訳する文言を識別するキーの型を定義します。
enum L10n: String {
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
    // 列挙型で使う選択肢として、manualInput, aiModelManagement, languageSettings, languageAlertTitle, languageAlertMessageを定義します。
    case manualInput, aiModelManagement, languageSettings, languageAlertTitle, languageAlertMessage
    // 列挙型で使う選択肢として、aiDownloadAlertTitle, aiDownloadAlertMessage, download, notNow, installed, uninstalledを定義します。
    case aiDownloadAlertTitle, aiDownloadAlertMessage, download, notNow, installed, uninstalled
    // 列挙型で使う選択肢として、deleteModel, modelDescription, downloading, aiReady, modelDeleted, modelInstallを定義します。
    case deleteModel, modelDescription, downloading, aiReady, modelDeleted, modelInstall
    
    // AI Butler Keys
    // 列挙型で使う選択肢として、aiButler, aiButlerWelcome, askAnythingを定義します。
    case aiButler, aiButlerWelcome, askAnything
    
    // Backup Keys
    // 列挙型で使う選択肢として、dataManagement, backup, restore, backupDesc, backupSuccess, restoreSuccess, errorを定義します。
    case dataManagement, backup, restore, backupDesc, backupSuccess, restoreSuccess, error
    
    // Category Customization
    // 列挙型で使う選択肢として、emoji, customColor, selectFromPaletteを定義します。
    case emoji, customColor, selectFromPalette
    
    // Ticker & UI
    // 列挙型で使う選択肢として、tickerLanguage, tickerJP, tickerENを定義します。
    case tickerLanguage, tickerJP, tickerEN
    // 列挙型で使う選択肢として、currentStatus, availableForDownload, installedModels, noInstalledModels, active, select, install, uninstallSwipeTipを定義します。
    case currentStatus, availableForDownload, installedModels, noInstalledModels, active, select, install, uninstallSwipeTip
// ここまでの処理またはデータ定義を閉じます。
}

// 表示言語と翻訳文言を管理する型を定義します。
final class LanguageManager: ObservableObject {
    // アプリ内で共有する、この管理クラスのインスタンスを一つ作ります。
    static let shared = LanguageManager()
    
    // 値が変わったことを画面へ通知できるプロパティを定義します。
    @Published var currentLanguage: AppLanguage
    // 設定保存を続けるための購読を作成または更新します。
    private var cancellables = Set<AnyCancellable>()
    
    // 渡された引数で新しい値を初期化する入口を定義します。
    init() {
        // savedLangとして後続の処理で使う値を作成または更新します。
        let savedLang = UserDefaults.standard.string(forKey: "selectedLanguage") ?? AppLanguage.japanese.rawValue
        // 保存済みの言語を選び、読めなければ日本語を使います。
        self.currentLanguage = AppLanguage(rawValue: savedLang) ?? .japanese
        
        // 直前に定義した処理へ、この設定または引数を追加します。
        $currentLanguage
            // 直前の値に、この設定または変換処理を続けて適用します。
            .dropFirst()
            // 直前の値に、この設定または変換処理を続けて適用します。
            .sink { lang in
                // 直前に定義した処理へ、この設定または引数を追加します。
                UserDefaults.standard.set(lang.rawValue, forKey: "selectedLanguage")
            // ここまでの処理またはデータ定義を閉じます。
            }
            // この言語に対応する表示文言を登録します。
            .store(in: &cancellables)
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // カテゴリ名の翻訳マッピング (DBの生データ -> L10nキー)
    // 保存済みカテゴリ名と翻訳キーの対応表を作成または更新します。
    private let categoryMapping: [String: L10n] = [
        // 保存済みカテゴリ名を、表示用の翻訳キーへ対応づけます。
        "食費": .catFood, "Food": .catFood, "Comida": .catFood, "식비": .catFood, "Cibo": .catFood, "طعام": .catFood,
        // 保存済みカテゴリ名を、表示用の翻訳キーへ対応づけます。
        "交通費": .catTransport, "Transport": .catTransport, "Transporte": .catTransport, "교통비": .catTransport, "Trasporti": .catTransport, "نقل": .catTransport,
        // 保存済みカテゴリ名を、表示用の翻訳キーへ対応づけます。
        "日用品": .catDaily, "Daily": .catDaily, "Diario": .catDaily, "생필품": .catDaily, "Quotidiano": .catDaily, "يومي": .catDaily,
        // 保存済みカテゴリ名を、表示用の翻訳キーへ対応づけます。
        "趣味": .catHobby, "Hobby": .catHobby, "Afición": .catHobby, "취미": .catHobby, "هواية": .catHobby,
        // 保存済みカテゴリ名を、表示用の翻訳キーへ対応づけます。
        "衣服": .catClothing, "Clothing": .catClothing, "Ropa": .catClothing, "의류": .catClothing, "Vestiti": .catClothing, "ملابس": .catClothing,
        // 保存済みカテゴリ名を、表示用の翻訳キーへ対応づけます。
        "その他": .catOthers, "Others": .catOthers, "Otros": .catOthers, "기타": .catOthers, "Altro": .catOthers, "أخرى": .catOthers
    // ここで一覧または辞書を閉じます。
    ]
    
    // 保存されたカテゴリ名を現在の言語に変える入口を定義します。
    func translateCategory(name: String) -> String {
        // この条件が成り立つ場合だけ、続く処理を行います。
        if let key = categoryMapping[name] {
            // 計算または取得した値を呼び出し元へ返します。
            return t(key)
        // ここまでの処理またはデータ定義を閉じます。
        }
        // 計算または取得した値を呼び出し元へ返します。
        return name
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // 辞書データ
    // 言語別の翻訳文言の辞書を作成または更新します。
    private let translations: [AppLanguage: [L10n: String]] = [
        // 日本語の翻訳文言をまとめます。
        .japanese: [
            // home、totalAssets、scan、deposit、historyの表示文言を対応づけます。
            .home: "ホーム", .totalAssets: "総資産", .scan: "スキャン", .deposit: "入金", .history: "最近の活動",
            // wallets、analysis、calendar、settingsの表示文言を対応づけます。
            .wallets: "資産", .analysis: "分析", .calendar: "カレンダー", .settings: "設定",
            // income、expense、category、dateの表示文言を対応づけます。
            .income: "収入", .expense: "支出", .category: "カテゴリ", .date: "日付",
            // save、cancel、edit、recurringの表示文言を対応づけます。
            .save: "保存", .cancel: "キャンセル", .edit: "編集", .recurring: "固定収支設定",
            // add、deleteの表示文言を対応づけます。
            .add: "追加", .delete: "削除",
            // noExpenses、noExpensesDesc、noDataの表示文言を対応づけます。
            .noExpenses: "支出なし", .noExpensesDesc: "この日の支出はありません", .noData: "データがありません",
            
            // tapToExpand、loadingの表示文言を対応づけます。
            .tapToExpand: "タップして拡大", .loading: "読み込み中...",
            // shopName、amount、wallet、selectWalletの表示文言を対応づけます。
            .shopName: "店名", .amount: "金額", .wallet: "財布", .selectWallet: "財布を選択",
            // editTitle、done、closeの表示文言を対応づけます。
            .editTitle: "編集", .done: "完了", .close: "閉じる",
            // depositTitle、depositInfo、details、dateLabelの表示文言を対応づけます。
            .depositTitle: "資金の追加", .depositInfo: "入金情報", .details: "詳細", .dateLabel: "日付",
            // categorySettings、newCategory、categoryName、icon、color、basicInfoの表示文言を対応づけます。
            .categorySettings: "カテゴリ設定", .newCategory: "新規カテゴリ", .categoryName: "カテゴリ名", .icon: "アイコン", .color: "カラー", .basicInfo: "基本情報",
            // recurringSettings、noRecurringItems、recurringDesc、newRule、type、monthlyDate、targetWalletの表示文言を対応づけます。
            .recurringSettings: "固定収支の設定", .noRecurringItems: "固定収支なし", .recurringDesc: "毎月の固定給やサブスクを登録しよう", .newRule: "新規ルール作成", .type: "タイプ", .monthlyDate: "毎月の日付", .targetWallet: "対象の財布",
            // unclassified、unselectedの表示文言を対応づけます。
            .unclassified: "未分類", .unselected: "未選択",
            
            // catFood、catTransport、catDaily、catHobby、catClothing、catOthersの表示文言を対応づけます。
            .catFood: "食費", .catTransport: "交通費", .catDaily: "日用品", .catHobby: "趣味", .catClothing: "衣服", .catOthers: "その他",
            
            // New
            // manualInputの表示文言を対応づけます。
            .manualInput: "手動入力",
            // aiModelManagementの表示文言を対応づけます。
            .aiModelManagement: "AIモデル管理",
            // languageSettingsの表示文言を対応づけます。
            .languageSettings: "言語設定",
            // languageAlertTitleの表示文言を対応づけます。
            .languageAlertTitle: "言語を選択 / Select Language",
            // languageAlertMessageの表示文言を対応づけます。
            .languageAlertMessage: "アプリの言語を選択してください。\nPlease select your preferred language.\n(後で設定から変更できます / You can change this later in Settings)",
            // aiDownloadAlertTitleの表示文言を対応づけます。
            .aiDownloadAlertTitle: "AIモデルのダウンロード",
            // aiDownloadAlertMessageの表示文言を対応づけます。
            .aiDownloadAlertMessage: "レシート解析にはAIモデルが必要です。\n設定画面から好みのモデルをダウンロードしてください。",
            // downloadの表示文言を対応づけます。
            .download: "設定へ移動",
            // notNowの表示文言を対応づけます。
            .notNow: "キャンセル",
            // installedの表示文言を対応づけます。
            .installed: "インストール済み",
            // uninstalledの表示文言を対応づけます。
            .uninstalled: "未インストール",
            // deleteModelの表示文言を対応づけます。
            .deleteModel: "モデルを削除",
            // modelDescriptionの表示文言を対応づけます。
            .modelDescription: "AIモデルを導入すると、レシートの読み取り精度が向上し、カテゴリーも自動分類されます。",
            // downloadingの表示文言を対応づけます。
            .downloading: "ダウンロード中",
            // aiReadyの表示文言を対応づけます。
            .aiReady: "準備完了",
            // modelDeletedの表示文言を対応づけます。
            .modelDeleted: "モデル削除済",
            // modelInstallの表示文言を対応づけます。
            .modelInstall: "モデルインストール",
            
            // Butler
            // aiButlerの表示文言を対応づけます。
            .aiButler: "AI執事",
            // aiButlerWelcomeの表示文言を対応づけます。
            .aiButlerWelcome: "こんにちは。私はあなたの家計執事です。資産や支出について何かお手伝いできることはありますか？",
            // askAnythingの表示文言を対応づけます。
            .askAnything: "何でも聞いてください...",
            
            // Backup
            // dataManagementの表示文言を対応づけます。
            .dataManagement: "データ管理",
            // backupの表示文言を対応づけます。
            .backup: "バックアップ作成",
            // restoreの表示文言を対応づけます。
            .restore: "バックアップから復元",
            // backupDescの表示文言を対応づけます。
            .backupDesc: "アプリの全データをファイルに保存します。",
            // backupSuccessの表示文言を対応づけます。
            .backupSuccess: "バックアップを作成しました。",
            // restoreSuccessの表示文言を対応づけます。
            .restoreSuccess: "復元が完了しました。",
            // errorの表示文言を対応づけます。
            .error: "エラー",
            
            // Category Customization
            // emojiの表示文言を対応づけます。
            .emoji: "絵文字",
            // customColorの表示文言を対応づけます。
            .customColor: "カスタムカラー",
            // selectFromPaletteの表示文言を対応づけます。
            .selectFromPalette: "パレットから選択",
            
            // Ticker Settings
            // tickerLanguageの表示文言を対応づけます。
            .tickerLanguage: "ホームティッカー言語",
            // tickerJPの表示文言を対応づけます。
            .tickerJP: "日本語",
            // tickerENの表示文言を対応づけます。
            .tickerEN: "英語",
            // currentStatusの表示文言を対応づけます。
            .currentStatus: "現在の状態",
            // availableForDownloadの表示文言を対応づけます。
            .availableForDownload: "ダウンロード可能",
            // installedModelsの表示文言を対応づけます。
            .installedModels: "インストール済みモデル",
            // noInstalledModelsの表示文言を対応づけます。
            .noInstalledModels: "インストール済みのモデルはありません",
            // activeの表示文言を対応づけます。
            .active: "使用中",
            // selectの表示文言を対応づけます。
            .select: "選択",
            // installの表示文言を対応づけます。
            .install: "インストール",
            // uninstallSwipeTipの表示文言を対応づけます。
            .uninstallSwipeTip: "ヒント: リストを左にスワイプして削除"
        // ここで一覧または辞書を閉じます。
        ],
        // 英語の翻訳文言をまとめます。
        .english: [
            // home、totalAssets、scan、deposit、historyの表示文言を対応づけます。
            .home: "Home", .totalAssets: "Total Assets", .scan: "SCAN", .deposit: "DEPOSIT", .history: "Recent Activity",
            // wallets、analysis、calendar、settingsの表示文言を対応づけます。
            .wallets: "Wallets", .analysis: "Analysis", .calendar: "Calendar", .settings: "Settings",
            // income、expense、category、dateの表示文言を対応づけます。
            .income: "Income", .expense: "Expense", .category: "Category", .date: "Date",
            // save、cancel、edit、recurringの表示文言を対応づけます。
            .save: "Save", .cancel: "Cancel", .edit: "Edit", .recurring: "Recurring Rules",
            // add、deleteの表示文言を対応づけます。
            .add: "Add", .delete: "Delete",
            // noExpenses、noExpensesDesc、noDataの表示文言を対応づけます。
            .noExpenses: "No Expenses", .noExpensesDesc: "No expenses for this day", .noData: "No data available",
            
            // tapToExpand、loadingの表示文言を対応づけます。
            .tapToExpand: "Tap to expand", .loading: "Loading...",
            // shopName、amount、wallet、selectWalletの表示文言を対応づけます。
            .shopName: "Shop Name", .amount: "Amount", .wallet: "Wallet", .selectWallet: "Select Wallet",
            // editTitle、done、closeの表示文言を対応づけます。
            .editTitle: "Edit", .done: "Done", .close: "Close",
            // depositTitle、depositInfo、details、dateLabelの表示文言を対応づけます。
            .depositTitle: "Add Funds", .depositInfo: "Deposit Info", .details: "Details", .dateLabel: "Date",
            // categorySettings、newCategory、categoryName、icon、color、basicInfoの表示文言を対応づけます。
            .categorySettings: "Categories", .newCategory: "New Category", .categoryName: "Category Name", .icon: "Icon", .color: "Color", .basicInfo: "Basic Info",
            // recurringSettings、noRecurringItems、recurringDesc、newRule、type、monthlyDate、targetWalletの表示文言を対応づけます。
            .recurringSettings: "Recurring Settings", .noRecurringItems: "No Recurring Items", .recurringDesc: "Register monthly salary or subscriptions", .newRule: "New Rule", .type: "Type", .monthlyDate: "Day of Month", .targetWallet: "Target Wallet",
            // unclassified、unselectedの表示文言を対応づけます。
            .unclassified: "Unclassified", .unselected: "Unselected",
            
            // catFood、catTransport、catDaily、catHobby、catClothing、catOthersの表示文言を対応づけます。
            .catFood: "Food", .catTransport: "Transport", .catDaily: "Daily", .catHobby: "Hobby", .catClothing: "Clothing", .catOthers: "Others",
            
             // New
            // manualInputの表示文言を対応づけます。
            .manualInput: "Manual Input",
            // aiModelManagementの表示文言を対応づけます。
            .aiModelManagement: "AI Model Management",
            // languageSettingsの表示文言を対応づけます。
            .languageSettings: "Language Settings",
            // languageAlertTitleの表示文言を対応づけます。
            .languageAlertTitle: "Select Language",
            // languageAlertMessageの表示文言を対応づけます。
            .languageAlertMessage: "Please select your preferred language.\n(You can change this later in Settings)",
            // aiDownloadAlertTitleの表示文言を対応づけます。
            .aiDownloadAlertTitle: "Download AI Model",
            // aiDownloadAlertMessageの表示文言を対応づけます。
            .aiDownloadAlertMessage: "AI Model is required for receipt scanning.\nPlease download a model from Settings.",
            // downloadの表示文言を対応づけます。
            .download: "Go to Settings",
            // notNowの表示文言を対応づけます。
            .notNow: "Cancel",
            // installedの表示文言を対応づけます。
            .installed: "Installed",
            // uninstalledの表示文言を対応づけます。
            .uninstalled: "Not Installed",
            // deleteModelの表示文言を対応づけます。
            .deleteModel: "Delete Model",
            // modelDescriptionの表示文言を対応づけます。
            .modelDescription: "Installing the AI model improves receipt scanning accuracy and enables automatic categorization.",
            // downloadingの表示文言を対応づけます。
            .downloading: "Downloading",
            // aiReadyの表示文言を対応づけます。
            .aiReady: "Ready",
            // modelDeletedの表示文言を対応づけます。
            .modelDeleted: "Model Deleted",
            // modelInstallの表示文言を対応づけます。
            .modelInstall: "Model Install",
            
            // Butler
            // aiButlerの表示文言を対応づけます。
            .aiButler: "AI Butler",
            // aiButlerWelcomeの表示文言を対応づけます。
            .aiButlerWelcome: "Hello. I am your financial butler. How can I help you regarding your assets or expenses?",
            // askAnythingの表示文言を対応づけます。
            .askAnything: "Ask anything...",
            
            // Backup
            // dataManagementの表示文言を対応づけます。
            .dataManagement: "Data Management",
            // backupの表示文言を対応づけます。
            .backup: "Backup Data",
            // restoreの表示文言を対応づけます。
            .restore: "Restore Data",
            // backupDescの表示文言を対応づけます。
            .backupDesc: "Save all app data to a file.",
            // backupSuccessの表示文言を対応づけます。
            .backupSuccess: "Backup created successfully.",
            // restoreSuccessの表示文言を対応づけます。
            .restoreSuccess: "Restore completed successfully.",
            // errorの表示文言を対応づけます。
            .error: "Error",
            
            // Category Customization
            // emojiの表示文言を対応づけます。
            .emoji: "Emoji",
            // customColorの表示文言を対応づけます。
            .customColor: "Custom Color",
            // selectFromPaletteの表示文言を対応づけます。
            .selectFromPalette: "Select from Palette",
            
            // Ticker Settings
            // tickerLanguageの表示文言を対応づけます。
            .tickerLanguage: "Home Ticker Language",
            // tickerJPの表示文言を対応づけます。
            .tickerJP: "Japanese",
            // tickerENの表示文言を対応づけます。
            .tickerEN: "English",
            // currentStatusの表示文言を対応づけます。
            .currentStatus: "Current Activity",
            // availableForDownloadの表示文言を対応づけます。
            .availableForDownload: "Available for Download",
            // installedModelsの表示文言を対応づけます。
            .installedModels: "Installed Models",
            // noInstalledModelsの表示文言を対応づけます。
            .noInstalledModels: "No installed models",
            // activeの表示文言を対応づけます。
            .active: "Active",
            // selectの表示文言を対応づけます。
            .select: "Select",
            // installの表示文言を対応づけます。
            .install: "Install",
            // uninstallSwipeTipの表示文言を対応づけます。
            .uninstallSwipeTip: "Tip: Swipe left on an installed model to uninstall it."
        // ここで一覧または辞書を閉じます。
        ]
    // ここで一覧または辞書を閉じます。
    ]
    
    // 翻訳キーから現在の言語の表示文言を取り出す入口を定義します。
    func t(_ key: L10n) -> String {
        // 現在の言語に対応する翻訳文言を返し、欠けていれば疑問符を返します。
        return translations[currentLanguage]?[key] ?? "???"
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // 表示に使う通貨記号を返す入口を定義します。
    var currencySymbol: String {
        // 値に応じて実行する処理を選びます。
        switch currentLanguage {

        // どの個別条件にも当てはまらない場合の値を返します。
        default: return "¥"
        // ここまでの処理またはデータ定義を閉じます。
        }
    // ここまでの処理またはデータ定義を閉じます。
    }
// ここまでの処理またはデータ定義を閉じます。
}

