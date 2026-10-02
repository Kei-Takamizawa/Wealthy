// OCRが返した文字と位置を、ネットワークやAIを使わずに整理するための標準機能を読み込みます。
import Foundation
// 文字の矩形の中心や端の座標を計算するCore Graphicsを読み込みます。
import CoreGraphics

// 画像の読み取りと切り離して、レシートの行・店名・円単位の金額を解析する型です。
enum ReceiptTextParser {
    // Visionが返した一つの文字列と、その位置を一緒に保持します。
    struct Element {
        // 認識結果をそのまま保存し、推測で文字を書き換えないようにします。
        let text: String
        // 左下を原点とする、画像全体に対して0〜1で表した文字の位置です。
        let frame: CGRect
    // 一つの認識結果の定義を閉じます。
    }

    // 同じ高さにある文字をまとめ、上から下、同じ行では左から右へ並べます。
    static func orderedRows(elements: [Element]) -> [[Element]] {
        // VisionではY座標が大きいほど上なので、縦の中心が大きい順に並べます。
        let sorted = elements.sorted { $0.frame.midY == $1.frame.midY ? $0.frame.minX < $1.frame.minX : $0.frame.midY > $1.frame.midY }
        // 各行の文字列を保持する、最初は空の二次元配列を作ります。
        var rows: [[Element]] = []
        // 上から順に、一つずつ所属する行を決めます。
        for element in sorted {
            // 行の最初の文字と高さが重なる行を探し、隣の行への連鎖的な結合を防ぎます。
            if let index = rows.firstIndex(where: { row in
                // 行を代表する最初の文字がなければ、その行は選びません。
                guard let anchor = row.first else { return false }
                // 二つの文字領域の縦方向の重なり幅を計算します。
                let overlap = min(anchor.frame.maxY, element.frame.maxY) - max(anchor.frame.minY, element.frame.minY)
                // 高さの違う大きな文字が隣の行を巻き込まないよう、中心の距離も確認します。
                let centerDistance = abs(anchor.frame.midY - element.frame.midY)
                // 小さい方の文字の高さの半分以上が重なる場合だけ、同じ行として扱います。
                return overlap > min(anchor.frame.height, element.frame.height) * 0.5 && centerDistance < min(anchor.frame.height, element.frame.height) * 0.5
            // 行を探す条件の定義を閉じます。
            }) {
                // 見つかった行へ、現在の文字を追加します。
                rows[index].append(element)
            // 既存の行と高さが合わない場合は、新しい行を作ります。
            } else {
                // 現在の文字を最初の要素とする行を追加します。
                rows.append([element])
            // 行への追加方法を選ぶ処理を閉じます。
            }
        // 全文字の行分けを閉じます。
        }
        // それぞれの行の文字を、左端のX座標が小さい順に並べて返します。
        return rows.map { $0.sorted { $0.frame.minX < $1.frame.minX } }
    // 行の整理を閉じます。
    }

    // 明示的な合計を優先し、複数の金額が矛盾する場合は未確定を表す0を返します。
    static func totalAmount(elements: [Element]) -> Int {
        // 文字の高さを基準に、合計ラベルと金額を同じ行へまとめます。
        let rows = orderedRows(elements: elements)
        // 合計ラベルのある行から得た金額を、重複を除いて保存します。
        var totals: Set<Int> = []
        // 合計ラベルが読めたのに金額が不明な場合、別の行の数字へ逃げないためのフラグです。
        var foundTotalLabel = false
        // 合計行の金額が複数ある場合や読めない場合、他の行の数字だけで確定しません。
        var hasAmbiguousTotal = false
        // 各行について、合計ラベルとその右側を調べます。
        for row in rows {
            // 同じ行の文字を空白でつなぎ、税額や数量の文脈も確認できるようにします。
            let rowText = row.map(\.text).joined(separator: " ")
            // 税額・点数などの合計は、支出額の合計として扱いません。
            if isExcludedAmountLine(rowText) { continue }
            // 一つの行の文字を、左から右へ調べます。
            for (index, element) in row.enumerated() {
                // 「合計」などの語がなければ、この文字からは金額を選びません。
                guard isTotalLabel(element.text) else { continue }
                // 合計ラベルを見つけたことを記録します。
                foundTotalLabel = true
                // ラベルより右の文脈を確認し、別の観測にある負号も見落とさないようにします。
                let amountText = row[index...].map(\.text).joined(separator: " ")
                // ドルやユーロなどの外貨を円として扱わず、金額を未確定にします。
                if rowText.range(of: #"[$€£]|\b(?:USD|EUR|GBP|AUD|CAD|CNY|KRW)\b"#, options: [.regularExpression, .caseInsensitive]) != nil { hasAmbiguousTotal = true; continue }
                // マイナスの合計を正の支出として登録しないよう、読み取れない金額として扱います。
                if normalized(amountText).range(of: #"[-−]\s*[¥￥]?\s*[0-9]"#, options: .regularExpression) != nil {
                    // 負数を見つけたため、他の合計候補だけで金額を確定しないようにします。
                    hasAmbiguousTotal = true
                    // この行の正の数字を採用しないように、次のラベルへ進みます。
                    continue
                // 負数を除外する処理を閉じます。
                }
                // 別の認識枠にある数字同士を結合せず、一つずつ金額候補を解析します。
                let fragmentValues = row[index...].enumerated().flatMap { offset, fragment -> [Int] in
                    // 同じ行にある、現在の文字の右隣の位置を計算します。
                    let nextIndex = index + offset + 1
                    // 右隣がある場合だけ、その先頭の文字を単位の確認用に取り出します。
                    let nextCharacter = nextIndex < row.count ? normalized(row[nextIndex].text).trimmingCharacters(in: .whitespaces).first : nil
                    // 「10」「%」や「5」「点」のように単位が別枠でも、数字の意味を正しく判定します。
                    let suffix = nextCharacter.map { "%点個枚年月日時分秒".contains($0) ? String($0) : "" } ?? ""
                    // 単位だけを補って解析し、別の枠にある数字は連結しません。
                    return amountValues(in: fragment.text + suffix)
                // 各認識枠の金額を解析する処理を閉じます。
                }
                // 同じ金額の重複を除き、一つの合計行が示す異なる金額の数を調べます。
                let values = Set(fragmentValues)
                // 同じ合計行の金額が一つに決まらないことを記録します。
                if values.count != 1 { hasAmbiguousTotal = true }
                // 一つに決められる場合だけ採用し、複数の異なる数字は推測で選びません。
                guard values.count == 1, let amount = values.first else { continue }
                // この行で確定できた金額を、合計候補へ追加します。
                totals.insert(amount)
            // 同じ行の文字を調べる処理を閉じます。
            }
        // 全行の合計ラベルを調べる処理を閉じます。
        }
        // 合計ラベルがある場合は、各行の候補が一つの値に一致するときだけ返します。
        if foundTotalLabel { return !hasAmbiguousTotal && totals.count == 1 ? totals.first! : 0 }
        // 円記号だけでは商品単価と合計額を区別できないので、合計ラベルがなければ未確定です。
        return 0
    // 合計額の解析を閉じます。
    }

    // 上部の文字から、住所・電話番号・書類の見出し以外の店名候補を選びます。
    static func title(elements: [Element]) -> String {
        // 店名として採用しない、書類見出しや連絡先を表す語です。
        let excluded = ["レシート", "領収書", "クレジット", "売上", "伝票", "御中", "TEL", "FAX", "電話", "住所", "〒"]
        // 画像の上側40%にある文字を、実際の読み順で調べます。
        for element in orderedRows(elements: elements).flatMap({ $0 }) where element.frame.midY > 0.6 {
            // 前後の空白だけを取り除き、店名の本文は変更しません。
            let text = element.text.trimmingCharacters(in: .whitespacesAndNewlines)
            // 数字・記号だけを店名にせず、少なくとも一文字の文字を必要とします。
            guard text.count >= 2, text.rangeOfCharacter(from: .letters) != nil else { continue }
            // 「店」「支店」は店名にも必要なので除外せず、見出しや電話番号のみ除きます。
            guard !excluded.contains(where: { text.uppercased().contains($0) }), !isTotalLabel(text) else { continue }
            // 最初に見つかった店名候補を返します。
            return text
        // 店名候補を探す処理を閉じます。
        }
        // 店名を選べなかったことを、既存の表示用文字列で返します。
        return "未分類"
    // 店名の解析を閉じます。
    }

    // レシートの印字日付だけを読み、広告や返品期限より前にある購入日の候補を優先します。
    static func printedDate(in original: String) -> Date? {
        let text = normalized(original)
        let japaneseLetters = text.filter { $0.unicodeScalars.contains { (0x3040...0x30FF).contains($0.value) || (0x4E00...0x9FFF).contains($0.value) } }.count
        // 英語OCRの一文字だけが漢字に誤認されても、日付の月日順を変えません。
        let japaneseContext = japaneseLetters >= 2 && Double(japaneseLetters) / Double(max(1, text.count)) > 0.1
        let patterns: [(String, String)] = [
            (#"(?<![0-9])([0-9]{4})\s*(?:年|[/.-])\s*([0-9]{1,2})\s*(?:月|[/.-])\s*([0-9]{1,2})(?:日)?(?![0-9])"#, "ymd"),
            (#"(令和|平成|昭和|[RHS])\s*(元|[0-9]{1,2})\s*(?:年|[/.-])\s*([0-9]{1,2})\s*(?:月|[/.-])\s*([0-9]{1,2})(?:日)?(?![0-9])"#, "era"),
            (#"(?<![0-9])([0-9]{1,2})[/.-]([0-9]{1,2})[/.-]([0-9]{4})(?![0-9])"#, "mdy"),
            (#"(?<![0-9RHS])([0-9]{1,2})[/.-]([0-9]{1,2})[/.-]([0-9]{2})(?![0-9])"#, japaneseContext ? "shortymd" : "shortmdy"),
            (#"\b(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\s+([0-9]{1,2}),?\s+([0-9]{4})\b"#, "monthname")
        ]
        var candidates: [(Int, Date)] = []
        for (pattern, kind) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
                let groups = (1..<match.numberOfRanges).map { index in Range(match.range(at: index), in: text).map { String(text[$0]) } ?? "" }
                var year = 0
                var month = 0
                var day = 0
                var eraBounds: (Int, Int, Int, Int, Int, Int)?
                switch kind {
                case "ymd":
                    year = Int(groups[0]) ?? 0
                    month = Int(groups[1]) ?? 0
                    day = Int(groups[2]) ?? 0
                case "mdy":
                    year = Int(groups[2]) ?? 0
                    month = Int(groups[0]) ?? 0
                    day = Int(groups[1]) ?? 0
                case "shortymd":
                    year = expandedYear(Int(groups[0]) ?? -1)
                    month = Int(groups[1]) ?? 0
                    day = Int(groups[2]) ?? 0
                case "shortmdy":
                    year = expandedYear(Int(groups[2]) ?? -1)
                    month = Int(groups[0]) ?? 0
                    day = Int(groups[1]) ?? 0
                case "era":
                    let eraYear = groups[1] == "元" ? 1 : Int(groups[1]) ?? 0
                    guard eraYear > 0 else { continue }
                    let era = groups[0].uppercased()
                    let offset = ["令和": 2018, "R": 2018, "平成": 1988, "H": 1988, "昭和": 1925, "S": 1925][era] ?? 0
                    year = offset + eraYear
                    month = Int(groups[2]) ?? 0
                    day = Int(groups[3]) ?? 0
                    if offset == 2018 { eraBounds = (2019, 5, 1, 9999, 12, 31) }
                    if offset == 1988 { eraBounds = (1989, 1, 8, 2019, 4, 30) }
                    if offset == 1925 { eraBounds = (1926, 12, 25, 1989, 1, 7) }
                default:
                    let months = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"]
                    month = (months.firstIndex(of: String(groups[0].lowercased().prefix(3))) ?? -1) + 1
                    day = Int(groups[1]) ?? 0
                    year = Int(groups[2]) ?? 0
                }
                guard let date = validatedDate(year: year, month: month, day: day) else { continue }
                if let bounds = eraBounds {
                    guard let first = validatedDate(year: bounds.0, month: bounds.1, day: bounds.2), let last = validatedDate(year: bounds.3, month: bounds.4, day: bounds.5), date >= first, date <= last else { continue }
                }
                let prefix = String(text[..<(Range(match.range, in: text)?.lowerBound ?? text.startIndex)].suffix(30)).uppercased()
                if ["返品期限", "有効期限", "応募期間", "EXPIRES", "EXPIRY", "VALID UNTIL"].contains(where: { prefix.contains($0) }) { continue }
                candidates.append((match.range.location, date))
            }
        }
        return candidates.sorted { $0.0 < $1.0 }.first?.1
    }

    // 二桁年は00〜69を2000年代、70〜99を1900年代とする明示的な変換です。
    private static func expandedYear(_ year: Int) -> Int {
        guard (0...99).contains(year) else { return 0 }
        return year < 70 ? 2000 + year : 1900 + year
    }

    // Calendarの自動繰り上げを許さず、うるう日を含め実在する日付だけを返します。
    private static func validatedDate(year: Int, month: Int, day: Int) -> Date? {
        guard (1...9999).contains(year), (1...12).contains(month), (1...31).contains(day) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else { return nil }
        let roundTrip = calendar.dateComponents([.year, .month, .day], from: date)
        return roundTrip.year == year && roundTrip.month == month && roundTrip.day == day ? date : nil
    }

    // 全角英数字を半角にそろえ、全角空白や改行も普通の空白にします。
    private static func normalized(_ text: String) -> String {
        // 幅の違いだけをそろえ、O→0などの推測による数字置換は行いません。
        let folded = text.folding(options: .widthInsensitive, locale: Locale(identifier: "ja_JP"))
        // 空白の種類を統一し、数字どうしの区切りを消さずに残します。
        return folded.map { $0.isWhitespace ? " " : String($0) }.joined()
    // 文字の正規化を閉じます。
    }

    // 金額の合計を表すラベルかどうかを、文字幅や語間の空白に左右されず確認します。
    private static func isTotalLabel(_ text: String) -> Bool {
        // 日本語の「合 計」と英語の大文字・小文字を同じ条件で扱います。
        let compact = normalized(text).replacingOccurrences(of: " ", with: "").uppercased()
        // 小計や数量の合計など、別の意味のラベルを先に除外します。
        guard !isExcludedAmountLine(text) else { return false }
        // 日本語の主要な合計ラベルを確認します。
        if compact.contains("合計") { return true }
        // 広告の「アプリでのお支払い」など、文中の支払い語を合計ラベルにしません。
        if ["お支払", "支払金額", "請求金額"].contains(where: { compact.hasPrefix($0) }) { return true }
        // 英語では単語としてTOTALまたはGRAND TOTALが現れる場合だけ認めます。
        return normalized(text).range(of: #"\b(?:GRAND\s+)?TOTAL\b"#, options: [.regularExpression, .caseInsensitive]) != nil
    // 合計ラベルの判定を閉じます。
    }

    // 支出合計と紛らわしい税額・預り金・数量・電話番号などの行を除外します。
    private static func isExcludedAmountLine(_ text: String) -> Bool {
        // 空白と文字幅を統一し、語間に空白がある場合にも対応します。
        let compact = normalized(text).replacingOccurrences(of: " ", with: "").uppercased()
        // 「税込合計」を除外しないよう、「税」という一文字だけの禁止は使いません。
        let excluded = ["小計", "SUBTOTAL", "SUB-TOTAL", "本体合計", "税合計", "税額", "消費税", "内税", "外税", "合計点", "合計数", "点数", "数量", "預", "釣", "値引", "割引", "ポイント", "電話", "TEL", "FAX", "番号", "日時", "日付", "CHANGE", "TENDER", "CASHRECEIVED", "TAX"]
        // 一つでも除外語があれば、この行から金額を選びません。
        return excluded.contains { compact.contains($0) }
    // 金額以外の行の判定を閉じます。
    }

    // 整数の円金額を読み、税率・日時・電話番号・小数・負数を金額から外します。
    private static func amountValues(in original: String) -> [Int] {
        // 全角数字を半角へ直し、数字間の空白はそのまま残します。
        let text = normalized(original)
        // カンマ区切り、1 980のような一組の空白区切り、通常の整数を別々に読みます。
        let pattern = #"(?<![0-9])(?:[0-9]{1,3}(?:,[0-9]{3})+|[0-9]{1,3} [0-9]{3}|[0-9]+)(?![0-9])"#
        // 正規表現を作れなければ、推測せず候補なしとして返します。
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        // UTF-16単位の検索範囲を作り、日本語を含む文字列でも位置を正しく扱います。
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        // 妥当な形式だった金額候補を保持します。
        var values: [Int] = []
        // 見つかった数字のまとまりを、個別に確認します。
        for match in matches {
            // 正規表現の位置をSwiftの文字列の位置へ変換できない候補は使いません。
            guard let range = Range(match.range, in: text) else { continue }
            // 数字の直前にある内容を取り出し、符号や通貨を確認します。
            let before = text[..<range.lowerBound].trimmingCharacters(in: .whitespaces)
            // 数字の直後にある内容を取り出し、税率や単位を確認します。
            let after = text[range.upperBound...].trimmingCharacters(in: .whitespaces)
            // 円記号の手前にある負号も見つけるため、末尾の通貨記号と空白を一時的に外します。
            let beforeCurrency = before.trimmingCharacters(in: CharacterSet(charactersIn: "¥￥ "))
            // 日付・時間・電話番号・小数・負数の区切りに隣接する数字を除外します。
            if let previous = beforeCurrency.last, "/.-−,".contains(previous) { continue }
            // 「合計:1980」のコロンは認め、12:30のように数字に続くコロンだけを時刻として除外します。
            if beforeCurrency.last == ":", beforeCurrency.dropLast().last?.isNumber == true { continue }
            // 税率・数量・点数・数字の続きに隣接する数字を除外します。
            if let next = after.first, "/:.-−,%点個枚年月日時分秒".contains(next) { continue }
            // 桁区切りだけを消し、別々の数字のまとまりを連結しないようにします。
            let digits = text[range].replacingOccurrences(of: ",", with: "").replacingOccurrences(of: " ", with: "")
            // 1円以上のIntで表現できる金額だけを認め、今年と同額でも除外しません。
            guard let value = Int(digits), value > 0 else { continue }
            // 有効な金額候補を配列へ追加します。
            values.append(value)
        // 金額候補を一つずつ確認する処理を閉じます。
        }
        // 妥当な金額候補だけを呼び出し元へ返します。
        return values
    // 数字の解析を閉じます。
    }
// レシート文字列の解析用の型を閉じます。
}
