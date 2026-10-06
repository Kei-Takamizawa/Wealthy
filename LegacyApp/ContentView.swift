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
        // この画面が現れたときの処理を登録します。
        .onAppear {
            // `setupInitialData` を呼び出し、括弧内の値を使って処理します。
            setupInitialData() 
            // `checkRecurringItems` を呼び出し、括弧内の値を使って処理します。
            checkRecurringItems()
        // 画面表示時の処理の範囲をここで閉じます。
        }
        // 条件に応じて確認メッセージを表示します。
        .alert(lm.text("processedRecurringTitle"), isPresented: Binding(get: { processedMessage != nil }, set: { _ in processedMessage = nil })) {
            // タップで処理を実行するボタンを配置します。
            Button(lm.text("ok"), role: .cancel) { }
        // 確認画面の範囲をここで閉じます。
        } message: {
            // 文字列を画面に表示します。
            Text(processedMessage ?? "")
        // } message:の範囲をここで閉じます。
        }
    // 画面構成の範囲をここで閉じます。
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
        var failures: [String] = []
        
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
                    do {
                        try processRecurringItem(item)
                        processList.append("\(item.title) (\(AppLocalization.amount(item.amount, currencyCode: item.effectiveCurrencyCode, language: lm.currentLanguage)))")
                    } catch { failures.append("\(item.title): \(error.localizedDescription)") }
                // 条件分岐の範囲をここで閉じます。
                }
            // 条件分岐の範囲をここで閉じます。
            }
        // 繰り返しの範囲をここで閉じます。
        }
        // 反映した定期収支が一件以上あれば、結果の案内文を作ります。
        if !processList.isEmpty || !failures.isEmpty {
            // `processedMessage`へ `processList.joined(separator: "\n")` の結果を代入します。
            processedMessage = (processList + failures).joined(separator: "\n")
        // 条件分岐の範囲をここで閉じます。
        }
    // 関数の範囲をここで閉じます。
    }
    
    // `processRecurringItem` という関数を定義し、括弧内の入力を使って処理します。
    private func processRecurringItem(_ item: RecurringItem) throws {
        let entry = Expense(title: item.title, amount: item.amount, date: Date(), assetName: item.assetName,
                            isIncome: item.isIncome, categoryName: lm.text("categoryFixedCosts"),
                            balanceApplied: false, currencyCode: item.effectiveCurrencyCode)
        let previous = item.lastProcessedDate
        item.lastProcessedDate = Date()
        do {
            try ExpenseLedger.saveDraft(entry, replacing: nil, context: modelContext)
        } catch {
            item.lastProcessedDate = previous
            throw error
        }
    }
}
