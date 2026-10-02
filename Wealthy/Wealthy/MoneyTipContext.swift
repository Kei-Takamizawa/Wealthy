import Foundation

/// Negative recorded wallet balances take priority; balances never substitute for monthly income records.
struct MoneyTipContext: Codable, Equatable {
    let assetsBalance: Int
    let walletCount: Int
    let monthlyIncome: Int
    let monthlySpending: Int
    let incomeRecordCount: Int
    let expenseRecordCount: Int

    enum Situation: String, Codable, CaseIterable {
        case negativeAssets
        case noTransactions
        case incomeNotRecorded
        case deficit
        case surplus
        case balanced
    }

    var situation: Situation {
        if walletCount > 0 && assetsBalance < 0 { return .negativeAssets }
        if incomeRecordCount == 0 && expenseRecordCount == 0 { return .noTransactions }
        if incomeRecordCount == 0 && expenseRecordCount > 0 { return .incomeNotRecorded }
        if monthlySpending > monthlyIncome { return .deficit }
        if monthlyIncome > monthlySpending { return .surplus }
        return .balanced
    }

    /// One modest action, with the fact explicitly limited to the user's records.
    /// Leaves at least 20 Japanese characters or eight English words for a humorous opening.
    func shortAction(language: String) -> String {
        let japanese = language.lowercased().hasPrefix("ja")
        switch situation {
        case .negativeAssets:
            return japanese
                ? "記録上の総残高はマイナス。財布ごとの入出金を確認しましょう。"
                : "The recorded total balance is negative. Check each wallet’s income and expense entries."
        case .noTransactions:
            return japanese
                ? "今月の取引は未記録。まず一件記録しましょう。"
                : "No transactions recorded this month. Start by recording one."
        case .incomeNotRecorded:
            return japanese
                ? "今月の収入は未記録。記録漏れを確認しましょう。"
                : "No income recorded this month. Check for missing income entries."
        case .deficit:
            return japanese
                ? "記録上は支出超過。任意の出費を一つ見直しましょう。"
                : "Recorded spending exceeds income. Review one optional expense."
        case .surplus:
            return japanese
                ? "記録上は黒字。余裕があれば少し取り分けましょう。"
                : "Records show a surplus. Set a little aside if affordable."
        case .balanced:
            return japanese
                ? "記録では収支同額。次の出費を一つ確認しましょう。"
                : "Recorded income matches spending. Check one upcoming expense."
        }
    }

    /// Number-free fallback humor avoids inferring that an unrecorded wallet is empty.
    func fallbackOpening(language: String) -> String {
        let japanese = language.lowercased().hasPrefix("ja")
        switch situation {
        case .negativeAssets:
            return japanese ? "財布が帳簿チェックを希望しています。" : "Your wallet has called a bookkeeping meeting."
        case .noTransactions:
            return japanese ? "財布の家計簿、まだ白紙ですね。" : "Your wallet’s diary has a blank page."
        case .incomeNotRecorded:
            return japanese ? "財布の入金欄がかくれんぼ中です。" : "The wallet’s income column is feeling shy."
        case .deficit:
            return japanese ? "財布が小休憩を希望しています。" : "Your wallet has requested a coffee break."
        case .surplus:
            return japanese ? "財布がちょっと得意げですね。" : "Your wallet is quietly taking a bow."
        case .balanced:
            return japanese ? "財布のシーソーが水平ですね。" : "Your wallet’s seesaw has found its balance."
        }
    }
}
