import Foundation

// Run from the repository root:
// xcrun swiftc -module-cache-path /tmp/wealthy-language-cache Wealthy/Wealthy/ReplyLanguagePolicy.swift Verification/ReplyLanguage/main.swift -o /tmp/wealthy-language-checks
// /tmp/wealthy-language-checks
let cases: [(message: String, fallback: String, expected: String)] = [
    ("今月の支出を教えて", "en", "ja"),
    ("日本語でお願いします", "en", "ja"),
    ("こんにちは", "en", "ja"),
    ("ありがとう", "en", "ja"),
    ("Appleの株はどうですか？", "en", "ja"),
    ("家計", "en", "ja"),
    ("残高？", "en", "ja"),
    ("貯金", "en", "ja"),
    ("収入", "en", "ja"),
    ("予算", "en", "ja"),
    ("  食費  ", "en", "ja"),
    ("Hi", "ja", "en"),
    ("OK!", "ja", "en"),
    ("Thanks", "ja", "en"),
    ("Thank you.", "ja", "en"),
    ("Help", "ja", "en"),
    ("What is my total spending this month?", "ja", "en"),
    ("Please explain my current budget in English.", "ja", "en"),
    ("How much money have I saved this month?", "ja", "en"),
    ("Could you explain the Japanese word 「ありがとう」 in English?", "ja", "en"),
    ("Could you explain what ありがとう means to me in English?", "ja", "en"),
    ("「ありがとう」", "en", "ja"),
    ("Apple Intelligenceの使い方を教えてください。", "en", "ja"),
    ("今天我的预算是多少？", "ja", "zh-Hans"),
    ("我想知道本月的收入和支出。", "ja", "zh-Hans"),
    ("¿Cuánto dinero he gastado este mes?", "en", "es"),
    ("Combien ai-je dépensé ce mois-ci ?", "en", "fr"),
    ("", "ja", "ja"),
    ("   \n", "en", "en"),
    ("12345", "ja", "ja"),
    ("¥1,234 😀", "en", "en")
]
var failures: [String] = []
for sample in cases {
    let actual = ReplyLanguagePolicy.languageIdentifier(for: sample.message, fallback: sample.fallback)
    if actual != sample.expected { failures.append("\(sample.message.debugDescription): expected \(sample.expected), got \(actual)") }
}
let japaneseInstruction = ReplyLanguagePolicy.instruction(for: "ja")
if !japaneseInstruction.contains("必ず日本語") { failures.append("Japanese instruction does not require Japanese.") }
let englishInstruction = ReplyLanguagePolicy.instruction(for: "en")
if !englishInstruction.contains("Write the entire answer in English") { failures.append("English instruction does not require English.") }
let outputCases: [(response: String, expected: String, conflict: Bool)] = [
    ("Your balance is 20,000 yen.", "ja", true),
    ("Your balance is 20,000 yen.", "en", false),
    ("Your total spending this month is 20,000 yen. You can review your food expenses to understand where your money went.", "ja", true),
    ("Your total spending this month is 20,000 yen. You can review your food expenses to understand where your money went.", "en", false),
    ("今月の支出は二万円です。食費の内訳を確認すると、どこにお金を使ったのかを把握しやすくなります。", "en", true),
    ("今月の支出は二万円です。食費の内訳を確認すると、どこにお金を使ったのかを把握しやすくなります。", "ja", false),
    ("The category 「食費」 means food expenses. You can review the transactions in this category to understand your monthly spending.", "en", false),
    ("The phrase \"今月の支出を教えてください\" asks about monthly spending. Your current total is 20,000 yen, based on the supplied records.", "en", false),
    ("今月の食費は二万円です。\"Your total spending this month is 20,000 yen. You can review your expenses.\" という英文を引用しています。", "ja", false),
    ("Apple, Microsoft, NVIDIA, Amazon, Google, Meta, Tesla, Toyota, Sony, Nintendo", "ja", false),
    ("¥20,000 / 2026-10-02 / AAPL", "ja", false),
    ("OK", "ja", false),
    ("```swift\nlet yourTotalSpending = 20_000\n// You can review your monthly spending with this value.\nprint(yourTotalSpending)\n```", "ja", false),
    ("let totalSpending = 20_000\nlet reviewYourMonthlyExpenses = true\nprint(totalSpending)", "ja", false),
    ("The total is shown in `let yourTotal = income - expenses`. You can review the remaining balance in your account.", "ja", true),
    ("Please review https://example.com/your/expenses/in/this/month before making changes to your budget. You can use the current totals to plan your spending.", "ja", true)
]
for sample in outputCases {
    let actual = ReplyLanguagePolicy.clearlyConflicts(sample.response, with: sample.expected)
    if actual != sample.conflict { failures.append("Output \(sample.response.debugDescription): expected conflict \(sample.conflict), got \(actual)") }
}
if failures.isEmpty {
    print("Passed \(cases.count) language decisions, 2 response-instruction checks and \(outputCases.count) output-language checks.")
} else {
    failures.forEach { print("FAIL: \($0)") }
    exit(1)
}
