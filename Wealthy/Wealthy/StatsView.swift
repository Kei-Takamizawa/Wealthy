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
                            MonthlyGraphView(
                                month: months[index],
                                expenses: filterExpenses(for: months[index])
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
    
    // その月の合計
    var totalAmount: Int {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    // 日ごとの集計データを作る
    var dailyData: [(day: Int, amount: Int)] {
        let calendar = Calendar.current
        // その月の日数（28~31）を取得
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        
        var data: [(Int, Int)] = []
        
        for day in range {
            // その日の支出を合計する
            let sum = expenses
                .filter { calendar.component(.day, from: $0.date) == day }
                .reduce(0) { $0 + $1.amount }
            
            data.append((day, sum))
        }
        return data
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 1. ヘッダー情報（月と合計）
            VStack(spacing: 5) {
                Text(month.formatted(.dateTime.year().month(.wide))) // "2025年 12月"
                    .font(.title3)
                    .foregroundStyle(.gray)
                
                Text(lm.currencySymbol + "\(totalAmount)")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(.orange)
                    .contentTransition(.numericText())
            }
            .padding(.top, 20)
            
            // 2. 棒グラフ
            if expenses.isEmpty {
                // データがない時
                Spacer()
                ContentUnavailableView {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 50))
                        .foregroundStyle(.gray.opacity(0.5))
                } description: {
                    Text(lm.t(.noData))
                        .foregroundStyle(.gray)
                }
                Spacer()
            } else {
                // グラフ描画
                Chart {
                    ForEach(dailyData, id: \.day) { item in
                        BarMark(
                            x: .value("Day", item.day),
                            y: .value("Amount", item.amount)
                        )
                        .foregroundStyle(LinearGradient(colors: [.orange, .red], startPoint: .bottom, endPoint: .top))
                        .cornerRadius(4)
                    }
                    
                    // 平均ライン（オプション）
                    if !expenses.isEmpty {
                        let average = totalAmount / dailyData.count
                        RuleMark(y: .value("Average", average))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundStyle(.gray.opacity(0.5))
                            .annotation(position: .leading, alignment: .bottom) {
                                Text("Avg")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                    }
                }
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
