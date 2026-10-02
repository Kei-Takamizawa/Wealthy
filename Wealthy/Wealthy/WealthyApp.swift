//
//  WealthyApp.swift
//  Wealthy
//
//  Created by Harrison on 12/26/25.
//

// SwiftUIの機能を、このファイルから使えるように読み込みます。
import SwiftUI
// SwiftDataの機能を、このファイルから使えるように読み込みます。
import SwiftData
import UIKit

// この型をアプリ起動時の入口として指定します。
@main
// アプリ起動時の画面とデータ保存を設定する型を定義します。
struct WealthyApp: App {
    // マネージャーをここで作成
    // 画面が所有し続ける監視対象の管理オブジェクトを作ります。
    @StateObject private var languageManager = LanguageManager.shared
    @State private var service = LocalLLMService.shared
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasSelectedLanguage") private var hasSelectedLanguage = false
    @State private var showLanguageSelection = false

    // アプリが表示する画面の構成を返す入口を定義します。
    var body: some Scene {
        // 直前に定義した処理へ、この設定または引数を追加します。
        WindowGroup {
            // 直前に定義した処理へ、この設定または引数を追加します。
            Group {
                if service.isReady {
                    ContentView()
                } else {
                    AppleIntelligenceUnavailableView(service: service)
                }
            }
                .overlay(alignment: .topLeading) {
                    ChatRetentionObserver()
                        .frame(width: 0, height: 0)
                }
                .alert(languageManager.currentLanguage == .japanese ? "言語を選択 / Select Language" : "Select Language", isPresented: $showLanguageSelection) {
                    Button("English") { selectLanguage(.english) }
                    Button("日本語") { selectLanguage(.japanese) }
                } message: {
                    Text(languageManager.currentLanguage == .japanese
                         ? "アプリの言語を選択してください。後で設定から変更できます。"
                         : "Choose the app language. You can change it later in Settings.")
                }
                // これで全画面から languageManager を呼べるようになります
                // 言語管理オブジェクトを下位の全画面へ渡します。
                .environmentObject(languageManager)
                .task { service.refreshAvailability() }
                .task {
                    if !hasSelectedLanguage { showLanguageSelection = true }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { service.refreshAvailability() }
                }
        // ここまでの処理またはデータ定義を閉じます。
        }
        // 指定したデータ型をSwiftDataに保存できるようにします。
        .modelContainer(for: [Expense.self, Asset.self, RecurringItem.self, Category.self, ChatMessageModel.self])
    // ここまでの処理またはデータ定義を閉じます。
    }
// ここまでの処理またはデータ定義を閉じます。
}

private extension WealthyApp {
    func selectLanguage(_ language: AppLanguage) {
        languageManager.currentLanguage = language
        hasSelectedLanguage = true
        showLanguageSelection = false
    }
}

@MainActor
private struct ChatRetentionObserver: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var messages: [ChatMessageModel]

    private var nextExpiry: Date? {
        messages.map { $0.timestamp.addingTimeInterval(ChatRetentionPolicy.lifetime) }.min()
    }

    var body: some View {
        Color.clear
            .task(id: nextExpiry) { await maintainRetention() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { purgeExpiredMessages() }
            }
    }

    private func purgeExpiredMessages() {
        let now = Date()
        var didDelete = false
        for message in messages where ChatRetentionPolicy.isExpired(message.timestamp, at: now) {
            modelContext.delete(message)
            didDelete = true
        }
        if didDelete { try? modelContext.save() }
    }

    private func maintainRetention() async {
        while !Task.isCancelled {
            purgeExpiredMessages()
            let now = Date()
            let delay = nextExpiry.map { max(1, $0.timeIntervalSince(now)) } ?? 300
            do {
                try await Task.sleep(for: .seconds(delay))
            } catch {
                return
            }
        }
    }
}

private struct AppleIntelligenceUnavailableView: View {
    @EnvironmentObject private var languageManager: LanguageManager
    let service: LocalLLMService

    private var isJapanese: Bool { languageManager.currentLanguage == .japanese }

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: service.readiness == .available ? "hourglass" : "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text(isJapanese ? "Apple Intelligenceを利用できません" : "Apple Intelligence is unavailable")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(service.loadStatus)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if !service.availabilityDetail.isEmpty {
                Text(service.availabilityDetail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Picker(isJapanese ? "表示言語" : "Display Language", selection: $languageManager.currentLanguage) {
                Text("English").tag(AppLanguage.english)
                Text("日本語").tag(AppLanguage.japanese)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 280)
            Button(isJapanese ? "再確認" : "Check Again") {
                service.refreshAvailability()
            }
            .buttonStyle(.borderedProminent)
            Button(isJapanese ? "設定を開く" : "Open Settings") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
            .buttonStyle(.bordered)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }

}
