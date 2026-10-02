import Foundation
import NaturalLanguage

/// Language decisions depend on the latest user message, never the financial context or prior replies.
struct ReplyLanguagePolicy {
    static func languageIdentifier(for text: String, fallback: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return fallback }
        let scalars = trimmed.unicodeScalars
        // A Japanese quotation or vocabulary word does not turn an English question into Japanese.
        if clearlyConflicts(trimmed, with: "ja") {
            let proseRecognizer = NLLanguageRecognizer()
            proseRecognizer.processString(proseForLanguageDetection(trimmed))
            if let language = proseRecognizer.dominantLanguage { return language.rawValue }
        }
        // Kana is a stronger Japanese signal than an English brand name or currency symbol.
        if scalars.contains(where: { (0x3040...0x30FF).contains($0.value) || (0xFF66...0xFF9D).contains($0.value) }) {
            return "ja"
        }
        // A short kanji-only finance query can otherwise be recognized as Chinese.
        let japaneseShortQueries: Set<String> = ["家計", "家計簿", "収入", "支出", "残高", "貯金", "節約", "予算", "今月", "昨日", "今日", "投資", "食費", "貯蓄", "総額", "合計"]
        if japaneseShortQueries.contains(trimmed.trimmingCharacters(in: .punctuationCharacters)) {
            return "ja"
        }
        // Recognizers frequently classify very short English greetings as another Latin-script language.
        let englishShortMessages: Set<String> = ["hi", "hello", "hey", "ok", "okay", "thanks", "thank you", "yes", "no", "help", "why", "budget", "balance", "income", "expenses", "savings"]
        if englishShortMessages.contains(trimmed.lowercased().trimmingCharacters(in: .punctuationCharacters)) {
            return "en"
        }
        guard scalars.contains(where: CharacterSet.letters.contains) else { return fallback }
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(trimmed)
        guard let detected = recognizer.dominantLanguage else { return fallback }
        return detected.rawValue
    }

    static func instruction(for identifier: String) -> String {
        if identifier == "ja" {
            return "最新のユーザー発言の言語は日本語です。回答本文は必ず日本語で書いてください。英語の家計データや過去の英語の返答に合わせて英語へ切り替えないでください。固有名詞・数値以外の説明も日本語で書いてください。"
        }
        let name = Locale(identifier: "en").localizedString(forLanguageCode: identifier) ?? identifier
        return "The latest user message is in \(name) (language code: \(identifier)). Write the entire answer in \(name), except proper names and numbers. Financial data and earlier replies must not change the response language."
    }

    /// Only reject a clearly different language in substantial prose; ambiguous short answers pass.
    static func clearlyConflicts(_ response: String, with expectedIdentifier: String) -> Bool {
        // Code, URLs and quotations are content, not evidence of the explanation's language.
        let prose = proseForLanguageDetection(response)
        let letters = prose.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        guard letters.count >= 12 else { return false }
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(prose)
        guard let detected = recognizer.dominantLanguage,
              (recognizer.languageHypotheses(withMaximum: 1)[detected] ?? 0) >= 0.85 else { return false }
        let detectedCode = Locale.Language(identifier: detected.rawValue).languageCode?.identifier
        let expectedCode = Locale.Language(identifier: expectedIdentifier).languageCode?.identifier
        guard detectedCode != expectedCode else { return false }

        let kanaCount = letters.filter { (0x3040...0x30FF).contains($0.value) || (0xFF66...0xFF9D).contains($0.value) }.count
        let hanCount = letters.filter { (0x3400...0x9FFF).contains($0.value) }.count
        let japaneseRatio = Double(kanaCount + hanCount) / Double(letters.count)
        if detectedCode == "ja" {
            return kanaCount >= 6 && japaneseRatio >= 0.65
        }
        if detectedCode == "zh" {
            return hanCount >= 20 && Double(hanCount) / Double(letters.count) >= 0.65
        }
        // Proper-name lists and single words lack the function words/sentence structure of prose.
        let words = prose.lowercased().components(separatedBy: CharacterSet.letters.inverted).filter { !$0.isEmpty }
        if detectedCode == "en" {
            let functionWords: Set<String> = ["a", "an", "the", "is", "are", "was", "were", "you", "your", "i", "we", "it", "this", "that", "can", "could", "should", "would", "to", "of", "in", "for", "with", "and", "but", "from"]
            let sentenceMarkers: Set<String> = ["is", "are", "was", "were", "you", "your", "i", "we", "it", "this", "can", "could", "should", "would"]
            let functionCount = words.filter { functionWords.contains($0) }.count
            let markerCount = words.filter { sentenceMarkers.contains($0) }.count
            // Short balance answers are still prose; a list of brand names is not.
            let shortSentence = words.count >= 4 && functionCount >= 2 && markerCount >= 2
            let longerSentence = words.count >= 8 && functionCount >= 3 && markerCount >= 1
            return (shortSentence || longerSentence) && japaneseRatio < 0.35
        }
        guard letters.count >= 24, words.count >= 8 else { return false }
        // For other scripts/languages, require a sentence and many lowercase words or non-Latin letters.
        return prose.rangeOfCharacter(from: CharacterSet(charactersIn: ".!?。！？")) != nil && japaneseRatio < 0.35
    }

    private static func proseForLanguageDetection(_ text: String) -> String {
        var prose = text.replacingOccurrences(of: "(?s)```.*?```", with: " ", options: .regularExpression)
        for pattern in ["`[^`]*`", "https?://\\S+", "\"[^\"\\n]*\"", "“[^”]*”", "「[^」]*」", "『[^』]*』", "(?m)^\\s*(?:import\\s|(?:let|var)\\s+\\w+\\s*=|(?:func|class|struct|enum)\\s|return\\s|print\\().*$"] {
            prose = prose.replacingOccurrences(of: pattern, with: " ", options: .regularExpression)
        }
        return prose
    }
}
