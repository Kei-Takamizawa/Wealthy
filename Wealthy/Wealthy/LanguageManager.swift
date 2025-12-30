//
//  LanguageManager.swift
//  Wealthy
//
//  Created by Harrison on 12/27/25.
//

import Foundation
import Combine
import SwiftUI

// 言語の種類の定義
enum AppLanguage: String, CaseIterable, Identifiable {
    case japanese = "日本語"
    case english = "English"
    
    var id: String { self.rawValue }
}

// 翻訳キー
enum L10n: String {
    case totalAssets, scan, deposit, history, wallets, analysis, calendar, settings
    case income, expense, category, date, save, cancel, edit, recurring, add, delete
    case home
    case noExpenses, noExpensesDesc, noData
    
    // New Keys
    case tapToExpand, loading
    case shopName, amount, wallet, selectWallet
    case editTitle, done, close
    case depositTitle, depositInfo, details, dateLabel
    case categorySettings, newCategory, categoryName, icon, color, basicInfo
    case recurringSettings, noRecurringItems, recurringDesc, newRule, type, monthlyDate, targetWallet
    case unclassified, unselected
    // Default Category Names (for translation mapping)
    case catFood, catTransport, catDaily, catHobby, catClothing, catOthers
    
    // Manual Input & Settings Keys
    case manualInput, aiModelManagement, languageSettings, languageAlertTitle, languageAlertMessage
    case aiDownloadAlertTitle, aiDownloadAlertMessage, download, notNow, installed, uninstalled
    case deleteModel, modelDescription, downloading, aiReady, modelDeleted, modelInstall
    
    // AI Butler Keys
    case aiButler, aiButlerWelcome, askAnything
    
    // Backup Keys
    case dataManagement, backup, restore, backupDesc, backupSuccess, restoreSuccess, error
    
    // Category Customization
    case emoji, customColor, selectFromPalette
    
    // Ticker & UI
    case tickerLanguage, tickerJP, tickerEN
    case currentStatus, availableForDownload, installedModels, noInstalledModels, active, select, install, uninstallSwipeTip
}

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: AppLanguage
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let savedLang = UserDefaults.standard.string(forKey: "selectedLanguage") ?? AppLanguage.japanese.rawValue
        self.currentLanguage = AppLanguage(rawValue: savedLang) ?? .japanese
        
        $currentLanguage
            .dropFirst()
            .sink { lang in
                UserDefaults.standard.set(lang.rawValue, forKey: "selectedLanguage")
            }
            .store(in: &cancellables)
    }
    
    // カテゴリ名の翻訳マッピング (DBの生データ -> L10nキー)
    private let categoryMapping: [String: L10n] = [
        "食費": .catFood, "Food": .catFood, "Comida": .catFood, "식비": .catFood, "Cibo": .catFood, "طعام": .catFood,
        "交通費": .catTransport, "Transport": .catTransport, "Transporte": .catTransport, "교통비": .catTransport, "Trasporti": .catTransport, "نقل": .catTransport,
        "日用品": .catDaily, "Daily": .catDaily, "Diario": .catDaily, "생필품": .catDaily, "Quotidiano": .catDaily, "يومي": .catDaily,
        "趣味": .catHobby, "Hobby": .catHobby, "Afición": .catHobby, "취미": .catHobby, "هواية": .catHobby,
        "衣服": .catClothing, "Clothing": .catClothing, "Ropa": .catClothing, "의류": .catClothing, "Vestiti": .catClothing, "ملابس": .catClothing,
        "その他": .catOthers, "Others": .catOthers, "Otros": .catOthers, "기타": .catOthers, "Altro": .catOthers, "أخرى": .catOthers
    ]
    
    func translateCategory(name: String) -> String {
        if let key = categoryMapping[name] {
            return t(key)
        }
        return name
    }
    
    // 辞書データ
    private let translations: [AppLanguage: [L10n: String]] = [
        .japanese: [
            .home: "ホーム", .totalAssets: "総資産", .scan: "スキャン", .deposit: "入金", .history: "最近の活動",
            .wallets: "資産", .analysis: "分析", .calendar: "カレンダー", .settings: "設定",
            .income: "収入", .expense: "支出", .category: "カテゴリ", .date: "日付",
            .save: "保存", .cancel: "キャンセル", .edit: "編集", .recurring: "固定収支設定",
            .add: "追加", .delete: "削除",
            .noExpenses: "支出なし", .noExpensesDesc: "この日の支出はありません", .noData: "データがありません",
            
            .tapToExpand: "タップして拡大", .loading: "読み込み中...",
            .shopName: "店名", .amount: "金額", .wallet: "財布", .selectWallet: "財布を選択",
            .editTitle: "編集", .done: "完了", .close: "閉じる",
            .depositTitle: "資金の追加", .depositInfo: "入金情報", .details: "詳細", .dateLabel: "日付",
            .categorySettings: "カテゴリ設定", .newCategory: "新規カテゴリ", .categoryName: "カテゴリ名", .icon: "アイコン", .color: "カラー", .basicInfo: "基本情報",
            .recurringSettings: "固定収支の設定", .noRecurringItems: "固定収支なし", .recurringDesc: "毎月の固定給やサブスクを登録しよう", .newRule: "新規ルール作成", .type: "タイプ", .monthlyDate: "毎月の日付", .targetWallet: "対象の財布",
            .unclassified: "未分類", .unselected: "未選択",
            
            .catFood: "食費", .catTransport: "交通費", .catDaily: "日用品", .catHobby: "趣味", .catClothing: "衣服", .catOthers: "その他",
            
            // New
            .manualInput: "手動入力",
            .aiModelManagement: "AIモデル管理",
            .languageSettings: "言語設定",
            .languageAlertTitle: "言語を選択 / Select Language",
            .languageAlertMessage: "アプリの言語を選択してください。\nPlease select your preferred language.\n(後で設定から変更できます / You can change this later in Settings)",
            .aiDownloadAlertTitle: "AIモデルのダウンロード",
            .aiDownloadAlertMessage: "レシート解析にはAIモデルが必要です。\n設定画面から好みのモデルをダウンロードしてください。",
            .download: "設定へ移動",
            .notNow: "キャンセル",
            .installed: "インストール済み",
            .uninstalled: "未インストール",
            .deleteModel: "モデルを削除",
            .modelDescription: "AIモデルを導入すると、レシートの読み取り精度が向上し、カテゴリーも自動分類されます。",
            .downloading: "ダウンロード中",
            .aiReady: "準備完了",
            .modelDeleted: "モデル削除済",
            .modelInstall: "モデルインストール",
            
            // Butler
            .aiButler: "AI執事",
            .aiButlerWelcome: "こんにちは。私はあなたの家計執事です。資産や支出について何かお手伝いできることはありますか？",
            .askAnything: "何でも聞いてください...",
            
            // Backup
            .dataManagement: "データ管理",
            .backup: "バックアップ作成",
            .restore: "バックアップから復元",
            .backupDesc: "アプリの全データをファイルに保存します。",
            .backupSuccess: "バックアップを作成しました。",
            .restoreSuccess: "復元が完了しました。",
            .error: "エラー",
            
            // Category Customization
            .emoji: "絵文字",
            .customColor: "カスタムカラー",
            .selectFromPalette: "パレットから選択",
            
            // Ticker Settings
            .tickerLanguage: "ホームティッカー言語",
            .tickerJP: "日本語",
            .tickerEN: "英語",
            .currentStatus: "現在の状態",
            .availableForDownload: "ダウンロード可能",
            .installedModels: "インストール済みモデル",
            .noInstalledModels: "インストール済みのモデルはありません",
            .active: "使用中",
            .select: "選択",
            .install: "インストール",
            .uninstallSwipeTip: "ヒント: リストを左にスワイプして削除"
        ],
        .english: [
            .home: "Home", .totalAssets: "Total Assets", .scan: "SCAN", .deposit: "DEPOSIT", .history: "Recent Activity",
            .wallets: "Wallets", .analysis: "Analysis", .calendar: "Calendar", .settings: "Settings",
            .income: "Income", .expense: "Expense", .category: "Category", .date: "Date",
            .save: "Save", .cancel: "Cancel", .edit: "Edit", .recurring: "Recurring Rules",
            .add: "Add", .delete: "Delete",
            .noExpenses: "No Expenses", .noExpensesDesc: "No expenses for this day", .noData: "No data available",
            
            .tapToExpand: "Tap to expand", .loading: "Loading...",
            .shopName: "Shop Name", .amount: "Amount", .wallet: "Wallet", .selectWallet: "Select Wallet",
            .editTitle: "Edit", .done: "Done", .close: "Close",
            .depositTitle: "Add Funds", .depositInfo: "Deposit Info", .details: "Details", .dateLabel: "Date",
            .categorySettings: "Categories", .newCategory: "New Category", .categoryName: "Category Name", .icon: "Icon", .color: "Color", .basicInfo: "Basic Info",
            .recurringSettings: "Recurring Settings", .noRecurringItems: "No Recurring Items", .recurringDesc: "Register monthly salary or subscriptions", .newRule: "New Rule", .type: "Type", .monthlyDate: "Day of Month", .targetWallet: "Target Wallet",
            .unclassified: "Unclassified", .unselected: "Unselected",
            
            .catFood: "Food", .catTransport: "Transport", .catDaily: "Daily", .catHobby: "Hobby", .catClothing: "Clothing", .catOthers: "Others",
            
             // New
            .manualInput: "Manual Input",
            .aiModelManagement: "AI Model Management",
            .languageSettings: "Language Settings",
            .languageAlertTitle: "Select Language",
            .languageAlertMessage: "Please select your preferred language.\n(You can change this later in Settings)",
            .aiDownloadAlertTitle: "Download AI Model",
            .aiDownloadAlertMessage: "AI Model is required for receipt scanning.\nPlease download a model from Settings.",
            .download: "Go to Settings",
            .notNow: "Cancel",
            .installed: "Installed",
            .uninstalled: "Not Installed",
            .deleteModel: "Delete Model",
            .modelDescription: "Installing the AI model improves receipt scanning accuracy and enables automatic categorization.",
            .downloading: "Downloading",
            .aiReady: "Ready",
            .modelDeleted: "Model Deleted",
            .modelInstall: "Model Install",
            
            // Butler
            .aiButler: "AI Butler",
            .aiButlerWelcome: "Hello. I am your financial butler. How can I help you regarding your assets or expenses?",
            .askAnything: "Ask anything...",
            
            // Backup
            .dataManagement: "Data Management",
            .backup: "Backup Data",
            .restore: "Restore Data",
            .backupDesc: "Save all app data to a file.",
            .backupSuccess: "Backup created successfully.",
            .restoreSuccess: "Restore completed successfully.",
            .error: "Error",
            
            // Category Customization
            .emoji: "Emoji",
            .customColor: "Custom Color",
            .selectFromPalette: "Select from Palette",
            
            // Ticker Settings
            .tickerLanguage: "Home Ticker Language",
            .tickerJP: "Japanese",
            .tickerEN: "English",
            .currentStatus: "Current Activity",
            .availableForDownload: "Available for Download",
            .installedModels: "Installed Models",
            .noInstalledModels: "No installed models",
            .active: "Active",
            .select: "Select",
            .install: "Install",
            .uninstallSwipeTip: "Tip: Swipe left on an installed model to uninstall it."
        ]
    ]
    
    func t(_ key: L10n) -> String {
        return translations[currentLanguage]?[key] ?? "???"
    }
    
    var currencySymbol: String {
        switch currentLanguage {

        default: return "¥"
        }
    }
}

