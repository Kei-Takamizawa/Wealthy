//
//  FinancialDataSummary.swift
//  Wealthy
//
//  Created by Harrison on 12/26/25.
//

import Foundation
import SwiftData

struct FinancialDataSummary {
    /// Generates a concise summary of the user's financial situation for the AI context.
    static func generate(assets: [Asset], expenses: [Expense], categories: [Category], languageManager: LanguageManager) -> String {
        let lm = languageManager
        let currency = lm.currencySymbol
        
        // 1. Total Assets
        let totalBalance = assets.reduce(0) { $0 + $1.balance }
        let assetDetails = assets.map { "- \($0.name): \(currency)\($0.balance)" }.joined(separator: "\n")
        
        // 2. Monthly Summary (Current Month)
        let calendar = Calendar.current
        let now = Date()
        let currentMonthExpenses = expenses.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month) && !$0.isIncome
        }
        let currentMonthIncome = expenses.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month) && $0.isIncome
        }
        
        let totalExpense = currentMonthExpenses.reduce(0) { $0 + $1.amount }
        let totalIncome = currentMonthIncome.reduce(0) { $0 + $1.amount }
        
        // 3. Recent Transactions (Last 20)
        // Sort by date descending
        let sortedExpenses = expenses.sorted { $0.date > $1.date }
        let recentTransactions = sortedExpenses.prefix(20).map { expense in
            let dateStr = expense.date.formatted(date: .numeric, time: .omitted)
            let sign = expense.isIncome ? "+" : "-"
            let catName = expense.categoryName ?? "Unclassified"
            return "\(dateStr): \(expense.title) (\(catName)) \(sign)\(currency)\(expense.amount)"
        }.joined(separator: "\n")
        
        // 4. Construct Context String
        return """
        [Current Status]
        Total Assets: \(currency)\(totalBalance)
        Breakdown:
        \(assetDetails)
        
        [This Month (\(now.formatted(.dateTime.month().year())))]
        Total Income: \(currency)\(totalIncome)
        Total Expense: \(currency)\(totalExpense)
        Net: \(currency)\(totalIncome - totalExpense)
        
        [Recent Transactions (Last 20)]
        \(recentTransactions)
        """
    }
}
