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
    @AppStorage("hasSelectedCurrencies") private var hasSelectedCurrencies = false
    @State private var showLanguageSelection = !UserDefaults.standard.bool(forKey: "hasSelectedLanguage")
    @State private var showCurrencySelection = UserDefaults.standard.bool(forKey: "hasSelectedLanguage") && !UserDefaults.standard.bool(forKey: "hasSelectedCurrencies")

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
                // これで全画面から languageManager を呼べるようになります
                // 言語管理オブジェクトを下位の全画面へ渡します。
                .environmentObject(languageManager)
                .environment(\.locale, languageManager.currentLanguage.locale)
                .environment(\.layoutDirection, languageManager.currentLanguage.isRTL ? .rightToLeft : .leftToRight)
                .task { service.refreshAvailability() }
                .sheet(isPresented: $showLanguageSelection, onDismiss: {
                    if hasSelectedLanguage && !hasSelectedCurrencies { showCurrencySelection = true }
                }) {
                    languageSelectionSheet
                        .environment(\.locale, languageManager.currentLanguage.locale)
                        .environment(\.layoutDirection, languageManager.currentLanguage.isRTL ? .rightToLeft : .leftToRight)
                }
                .sheet(isPresented: $showCurrencySelection) {
                    CurrencySelectionView(firstLaunch: true, onSave: {
                        hasSelectedCurrencies = true
                        showCurrencySelection = false
                    })
                    .environmentObject(languageManager)
                    .environment(\.locale, languageManager.currentLanguage.locale)
                    .environment(\.layoutDirection, languageManager.currentLanguage.isRTL ? .rightToLeft : .leftToRight)
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { service.refreshAvailability() }
                }
        // ここまでの処理またはデータ定義を閉じます。
        }
        // 指定したデータ型をSwiftDataに保存できるようにします。
        .modelContainer(for: [Expense.self, Asset.self, RecurringItem.self, Category.self, ChatMessageModel.self, PointCard.self])
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

    var languageSelectionSheet: some View {
        NavigationStack {
            List {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        selectLanguage(language)
                    } label: {
                        HStack {
                            Text(language.nativeName)
                            Spacer()
                            Text(language.englishName)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("onboarding.language.\(language.languageIdentifier)")
                }
            }
            .navigationTitle(languageManager.text("language.choose"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled()
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

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: service.readiness == .available ? "hourglass" : "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text(languageManager.text("availability.unavailable"))
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
            Menu {
                Picker(languageManager.text("language.display"), selection: $languageManager.currentLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.nativeName).tag(language)
                    }
                }
            } label: {
                Label(languageManager.currentLanguage.nativeName, systemImage: "globe")
            }
            Button(languageManager.text("availability.checkAgain")) {
                service.refreshAvailability()
            }
            .buttonStyle(.borderedProminent)
            Button(languageManager.text("settings.open")) {
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
