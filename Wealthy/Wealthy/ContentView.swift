//
//  ContentView.swift
//  家計簿
//
//  Created by Harrison on 12/26/25.
//

// `SwiftUI` の機能をこのファイルで使えるように読み込みます。
import SwiftUI
// `SwiftData` の機能をこのファイルで使えるように読み込みます。
import SwiftData

// `ContentView` という構造体を定義し、関連する値や処理をまとめます。
struct ContentView: View {
    // 表示言語の管理役を親画面から受け取ります。
    @EnvironmentObject var lm: LanguageManager
    // SwiftUIの環境からデータ保存用のコンテキストを取得します。
    @Environment(\.modelContext) private var modelContext
    
    // SwiftDataから財布・資産を読み、変更を画面に反映します。
    @Query private var assets: [Asset]
    // SwiftDataから`recurringItems`を読み、変更を画面に反映します。
    @Query private var recurringItems: [RecurringItem]
    // SwiftDataからカテゴリを読み、変更を画面に反映します。
    @Query private var categories: [Category] // New
    
    // 括弧内のキーを使い、設定値を端末内に保存・読み出しします。
    @AppStorage("hasSelectedLanguage") private var hasSelectedLanguage = false
    // 括弧内のキーを使い、設定値を端末内に保存・読み出しします。
    @AppStorage("hasShownAIDownloadAlert") private var hasShownAIDownloadAlert = false
    
    // `showLanguageAlert`を画面の状態として保持し、変更時に表示を更新します。
    @State private var showLanguageAlert = false
    // `showAIDownloadAlert`を画面の状態として保持し、変更時に表示を更新します。
    @State private var showAIDownloadAlert = false
    // AIモデル管理画面を表示するかどうかを記録します。
    @State private var showModelSettings = false
    // 選択中のタブ番号を画面の状態として保持し、変更時に表示を更新します。
    @State private var selection = 0
    // `processedMessage`を画面の状態として保持し、変更時に表示を更新します。
    @State private var processedMessage: String?
    
    // 画面に表示する部品の並びを返す `body` を定義します。
    var body: some View {
        // タブで切り替える画面を作ります。
        TabView(selection: $selection) {
            // 家計簿のホーム画面を表示します。
            DashboardView()
                // タブの名前とアイコンを設定します。
                .tabItem { Label(lm.t(.home), systemImage: "house.fill") }
                // 切り替え対象を識別する番号を設定します。
                .tag(0)
            
            // カレンダー画面を表示します。
            CalendarView()
                // タブの名前とアイコンを設定します。
                .tabItem { Label(lm.t(.calendar), systemImage: "calendar") }
                // 切り替え対象を識別する番号を設定します。
                .tag(1)
            
            // 分析画面を表示します。
            StatsView()
                // タブの名前とアイコンを設定します。
                .tabItem { Label(lm.t(.analysis), systemImage: "chart.bar.xaxis") }
                // 切り替え対象を識別する番号を設定します。
                .tag(2)
            
            // 財布・資産の画面を表示します。
            AssetsView()
                // タブの名前とアイコンを設定します。
                .tabItem { Label(lm.t(.wallets), systemImage: "creditcard.fill") }
                // 切り替え対象を識別する番号を設定します。
                .tag(3)
        // TabView(selection: $selection)の範囲をここで閉じます。
        }
        // 画面内の強調色を設定します。
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
        // この画面が現れたときの処理を登録します。
        .onAppear {
            // `setupInitialData` を呼び出し、括弧内の値を使って処理します。
            setupInitialData() 
            // `checkRecurringItems` を呼び出し、括弧内の値を使って処理します。
            checkRecurringItems()
            
            // 初回起動時のフロー
            // 最初の言語が未選択の場合、言語選択の案内を出します。
            if !hasSelectedLanguage {
                // `showLanguageAlert`をオンにし、対応する状態を更新します。
                showLanguageAlert = true
            // 前の条件が成り立たず、続く条件が成り立つ場合の処理に進みます。
            } else if !hasShownAIDownloadAlert {
                // 言語は選択済みだがAIはまだの場合（アプデ後など）
                // `showAIDownloadAlert`をオンにし、対応する状態を更新します。
                showAIDownloadAlert = true
            // 開いていた画面部品や処理の範囲を閉じます。
            }
        // 画面表示時の処理の範囲をここで閉じます。
        }
        // 言語選択アラート
        // 条件に応じて確認メッセージを表示します。
        .alert(lm.t(.languageAlertTitle), isPresented: $showLanguageAlert) {
            // タップで処理を実行するボタンを配置します。
            Button("日本語") {
                // `completeLanguageSelection` を呼び出し、括弧内の値を使って処理します。
                completeLanguageSelection(language: .japanese)
            // ボタンの処理の範囲をここで閉じます。
            }
            // タップで処理を実行するボタンを配置します。
            Button("English") {
                // `lm.currentLanguage`へ `.english` の結果を代入します。
                lm.currentLanguage = .english
                // `completeLanguageSelection` を呼び出し、括弧内の値を使って処理します。
                completeLanguageSelection(language: .english)
            // ボタンの処理の範囲をここで閉じます。
            }
        // 確認画面の範囲をここで閉じます。
        } message: {
            // 文字列を画面に表示します。
            Text(lm.t(.languageAlertMessage))
        // } message:の範囲をここで閉じます。
        }
        // AIダウンロードアラート
        // 条件に応じて確認メッセージを表示します。
        .alert(lm.t(.aiDownloadAlertTitle), isPresented: $showAIDownloadAlert) {
            // タップで処理を実行するボタンを配置します。
            Button(lm.t(.download)) {
                // 存在しない5番目のタブではなく、AIモデル管理画面を開きます。
                showModelSettings = true
                // 初回案内を閉じます。
                showAIDownloadAlert = false
            // ボタンの処理の範囲をここで閉じます。
            }
            // タップで処理を実行するボタンを配置します。
            Button(lm.t(.notNow), role: .cancel) {
                // `hasShownAIDownloadAlert`をオンにし、対応する状態を更新します。
                hasShownAIDownloadAlert = true // Still mark as shown if user cancels
                // `showAIDownloadAlert`をオフにし、対応する状態を更新します。
                showAIDownloadAlert = false // Dismiss the alert
            // ボタンの処理の範囲をここで閉じます。
            }
        // 確認画面の範囲をここで閉じます。
        } message: {
            // 文字列を画面に表示します。
            Text(lm.t(.aiDownloadAlertMessage))
        // } message:の範囲をここで閉じます。
        }
        // 条件に応じて確認メッセージを表示します。
        .alert("固定収支を反映しました", isPresented: Binding(get: { processedMessage != nil }, set: { _ in processedMessage = nil })) {
            // タップで処理を実行するボタンを配置します。
            Button("OK", role: .cancel) { }
        // 確認画面の範囲をここで閉じます。
        } message: {
            // 文字列を画面に表示します。
            Text(processedMessage ?? "")
        // } message:の範囲をここで閉じます。
        }
    // 画面構成の範囲をここで閉じます。
    }
    
    // `completeLanguageSelection` という関数を定義し、括弧内の入力を使って処理します。
    private func completeLanguageSelection(language: AppLanguage) {
        // `lm.currentLanguage`へ `language` の結果を代入します。
        lm.currentLanguage = language
        
        // Initial Model & Ticker Suggestion
        // 選択された言語が日本語の場合に進みます。
        if language == .japanese {
             // `LocalLLMService.shared.currentModelId`へ `"gemma"` の結果を代入します。
             LocalLLMService.shared.currentModelId = "gemma"
             // AIの短い助言に使う言語を日本語へ切り替えます。
             LocalLLMService.shared.setTickerLanguage("日本語")
        // 前の条件に当てはまらない場合の処理に進みます。
        } else {
             // `LocalLLMService.shared.currentModelId`へ `"llama"` の結果を代入します。
             LocalLLMService.shared.currentModelId = "llama"
             // AIの短い助言に使う言語を英語へ切り替えます。
             LocalLLMService.shared.setTickerLanguage("English")
        // } elseの範囲をここで閉じます。
        }
        
        // `hasSelectedLanguage`をオンにし、対応する状態を更新します。
        hasSelectedLanguage = true // Keep this to mark language as selected
        // `showLanguageAlert`をオフにし、対応する状態を更新します。
        showLanguageAlert = false
        // `showAIDownloadAlert`をオンにし、対応する状態を更新します。
        showAIDownloadAlert = true
    // 関数の範囲をここで閉じます。
    }
    
    // `setupInitialData` という関数を定義し、括弧内の入力を使って処理します。
    private func setupInitialData() {
            // ■ 修正: 現金50000円を作るコードを削除しました
            // if assets.isEmpty { ... } のブロックを丸ごと消すだけです。
            
            // カテゴリの初期データは便利なので残しておきます
            // カテゴリが一件も保存されていない場合、初期カテゴリを登録します。
            if categories.isEmpty {
                // `defaults`を変更できない値として作り、右辺の結果を保存します。
                let defaults = [
                    // `Category` を呼び出し、括弧内の値を使って処理します。
                    Category(name: "食費", icon: "fork.knife", colorHex: "FFA500"),
                    // `Category` を呼び出し、括弧内の値を使って処理します。
                    Category(name: "交通費", icon: "bus", colorHex: "1E90FF"),
                    // `Category` を呼び出し、括弧内の値を使って処理します。
                    Category(name: "日用品", icon: "cart.fill", colorHex: "32CD32"),
                    // `Category` を呼び出し、括弧内の値を使って処理します。
                    Category(name: "趣味", icon: "gamecontroller.fill", colorHex: "8A2BE2"),
                    // `Category` を呼び出し、括弧内の値を使って処理します。
                    Category(name: "衣服", icon: "tshirt.fill", colorHex: "FF69B4"),
                    // `Category` を呼び出し、括弧内の値を使って処理します。
                    Category(name: "その他", icon: "questionmark.circle", colorHex: "808080")
                // 条件分岐の範囲をここで閉じます。
                ]
                // 初期カテゴリを一件ずつSwiftDataの保存対象に追加します。
                defaults.forEach { modelContext.insert($0) }
            // 条件分岐の範囲をここで閉じます。
            }
        // 関数の範囲をここで閉じます。
        }
    
    // ■ 定期処理ロジック
    // `checkRecurringItems` という関数を定義し、括弧内の入力を使って処理します。
    private func checkRecurringItems() {
        // `calendar`を変更できない値として作り、右辺の結果を保存します。
        let calendar = Calendar.current
        // `today`を変更できない値として作り、右辺の結果を保存します。
        let today = Date()
        // `currentDay`を変更できない値として作り、右辺の結果を保存します。
        let currentDay = calendar.component(.day, from: today)
        // `processList`を表す変更可能な値または計算結果を定義します。
        var processList: [String] = []
        
        // `item in recurringItems` の要素を順番に処理します。
        for item in recurringItems {
            // 今日の日付が定期収支の設定日以降なら、今月分の反映を確認します。
            if currentDay >= item.dayOfMonth {
                // `alreadyProcessed`を変更できない値として作り、右辺の結果を保存します。
                let alreadyProcessed: Bool
                // この定期収支に前回の処理日がある場合、その日付を確認します。
                if let lastDate = item.lastProcessedDate {
                    // 最後の処理日と今日が同じ月か調べ、その結果を `alreadyProcessed` に保存します。
                    alreadyProcessed = calendar.isDate(lastDate, equalTo: today, toGranularity: .month)
                // 前の条件に当てはまらない場合の処理に進みます。
                } else {
                    // `alreadyProcessed`をオフにし、対応する状態を更新します。
                    alreadyProcessed = false
                // } elseの範囲をここで閉じます。
                }
                
                // 今月分をまだ処理していない場合だけ、収支を追加します。
                if !alreadyProcessed {
                    // `processRecurringItem` を呼び出し、括弧内の値を使って処理します。
                    processRecurringItem(item)
                    // 処理した定期収支の名前と金額を通知用の一覧に追加します。
                    processList.append("\(item.title) (¥\(item.amount))")
                // 条件分岐の範囲をここで閉じます。
                }
            // 条件分岐の範囲をここで閉じます。
            }
        // 繰り返しの範囲をここで閉じます。
        }
        // 反映した定期収支が一件以上あれば、結果の案内文を作ります。
        if !processList.isEmpty {
            // `processedMessage`へ `processList.joined(separator: "\n")` の結果を代入します。
            processedMessage = processList.joined(separator: "\n")
        // 条件分岐の範囲をここで閉じます。
        }
    // 関数の範囲をここで閉じます。
    }
    
    // `processRecurringItem` という関数を定義し、括弧内の入力を使って処理します。
    private func processRecurringItem(_ item: RecurringItem) {
        // `newLog`を変更できない値として作り、右辺の結果を保存します。
        let newLog = Expense(
            // `title` という引数・項目に続く値を指定します。
            title: item.title,
            // `amount` という引数・項目に続く値を指定します。
            amount: item.amount,
            // `date` という引数・項目に続く値を指定します。
            date: Date(),
            // `assetName` という引数・項目に続く値を指定します。
            assetName: item.assetName,
            // `isIncome` という引数・項目に続く値を指定します。
            isIncome: item.isIncome,
            // `categoryName` という引数・項目に続く値を指定します。
            categoryName: "固定費" // 固定費として記録
        // 関数の範囲をここで閉じます。
        )
        // 新しく作った定期収支の記録を保存対象に追加します。
        modelContext.insert(newLog)
        
        // 定期収支に指定された名前の財布が見つかれば、その残高を更新します。
        if let targetAsset = assets.first(where: { $0.name == item.assetName }) {
            // 定期収支が収入なら、財布の残高に金額を加えます。
            if item.isIncome {
                // `targetAsset.balance`を右辺の値で増減し、結果を保存します。
                targetAsset.balance += item.amount
            // 前の条件に当てはまらない場合の処理に進みます。
            } else {
                // `targetAsset.balance`を右辺の値で増減し、結果を保存します。
                targetAsset.balance -= item.amount
            // } elseの範囲をここで閉じます。
            }
        // 条件分岐の範囲をここで閉じます。
        }
        // `item.lastProcessedDate`へ `Date()` の結果を代入します。
        item.lastProcessedDate = Date()
    // 関数の範囲をここで閉じます。
    }
// 構造体の範囲をここで閉じます。
}
