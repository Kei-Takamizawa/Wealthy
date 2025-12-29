//
//  CalendarView.swift
//  家計簿
//
//  Created by Harrison on 12/26/25.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @EnvironmentObject var lm: LanguageManager
    @Query var expenses: [Expense]
    @Query var categories: [Category] // カテゴリ取得用
    
    @State private var selectedDate = Date()
    
    // 今月の合計計算
    private var monthlyStats: (income: Int, expense: Int) {
        let calendar = Calendar.current
        // カレンダーで表示されている「月」の合計を出したいが、DatePicker(.graphical)は
        // selectedDateを含む月を表示していると仮定する（厳密にはSwipe検知不可だが簡易実装として）
        let targetMonth = selectedDate
        let monthlyExpenses = expenses.filter {
            calendar.isDate($0.date, equalTo: targetMonth, toGranularity: .month)
        }
        
        let inc = monthlyExpenses.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
        let exp = monthlyExpenses.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
        return (inc, exp)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 月の合計表示エリア
                    HStack(spacing: 30) {
                        VStack(spacing: 2) {
                            Text(lm.t(.income)).font(.caption).foregroundStyle(.gray)
                            Text("+\(lm.currencySymbol)\(monthlyStats.income)")
                                .font(.headline).bold().foregroundStyle(.green)
                        }
                        VStack(spacing: 2) {
                            Text(lm.t(.expense)).font(.caption).foregroundStyle(.gray)
                            Text("-\(lm.currencySymbol)\(monthlyStats.expense)")
                                .font(.headline).bold().foregroundStyle(.red)
                        }
                    }
                    .padding(.top)
                    
                    // カレンダーヘッダー
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .colorScheme(.dark)
                        .accentColor(.orange)
                        .padding()
                        .background(Color(white: 0.1))
                        .cornerRadius(15)
                        .padding()
                    
                    // その日の支出リスト
                    let dailyExpenses = expenses.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
                    
                    if dailyExpenses.isEmpty {
                        Spacer()
                        ContentUnavailableView {
                            Text(lm.t(.noExpenses))
                                .foregroundStyle(.gray)
                        } description: {
                            Text(lm.t(.noExpensesDesc))
                                .foregroundStyle(.gray)
                        }
                        Spacer()
                    } else {
                        List(dailyExpenses) { expense in
                            HStack {
                                // カテゴリアイコン
                                let category = categories.first(where: { $0.name == expense.categoryName })
                                Image(systemName: category?.icon ?? "questionmark.circle")
                                    .foregroundStyle(Color(hex: category?.colorHex ?? "808080"))
                                    .frame(width: 24)
                                
                                Text(expense.title).foregroundStyle(.white)
                                Spacer()
                                
                                // 金額表示 (+/- と 色)
                                Text((expense.isIncome ? "+" : "-") + "\(lm.currencySymbol)\(expense.amount)")
                                    .bold()
                                    .foregroundStyle(expense.isIncome ? .green : .red)
                            }
                            .listRowBackground(Color(white: 0.1))
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle(lm.t(.calendar))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
