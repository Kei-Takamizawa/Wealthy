//
//  WealthyApp.swift
//  Wealthy
//
//  Created by Harrison on 12/26/25.
//

import SwiftUI
import SwiftData

@main
struct WealthyApp: App {
    // マネージャーをここで作成
    @StateObject private var languageManager = LanguageManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                // これで全画面から languageManager を呼べるようになります
                .environmentObject(languageManager)
                .task {
                    // 既にインストール済みの場合のみ、アプリ起動時にモデルロードを開始
                    if LocalLLMService.shared.isModelInstalled {
                        await LocalLLMService.shared.loadModel()
                    }
                }
        }
        .modelContainer(for: [Expense.self, Asset.self, RecurringItem.self, Category.self, ChatMessageModel.self])
    }
}
