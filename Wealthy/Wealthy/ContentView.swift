//
//  ContentView.swift
//  家計簿
//
//  Created by Harrison on 12/26/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var lm: LanguageManager
    @Environment(\.modelContext) private var modelContext
    
    @Query private var assets: [Asset]
    @Query private var recurringItems: [RecurringItem]
    @Query private var categories: [Category] // New
    
    @AppStorage("hasSelectedLanguage") private var hasSelectedLanguage = false
    @AppStorage("hasShownAIDownloadAlert") private var hasShownAIDownloadAlert = false
    
    @State private var showLanguageAlert = false
    @State private var showAIDownloadAlert = false
    // AIモデル管理画面を表示するかどうかを記録します。
    @State private var showModelSettings = false
    @State private var selection = 0
    @State private var processedMessage: String?
    
    var body: some View {
        TabView(selection: $selection) {
            DashboardView()
                .tabItem { Label(lm.t(.home), systemImage: "house.fill") }
                .tag(0)
            
            CalendarView()
                .tabItem { Label(lm.t(.calendar), systemImage: "calendar") }
                .tag(1)
            
            StatsView()
                .tabItem { Label(lm.t(.analysis), systemImage: "chart.bar.xaxis") }
                .tag(2)
            
            AssetsView()
                .tabItem { Label(lm.t(.wallets), systemImage: "creditcard.fill") }
                .tag(3)
        }
        .accentColor(.orange)
        // 初回案内でダウンロードを選んだとき、既存のモデル管理画面を表示します。
        .sheet(isPresented: $showModelSettings) {
            // モデル管理画面に見出しを表示できるようにします。
            NavigationStack {
                // アプリに元からあるAIモデル管理画面を開きます。
                ModelSettingsView()
            // ナビゲーション画面の範囲を閉じます。
            }
        // シート表示の範囲を閉じます。
        }
        .onAppear {
            setupInitialData() 
            checkRecurringItems()
            
            // 初回起動時のフロー
            if !hasSelectedLanguage {
                showLanguageAlert = true
            } else if !hasShownAIDownloadAlert {
                // 言語は選択済みだがAIはまだの場合（アプデ後など）
                showAIDownloadAlert = true
            }
        }
        // 言語選択アラート
        .alert(lm.t(.languageAlertTitle), isPresented: $showLanguageAlert) {
            Button("日本語") {
                completeLanguageSelection(language: .japanese)
            }
            Button("English") {
                lm.currentLanguage = .english
                completeLanguageSelection(language: .english)
            }
        } message: {
            Text(lm.t(.languageAlertMessage))
        }
        // AIダウンロードアラート
        .alert(lm.t(.aiDownloadAlertTitle), isPresented: $showAIDownloadAlert) {
            Button(lm.t(.download)) {
                // 存在しない5番目のタブではなく、AIモデル管理画面を開きます。
                showModelSettings = true
                // 初回案内を閉じます。
                showAIDownloadAlert = false
            }
            Button(lm.t(.notNow), role: .cancel) {
                hasShownAIDownloadAlert = true // Still mark as shown if user cancels
                showAIDownloadAlert = false // Dismiss the alert
            }
        } message: {
            Text(lm.t(.aiDownloadAlertMessage))
        }
        .alert("固定収支を反映しました", isPresented: Binding(get: { processedMessage != nil }, set: { _ in processedMessage = nil })) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(processedMessage ?? "")
        }
    }
    
    private func completeLanguageSelection(language: AppLanguage) {
        lm.currentLanguage = language
        
        // Initial Model & Ticker Suggestion
        if language == .japanese {
             LocalLLMService.shared.currentModelId = "gemma"
             LocalLLMService.shared.setTickerLanguage("日本語")
        } else {
             LocalLLMService.shared.currentModelId = "llama"
             LocalLLMService.shared.setTickerLanguage("English")
        }
        
        hasSelectedLanguage = true // Keep this to mark language as selected
        showLanguageAlert = false
        showAIDownloadAlert = true
    }
    
    private func setupInitialData() {
            // ■ 修正: 現金50000円を作るコードを削除しました
            // if assets.isEmpty { ... } のブロックを丸ごと消すだけです。
            
            // カテゴリの初期データは便利なので残しておきます
            if categories.isEmpty {
                let defaults = [
                    Category(name: "食費", icon: "fork.knife", colorHex: "FFA500"),
                    Category(name: "交通費", icon: "bus", colorHex: "1E90FF"),
                    Category(name: "日用品", icon: "cart.fill", colorHex: "32CD32"),
                    Category(name: "趣味", icon: "gamecontroller.fill", colorHex: "8A2BE2"),
                    Category(name: "衣服", icon: "tshirt.fill", colorHex: "FF69B4"),
                    Category(name: "その他", icon: "questionmark.circle", colorHex: "808080")
                ]
                defaults.forEach { modelContext.insert($0) }
            }
        }
    
    // ■ 定期処理ロジック
    private func checkRecurringItems() {
        let calendar = Calendar.current
        let today = Date()
        let currentDay = calendar.component(.day, from: today)
        var processList: [String] = []
        
        for item in recurringItems {
            if currentDay >= item.dayOfMonth {
                let alreadyProcessed: Bool
                if let lastDate = item.lastProcessedDate {
                    alreadyProcessed = calendar.isDate(lastDate, equalTo: today, toGranularity: .month)
                } else {
                    alreadyProcessed = false
                }
                
                if !alreadyProcessed {
                    processRecurringItem(item)
                    processList.append("\(item.title) (¥\(item.amount))")
                }
            }
        }
        if !processList.isEmpty {
            processedMessage = processList.joined(separator: "\n")
        }
    }
    
    private func processRecurringItem(_ item: RecurringItem) {
        let newLog = Expense(
            title: item.title,
            amount: item.amount,
            date: Date(),
            assetName: item.assetName,
            isIncome: item.isIncome,
            categoryName: "固定費" // 固定費として記録
        )
        modelContext.insert(newLog)
        
        if let targetAsset = assets.first(where: { $0.name == item.assetName }) {
            if item.isIncome {
                targetAsset.balance += item.amount
            } else {
                targetAsset.balance -= item.amount
            }
        }
        item.lastProcessedDate = Date()
    }
}
