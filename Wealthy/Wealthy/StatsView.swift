//
//  StatsView.swift
//  Wealthy
//
//  Created by Harrison on 12/26/25.
//

import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @EnvironmentObject var lm: LanguageManager
    @Query var expenses: [Expense]
    @Query var categories: [Category] // For colors/icons
    
    // Month Switching
    @State private var selectedMonthIndex: Int = 24
    let months: [Date]
    
    // Chart Type
    enum ChartType: String, CaseIterable, Identifiable {
        case bar = "Daily"
        case pie = "Category"
        var id: String { self.rawValue }
    }
    @State private var chartType: ChartType = .bar
    
    init() {
        var tempMonths: [Date] = []
        let calendar = Calendar.current
        let currentMonth = Date()
        for i in -24...24 {
            if let date = calendar.date(byAdding: .month, value: i, to: currentMonth) {
                tempMonths.append(date)
            }
        }
        self.months = tempMonths
        _selectedMonthIndex = State(initialValue: 24)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Modern Dark Background
                LinearGradient(colors: [Color.black, Color(white: 0.05)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header Area
                    VStack(spacing: 12) {
                        Text(lm.t(.analysis))
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        // Chart Type Picker
                        Picker("Type", selection: $chartType) {
                            ForEach(ChartType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 40)
                    }
                    .padding(.top)
                    
                    // Main Chart Area (Swipeable)
                    TabView(selection: $selectedMonthIndex) {
                        ForEach(0..<months.count, id: \.self) { index in
                            let currentExpenses = filterExpenses(for: months[index])
                            
                            VStack {
                                monthHeader(for: months[index], expenses: currentExpenses)
                                
                                if chartType == .bar {
                                    ModernBarChart(month: months[index], expenses: currentExpenses, lm: lm)
                                        .transition(.opacity.combined(with: .move(edge: .leading)))
                                } else {
                                    ModernPieChart(expenses: currentExpenses, categories: categories, lm: lm)
                                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                                }
                            }
                            .tag(index)
                            .padding(.horizontal)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.spring, value: chartType) // Animate switcher
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func filterExpenses(for date: Date) -> [Expense] {
        let calendar = Calendar.current
        return expenses.filter {
            calendar.isDate($0.date, equalTo: date, toGranularity: .month)
        }
    }
    
    private func monthHeader(for date: Date, expenses: [Expense]) -> some View {
        let totalExpense = expenses.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
        
        return VStack(spacing: 5) {
            Text(date.formatted(.dateTime.year().month(.wide)))
                .font(.title3)
                .foregroundStyle(.gray)
            
            Text(lm.currencySymbol + "\(totalExpense)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
        .padding(.top, 10)
    }
}

// MARK: - Modern Bar Chart
struct ModernBarChart: View {
    let month: Date
    let expenses: [Expense]
    let lm: LanguageManager
    
    var dailyData: [(day: Int, amount: Int)] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let expenseItems = expenses.filter { !$0.isIncome }
        
        var data: [(Int, Int)] = []
        for day in range {
            let sum = expenseItems
                .filter { calendar.component(.day, from: $0.date) == day }
                .reduce(0) { $0 + $1.amount }
            data.append((day, sum))
        }
        return data
    }
    
    var body: some View {
        Chart {
            ForEach(dailyData, id: \.day) { item in
                BarMark(
                    x: .value("Day", item.day),
                    y: .value("Amount", item.amount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(6)
            }
        }
        .chartXScale(domain: 1...31)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(.gray.opacity(0.1))
                AxisValueLabel().foregroundStyle(.gray.opacity(0.6))
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 5)) { value in
                AxisGridLine().foregroundStyle(.gray.opacity(0.1))
                AxisValueLabel().foregroundStyle(.gray.opacity(0.6))
            }
        }
        .frame(height: 300)
        .padding()
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.05)))
    }
}

// MARK: - Modern Pie Chart
struct ModernPieChart: View {
    let expenses: [Expense]
    let categories: [Category]
    let lm: LanguageManager
    
    struct PieData: Identifiable {
        let id = UUID()
        let category: String
        let amount: Int
        let color: String
    }
    
    var data: [PieData] {
        let expenseItems = expenses.filter { !$0.isIncome }
        let grouped = Dictionary(grouping: expenseItems, by: { $0.categoryName ?? "Unknown" })
        
        return grouped.map { (key, value) in
            let total = value.reduce(0) { $0 + $1.amount }
            // Find color
            let catColor = categories.first(where: { $0.name == key })?.colorHex ?? "808080"
            return PieData(category: key, amount: total, color: catColor)
        }.sorted { $0.amount > $1.amount }
    }
    
    var body: some View {
        VStack {
            if data.isEmpty {
                ContentUnavailableView(label: {
                    Label(lm.t(.noData), systemImage: "chart.pie")
                })
            } else {
                Chart(data) { item in
                    SectorMark(
                        angle: .value("Amount", item.amount),
                        innerRadius: .ratio(0.6), // Donut style
                        angularInset: 2.0
                    )
                    .foregroundStyle(Color(hex: item.color))
                    .cornerRadius(5)
                }
                .frame(height: 300)
                .padding()
                
                // Legend
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(data) { item in
                            HStack {
                                Circle().fill(Color(hex: item.color)).frame(width: 12, height: 12)
                                Text(lm.translateCategory(name: item.category)).foregroundStyle(.white)
                                Spacer()
                                Text(lm.currencySymbol + "\(item.amount)").bold().foregroundStyle(.gray)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.05)))
    }
}
