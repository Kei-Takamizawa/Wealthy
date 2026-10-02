import Foundation
import FoundationModels
import NaturalLanguage

/// Exercises the actual service with synthetic records; it does not access an app database.
@main
struct EvaluateTickerAdvice {
    @MainActor
    static func main() async throws {
        let output = URL(fileURLWithPath: CommandLine.arguments[1])
        let defaults = UserDefaults.standard
        let previousLanguage = defaults.object(forKey: "selectedLanguage")
        defer {
            if let previousLanguage { defaults.set(previousLanguage, forKey: "selectedLanguage") }
            else { defaults.removeObject(forKey: "selectedLanguage") }
        }
        let service = LocalLLMService()
        guard service.isReady else {
            throw NSError(domain: "TickerEvaluation", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: service.loadStatus])
        }
        let now = Date()
        var results: [[String: Any]] = []
        for language in AppLanguage.allCases {
            defaults.set(language.rawValue, forKey: "selectedLanguage")
            let scenarios: [(String, [Asset], [Expense])] = [
                ("empty", [], []),
                ("spending_exceeds_income", [Asset(name: "Wallet", balance: 20000)], [
                    Expense(title: "Income", amount: 10000, date: now, isIncome: true),
                    Expense(title: "Groceries", amount: 15000, date: now, categoryName: "Food")
                ]),
                ("surplus", [Asset(name: "Wallet", balance: 300000)], [
                    Expense(title: "Income", amount: 100000, date: now, isIncome: true),
                    Expense(title: "Groceries", amount: 60000, date: now, categoryName: "Food")
                ])
            ]
            for (name, assets, expenses) in scenarios {
                let context = FinancialDataSummary.moneyTipContext(assets: assets, expenses: expenses, now: now)
                let started = Date()
                do {
                    let reply = try await service.generateAdvice(context: context)
                    let languageCode = language.languageIdentifier
                    let countsCharacters = [.japanese, .chinese, .korean].contains(language)
                    let length = countsCharacters ? reply.count : reply.split(whereSeparator: { $0.isWhitespace }).count
                    let limit = language == .japanese ? 70 : (countsCharacters ? 100 : 30)
                    let recognizer = NLLanguageRecognizer()
                    recognizer.processString(reply)
                    results.append([
                        "scenario": name, "language": languageCode, "situation": context.situation.rawValue, "reply": reply,
                        "fallbackUsed": service.lastAdviceUsedFallback,
                        "fallbackReason": service.lastAdviceFallbackReason ?? "",
                        "length": length, "lengthWithinPromptLimit": length < limit,
                        "languageConflict": ReplyLanguagePolicy.clearlyConflicts(reply, with: languageCode),
                        "detectedLanguage": recognizer.dominantLanguage?.rawValue ?? "unknown",
                        "modelSupportsLocale": SystemLanguageModel.default.supportsLocale(language.locale),
                        "seconds": Date().timeIntervalSince(started)
                    ])
                } catch {
                    results.append(["scenario": name, "language": language.rawValue, "error": error.localizedDescription])
                }
                try JSONSerialization.data(withJSONObject: results, options: [.prettyPrinted, .sortedKeys]).write(to: output)
                print("Measured \(results.count)/\(AppLanguage.allCases.count * 3) ticker cases")
            }
        }
    }
}
