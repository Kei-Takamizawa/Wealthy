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
        }
        .modelContainer(for: [Expense.self, Asset.self, RecurringItem.self, Category.self])
    }
}
