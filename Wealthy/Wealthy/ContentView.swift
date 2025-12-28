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
    
    @State private var processedMessage: String? = nil
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label(lm.t(.home), systemImage: "house.fill") }
            
            CalendarView()
                .tabItem { Label(lm.t(.calendar), systemImage: "calendar") }
            
            StatsView()
                .tabItem { Label(lm.t(.analysis), systemImage: "chart.bar.xaxis") }
            
            AssetsView()
                .tabItem { Label(lm.t(.wallets), systemImage: "creditcard.fill") }
        }
        .accentColor(.orange)
        .onAppear {
            setupInitialData() // 初期データ作成
            checkRecurringItems() // 定期処理チェック
        }
        .alert("固定収支を反映しました", isPresented: Binding(get: { processedMessage != nil }, set: { _ in processedMessage = nil })) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(processedMessage ?? "")
        }
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
