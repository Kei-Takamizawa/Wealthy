import Foundation

/// Payment evidence is read deterministically. Advertising and loyalty messages are not payments.
enum ReceiptPaymentPolicy {
    struct Detection: Equatable {
        let method: String?
        let needsReview: Bool
    }
    static let methods = ["cash", "sbiShinsei", "docomoSMTB", "paypay", "paypayCredit", "rakutenPay", "rakutenCard", "suica", "pasmo", "icoca", "waon", "nanaco", "quicpay", "id", "auPay", "dPay", "merpay", "visa", "mastercard", "jcb", "amex", "creditCard", "debitCard", "bankTransfer"]
    private static let brands: [(String, [String])] = [
        ("sbiShinsei", ["sbi新生銀行", "sbi shinsei bank", "新生銀行"]),
        ("docomoSMTB", ["ドコモsmtbネット銀行", "docomo smtb net bank", "住信sbiネット銀行", "d neobank"]),
        ("paypayCredit", ["paypayクレジット", "paypay credit"]),
        ("rakutenCard", ["楽天カード", "rakuten card"]), ("rakutenPay", ["楽天ペイ", "rakuten pay", "楽天pay"]),
        ("paypay", ["paypay", "ペイペイ"]), ("suica", ["suica", "スイカ"]), ("pasmo", ["pasmo", "パスモ"]),
        ("icoca", ["icoca", "イコカ"]), ("waon", ["waon", "ワオン"]), ("nanaco", ["nanaco", "ナナコ"]),
        ("quicpay", ["quicpay", "クイックペイ"]), ("id", ["id"]), ("auPay", ["au pay", "aupay"]),
        ("dPay", ["d払い", "d pay"]), ("merpay", ["メルペイ", "merpay"]), ("visa", ["visa"]),
        ("mastercard", ["mastercard", "master card", "マスターカード"]), ("jcb", ["jcb"]),
        ("amex", ["amex", "american express"]), ("debitCard", ["デビット", "debit"]),
        ("creditCard", ["クレジット", "credit card", "credit", "カード払い"]),
        ("bankTransfer", ["銀行振込", "口座振替", "bank transfer"]), ("cash", ["現金", "cash"])
    ]
    static func displayName(_ method: String, language: AppLanguage) -> String {
        if method.hasPrefix("custom:") { return String(method.dropFirst(7)) }
        if method == "sbiShinsei" { return language == .japanese ? "SBI新生銀行" : "SBI Shinsei Bank" }
        if method == "docomoSMTB" { return language == .japanese ? "ドコモSMTBネット銀行" : "DOCOMO SMTB Net Bank" }
        let names = ["paypay": "PayPay", "paypayCredit": "PayPay Credit", "rakutenPay": "楽天ペイ", "rakutenCard": "楽天カード", "suica": "Suica", "pasmo": "PASMO", "icoca": "ICOCA", "waon": "WAON", "nanaco": "nanaco", "quicpay": "QUICPay", "id": "iD", "auPay": "au PAY", "dPay": "d払い", "merpay": "メルペイ", "visa": "Visa", "mastercard": "Mastercard", "jcb": "JCB", "amex": "American Express"]
        return names[method] ?? AppLocalization.text("payment." + method, language: language)
    }
    static func method(forAssetName name: String) -> String? {
        let value = AppLocalization.normalized(name)
        for language in AppLanguage.allCases {
            for method in ["cash", "creditCard", "debitCard", "bankTransfer"] where value == AppLocalization.normalized(displayName(method, language: language)) { return method }
        }
        return brand(in: value)
    }
    private static func brand(in text: String) -> String? {
        for (method, aliases) in brands {
            for alias in aliases {
                if alias == "id" {
                    if text.range(of: "(?i)(^|[^a-z0-9])id([^a-z0-9]|$)", options: .regularExpression) != nil { return method }
                } else if text.contains(alias) { return method }
            }
        }
        return nil
    }
    static func detect(_ text: String) -> Detection {
        var candidates = Set<String>()
        var pointsUsed = false
        for rawLine in text.components(separatedBy: .newlines) {
            let line = AppLocalization.normalized(rawLine)
            let explicit = line.range(of: "支払(?:い)?(?:方法|種別)|決済方法|お支払い|payment(?: method)?|tender|paid (by|with)|card type", options: .regularExpression) != nil
            if line.range(of: "ポイント(?:利用|使用).*?[1-9]|(?:points redeemed|points used).*?[1-9]", options: .regularExpression) != nil { pointsUsed = true }
            if !explicit && ["ポイント", "point", "キャンペーン", "campaign", "利用可能", "accepted", "ご利用いただけ", "還元", "会員", "member", "広告"].contains(where: line.contains) { continue }
            if let method = brand(in: line) {
                let aliases = brands.first(where: { $0.0 == method })?.1 ?? []
                let nameOnly = aliases.contains(line)
                let startsWithMethod = aliases.contains { alias in
                    line.hasPrefix(alias + " ") || line.hasPrefix(alias + ":") || line.hasPrefix(alias + "：") || line.hasPrefix(alias + "¥") || line.hasPrefix(alias + "￥")
                }
                let hasAmount = line.rangeOfCharacter(from: .decimalDigits) != nil
                if explicit || nameOnly || (hasAmount && startsWithMethod) { candidates.insert(method) }
            } else if explicit, let match = line.range(of: "(?:支払(?:い)?(?:方法|種別)|決済方法|payment method|paid (?:by|with))\\s*[:：]?\\s*(.+)", options: .regularExpression) {
                let label = String(line[match]).replacingOccurrences(of: "^(?:支払(?:い)?(?:方法|種別)|決済方法|payment method|paid (?:by|with))\\s*[:：]?\\s*", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
                if !label.isEmpty && label.count <= 40 && label.rangeOfCharacter(from: .letters) != nil { candidates.insert("custom:" + label) }
            }
        }
        // A generic credit line can accompany its specific network/provider on the next line.
        if candidates.count > 1 && !candidates.isDisjoint(with: ["visa", "mastercard", "jcb", "amex", "rakutenCard", "paypayCredit"]) { candidates.remove("creditCard") }
        if pointsUsed || candidates.count > 1 { return Detection(method: nil, needsReview: true) }
        return Detection(method: candidates.first ?? "cash", needsReview: false)
    }
}
