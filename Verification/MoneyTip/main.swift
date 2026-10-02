import Foundation

struct Fixture {
    let name: String
    let context: MoneyTipContext
    let expected: MoneyTipContext.Situation
}

let fixtures: [Fixture] = [
    .init(name: "no wallets does not mean empty cash", context: .init(assetsBalance: 0, walletCount: 0, monthlyIncome: 0, monthlySpending: 0, incomeRecordCount: 0, expenseRecordCount: 0), expected: .noTransactions),
    .init(name: "assets do not create transaction history", context: .init(assetsBalance: 8_000_000, walletCount: 3, monthlyIncome: 0, monthlySpending: 0, incomeRecordCount: 0, expenseRecordCount: 0), expected: .noTransactions),
    .init(name: "missing income is not a deficit", context: .init(assetsBalance: 80_000, walletCount: 1, monthlyIncome: 0, monthlySpending: 15_000, incomeRecordCount: 0, expenseRecordCount: 4), expected: .incomeNotRecorded),
    .init(name: "zero value expense still records a transaction", context: .init(assetsBalance: 0, walletCount: 1, monthlyIncome: 0, monthlySpending: 0, incomeRecordCount: 0, expenseRecordCount: 1), expected: .incomeNotRecorded),
    .init(name: "large assets are not monthly income", context: .init(assetsBalance: 10_000_000, walletCount: 2, monthlyIncome: 150_000, monthlySpending: 180_000, incomeRecordCount: 1, expenseRecordCount: 8), expected: .deficit),
    .init(name: "zero recorded assets do not negate monthly surplus", context: .init(assetsBalance: 0, walletCount: 0, monthlyIncome: 200_000, monthlySpending: 100_000, incomeRecordCount: 1, expenseRecordCount: 5), expected: .surplus),
    .init(name: "matching nonzero transactions", context: .init(assetsBalance: 10_000, walletCount: 1, monthlyIncome: 50_000, monthlySpending: 50_000, incomeRecordCount: 1, expenseRecordCount: 3), expected: .balanced),
    .init(name: "recorded zero transactions are not unrecorded", context: .init(assetsBalance: 5_000, walletCount: 1, monthlyIncome: 0, monthlySpending: 0, incomeRecordCount: 1, expenseRecordCount: 1), expected: .balanced),
    .init(name: "negative balance precedes absent monthly transactions", context: .init(assetsBalance: -1, walletCount: 1, monthlyIncome: 0, monthlySpending: 0, incomeRecordCount: 0, expenseRecordCount: 0), expected: .negativeAssets),
    .init(name: "negative balance precedes unrecorded income", context: .init(assetsBalance: -30_000, walletCount: 2, monthlyIncome: 0, monthlySpending: 15_000, incomeRecordCount: 0, expenseRecordCount: 4), expected: .negativeAssets),
    .init(name: "negative balance precedes monthly surplus", context: .init(assetsBalance: -10_000, walletCount: 1, monthlyIncome: 200_000, monthlySpending: 100_000, incomeRecordCount: 1, expenseRecordCount: 5), expected: .negativeAssets),
    .init(name: "contradictory negative balance without wallets remains unrecorded", context: .init(assetsBalance: -10_000, walletCount: 0, monthlyIncome: 0, monthlySpending: 0, incomeRecordCount: 0, expenseRecordCount: 0), expected: .noTransactions),
    .init(name: "contradictory negative balance without wallets keeps monthly deficit", context: .init(assetsBalance: -10_000, walletCount: 0, monthlyIncome: 100_000, monthlySpending: 150_000, incomeRecordCount: 1, expenseRecordCount: 5), expected: .deficit)
]
var checks = 0
func expect(_ condition: Bool, _ label: String) {
    checks += 1
    guard condition else { fatalError("FAIL: \(label)") }
}
func words(_ text: String) -> Int { text.split(whereSeparator: \.isWhitespace).count }

for fixture in fixtures {
    let context = fixture.context
    expect(context.situation == fixture.expected, fixture.name)
    let data = try JSONEncoder().encode(context)
    expect(try JSONDecoder().decode(MoneyTipContext.self, from: data) == context, "Codable roundtrip: \(fixture.name)")
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    expect(Set(json.keys) == Set(["assetsBalance", "walletCount", "monthlyIncome", "monthlySpending", "incomeRecordCount", "expenseRecordCount"]), "JSON fields: \(fixture.name)")
    for language in ["ja", "en"] {
        let opening = context.fallbackOpening(language: language)
        let action = context.shortAction(language: language)
        expect(!opening.isEmpty && !action.isEmpty, "nonempty text: \(fixture.name)/\(language)")
        expect(opening.rangeOfCharacter(from: .decimalDigits) == nil, "humor never invents figures: \(fixture.name)/\(language)")
        expect(!opening.contains("空") && !opening.lowercased().contains("empty"), "humor never assumes an empty wallet: \(fixture.name)/\(language)")
        if language == "ja" {
            expect(opening.count <= 20, "Japanese opening fits budget: \(fixture.name)")
            expect(action.count + 20 < 70, "Japanese action reserves full opening budget: \(fixture.name)")
            expect((opening + action).count < 70, "complete Japanese fallback length: \(fixture.name)")
        } else {
            expect(words(opening) <= 8, "English opening fits budget: \(fixture.name)")
            expect(words(action) + 8 < 30, "English action reserves full opening budget: \(fixture.name)")
            expect(words(opening + " " + action) < 30, "complete English fallback length: \(fixture.name)")
        }
    }
}
let missing = fixtures[2].context
expect(!missing.shortAction(language: "ja").contains("支出超過"), "unrecorded income does not claim overspending")
expect(!missing.shortAction(language: "en").contains("exceeds"), "unrecorded income does not claim deficit")
expect(fixtures[1].context.shortAction(language: "ja").contains("取引は未記録"), "assets remain separate from transaction facts")
expect(fixtures[5].context.shortAction(language: "en").contains("if affordable"), "recorded surplus does not guarantee spare cash")
expect(fixtures[0].context.shortAction(language: "ja-JP") == fixtures[0].context.shortAction(language: "ja"), "Japanese locale identifier")
expect(fixtures[8].context.shortAction(language: "ja").contains("総残高はマイナス"), "negative balance fact is explicit")
expect(fixtures[8].context.shortAction(language: "ja").contains("財布ごとの入出金"), "negative balance action checks individual wallets")
expect(fixtures[10].context.shortAction(language: "en").contains("total balance is negative"), "monthly surplus does not hide negative assets")
expect(!fixtures[11].context.shortAction(language: "en").contains("negative"), "contradictory absent wallets do not assert negative cash")
print("PASS: \(checks) checks across \(fixtures.count) money-tip fixtures (deterministic context/actions, not model generation)")
