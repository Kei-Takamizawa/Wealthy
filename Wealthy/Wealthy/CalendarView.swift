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
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    // カレンダーヘッダー
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .colorScheme(.dark) // ダークモードカレンダー
                        .accentColor(.orange)
                        .padding()
                        .background(Color(white: 0.1))
                        .cornerRadius(15)
                        .padding()
                    
                    // その日の支出リスト
                    let dailyExpenses = expenses.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
                    
                    if dailyExpenses.isEmpty {
                        ContentUnavailableView {
                            Text(lm.t(.noExpenses))
                                .foregroundStyle(.gray)
                        } description: {
                            Text(lm.t(.noExpensesDesc))
                                .foregroundStyle(.gray)
                        }
                    } else {
                        List(dailyExpenses) { expense in
                            HStack {
                                Text(expense.title).foregroundStyle(.white)
                                Spacer()
                                Text("¥\(expense.amount)").bold().foregroundStyle(.orange)
                            }
                            .listRowBackground(Color(white: 0.1))
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
