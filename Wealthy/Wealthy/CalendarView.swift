//
//  CalendarView.swift
//  Wealthy
//
//  Created by Harrison on 12/26/25.
//

// 画面部品やレイアウトを使うためのフレームワークを読み込みます。
import SwiftUI
// 保存データの検索や追加に使う仕組みを読み込みます。
import SwiftData
// 画像やUIKit部品を扱うための仕組みを読み込みます。
import UIKit

// 月を切り替えながら日ごとの収支を確認できるカレンダー画面を定義します。
struct CalendarView: View {
    // 画面間で共有される言語設定を受け取り、表示文や通貨記号に使います。
    @EnvironmentObject var lm: LanguageManager
    // 保存済みの収支記録を取得し、月別・日別の集計に使います。
    @Query var expenses: [Expense]
    // 保存済みカテゴリを取得し、選択肢や色・アイコン表示に使います。
    @Query var categories: [Category]
    
    // TabView Month Management
    // 現在表示している月の位置を保持し、値が変わると画面を更新します。
    @State private var currentMonthIndex: Int = 24 // Center of 48 months
    // 選択中の日付を保持し、値が変わると画面を更新します。
    @State private var selectedDate = Date()
    
    // Months Data Source (Past 2 Years .. Future 2 Years)
    // 表示対象となる過去2年から未来2年までの月を保持します。
    private let months: [Date]
    // 日付の月・日・範囲を計算するため、端末設定の暦を保持します。
    private let calendar = Calendar.current
    // カレンダー見出しに表示する曜日名を日曜から順に保持します。
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"] // Ideally localized
    
    // この型を作るときに実行する初期化処理を定義します。
    init() {
        // tempMonthsという値または計算結果を定義します。
        var tempMonths: [Date] = []
        // currentという定数へ「Date()」の計算結果を保存します。
        let current = Date()
        // calという定数へ「Calendar.current」の計算結果を保存します。
        let cal = Calendar.current
        // +/- 24 months
        // iへ-24...24の各要素を順番に取り出して処理します。
        for i in -24...24 {
            // オプショナル値の取得に成功した場合だけ、中の値を使って表示します。
            if let date = cal.date(byAdding: .month, value: i, to: current) {
                // 作成した月の日付を、表示対象の月一覧の末尾へ追加します。
                tempMonths.append(date)
            // ここで「条件分岐」の範囲を閉じます。
            }
        // ここで「繰り返し」の範囲を閉じます。
        }
        // このインスタンスが持つプロパティへ値を設定します。
        self.months = tempMonths
    // ここで「初期化処理」の範囲を閉じます。
    }
    
    // State for Popover
    // 詳細を開く日付を保持し、値が変わると画面を更新します。
    @State private var detailDate: Date? 
    // 日ごとの詳細シートを開くかどうかを保持し、値が変わると画面を更新します。
    @State private var showDetailSheet = false

    // この画面または部品の表示内容をSwiftUIの部品として返します。
    var body: some View {
        // 画面遷移やナビゲーションタイトルを持つ画面の土台を作ります。
        NavigationStack {
            // 背景と前景の部品を重ねて配置する領域を作ります。
            ZStack {
                // Background Gradient
                // 指定色が上から下へ変化する背景を描画します。
                LinearGradient(gradient: Gradient(colors: [Color.black, Color(white: 0.1)]), startPoint: .top, endPoint: .bottom)
                    // 端末の安全領域の外側まで表示を広げます。
                    .ignoresSafeArea()
                
                // 子部品を上から下へ並べる領域を作ります。
                VStack(spacing: 0) {
                    // Month & Stats Header
                    // currentMonthという定数へ「months[currentMonthIndex]」の計算結果を保存します。
                    let currentMonth = months[currentMonthIndex]
                    // 現在の月名と集計結果を示す見出しを表示します。
                    headerView(for: currentMonth)
                    
                    // Weekday Headers
                    // 子部品を左から右へ並べる領域を作ります。
                    HStack {
                        // 配列や範囲の各要素に対応する画面部品を繰り返し生成します。
                        ForEach(daysOfWeek, id: \.self) { day in
                            // 画面に文字を表示します。
                            Text(day).font(.caption).bold().frame(maxWidth: .infinity).foregroundStyle(.white.opacity(0.6))
                        // ここで「ForEachクロージャ」の範囲を閉じます。
                        }
                    // ここで「横並びレイアウト」の範囲を閉じます。
                    }
                    // 部品の内側または外側に余白を追加します。
                    .padding(.vertical, 8)
                    
                    // Swipeable Calendar Grid
                    // 月やページを左右へ切り替える表示領域を作ります。
                    TabView(selection: $currentMonthIndex) {
                        // 配列や範囲の各要素に対応する画面部品を繰り返し生成します。
                        ForEach(0..<months.count, id: \.self) { index in
                            // この行で「CalendarGridView(」を指定し、画面構成または処理の一部を定義します。
                            CalendarGridView(
                                // month引数に、この部品または処理へ渡す値を指定します。
                                month: months[index],
                                // expenses引数に、この部品または処理へ渡す値を指定します。
                                expenses: expenses,
                                // categories引数に、この部品または処理へ渡す値を指定します。
                                categories: categories,
                                // lm引数に、この部品または処理へ渡す値を指定します。
                                lm: lm,
                                // onLongPress引数に、この部品または処理へ渡す値を指定します。
                                onLongPress: { date in
                                    // detailDateへ右辺の値を代入し、状態または集計結果を更新します。
                                    detailDate = date
                                    // showDetailSheetへ右辺の値を代入し、状態または集計結果を更新します。
                                    showDetailSheet = true
                                // この画面部品または処理の範囲をここで閉じます。
                                }
                            // 直前に開いた引数または配列のまとまりを閉じます。
                            )
                            // 各ページや選択肢を識別する値を設定します。
                            .tag(index)
                        // ここで「ForEachクロージャ」の範囲を閉じます。
                        }
                    // この画面部品または処理の範囲をここで閉じます。
                    }
                    // ページ切り替え表示の見た目を設定します。
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    // .frame(height: 500) remove fixed height to let it fill available space if needed, or keep to ensure fit
                    // User said "Remove ScrollView". Safe to keep TabView flexible.
                    
                    // 伸縮する空白を入れ、周囲の部品を離して配置します。
                    Spacer()
                // ここで「縦並びレイアウト」の範囲を閉じます。
                }
            // ここで「重ね合わせレイアウト」の範囲を閉じます。
            }
            // ナビゲーションバーに現在の画面名を表示します。
            .navigationTitle(lm.t(.calendar))
            // 画面タイトルをナビゲーションバー内に表示します。
            .navigationBarTitleDisplayMode(.inline)
            // ナビゲーションバーなどの操作項目をまとめます。
            .toolbarColorScheme(.dark, for: .navigationBar)
            // ナビゲーションバーなどの操作項目をまとめます。
            .toolbar {
                // キャンセルまたは確定などの操作をナビゲーションバーへ配置します。
                ToolbarItem(placement: .topBarTrailing) {
                    // 押したときに実行する処理と、ボタンに見せる内容を定義します。
                    Button("Today") {
                        // currentMonthIndexへ右辺の値を代入し、状態または集計結果を更新します。
                        currentMonthIndex = 24 
                    // ここで「ボタン定義」の範囲を閉じます。
                    }
                // ここで「ツールバー項目」の範囲を閉じます。
                }
            // この画面部品または処理の範囲をここで閉じます。
            }
            // 状態に応じてモーダルのシート画面を表示します。
            .sheet(isPresented: $showDetailSheet) {
                // オプショナル値の取得に成功した場合だけ、中の値を使って表示します。
                if let date = detailDate {
                    // 選んだ日付の収支履歴を詳細画面へ渡して表示します。
                    DayDetailView(date: date, expenses: expenses, categories: categories, lm: lm)
                        // シートで選べる表示高さを設定します。
                        .presentationDetents([.medium, .large])
                // ここで「条件分岐」の範囲を閉じます。
                }
            // ここで「シート表示」の範囲を閉じます。
            }
        // ここで「ナビゲーション画面」の範囲を閉じます。
        }
    // この画面部品または処理の範囲をここで閉じます。
    }
    
    // ... headerView ...
    // headerViewを実行する処理を定義します。
    private func headerView(for month: Date) -> some View {
        // statsという定数へ「getMonthlyStats(for: month)」の計算結果を保存します。
        let stats = getMonthlyStats(for: month)
        // 計算結果を呼び出し元へ返し、この関数の処理を終えます。
        return HStack {
            // 押したときに実行する処理と、ボタンに見せる内容を定義します。
            Button { withAnimation { currentMonthIndex = max(0, currentMonthIndex - 1) } } label: {
                // 画像またはシステムアイコンを表示します。
                Image(systemName: "chevron.left").foregroundStyle(.white)
            // ここで「ボタン定義」の範囲を閉じます。
            }
            
            // 伸縮する空白を入れ、周囲の部品を離して配置します。
            Spacer()
            
            // 子部品を上から下へ並べる領域を作ります。
            VStack {
                // 画面に文字を表示します。
                Text(month.formatted(.dateTime.year().month(.wide)))
                    // 文字またはアイコンの書体と大きさを指定します。
                    .font(.title2).bold().foregroundStyle(.white)
                
                // 子部品を左から右へ並べる領域を作ります。
                HStack(spacing: 15) {
                    // 画面に「In: \(lm.currencySymbol)\(stats.income)」という文字を表示します。
                    Text("In: \(lm.currencySymbol)\(stats.income)").font(.caption).foregroundStyle(.green)
                    // 画面に「Out: \(lm.currencySymbol)\(stats.expense)」という文字を表示します。
                    Text("Out: \(lm.currencySymbol)\(stats.expense)").font(.caption).foregroundStyle(.red)
                // ここで「横並びレイアウト」の範囲を閉じます。
                }
            // ここで「縦並びレイアウト」の範囲を閉じます。
            }
            
            // 伸縮する空白を入れ、周囲の部品を離して配置します。
            Spacer()
            
            // 押したときに実行する処理と、ボタンに見せる内容を定義します。
            Button { withAnimation { currentMonthIndex = min(months.count - 1, currentMonthIndex + 1) } } label: {
                // 画像またはシステムアイコンを表示します。
                Image(systemName: "chevron.right").foregroundStyle(.white)
            // ここで「ボタン定義」の範囲を閉じます。
            }
        // この画面部品または処理の範囲をここで閉じます。
        }
        // 部品の内側または外側に余白を追加します。
        .padding()
        // この部品の背後に指定した背景を描きます。
        .background(Color.white.opacity(0.05))
    // ここで「headerView関数」の範囲を閉じます。
    }

    // 指定月の収入と支出を集計する処理を定義します。
    private func getMonthlyStats(for date: Date) -> (income: Int, expense: Int) {
        // monthStartという定数へ「calendar.date(from: calendar.dateComponents([.year, .mo」の計算結果を保存します。
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        // monthExpensesという定数へ「expenses.filter {」の計算結果を保存します。
        let monthExpenses = expenses.filter {
            // 収支記録の日付が表示中の月に含まれるか調べます。
            calendar.isDate($0.date, equalTo: monthStart, toGranularity: .month)
        // この画面部品または処理の範囲をここで閉じます。
        }
        // incという定数へ「monthExpenses.filter { $0.isIncome }.reduce(0) { $0 + $」の計算結果を保存します。
        let inc = monthExpenses.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
        // expという定数へ「monthExpenses.filter { !$0.isIncome }.reduce(0) { $0 + 」の計算結果を保存します。
        let exp = monthExpenses.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
        // 計算結果を呼び出し元へ返し、この関数の処理を終えます。
        return (inc, exp)
    // ここで「getMonthlyStats関数」の範囲を閉じます。
    }
// ここで「CalendarView型」の範囲を閉じます。
}

// Subview for the Grid
// CalendarGridViewという画面または補助部品の定義を始めます。
struct CalendarGridView: View {
    // グラフの集計対象にする月を受け取ります。
    let month: Date
    // 表示対象の収支記録を親から受け取ります。
    let expenses: [Expense]
    // カテゴリ名に対応する色やアイコンを親から受け取ります。
    let categories: [Category]
    // 翻訳と通貨表示に使う言語設定を受け取ります。
    let lm: LanguageManager
    // 日付を長押ししたとき親画面へ通知する処理を受け取ります。
    let onLongPress: (Date) -> Void
    
    // 日付の月・日・範囲を計算するため、端末設定の暦を保持します。
    private let calendar = Calendar.current
    
    // この画面または部品の表示内容をSwiftUIの部品として返します。
    var body: some View {
        // 項目を列に並べ、必要になった分だけ生成するグリッドを作ります。
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            // 配列や範囲の各要素に対応する画面部品を繰り返し生成します。
            ForEach(generateDays(), id: \.self) { date in
                // オプショナル値の取得に成功した場合だけ、中の値を使って表示します。
                if let date = date {
                    // この行で「ModernDayCell(」を指定し、画面構成または処理の一部を定義します。
                    ModernDayCell(
                        // date引数に、この部品または処理へ渡す値を指定します。
                        date: date,
                        // expenses引数に、この部品または処理へ渡す値を指定します。
                        expenses: expenses.filter { calendar.isDate($0.date, inSameDayAs: date) },
                        // categories引数に、この部品または処理へ渡す値を指定します。
                        categories: categories,
                        // currencySymbol引数に、この部品または処理へ渡す値を指定します。
                        currencySymbol: lm.currencySymbol
                    // 直前に開いた引数または配列のまとまりを閉じます。
                    )
                    // 日付を長押ししたときの詳細表示処理を登録します。
                    .onLongPressGesture {
                        // 長押しされた日付を親画面の処理へ渡します。
                        onLongPress(date)
                    // この画面部品または処理の範囲をここで閉じます。
                    }
                // ここで「条件分岐」の処理範囲を閉じます。
                } else {
                    // 背景や塗りつぶしに使う色を指定します。
                    Color.clear.frame(height: 60)
                // この画面部品または処理の範囲をここで閉じます。
                }
            // ここで「ForEachクロージャ」の範囲を閉じます。
            }
        // この画面部品または処理の範囲をここで閉じます。
        }
        // 部品の内側または外側に余白を追加します。
        .padding(.horizontal)
    // この画面部品または処理の範囲をここで閉じます。
    }
    
    // カレンダー表示に使う日付と空白を作る処理を定義します.
    private func generateDays() -> [Date?] {
        // 必要な値を安全に取り出し、値がなければこの関数をその場で終了します。
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return [] }
        // monthStartという定数へ「monthInterval.start」の計算結果を保存します。
        let monthStart = monthInterval.start
        
        // weekdayという定数へ「calendar.component(.weekday, from: monthStart)」の計算結果を保存します。
        let weekday = calendar.component(.weekday, from: monthStart)
        // offsetという定数へ「weekday - 1」の計算結果を保存します。
        let offset = weekday - 1
        
        // daysという値または計算結果を定義します。
        var days: [Date?] = Array(repeating: nil, count: offset)
        
        // オプショナル値の取得に成功した場合だけ、中の値を使って表示します。
        if let range = calendar.range(of: .day, in: .month, for: monthStart) {
            // dayへrangeの各要素を順番に取り出して処理します。
            for day in range {
                // オプショナル値の取得に成功した場合だけ、中の値を使って表示します。
                if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                    // 作成した日付をカレンダーの日付一覧へ追加します。
                    days.append(date)
                // ここで「条件分岐」の範囲を閉じます。
                }
            // ここで「繰り返し」の範囲を閉じます。
            }
        // ここで「条件分岐」の範囲を閉じます。
        }
        // 計算結果を呼び出し元へ返し、この関数の処理を終えます。
        return days
    // ここで「generateDays関数」の範囲を閉じます。
    }
// ここで「CalendarGridView型」の範囲を閉じます。
}

// Improved Modern Day Cell
// ModernDayCellという画面または補助部品の定義を始めます。
struct ModernDayCell: View {
    // 詳細または集計の対象にする日付を受け取ります。
    let date: Date
    // 表示対象の収支記録を親から受け取ります。
    let expenses: [Expense]
    // カテゴリ名に対応する色やアイコンを親から受け取ります。
    let categories: [Category]
    // 金額の前に表示する通貨記号を受け取ります。
    let currencySymbol: String
    
    // その日の収入合計から支出合計を引いた差額を計算します。
    var dailyTotal: Int {
        // incという定数へ「expenses.filter { $0.isIncome }.reduce(0) { $0 + $1.amo」の計算結果を保存します。
        let inc = expenses.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
        // expという定数へ「expenses.filter { !$0.isIncome }.reduce(0) { $0 + $1.am」の計算結果を保存します。
        let exp = expenses.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
        // 計算結果を呼び出し元へ返し、この関数の処理を終えます。
        return inc - exp
    // この画面部品または処理の範囲をここで閉じます。
    }
    
    // この画面または部品の表示内容をSwiftUIの部品として返します。
    var body: some View {
        // 子部品を上から下へ並べる領域を作ります。
        VStack(spacing: 4) {
            // Day Number
            // 画面に「\(Calendar.current.component(.day, from: date))」という文字を表示します。
            Text("\(Calendar.current.component(.day, from: date))")
                // 文字またはアイコンの書体と大きさを指定します。
                .font(.system(size: 14, weight: .bold))
                // この文字やアイコンを.whiteで描画します。
                .foregroundStyle(.white)
            
            // 「!expenses.isEmpty」の条件が真の場合にだけ、次の処理を実行します。
            if !expenses.isEmpty {
                // Total Amount
                // Total Amount
                // 「dailyTotal != 0」の条件が真の場合にだけ、次の処理を実行します。
                if dailyTotal != 0 {
                    // 画面に「\(dailyTotal > 0 ? 」という文字を表示します。
                    Text("\(dailyTotal > 0 ? "+" : "")\(dailyTotal)")
                        // 文字またはアイコンの書体と大きさを指定します。
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        // この文字やアイコンをdailyTotal > 0 ? .green : .redで描画します。
                        .foregroundStyle(dailyTotal > 0 ? .green : .red)
                        // .lineLimitをこの画面部品に適用します。
                        .lineLimit(1)
                // ここで「条件分岐」の処理範囲を閉じます。
                } else {
                    // 画面に「-」という文字を表示します。
                    Text("-").font(.caption2).foregroundStyle(.gray)
                // この画面部品または処理の範囲をここで閉じます。
                }
                
                // Icons (Limit to 3)
                // 子部品を左から右へ並べる領域を作ります。
                HStack(spacing: 2) {
                    // 配列や範囲の各要素に対応する画面部品を繰り返し生成します。
                    ForEach(expenses.prefix(3)) { exp in
                        // オプショナル値の取得に成功した場合だけ、中の値を使って表示します。
                        if let cat = categories.first(where: { $0.name == exp.categoryName }) {
                            // 「UIImage(systemName: cat.icon) != nil」の条件が真の場合にだけ、次の処理を実行します。
                            if UIImage(systemName: cat.icon) != nil {
                                // 画像またはシステムアイコンを表示します。
                                Image(systemName: cat.icon)
                                    // 文字またはアイコンの書体と大きさを指定します。
                                    .font(.system(size: 8))
                                    // この文字やアイコンをColor(hex: cat.colorHexで描画します。
                                    .foregroundStyle(Color(hex: cat.colorHex))
                            // ここで「条件分岐」の処理範囲を閉じます。
                            } else {
                                // 画面に文字を表示します。
                                Text(cat.icon)
                                    // 文字またはアイコンの書体と大きさを指定します。
                                    .font(.system(size: 8))
                            // この画面部品または処理の範囲をここで閉じます。
                            }
                        // ここで「条件分岐」の処理範囲を閉じます。
                        } else {
                            // 円形の色見本やマークを作ります。
                            Circle().fill(.gray).frame(width: 4, height: 4)
                        // この画面部品または処理の範囲をここで閉じます。
                        }
                    // ここで「ForEachクロージャ」の範囲を閉じます。
                    }
                // ここで「横並びレイアウト」の範囲を閉じます。
                }
            // ここで「条件分岐」の処理範囲を閉じます。
            } else {
                // 伸縮する空白を入れ、周囲の部品を離して配置します。
                Spacer().frame(height: 10)
            // この画面部品または処理の範囲をここで閉じます。
            }
        // ここで「縦並びレイアウト」の範囲を閉じます。
        }
        // 部品の幅、高さ、配置できる範囲を指定します。
        .frame(height: 65) // Taller cell
        // 部品の幅、高さ、配置できる範囲を指定します。
        .frame(maxWidth: .infinity)
        // この部品の背後に指定した背景を描きます。
        .background(
            // 角を丸めた四角形を背景や枠として作ります。
            RoundedRectangle(cornerRadius: 12)
                // 図形の内側を塗りつぶします。
                .fill(Color(white: 0.15))
        // 直前に開いた引数または配列のまとまりを閉じます。
        )
        // この部品の上に枠や補助表示を重ねます。
        .overlay(
            // 角を丸めた四角形を背景や枠として作ります。
            RoundedRectangle(cornerRadius: 12)
                // 図形の輪郭線を描きます。
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        // 直前に開いた引数または配列のまとまりを閉じます。
        )
    // この画面部品または処理の範囲をここで閉じます。
    }
// ここで「ModernDayCell型」の範囲を閉じます。
}

// Day Detail Popup
// DayDetailViewという画面または補助部品の定義を始めます。
struct DayDetailView: View {
    // 詳細または集計の対象にする日付を受け取ります。
    let date: Date
    // 表示対象の収支記録を親から受け取ります。
    let expenses: [Expense]
    // カテゴリ名に対応する色やアイコンを親から受け取ります。
    let categories: [Category]
    // 翻訳と通貨表示に使う言語設定を受け取ります。
    let lm: LanguageManager
    
    // 対象日と一致する支出・収入だけを一覧用に抽出します。
    private var dailyExpenses: [Expense] {
        // この行で「expenses.filter { Calendar.current.isDate(」を指定し、画面構成または処理の一部を定義します。
        expenses.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    // この画面部品または処理の範囲をここで閉じます。
    }
    
    // この画面または部品の表示内容をSwiftUIの部品として返します。
    var body: some View {
        // 画面遷移やナビゲーションタイトルを持つ画面の土台を作ります。
        NavigationStack {
            // 子部品を上から下へ並べる領域を作ります。
            VStack {
                 // 「dailyExpenses.isEmpty」の条件が真の場合にだけ、次の処理を実行します。
                 if dailyExpenses.isEmpty {
                    // 表示できるデータがない状態を利用者へ案内します。
                    ContentUnavailableView {
                        // 言語設定の「noExpenses」に対応する翻訳文を表示します。
                        Text(lm.t(.noExpenses)).foregroundStyle(.gray)
                    // この画面部品または処理の範囲をここで閉じます。
                    }
                // ここで「条件分岐」の処理範囲を閉じます。
                } else {
                    // 各データを行に分けて表示するスクロール可能な一覧を作ります。
                    List(dailyExpenses) { expense in
                        // 子部品を左から右へ並べる領域を作ります。
                        HStack {
                            // categoryという定数へ「categories.first(where: { $0.name == expense.categoryNa」の計算結果を保存します。
                            let category = categories.first(where: { $0.name == expense.categoryName })
                            // オプショナル値の取得に成功した場合だけ、中の値を使って表示します。
                            if let icon = category?.icon {
                                // 画像またはシステムアイコンを表示します。
                                Image(systemName: icon)
                                    // この文字やアイコンをColor(hex: category?.colorHex ?? "808080"で描画します。
                                    .foregroundStyle(Color(hex: category?.colorHex ?? "808080"))
                                    // 部品の幅、高さ、配置できる範囲を指定します。
                                    .frame(width: 24)
                            // ここで「条件分岐」の処理範囲を閉じます。
                            } else {
                                // 画像またはシステムアイコンを表示します。
                                Image(systemName: "questionmark.circle").foregroundStyle(.gray)
                            // この画面部品または処理の範囲をここで閉じます。
                            }
                            
                            // 子部品を上から下へ並べる領域を作ります。
                            VStack(alignment: .leading) {
                                // 画面に文字を表示します。
                                Text(expense.title).foregroundStyle(.primary)
                                // 画面に文字を表示します。
                                Text(category?.name ?? "").font(.caption).foregroundStyle(.gray)
                            // ここで「縦並びレイアウト」の範囲を閉じます。
                            }
                            
                            // 伸縮する空白を入れ、周囲の部品を離して配置します。
                            Spacer()
                            
                            // 画面に文字を表示します。
                            Text((expense.isIncome ? "+" : "-") + "\(lm.currencySymbol)\(expense.amount)")
                                // 文字を太字にします。
                                .bold()
                                // この文字やアイコンをexpense.isIncome ? .green : .redで描画します。
                                .foregroundStyle(expense.isIncome ? .green : .red)
                        // ここで「横並びレイアウト」の範囲を閉じます。
                        }
                    // ここで「一覧表示」の範囲を閉じます。
                    }
                // この画面部品または処理の範囲をここで閉じます。
                }
            // ここで「縦並びレイアウト」の範囲を閉じます。
            }
            // ナビゲーションバーに現在の画面名を表示します。
            .navigationTitle(date.formatted(date: .complete, time: .omitted))
            // 画面タイトルをナビゲーションバー内に表示します。
            .navigationBarTitleDisplayMode(.inline)
        // ここで「ナビゲーション画面」の範囲を閉じます。
        }
    // この画面部品または処理の範囲をここで閉じます。
    }
// ここで「DayDetailView型」の範囲を閉じます。
}
