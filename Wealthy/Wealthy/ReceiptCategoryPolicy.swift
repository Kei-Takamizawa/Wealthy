import Foundation

/// Clear OCR purchase-purpose evidence can select a category; uncertain text stays generic.
enum ReceiptCategoryPolicy {
    static func evidenceBasedCategory(text: String, existingCategories: [String], language: String = "ja") -> String? {
        let value = AppLocalization.normalized(text)
        // 明瞭な商品語を先に評価し、税区分による補助根拠は最後に追加します。
        var rules: [(keywords: [String], aliasKeys: [String], newKey: String)] = [
            (["書店", "新書", "文庫", "書籍", "bookstore", "paperback"], ["categoryBooks", "catHobby"], "categoryBooks"),
            (["rebar", "lumber", "timber", "home depot", "木材", "鉄筋", "建材"], ["categoryHomeDIY"], "categoryHomeDIY"),
            (["乗車", "運賃", "乗車券", "タクシー", "taxi", "train fare", "bus fare", "交通運賃"], ["catTransport"], "categoryTransportation"),
            (["シャツ", "ズボン", "靴下", "衣料", "t-shirt", "jeans", "socks"], ["catClothing"], "catClothing"),
            (["牛丼", "ラーメン", "ヨーグル", "ワッフル", "waffle", "焼き", "カフェ", "starbucks", "lawson", "coffee", "cookie", "apple pie", "banana", "bread", "牛肉", "チーズ", "パン", "羊かん", "ようかん", "お茶", "ジャスミン茶", "マネケン", "manneken", "飲料", "グミ", "コーラ", "焼酎", "ビール", "restaurant"], ["catFood"], "catFood"),
            (["処方", "調剤", "薬剤", "診察", "医薬品", "prescription", "medicine", "clinic"], ["categoryHealthcare"], "categoryHealthcare"),
            (["洗剤", "ティッシュ", "トイレット", "シャンプー", "detergent", "toilet paper", "shampoo"], ["catDaily"], "categoryHousehold")
        ]
        // 商品名が読めなくても、限定的な軽減税率の根拠があれば食費の別名を再利用します。
        if hasReducedRateFoodEvidence(value) {
            // 検証済みの対象額表記を照合語として使い、従来の商品語より優先させません。
            rules.append((["軽減税率"], ["catFood"], "catFood"))
        }
        for rule in rules {
            guard rule.keywords.contains(where: { value.contains($0) }) else { continue }
            let aliases = rule.aliasKeys.flatMap { AppLocalization.categoryAliases(for: $0) }.map(AppLocalization.normalized)
            if let existing = existingCategories.first(where: { aliases.contains(AppLocalization.normalized($0)) }) { return existing }
            return AppLocalization.text(rule.newKey, language: .from(identifier: language))
        }
        return nil
    }

    /// Japan's reduced rate also covers qualifying newspaper subscriptions; a rate alone is insufficient.
    // 税区分だけの曖昧な分類を避け、食品を示す限定的な条件を確認します。
    private static func hasReducedRateFoodEvidence(_ value: String) -> Bool {
        // 軽減税率の明記がない旧税率レシートや外国の税率は分類根拠にしません。
        guard value.contains("軽減税率") else { return false }
        // 新聞の定期購読も軽減税率なので、食品としての推測を止めます。
        guard !["新聞", "購読", "newspaper", "subscription"].contains(where: { value.contains($0) }) else { return false }
        // 標準税率の商品が混在する可能性があれば、食品だけの買い物とは推測しません。
        let standardTaxLine = #"(?<![0-9])10[ \t]*%[^\n]*(?:対象(?:金額|額|計)|税額|税込|税抜|消費税|課税|税率)|(?:対象(?:金額|額|計)|税額|税込|税抜|消費税|課税|税率)[^\n]*10[ \t]*%"#
        // 会員割引などの10%OFFは税区分の語を伴わず、この判定には一致しません。
        guard value.range(of: standardTaxLine, options: .regularExpression) == nil else { return false }
        // 注意書きだけでなく、正の金額を持つ8%の対象額を同じ行で確認します。
        let reducedSubtotal = #"(?<![0-9])8[ \t]*%[ \t]*(?:税込|税抜)?[ \t]*対象(?:金額|額|計)[ \t]*[¥￥]?[ \t]*([0-9][0-9,]*)"#
        // 対象額を抽出できない場合は、分類の根拠を返しません。
        guard let expression = try? NSRegularExpression(pattern: reducedSubtotal) else { return false }
        // 正規表現のUTF-16位置をSwift文字列全体の範囲に合わせます。
        let fullRange = NSRange(value.startIndex..<value.endIndex, in: value)
        // 対象額がゼロの空欄表記から食品購入を推測しないことを確認します。
        return expression.matches(in: value, range: fullRange).contains { match in
            // キャプチャーされた金額が文字列の範囲内にあることを確認します。
            guard let range = Range(match.range(at: 1), in: value) else { return false }
            // 桁区切りを除いて、実際に正の対象額がある場合だけ根拠として採用します。
            return (Int(value[range].replacingOccurrences(of: ",", with: "")) ?? 0) > 0
        }
    }

    static func suggestedCategory(text: String, existingCategories: [String], language: String = "ja") -> String {
        if let evidence = evidenceBasedCategory(text: text, existingCategories: existingCategories, language: language) { return evidence }
        let displayLanguage = AppLanguage.from(identifier: language)
        guard text.rangeOfCharacter(from: .letters) != nil else { return AppLocalization.text("unclassified", language: displayLanguage) }
        let aliases = AppLocalization.categoryAliases(for: "catOthers").map(AppLocalization.normalized)
        return existingCategories.first { aliases.contains(AppLocalization.normalized($0)) }
            ?? AppLocalization.text("categoryShopping", language: displayLanguage)
    }
}
