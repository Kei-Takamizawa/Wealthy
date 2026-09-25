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

// この型をアプリ起動時の入口として指定します。
@main
// アプリ起動時の画面とデータ保存を設定する型を定義します。
struct WealthyApp: App {
    // マネージャーをここで作成
    // 画面が所有し続ける監視対象の管理オブジェクトを作ります。
    @StateObject private var languageManager = LanguageManager.shared

    // アプリが表示する画面の構成を返す入口を定義します。
    var body: some Scene {
        // 直前に定義した処理へ、この設定または引数を追加します。
        WindowGroup {
            // 直前に定義した処理へ、この設定または引数を追加します。
            ContentView()
                // これで全画面から languageManager を呼べるようになります
                // 言語管理オブジェクトを下位の全画面へ渡します。
                .environmentObject(languageManager)
                // 画面表示後に非同期で行う初期処理を登録します。
                .task {
                    // 既にインストール済みの場合のみ、アプリ起動時にモデルロードを開始
                    // この条件が成り立つ場合だけ、続く処理を行います。
                    if LocalLLMService.shared.isModelInstalled {
                        // 直前に定義した処理へ、この設定または引数を追加します。
                        await LocalLLMService.shared.loadModel()
                    // ここまでの処理またはデータ定義を閉じます。
                    }
                // ここまでの処理またはデータ定義を閉じます。
                }
        // ここまでの処理またはデータ定義を閉じます。
        }
        // 指定したデータ型をSwiftDataに保存できるようにします。
        .modelContainer(for: [Expense.self, Asset.self, RecurringItem.self, Category.self, ChatMessageModel.self])
    // ここまでの処理またはデータ定義を閉じます。
    }
// ここまでの処理またはデータ定義を閉じます。
}
