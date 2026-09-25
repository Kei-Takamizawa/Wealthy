//
//  FinancialDataSummary.swift
//  Wealthy
//
//  Created by Harrison on 12/26/25.
//

// Foundationの機能を、このファイルから使えるように読み込みます。
import Foundation
// SwiftDataの機能を、このファイルから使えるように読み込みます。
import SwiftData

// AIに渡す家計の要約を作る型を定義します。
struct FinancialDataSummary {
    /// Generates a concise summary of the user's financial situation for the AI context.
    // 渡された情報から文字列やAIの回答を生成する入口を定義します。
    static func generate(assets: [Asset], expenses: [Expense], categories: [Category], languageManager: LanguageManager) -> String {
        // 渡された言語管理オブジェクトを短い名前で参照します。
        let lm = languageManager
        // 現在の言語で使う通貨記号を取得します。
        let currency = lm.currencySymbol
        
        // 1. Total Assets
        // 全資産の残高合計を作成または更新します。
        let totalBalance = assets.reduce(0) { $0 + $1.balance }
        // 資産ごとの残高を並べた文章を作成または更新します。
        let assetDetails = assets.map { "- \($0.name): \(currency)\($0.balance)" }.joined(separator: "\n")
        
        // 2. Monthly Summary (Current Month)
        // 端末の暦設定を取得します。
        let calendar = Calendar.current
        // 現在の日時を取得します。
        let now = Date()
        // 今月の支出だけの一覧を作成または更新します。
        let currentMonthExpenses = expenses.filter {
            // 取引日が今月に含まれ、収入か支出かの条件にも合う項目だけ残します。
            calendar.isDate($0.date, equalTo: now, toGranularity: .month) && !$0.isIncome
        // ここまでの処理またはデータ定義を閉じます。
        }
        // 今月の収入だけの一覧を作成または更新します。
        let currentMonthIncome = expenses.filter {
            // 取引日が今月に含まれ、収入か支出かの条件にも合う項目だけ残します。
            calendar.isDate($0.date, equalTo: now, toGranularity: .month) && $0.isIncome
        // ここまでの処理またはデータ定義を閉じます。
        }
        
        // 今月の支出合計を作成または更新します。
        let totalExpense = currentMonthExpenses.reduce(0) { $0 + $1.amount }
        // 今月の収入合計を作成または更新します。
        let totalIncome = currentMonthIncome.reduce(0) { $0 + $1.amount }
        
        // 3. Recent Transactions (Last 20)
        // Sort by date descending
        // 日付が新しい順の取引を作成または更新します。
        let sortedExpenses = expenses.sorted { $0.date > $1.date }
        // 新しい取引20件の文章を作成または更新します。
        let recentTransactions = sortedExpenses.prefix(20).map { expense in
            // 取引日を数字の年月日で表示できる文字列にします。
            let dateStr = expense.date.formatted(date: .numeric, time: .omitted)
            // 収入ならプラス、支出ならマイナスの記号を選びます。
            let sign = expense.isIncome ? "+" : "-"
            // 取引のカテゴリ名を取り出し、未設定なら分類なしにします。
            let catName = expense.categoryName ?? "Unclassified"
            // 日付、項目、分類、金額を一行の取引概要にして返します。
            return "\(dateStr): \(expense.title) (\(catName)) \(sign)\(currency)\(expense.amount)"
        // ここまでの処理またはデータ定義を閉じます。
        }.joined(separator: "\n")
        
        // 4. Construct Context String
        // 集計結果を見出し付きの複数行の文章にまとめて返します。
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
    // ここまでの処理またはデータ定義を閉じます。
    }
// ここまでの処理またはデータ定義を閉じます。
}
