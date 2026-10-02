import Foundation

/// Negative recorded wallet balances take priority; balances never substitute for monthly income records.
struct MoneyTipContext: Codable, Equatable {
    // 複数のInt残高の合計も、整数の上限を超えて正確に保持します。
    let assetsBalance: Decimal
    let walletCount: Int
    // 今月の収入合計を、丸めずに比較できる十進数で保持します。
    let monthlyIncome: Decimal
    // 今月の支出合計を、丸めずに比較できる十進数で保持します。
    let monthlySpending: Decimal
    let incomeRecordCount: Int
    let expenseRecordCount: Int

    // 従来のInt入力を受け付け、保存単位を変えずに十進数へ変換します。
    init(assetsBalance: Int, walletCount: Int, monthlyIncome: Int, monthlySpending: Int, incomeRecordCount: Int, expenseRecordCount: Int) {
        // 既存のテストや呼び出しも、上限で切り詰めずに同じ初期化処理へ渡します。
        self.init(assetsBalance: Decimal(string: String(assetsBalance))!, walletCount: walletCount,
                  monthlyIncome: Decimal(string: String(monthlyIncome))!, monthlySpending: Decimal(string: String(monthlySpending))!,
                  incomeRecordCount: incomeRecordCount, expenseRecordCount: expenseRecordCount)
    }

    // 集計済みの十進数をそのまま受け取り、Intへ戻さない入口です。
    init(assetsBalance: Decimal, walletCount: Int, monthlyIncome: Decimal, monthlySpending: Decimal, incomeRecordCount: Int, expenseRecordCount: Int) {
        // 通貨別の残高合計を保持します。
        self.assetsBalance = assetsBalance
        // 集計対象の財布の数を保持します。
        self.walletCount = walletCount
        // 通貨別の収入合計を保持します。
        self.monthlyIncome = monthlyIncome
        // 通貨別の支出合計を保持します。
        self.monthlySpending = monthlySpending
        // 収入の記録件数を保持します。
        self.incomeRecordCount = incomeRecordCount
        // 支出の記録件数を保持します。
        self.expenseRecordCount = expenseRecordCount
    }

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

    /// Factual advice stays bounded to recorded data in every display language.
    func shortAction(language: String) -> String {
        AppLocalization.text("tipAction" + localizationSuffix, language: .from(identifier: language))
    }

    /// Number-free humor never infers that an unrecorded wallet is empty.
    func fallbackOpening(language: String) -> String {
        AppLocalization.text("tipOpening" + localizationSuffix, language: .from(identifier: language))
    }

    private var localizationSuffix: String {
        switch situation {
        case .negativeAssets: "NegativeAssets"
        case .noTransactions: "NoTransactions"
        case .incomeNotRecorded: "IncomeNotRecorded"
        case .deficit: "Deficit"
        case .surplus: "Surplus"
        case .balanced: "Balanced"
        }
    }
}
