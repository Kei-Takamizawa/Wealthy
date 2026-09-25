//
//  StatsView.swift
//  Wealthy
//
//  Created by Harrison on 12/26/25.
//

// 画面部品やレイアウトを使うためのフレームワークを読み込みます。
import SwiftUI
// 保存データの検索や追加に使う仕組みを読み込みます。
import SwiftData
// グラフを描画する部品を使うための仕組みを読み込みます。
import Charts

// 月別の収支を集計してグラフで示す分析画面を定義します。
struct StatsView: View {
    // 画面間で共有される言語設定を受け取り、表示文や通貨記号に使います。
    @EnvironmentObject var lm: LanguageManager
    // 保存済みの収支記録を取得し、月別・日別の集計に使います。
    @Query var expenses: [Expense]
    // 保存済みカテゴリを取得し、選択肢や色・アイコン表示に使います。
    @Query var categories: [Category] // For colors/icons
    
    // Month Switching
    // 現在表示している月の位置を保持し、値が変わると画面を更新します。
    @State private var selectedMonthIndex: Int = 24
    // 表示対象となる過去2年から未来2年までの月を保持します。
    let months: [Date]
    
    // Chart Type
    // ChartTypeという選択肢の型を定義します。
    enum ChartType: String, CaseIterable, Identifiable {
        // 日別の棒グラフを表す選択肢を定義します。
        case bar = "Daily"
        // カテゴリ別の円グラフを表す選択肢を定義します。
        case pie = "Category"
        // idという値または計算結果を定義します。
        var id: String { self.rawValue }
    // ここで「ChartType列挙型」の範囲を閉じます。
    }
    // 表示するグラフの種類を保持し、値が変わると画面を更新します。
    @State private var chartType: ChartType = .bar
    
    // この型を作るときに実行する初期化処理を定義します。
    init() {
        // tempMonthsという値または計算結果を定義します。
        var tempMonths: [Date] = []
        // calendarという定数へ「Calendar.current」の計算結果を保存します。
        let calendar = Calendar.current
        // currentMonthという定数へ「Date()」の計算結果を保存します。
        let currentMonth = Date()
        // iへ-24...24の各要素を順番に取り出して処理します。
        for i in -24...24 {
            // オプショナル値の取得に成功した場合だけ、中の値を使って表示します。
            if let date = calendar.date(byAdding: .month, value: i, to: currentMonth) {
                // 作成した月の日付を、表示対象の月一覧の末尾へ追加します。
                tempMonths.append(date)
            // ここで「条件分岐」の範囲を閉じます。
            }
        // ここで「繰り返し」の範囲を閉じます。
        }
        // このインスタンスが持つプロパティへ値を設定します。
        self.months = tempMonths
        // _selectedMonthIndexへ右辺の値を代入し、状態または集計結果を更新します。
        _selectedMonthIndex = State(initialValue: 24)
    // ここで「初期化処理」の範囲を閉じます。
    }
    
    // この画面または部品の表示内容をSwiftUIの部品として返します。
    var body: some View {
        // 画面遷移やナビゲーションタイトルを持つ画面の土台を作ります。
        NavigationStack {
            // 背景と前景の部品を重ねて配置する領域を作ります。
            ZStack {
                // Modern Dark Background
                // 指定色が上から下へ変化する背景を描画します。
                LinearGradient(colors: [Color.black, Color(white: 0.05)], startPoint: .top, endPoint: .bottom)
                    // 端末の安全領域の外側まで表示を広げます。
                    .ignoresSafeArea()
                
                // 子部品を上から下へ並べる領域を作ります。
                VStack(spacing: 20) {
                    // Header Area
                    // 子部品を上から下へ並べる領域を作ります。
                    VStack(spacing: 12) {
                        // 言語設定の「analysis」に対応する翻訳文を表示します。
                        Text(lm.t(.analysis))
                            // 文字またはアイコンの書体と大きさを指定します。
                            .font(.headline)
                            // この文字やアイコンを.whiteで描画します。
                            .foregroundStyle(.white)
                        
                        // Chart Type Picker
                        // 「Type」の候補を表示し、選択値をバインド先へ保存します。
                        Picker("Type", selection: $chartType) {
                            // 配列や範囲の各要素に対応する画面部品を繰り返し生成します。
                            ForEach(ChartType.allCases) { type in
                                // 画面に文字を表示します。
                                Text(type.rawValue).tag(type)
                            // ここで「ForEachクロージャ」の範囲を閉じます。
                            }
                        // この画面部品または処理の範囲をここで閉じます。
                        }
                        // .pickerStyleをこの画面部品に適用します。
                        .pickerStyle(.segmented)
                        // 部品の内側または外側に余白を追加します。
                        .padding(.horizontal, 40)
                    // ここで「縦並びレイアウト」の範囲を閉じます。
                    }
                    // 部品の内側または外側に余白を追加します。
                    .padding(.top)
                    
                    // Main Chart Area (Swipeable)
                    // 月やページを左右へ切り替える表示領域を作ります。
                    TabView(selection: $selectedMonthIndex) {
                        // 配列や範囲の各要素に対応する画面部品を繰り返し生成します。
                        ForEach(0..<months.count, id: \.self) { index in
                            // currentExpensesという定数へ「filterExpenses(for: months[index])」の計算結果を保存します。
                            let currentExpenses = filterExpenses(for: months[index])
                            
                            // 子部品を上から下へ並べる領域を作ります。
                            VStack {
                                // 表示中の月とその月の収支を使って見出しを描きます。
                                monthHeader(for: months[index], expenses: currentExpenses)
                                
                                // 「chartType == .bar」の条件が真の場合にだけ、次の処理を実行します。
                                if chartType == .bar {
                                    // 表示中の月の収支を日別の棒グラフに描きます。
                                    ModernBarChart(month: months[index], expenses: currentExpenses, lm: lm)
                                        // 表示切り替え時の変化の仕方を指定します。
                                        .transition(.opacity.combined(with: .move(edge: .leading)))
                                // ここで「条件分岐」の処理範囲を閉じます。
                                } else {
                                    // 表示中の月の支出をカテゴリ別の円グラフに描きます。
                                    ModernPieChart(expenses: currentExpenses, categories: categories, lm: lm)
                                        // 表示切り替え時の変化の仕方を指定します。
                                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                                // この画面部品または処理の範囲をここで閉じます。
                                }
                            // ここで「縦並びレイアウト」の範囲を閉じます。
                            }
                            // 各ページや選択肢を識別する値を設定します。
                            .tag(index)
                            // 部品の内側または外側に余白を追加します。
                            .padding(.horizontal)
                        // ここで「ForEachクロージャ」の範囲を閉じます。
                        }
                    // この画面部品または処理の範囲をここで閉じます。
                    }
                    // ページ切り替え表示の見た目を設定します。
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    // 状態変更時に使うアニメーションを指定します。
                    .animation(.spring, value: chartType) // Animate switcher
                    
                    // 伸縮する空白を入れ、周囲の部品を離して配置します。
                    Spacer()
                // ここで「縦並びレイアウト」の範囲を閉じます。
                }
            // ここで「重ね合わせレイアウト」の範囲を閉じます。
            }
            // ナビゲーションバーを表示するかどうかを切り替えます。
            .navigationBarHidden(true)
        // ここで「ナビゲーション画面」の範囲を閉じます。
        }
    // この画面部品または処理の範囲をここで閉じます。
    }
    
    // 指定月に属する記録だけを抽出する処理を定義します。
    private func filterExpenses(for date: Date) -> [Expense] {
        // calendarという定数へ「Calendar.current」の計算結果を保存します。
        let calendar = Calendar.current
        // 計算結果を呼び出し元へ返し、この関数の処理を終えます。
        return expenses.filter {
            // 収支の日付が指定した月と同じか調べます。
            calendar.isDate($0.date, equalTo: date, toGranularity: .month)
        // この画面部品または処理の範囲をここで閉じます。
        }
    // ここで「filterExpenses関数」の範囲を閉じます。
    }
    
    // 月と集計額を見せる見出し部品を作る処理を定義します。
    private func monthHeader(for date: Date, expenses: [Expense]) -> some View {
        // totalExpenseという定数へ「expenses.filter { !$0.isIncome }.reduce(0) { $0 + $1.am」の計算結果を保存します。
        let totalExpense = expenses.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
        
        // 計算結果を呼び出し元へ返し、この関数の処理を終えます。
        return VStack(spacing: 5) {
            // 画面に文字を表示します。
            Text(date.formatted(.dateTime.year().month(.wide)))
                // 文字またはアイコンの書体と大きさを指定します。
                .font(.title3)
                // この文字やアイコンを.grayで描画します。
                .foregroundStyle(.gray)
            
            // 画面に文字を表示します。
            Text(lm.currencySymbol + "\(totalExpense)")
                // 文字またはアイコンの書体と大きさを指定します。
                .font(.system(size: 40, weight: .bold, design: .rounded))
                // この文字やアイコンを.whiteで描画します。
                .foregroundStyle(.white)
                // 値が切り替わるときの文字表示アニメーションを指定します。
                .contentTransition(.numericText())
        // この画面部品または処理の範囲をここで閉じます。
        }
        // 部品の内側または外側に余白を追加します。
        .padding(.top, 10)
    // ここで「monthHeader関数」の範囲を閉じます。
    }
// ここで「StatsView型」の範囲を閉じます。
}

// MARK: - Modern Bar Chart
// ModernBarChartという画面または補助部品の定義を始めます。
struct ModernBarChart: View {
    // グラフの集計対象にする月を受け取ります。
    let month: Date
    // 表示対象の収支記録を親から受け取ります。
    let expenses: [Expense]
    // 翻訳と通貨表示に使う言語設定を受け取ります。
    let lm: LanguageManager
    
    // 月内の日ごとの支出額をグラフ用データにまとめます。
    var dailyData: [(day: Int, amount: Int)] {
        // calendarという定数へ「Calendar.current」の計算結果を保存します。
        let calendar = Calendar.current
        // 必要な値を安全に取り出し、値がなければこの関数をその場で終了します。
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        // expenseItemsという定数へ「expenses.filter { !$0.isIncome }」の計算結果を保存します。
        let expenseItems = expenses.filter { !$0.isIncome }
        
        // dataという値または計算結果を定義します。
        var data: [(Int, Int)] = []
        // dayへrangeの各要素を順番に取り出して処理します。
        for day in range {
            // sumという定数へ「expenseItems」の計算結果を保存します。
            let sum = expenseItems
                // 条件に合う要素だけを抽出します。
                .filter { calendar.component(.day, from: $0.date) == day }
                // 複数の金額を合計します。
                .reduce(0) { $0 + $1.amount }
            // その日の日付と合計額をグラフ用の一覧へ追加します。
            data.append((day, sum))
        // ここで「繰り返し」の範囲を閉じます。
        }
        // 計算結果を呼び出し元へ返し、この関数の処理を終えます。
        return data
    // この画面部品または処理の範囲をここで閉じます。
    }
    
    // この画面または部品の表示内容をSwiftUIの部品として返します。
    var body: some View {
        // 与えられたデータをグラフとして描画する領域を作ります。
        Chart {
            // 配列や範囲の各要素に対応する画面部品を繰り返し生成します。
            ForEach(dailyData, id: \.day) { item in
                // この行で「BarMark(」を指定し、画面構成または処理の一部を定義します。
                BarMark(
                    // x引数に、この部品または処理へ渡す値を指定します。
                    x: .value("Day", item.day),
                    // y引数に、この部品または処理へ渡す値を指定します。
                    y: .value("Amount", item.amount)
                // 直前に開いた引数または配列のまとまりを閉じます。
                )
                // この文字やアイコンをで描画します。
                .foregroundStyle(
                    // 指定色が上から下へ変化する背景を描画します。
                    LinearGradient(
                        // colors引数に、この部品または処理へ渡す値を指定します。
                        colors: [.orange, .red],
                        // startPoint引数に、この部品または処理へ渡す値を指定します。
                        startPoint: .bottom,
                        // endPoint引数に、この部品または処理へ渡す値を指定します。
                        endPoint: .top
                    // 直前に開いた引数または配列のまとまりを閉じます。
                    )
                // 直前に開いた引数または配列のまとまりを閉じます。
                )
                // 部品の角を指定した半径で丸くします。
                .cornerRadius(6)
            // ここで「ForEachクロージャ」の範囲を閉じます。
            }
        // ここで「グラフ定義」の範囲を閉じます。
        }
        // グラフの横軸を1日から31日までの範囲に固定します。
        .chartXScale(domain: 1...31)
        // グラフの縦軸の目盛りとラベルを設定します。
        .chartYAxis {
            // この行で「AxisMarks(position: .leading) { value in」を指定し、画面構成または処理の一部を定義します。
            AxisMarks(position: .leading) { value in
                // グラフの補助線を薄い灰色で描きます。
                AxisGridLine().foregroundStyle(.gray.opacity(0.1))
                // グラフ軸の目盛りを灰色の文字で表示します。
                AxisValueLabel().foregroundStyle(.gray.opacity(0.6))
            // この画面部品または処理の範囲をここで閉じます。
            }
        // この画面部品または処理の範囲をここで閉じます。
        }
        // グラフの横軸の目盛り間隔とラベルを設定します。
        .chartXAxis {
            // この行で「AxisMarks(values: .stride(by: 5)) { value 」を指定し、画面構成または処理の一部を定義します。
            AxisMarks(values: .stride(by: 5)) { value in
                // グラフの補助線を薄い灰色で描きます。
                AxisGridLine().foregroundStyle(.gray.opacity(0.1))
                // グラフ軸の目盛りを灰色の文字で表示します。
                AxisValueLabel().foregroundStyle(.gray.opacity(0.6))
            // この画面部品または処理の範囲をここで閉じます。
            }
        // この画面部品または処理の範囲をここで閉じます。
        }
        // 部品の幅、高さ、配置できる範囲を指定します。
        .frame(height: 300)
        // 部品の内側または外側に余白を追加します。
        .padding()
        // この部品の背後に指定した背景を描きます。
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.05)))
    // この画面部品または処理の範囲をここで閉じます。
    }
// ここで「ModernBarChart型」の範囲を閉じます。
}

// MARK: - Modern Pie Chart
// ModernPieChartという画面または補助部品の定義を始めます。
struct ModernPieChart: View {
    // 表示対象の収支記録を親から受け取ります。
    let expenses: [Expense]
    // カテゴリ名に対応する色やアイコンを親から受け取ります。
    let categories: [Category]
    // 翻訳と通貨表示に使う言語設定を受け取ります。
    let lm: LanguageManager
    
    // PieDataという画面または補助部品の定義を始めます。
    struct PieData: Identifiable {
        // idという定数へ「UUID()」の計算結果を保存します。
        let id = UUID()
        // categoryに後から変更しない値を保持します。
        let category: String
        // amountに後から変更しない値を保持します。
        let amount: Int
        // colorに後から変更しない値を保持します。
        let color: String
    // ここで「PieData型」の範囲を閉じます。
    }
    
    // 支出をカテゴリ別に合計し、円グラフ用のデータへ変換します。
    var data: [PieData] {
        // expenseItemsという定数へ「expenses.filter { !$0.isIncome }」の計算結果を保存します。
        let expenseItems = expenses.filter { !$0.isIncome }
        // groupedという定数へ「Dictionary(grouping: expenseItems, by: { $0.categoryNam」の計算結果を保存します。
        let grouped = Dictionary(grouping: expenseItems, by: { $0.categoryName ?? "Unknown" })
        
        // 計算結果を呼び出し元へ返し、この関数の処理を終えます。
        return grouped.map { (key, value) in
            // totalという定数へ「value.reduce(0) { $0 + $1.amount }」の計算結果を保存します。
            let total = value.reduce(0) { $0 + $1.amount }
            // Find color
            // catColorという定数へ「categories.first(where: { $0.name == key })?.colorHex ?」の計算結果を保存します。
            let catColor = categories.first(where: { $0.name == key })?.colorHex ?? "808080"
            // 計算結果を呼び出し元へ返し、この関数の処理を終えます。
            return PieData(category: key, amount: total, color: catColor)
        // この画面部品または処理の範囲をここで閉じます。
        }.sorted { $0.amount > $1.amount }
    // この画面部品または処理の範囲をここで閉じます。
    }
    
    // この画面または部品の表示内容をSwiftUIの部品として返します。
    var body: some View {
        // 子部品を上から下へ並べる領域を作ります。
        VStack {
            // 「data.isEmpty」の条件が真の場合にだけ、次の処理を実行します。
            if data.isEmpty {
                // 表示できるデータがない状態を利用者へ案内します。
                ContentUnavailableView(label: {
                    // 集計できるデータがないことをアイコンと文章で知らせます。
                    Label(lm.t(.noData), systemImage: "chart.pie")
                // この画面部品または処理の範囲をここで閉じます。
                })
            // ここで「条件分岐」の処理範囲を閉じます。
            } else {
                // この行で「Chart(data) { item in」を指定し、画面構成または処理の一部を定義します。
                Chart(data) { item in
                    // この行で「SectorMark(」を指定し、画面構成または処理の一部を定義します。
                    SectorMark(
                        // angle引数に、この部品または処理へ渡す値を指定します。
                        angle: .value("Amount", item.amount),
                        // innerRadius引数に、この部品または処理へ渡す値を指定します。
                        innerRadius: .ratio(0.6), // Donut style
                        // angularInset引数に、この部品または処理へ渡す値を指定します。
                        angularInset: 2.0
                    // 直前に開いた引数または配列のまとまりを閉じます。
                    )
                    // この文字やアイコンをColor(hex: item.colorで描画します。
                    .foregroundStyle(Color(hex: item.color))
                    // 部品の角を指定した半径で丸くします。
                    .cornerRadius(5)
                // ここで「グラフ定義」の範囲を閉じます。
                }
                // 部品の幅、高さ、配置できる範囲を指定します。
                .frame(height: 300)
                // 部品の内側または外側に余白を追加します。
                .padding()
                
                // Legend
                // 内容が画面より大きい場合にスクロールできる表示領域を作ります。
                ScrollView {
                    // 子部品を上から下へ並べる領域を作ります。
                    VStack(alignment: .leading, spacing: 12) {
                        // 配列や範囲の各要素に対応する画面部品を繰り返し生成します。
                        ForEach(data) { item in
                            // 子部品を左から右へ並べる領域を作ります。
                            HStack {
                                // 円形の色見本やマークを作ります。
                                Circle().fill(Color(hex: item.color)).frame(width: 12, height: 12)
                                // 画面に文字を表示します。
                                Text(lm.translateCategory(name: item.category)).foregroundStyle(.white)
                                // 伸縮する空白を入れ、周囲の部品を離して配置します。
                                Spacer()
                                // 画面に文字を表示します。
                                Text(lm.currencySymbol + "\(item.amount)").bold().foregroundStyle(.gray)
                            // ここで「横並びレイアウト」の範囲を閉じます。
                            }
                        // ここで「ForEachクロージャ」の範囲を閉じます。
                        }
                    // ここで「縦並びレイアウト」の範囲を閉じます。
                    }
                    // 部品の内側または外側に余白を追加します。
                    .padding()
                // ここで「スクロール領域」の範囲を閉じます。
                }
            // この画面部品または処理の範囲をここで閉じます。
            }
        // ここで「縦並びレイアウト」の範囲を閉じます。
        }
        // この部品の背後に指定した背景を描きます。
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.05)))
    // この画面部品または処理の範囲をここで閉じます。
    }
// ここで「ModernPieChart型」の範囲を閉じます。
}
