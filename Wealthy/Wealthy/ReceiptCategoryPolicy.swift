import Foundation

// OCRの明瞭な用途から既存カテゴリーを選び、対応がなければ新しい名前を提案します。
enum ReceiptCategoryPolicy {
    /// Returns nil when no clear purchase-purpose evidence matches the rules.
    static func evidenceBasedCategory(text: String, existingCategories: [String], language: String = "ja") -> String? {
        let value = text.folding(options: [.widthInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US"))
        let rules: [(keywords: [String], aliases: [String], ja: String, en: String)] = [
            (["書店", "新書", "文庫", "書籍", "bookstore", "paperback"], ["書籍", "本", "books", "趣味", "hobbies", "hobby", "entertainment"], "書籍", "Books"),
            (["rebar", "lumber", "timber", "home depot", "木材", "鉄筋", "建材"], ["住居・DIY", "住居", "住宅", "diy", "home", "housing"], "住居・DIY", "Home & DIY"),
            (["乗車", "運賃", "乗車券", "タクシー", "taxi", "train fare", "bus fare", "交通運賃"], ["交通費", "交通", "transportation", "transport", "travel"], "交通費", "Transportation"),
            (["シャツ", "ズボン", "靴下", "衣料", "t-shirt", "jeans", "socks"], ["衣服", "衣類", "clothing", "clothes"], "衣服", "Clothing"),
            (["牛丼", "ラーメン", "ヨーグル", "ワッフル", "waffle", "焼き", "カフェ", "starbucks", "lawson", "coffee", "cookie", "apple pie", "banana", "bread", "牛肉", "チーズ", "パン", "羊かん", "ようかん", "お茶", "ジャスミン茶", "マネケン", "manneken", "飲料", "グミ", "コーラ", "焼酎", "ビール", "restaurant"], ["食費", "食品", "外食", "カフェ", "food", "groceries", "dining", "cafe", "restaurants"], "食費", "Food"),
            (["処方", "調剤", "薬剤", "診察", "医薬品", "prescription", "medicine", "clinic"], ["医療費", "医療", "health", "medical", "healthcare"], "医療費", "Healthcare"),
            (["洗剤", "ティッシュ", "トイレット", "シャンプー", "detergent", "toilet paper", "shampoo"], ["日用品", "生活用品", "daily necessities", "household", "household goods"], "日用品", "Household")
        ]
        for rule in rules {
            guard rule.keywords.contains(where: { value.contains($0) }) else { continue }
            if let existing = existingCategories.first(where: { category in rule.aliases.contains(category.folding(options: [.widthInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US"))) }) { return existing }
            return language.hasPrefix("en") ? rule.en : rule.ja
        }
        return nil
    }

    /// Uses a generic shopping category only when readable text has no clear purpose.
    static func suggestedCategory(text: String, existingCategories: [String], language: String = "ja") -> String {
        if let evidence = evidenceBasedCategory(text: text, existingCategories: existingCategories, language: language) { return evidence }
        let value = text.folding(options: [.widthInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US"))
        guard value.rangeOfCharacter(from: .letters) != nil else { return language.hasPrefix("en") ? "Unclassified" : "未分類" }
        // 文字は読めても用途が不明な買い物には、汎用カテゴリーを使います。
        return existingCategories.first { ["その他", "other", "others", "miscellaneous"].contains($0.lowercased()) } ?? (language.hasPrefix("en") ? "Shopping" : "買い物")
    }
}
