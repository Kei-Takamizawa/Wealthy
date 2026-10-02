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
    // 一つの通貨の残高と今月の取引だけで、助言用の比較値を作ります。
    static func moneyTipContext(assets: [Asset], expenses: [Expense], now: Date = Date(), currencyCode: String = "JPY") -> MoneyTipContext {
        // 旧データのJPYと、選択された有効な通貨コードを同じ規則で扱います。
        let code = CurrencyPolicy.normalizedCode(currencyCode)
        // 異なる通貨の残高を加算しないよう、対象の財布を絞ります。
        let matchingAssets = assets.filter { $0.effectiveCurrencyCode == code }
        // 月と通貨の両方が一致する取引だけを助言の入力にします。
        let monthly = expenses.filter { $0.effectiveCurrencyCode == code && Calendar.current.isDate($0.date, equalTo: now, toGranularity: .month) }
        let income = monthly.filter(\.isIncome)
        let spending = monthly.filter { !$0.isIncome }
        return MoneyTipContext(
            assetsBalance: CurrencyPolicy.sum(matchingAssets.map(\.balance)), walletCount: matchingAssets.count,
            monthlyIncome: CurrencyPolicy.sum(income.map(\.amount)), monthlySpending: CurrencyPolicy.sum(spending.map(\.amount)),
            incomeRecordCount: income.count, expenseRecordCount: spending.count
        )
    }

    /// Generates a concise summary of the user's financial situation for the AI context.
    // 渡された情報から文字列やAIの回答を生成する入口を定義します。
    static func generate(assets: [Asset], expenses: [Expense], categories: [Category], languageManager: LanguageManager) -> String {
        // 表示言語に合わせて小数点と通貨表示を整えます。
        let locale = languageManager.currentLanguage.locale
        // 同じ記号を持つ通貨も区別できるよう、ISOコードを必ず付けます。
        func amountDescription(_ amount: Decimal, code: String) -> String {
            // 保存された最小通貨単位を通貨の小数桁数に従って表示します。
            "\(code) \(CurrencyPolicy.format(amount, currencyCode: code, locale: locale))"
        }
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
        
        // 全記録に登場する通貨を列挙し、異なる通貨の合計を分離します。
        let recordedCodes = Set(assets.map(\.effectiveCurrencyCode) + expenses.map(\.effectiveCurrencyCode)).sorted()
        // 記録がないときは、旧データの既定通貨でゼロ件を表示します。
        let codes = recordedCodes.isEmpty ? [CurrencyPolicy.defaultCode] : recordedCodes
        // 通貨ごとの資産残高だけを集計します。
        let assetTotals = codes.map { code in
            // 同じ通貨の財布の残高を合計します。
            let balance = CurrencyPolicy.sum(assets.filter { $0.effectiveCurrencyCode == code }.map(\.balance))
            // 通貨コードを付けた独立した残高行を返します。
            return "- \(amountDescription(balance, code: code))"
        // 通貨別の残高を改行で並べます。
        }.joined(separator: "\n")
        // 各財布の残高を、その財布に保存された通貨で表示します。
        let assetDetails = assets.map { "- \($0.name): \(amountDescription(Decimal(string: String($0.balance))!, code: $0.effectiveCurrencyCode))" }.joined(separator: "\n")
        // 同じ通貨の収入と支出だけを比較して、月次合計を並べます。
        let monthlyTotals = codes.map { code in
            // この通貨に一致する今月の支出を合計します。
            let totalExpense = CurrencyPolicy.sum(currentMonthExpenses.filter { $0.effectiveCurrencyCode == code }.map(\.amount))
            // この通貨に一致する今月の収入を合計します。
            let totalIncome = CurrencyPolicy.sum(currentMonthIncome.filter { $0.effectiveCurrencyCode == code }.map(\.amount))
            // 同じ通貨だけの収支差と合計を、単位付きで返します。
            return """
            [\(code)]
            Total Income: \(amountDescription(totalIncome, code: code))
            Total Expense: \(amountDescription(totalExpense, code: code))
            Net: \(amountDescription(totalIncome - totalExpense, code: code))
            """
        // 通貨別の月次合計を改行で並べます。
        }.joined(separator: "\n")
        
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
            return "\(dateStr): \(expense.title) (\(catName)) \(sign)\(amountDescription(Decimal(string: String(expense.amount))!, code: expense.effectiveCurrencyCode))"
        // ここまでの処理またはデータ定義を閉じます。
        }.joined(separator: "\n")
        
        // 4. Construct Context String
        // 集計結果を見出し付きの複数行の文章にまとめて返します。
        return """
        [Current Status]
        Amounts are displayed in major currency units, with ISO currency codes.
        Currencies are grouped separately; no exchange-rate conversion or combined total is available.
        Total Assets by Currency:
        \(assetTotals)
        Breakdown:
        \(assetDetails)
        
        [This Month (\(now.formatted(.dateTime.month().year())))]
        \(monthlyTotals)
        
        [Recent Transactions (Last 20)]
        \(recentTransactions)
        """
    // ここまでの処理またはデータ定義を閉じます。
    }
// ここまでの処理またはデータ定義を閉じます。
}
