//
//  CalendarView.swift
//  Wealthy
//
//  Created by Harrison on 12/26/25.
//

import SwiftUI
import SwiftData
import UIKit

struct CalendarView: View {
    @EnvironmentObject var lm: LanguageManager
    @Query var expenses: [Expense]
    @Query var categories: [Category]
    
    // TabView Month Management
    @State private var currentMonthIndex: Int = 24 // Center of 48 months
    @State private var selectedDate = Date()
    
    // Months Data Source (Past 2 Years .. Future 2 Years)
    private let months: [Date]
    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"] // Ideally localized
    
    init() {
        var tempMonths: [Date] = []
        let current = Date()
        let cal = Calendar.current
        // +/- 24 months
        for i in -24...24 {
            if let date = cal.date(byAdding: .month, value: i, to: current) {
                tempMonths.append(date)
            }
        }
        self.months = tempMonths
    }
    
    // State for Popover
    @State private var detailDate: Date? 
    @State private var showDetailSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                LinearGradient(gradient: Gradient(colors: [Color.black, Color(white: 0.1)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Month & Stats Header
                    let currentMonth = months[currentMonthIndex]
                    headerView(for: currentMonth)
                    
                    // Weekday Headers
                    HStack {
                        ForEach(daysOfWeek, id: \.self) { day in
                            Text(day).font(.caption).bold().frame(maxWidth: .infinity).foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Swipeable Calendar Grid
                    TabView(selection: $currentMonthIndex) {
                        ForEach(0..<months.count, id: \.self) { index in
                            CalendarGridView(
                                month: months[index],
                                expenses: expenses,
                                categories: categories,
                                lm: lm,
                                onLongPress: { date in
                                    detailDate = date
                                    showDetailSheet = true
                                }
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    // .frame(height: 500) remove fixed height to let it fill available space if needed, or keep to ensure fit
                    // User said "Remove ScrollView". Safe to keep TabView flexible.
                    
                    Spacer()
                }
            }
            .navigationTitle(lm.t(.calendar))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Today") {
                        currentMonthIndex = 24 
                    }
                }
            }
            .sheet(isPresented: $showDetailSheet) {
                if let date = detailDate {
                    DayDetailView(date: date, expenses: expenses, categories: categories, lm: lm)
                        .presentationDetents([.medium, .large])
                }
            }
        }
    }
    
    // ... headerView ...
    private func headerView(for month: Date) -> some View {
        let stats = getMonthlyStats(for: month)
        return HStack {
            Button { withAnimation { currentMonthIndex = max(0, currentMonthIndex - 1) } } label: {
                Image(systemName: "chevron.left").foregroundStyle(.white)
            }
            
            Spacer()
            
            VStack {
                Text(month.formatted(.dateTime.year().month(.wide)))
                    .font(.title2).bold().foregroundStyle(.white)
                
                HStack(spacing: 15) {
                    Text("In: \(lm.currencySymbol)\(stats.income)").font(.caption).foregroundStyle(.green)
                    Text("Out: \(lm.currencySymbol)\(stats.expense)").font(.caption).foregroundStyle(.red)
                }
            }
            
            Spacer()
            
            Button { withAnimation { currentMonthIndex = min(months.count - 1, currentMonthIndex + 1) } } label: {
                Image(systemName: "chevron.right").foregroundStyle(.white)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
    }

    private func getMonthlyStats(for date: Date) -> (income: Int, expense: Int) {
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let monthExpenses = expenses.filter {
            calendar.isDate($0.date, equalTo: monthStart, toGranularity: .month)
        }
        let inc = monthExpenses.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
        let exp = monthExpenses.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
        return (inc, exp)
    }
}

// Subview for the Grid
struct CalendarGridView: View {
    let month: Date
    let expenses: [Expense]
    let categories: [Category]
    let lm: LanguageManager
    let onLongPress: (Date) -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(generateDays(), id: \.self) { date in
                if let date = date {
                    ModernDayCell(
                        date: date,
                        expenses: expenses.filter { calendar.isDate($0.date, inSameDayAs: date) },
                        categories: categories,
                        currencySymbol: lm.currencySymbol
                    )
                    .onLongPressGesture {
                        onLongPress(date)
                    }
                } else {
                    Color.clear.frame(height: 60)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func generateDays() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return [] }
        let monthStart = monthInterval.start
        
        let weekday = calendar.component(.weekday, from: monthStart)
        let offset = weekday - 1
        
        var days: [Date?] = Array(repeating: nil, count: offset)
        
        if let range = calendar.range(of: .day, in: .month, for: monthStart) {
            for day in range {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                    days.append(date)
                }
            }
        }
        return days
    }
}

// Improved Modern Day Cell
struct ModernDayCell: View {
    let date: Date
    let expenses: [Expense]
    let categories: [Category]
    let currencySymbol: String
    
    var dailyTotal: Int {
        let inc = expenses.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
        let exp = expenses.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
        return inc - exp
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Day Number
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
            
            if !expenses.isEmpty {
                // Total Amount
                // Total Amount
                if dailyTotal != 0 {
                    Text("\(dailyTotal > 0 ? "+" : "")\(dailyTotal)")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(dailyTotal > 0 ? .green : .red)
                        .lineLimit(1)
                } else {
                    Text("-").font(.caption2).foregroundStyle(.gray)
                }
                
                // Icons (Limit to 3)
                HStack(spacing: 2) {
                    ForEach(expenses.prefix(3)) { exp in
                        if let cat = categories.first(where: { $0.name == exp.categoryName }) {
                            if UIImage(systemName: cat.icon) != nil {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 8))
                                    .foregroundStyle(Color(hex: cat.colorHex))
                            } else {
                                Text(cat.icon)
                                    .font(.system(size: 8))
                            }
                        } else {
                            Circle().fill(.gray).frame(width: 4, height: 4)
                        }
                    }
                }
            } else {
                Spacer().frame(height: 10)
            }
        }
        .frame(height: 65) // Taller cell
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// Day Detail Popup
struct DayDetailView: View {
    let date: Date
    let expenses: [Expense]
    let categories: [Category]
    let lm: LanguageManager
    
    private var dailyExpenses: [Expense] {
        expenses.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                 if dailyExpenses.isEmpty {
                    ContentUnavailableView {
                        Text(lm.t(.noExpenses)).foregroundStyle(.gray)
                    }
                } else {
                    List(dailyExpenses) { expense in
                        HStack {
                            let category = categories.first(where: { $0.name == expense.categoryName })
                            if let icon = category?.icon {
                                Image(systemName: icon)
                                    .foregroundStyle(Color(hex: category?.colorHex ?? "808080"))
                                    .frame(width: 24)
                            } else {
                                Image(systemName: "questionmark.circle").foregroundStyle(.gray)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(expense.title).foregroundStyle(.primary)
                                Text(category?.name ?? "").font(.caption).foregroundStyle(.gray)
                            }
                            
                            Spacer()
                            
                            Text((expense.isIncome ? "+" : "-") + "\(lm.currencySymbol)\(expense.amount)")
                                .bold()
                                .foregroundStyle(expense.isIncome ? .green : .red)
                        }
                    }
                }
            }
            .navigationTitle(date.formatted(date: .complete, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
