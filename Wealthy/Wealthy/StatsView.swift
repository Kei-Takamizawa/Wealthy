//
//  StatsView.swift
//  家計簿
//
//  Created by Harrison on 12/26/25.
//

import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @EnvironmentObject var lm: LanguageManager
    @Query var expenses: [Expense]
    
    // 月切り替え用（前後2年分を用意）
    @State private var selectedMonthIndex: Int = 24
    let months: [Date]
    
    init() {
        var tempMonths: [Date] = []
        let calendar = Calendar.current
        let currentMonth = Date()
        // 過去24ヶ月 〜 未来24ヶ月
        for i in -24...24 {
            if let date = calendar.date(byAdding: .month, value: i, to: currentMonth) {
                tempMonths.append(date)
            }
        }
        self.months = tempMonths
        _selectedMonthIndex = State(initialValue: 24) // 初期値は「今月」
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // タイトルエリア
                    Text(lm.t(.analysis))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.top)
                    
                    // スワイプ可能なグラフエリア
                    TabView(selection: $selectedMonthIndex) {
                        ForEach(0..<months.count, id: \.self) { index in
                            let currentExpenses = filterExpenses(for: months[index])
                            let prevExpenses = index > 0 ? filterExpenses(for: months[index - 1]) : []
                            
                            MonthlyGraphView(
                                month: months[index],
                                expenses: currentExpenses,
                                prevExpenses: prevExpenses
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never)) // ドットを消す
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // 指定した月のデータだけ抽出する
    private func filterExpenses(for date: Date) -> [Expense] {
        let calendar = Calendar.current
        return expenses.filter {
            calendar.isDate($0.date, equalTo: date, toGranularity: .month)
        }
    }
}

// ■ 月ごとのグラフを表示するビュー
struct MonthlyGraphView: View {
    @EnvironmentObject var lm: LanguageManager
    let month: Date
    let expenses: [Expense]
    let prevExpenses: [Expense] // 先月のデータ
    
    // その月の合計（支出のみ）
    var totalExpense: Int {
        expenses.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
    }
    
    // 先月の合計（支出のみ）
    var prevTotalExpense: Int {
        prevExpenses.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
    }
    
    // 日ごとの集計データ（支出のみ）
    var dailyData: [(day: Int, amount: Int)] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        
        var data: [(Int, Int)] = []
        let expenseItems = expenses.filter { !$0.isIncome } // 支出のみにフィルタリング
        
        for day in range {
            let sum = expenseItems
                .filter { calendar.component(.day, from: $0.date) == day }
                .reduce(0) { $0 + $1.amount }
            data.append((day, sum))
        }
        return data
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 1. ヘッダー情報（月、支出合計、先月比）
            VStack(spacing: 10) {
                Text(month.formatted(.dateTime.year().month(.wide)))
                    .font(.title3)
                    .foregroundStyle(.gray)
                
                // 支出合計
                Text(lm.currencySymbol + "\(totalExpense)")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(.red)
                    .contentTransition(.numericText())
                
                // 先月比
                if prevExpenses.isEmpty {
                   Text("-")
                       .font(.caption)
                       .foregroundStyle(.gray)
                } else {
                    let diff = totalExpense - prevTotalExpense
                    let sign = diff >= 0 ? "+" : ""
                    // "先月比: +¥1000"
                    HStack(spacing: 4) {
                        Text("vs Last Month:") // 簡易ローカライズ対応が必要なら lm.t 追加推奨だが、今回は直書き
                            .font(.caption)
                            .foregroundStyle(.gray)
                        Text("\(sign)\(lm.currencySymbol)\(diff)")
                            .font(.caption).bold()
                            .foregroundStyle(diff > 0 ? .red : (diff < 0 ? .green : .gray)) // 支出増＝赤（悪い）、支出減＝緑（良い）
                    }
                }
            }
            .padding(.top, 20)
            
            // 2. 棒グラフ
            if expenses.filter({ !$0.isIncome }).isEmpty {
                Spacer()
                ContentUnavailableView {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 50))
                        .foregroundStyle(.gray.opacity(0.5))
                } description: {
                    Text(lm.t(.noData)).foregroundStyle(.gray)
                }
                Spacer()
            } else {
                Chart {
                    ForEach(dailyData, id: \.day) { item in
                        BarMark(
                            x: .value("Day", item.day),
                            y: .value("Amount", item.amount)
                        )
                        .foregroundStyle(LinearGradient(colors: [.orange, .red], startPoint: .bottom, endPoint: .top))
                        .cornerRadius(4)
                    }
                }
                // 横軸：1〜31（または月末）で固定
                .chartXScale(domain: 1...31)
                .chartXAxis {
                    AxisMarks(values: .stride(by: 5)) { value in
                        AxisGridLine().foregroundStyle(.gray.opacity(0.2))
                        AxisTick().foregroundStyle(.gray)
                        if let intValue = value.as(Int.self) {
                            AxisValueLabel("\(intValue)").foregroundStyle(.gray)
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine().foregroundStyle(.gray.opacity(0.2))
                        AxisValueLabel().foregroundStyle(.gray)
                    }
                }
                .frame(height: 350)
                .padding()
                .background(Color(white: 0.1))
                .cornerRadius(20)
                .padding(.horizontal)
            }
            Spacer()
        }
    }
}
