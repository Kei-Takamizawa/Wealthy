//
//  ReceiptScanner.swift
//  家計簿
//
//  Created by Harrison on 12/26/25.
//

// Foundationの機能を、このファイルから使えるように読み込みます。
import Foundation
// Visionの機能を、このファイルから使えるように読み込みます。
import Vision
// UIKitの機能を、このファイルから使えるように読み込みます。
import UIKit

// 画像からレシート情報を読み取る型を定義します。
class ReceiptScanner {
    
    // 認識した文字と画像上の位置をまとめる型を定義します。
    struct ScannedElement {
        // 認識した文字列または書類本文を保持するプロパティを定義します。
        let text: String
        // 画像上の文字の位置を保持するプロパティを定義します。
        let frame: CGRect
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // 読み取り結果を呼び出し元へ返す型を定義します。
    struct ReceiptScanResult {
        // 認識した全文を保持するプロパティを定義します。
        let rawText: String
        // 従来方式で推定した店名を保持するプロパティを定義します。
        let legacyTitle: String
        // 従来方式で推定した金額を保持するプロパティを定義します。
        let legacyAmount: Int
    // ここまでの処理またはデータ定義を閉じます。
    }

    // 画像を文字認識し、家計簿で使う文字列・店名・金額を返します。
    static func scan(image: UIImage) async -> ReceiptScanResult {
        // 非同期の呼び出し元へ、読み取り完了時に結果を一度だけ返します。
        return await withCheckedContinuation { continuation in
            // 文字認識に必要な画像データを取り出し、取得できなければ終了します。
            guard let cgImage = image.cgImage else {
                // 画像を取得できない場合も、待機中の処理へ失敗結果を返します。
                continuation.resume(returning: ReceiptScanResult(rawText: "", legacyTitle: "Error", legacyAmount: 0))
                // 画像がないため、これ以上の処理を行いません。
                return
            // 画像取得に失敗した場合の処理を閉じます。
            }
            // 時間のかかる文字認識を、画面表示とは別の処理で実行します。
            DispatchQueue.global(qos: .userInitiated).async {
                // 文字認識の設定と実行を、同じ処理内で行うための要求を作ります。
                let request = VNRecognizeTextRequest()
                // 日本語と英語のレシートを読み取れるようにします。
                request.recognitionLanguages = ["ja-JP", "en-US"]
                // 速度よりも認識精度を優先します。
                request.recognitionLevel = .accurate
                // 認識した単語を言語情報で補正します。
                request.usesLanguageCorrection = true
                // 取り出した画像を文字認識の入力に設定します。
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                // 文字認識中の失敗を捕捉し、呼び出し元の待機を必ず終えます。
                do {
                    // 設定した要求を実行し、完了するまでこの処理内で待ちます。
                    try handler.perform([request])
                // Visionがエラーを返した場合の処理を始めます。
                } catch {
                    // 失敗結果を一度だけ返し、呼び出し元が待ち続けないようにします。
                    continuation.resume(returning: ReceiptScanResult(rawText: "", legacyTitle: "Error", legacyAmount: 0))
                    // 失敗時は認識結果を調べずに終了します。
                    return
                // エラー時の処理を閉じます。
                }
                // 認識結果がない場合は、空の結果を返します。
                guard let observations = request.results else {
                    // 認識できた文字がないことを示す既存の結果を返します。
                    continuation.resume(returning: ReceiptScanResult(rawText: "", legacyTitle: "未分類", legacyAmount: 0))
                    // 認識結果がないため、残りの集計を行いません。
                    return
                // 認識結果がない場合の処理を閉じます。
                }
                // 認識した文字とその位置を保存する配列を用意します。
                var elements: [ScannedElement] = []
                // 認識した全文を保存する配列を用意します。
                var allTextLines: [String] = []
                // レシート上部にある店名候補を保存する配列を用意します。
                var titleCandidates: [String] = []
                // 認識された文字のまとまりを一つずつ調べます。
                for observation in observations {
                    // 最も確からしい文字列がなければ、このまとまりを飛ばします。
                    guard let candidate = observation.topCandidates(1).first else { continue }
                    // 文字列が画像内のどこにあるかを取得します。
                    let box = observation.boundingBox
                    // 金額の判定に使う文字列と位置を保存します。
                    elements.append(ScannedElement(text: candidate.string, frame: box))
                    // 全文表示に使う文字列を保存します。
                    allTextLines.append(candidate.string)
                    // 画像上部の文字列だけを店名候補にします。
                    if box.origin.y > 0.6 {
                        // 店名候補の配列へ文字列を追加します。
                        titleCandidates.append(candidate.string)
                    // 店名候補の判定を閉じます。
                    }
                // 文字列を一つずつ調べる処理を閉じます。
                }
                // 既存のルールで合計金額を推定します。
                let fallbackAmount = findTotalAmount(elements: elements)
                // 既存のルールで店名を推定します。
                let fallbackTitle = extractTitle(from: titleCandidates)
                // すべての文字列を改行でつなぎ、全文を作ります。
                let fullText = allTextLines.joined(separator: "\n")
                // 呼び出し元へ返す結果を一つにまとめます。
                let result = ReceiptScanResult(rawText: fullText, legacyTitle: fallbackTitle, legacyAmount: fallbackAmount)
                // 認識結果を一度だけ返して、呼び出し元の待機を終えます。
                continuation.resume(returning: result)
            // 画面表示とは別に実行する処理を閉じます。
            }
        // 非同期の結果を待つ処理を閉じます。
        }
    // レシート読み取り関数を閉じます。
    }
    
    // 認識した文字の位置から合計額を推定する入口を定義します。
    private static func findTotalAmount(elements: [ScannedElement]) -> Int {
        // キーワードによる特定
        // totalKeywordsとして後続の処理で使う値を作成または更新します。
        let totalKeywords = ["合計", "合　計", "お支払", "請求金額", "Total", "TOTAL"]
        
        // 1. 下にある「合計」キーワードを探す
        // Y座標が低い順（下にある順）に並べ替える
        // 画像の下側にある文字から順に並べます。
        let sortedElements = elements.sorted { $0.frame.origin.y < $1.frame.origin.y }
        // 合計を示す文字が見つかったら保持する変数を作ります。
        var totalLabel: ScannedElement? = nil
        
        // 配列の各要素を順番に取り出して処理します。
        for element in sortedElements {
            // 配列の各要素を順番に取り出して処理します。
            for keyword in totalKeywords {
                // この条件が成り立つ場合だけ、続く処理を行います。
                if element.text.contains(keyword) {
                    // totalLabelに、右辺の計算結果または取得結果を設定します。
                    totalLabel = element
                    // 目的の値が見つかったので、この繰り返しを終了します。
                    break
                // ここまでの処理またはデータ定義を閉じます。
                }
            // ここまでの処理またはデータ定義を閉じます。
            }
            // この条件が成り立つ場合だけ、続く処理を行います。
            if totalLabel != nil { break } // 一番下の合計を見つけたら終了
        // ここまでの処理またはデータ定義を閉じます。
        }
        
        // 2. キーワードが見つかった場合：その高さ（Y座標）周辺にある数字を探す
        // この条件が成り立つ場合だけ、続く処理を行います。
        if let label = totalLabel {
            // 合計ラベルの縦方向の中心を取得します。
            let centerY = label.frame.midY
            // 同じ行とみなす縦方向の許容幅を決めます。
            let tolerance = label.frame.height * 0.8 // 許容範囲
            
            // 候補中で最も適切な金額を作成または更新します。
            var bestAmount = 0
            // maxXとして後続の処理で使う値を作成または更新します。
            var maxX: CGFloat = -1.0
            
            // 配列の各要素を順番に取り出して処理します。
            for element in elements {
                // この条件が成り立つ場合だけ、続く処理を行います。
                if element.text == label.text { continue }
                
                // 高さが合っているか
                // この条件が成り立つ場合だけ、続く処理を行います。
                if abs(element.frame.midY - centerY) < tolerance {
                    // 文字列から取り出した金額候補を保持します。
                    let val = extractNumber(element.text)
                    // この条件が成り立つ場合だけ、続く処理を行います。
                    if val > 0 {
                        // より右側にあるものを優先（合計 ... 1000）
                        // この条件が成り立つ場合だけ、続く処理を行います。
                        if element.frame.minX > maxX {
                            // maxXに、右辺の計算結果または取得結果を設定します。
                            maxX = element.frame.minX
                            // bestAmountに、右辺の計算結果または取得結果を設定します。
                            bestAmount = val
                        // ここまでの処理またはデータ定義を閉じます。
                        }
                    // ここまでの処理またはデータ定義を閉じます。
                    }
                // ここまでの処理またはデータ定義を閉じます。
                }
            // ここまでの処理またはデータ定義を閉じます。
            }
            // この条件が成り立つ場合だけ、続く処理を行います。
            if bestAmount > 0 { return bestAmount }
        // ここまでの処理またはデータ定義を閉じます。
        }
        
        // 3. キーワード失敗時の「ボトム・ビッグ・ナンバー」作戦
        // 画面の下半分(Y < 0.5)にあり、文字が大きいor右にある数字を探す
        // 現在最も高い候補の点数を作成または更新します。
        var maxScore: Double = -1.0
        // 採用する金額候補を作成または更新します。
        var bestCandidate = 0
        
        // 配列の各要素を順番に取り出して処理します。
        for element in elements {
            // 下半分以外は無視（レシートの合計が上半分にあることはまずない）
            // この条件が成り立つ場合だけ、続く処理を行います。
            if element.frame.minY > 0.5 { continue }
            
            // ノイズチェック
            // この条件が成り立つ場合だけ、続く処理を行います。
            if isNoise(element.text) { continue }
            
            // 文字列から取り出した金額候補を保持します。
            let val = extractNumber(element.text)
            // この条件が成り立つ場合だけ、続く処理を行います。
            if val <= 0 { continue }
            
            // スコアリング
            // 高さ（文字サイズ）を最重要視
            // 文字の大きさによる点数を作成または更新します。
            let sizeScore = Double(element.frame.height) * 2000
            // 位置（右にあるほど良い）
            // 右寄りの位置による点数を作成または更新します。
            let xScore = Double(element.frame.minX) * 100
            // 位置（下にあるほど良い = Yが小さいほど良い... Visionでは0が下）
            // 下寄りの位置による点数を作成または更新します。
            let yScore = (1.0 - Double(element.frame.minY)) * 500
            
            // 候補の大きさと位置から計算した点数を作成または更新します。
            let totalScore = sizeScore + xScore + yScore
            
            // この条件が成り立つ場合だけ、続く処理を行います。
            if totalScore > maxScore {
                // maxScoreに、右辺の計算結果または取得結果を設定します。
                maxScore = totalScore
                // bestCandidateに、右辺の計算結果または取得結果を設定します。
                bestCandidate = val
            // ここまでの処理またはデータ定義を閉じます。
            }
        // ここまでの処理またはデータ定義を閉じます。
        }
        
        // 計算または取得した値を呼び出し元へ返します。
        return bestCandidate
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // 強力な数字クリーニング
    // 金額らしい数字を文字列から取り出す入口を定義します。
    private static func extractNumber(_ text: String) -> Int {
        // 全角数字を半角に変換
        // 全角数字を半角数字へ置き換える対応表を作ります。
        let widthMap: [String: String] = [
            // 判定に使う文字列または数字の変換対応を一覧に追加します。
            "０":"0", "１":"1", "２":"2", "３":"3", "４":"4",
            // 判定に使う文字列または数字の変換対応を一覧に追加します。
            "５":"5", "６":"6", "７":"7", "８":"8", "９":"9"
        // ここで一覧または辞書を閉じます。
        ]
        // 数字を置換するための作業用文字列を作ります。
        var converted = text
        // 配列の各要素を順番に取り出して処理します。
        for (full, half) in widthMap {
            // convertedに、右辺の計算結果または取得結果を設定します。
            converted = converted.replacingOccurrences(of: full, with: half)
        // ここまでの処理またはデータ定義を閉じます。
        }
        
        // 記号やスペースを削除（"1 980" -> "1980"）
        // 通貨記号や空白を取り除いた文字列を作ります。
        let cleaned = converted
            // 直前の値に、この設定または変換処理を続けて適用します。
            .replacingOccurrences(of: ",", with: "")
            // 直前の値に、この設定または変換処理を続けて適用します。
            .replacingOccurrences(of: "¥", with: "")
            // 直前の値に、この設定または変換処理を続けて適用します。
            .replacingOccurrences(of: "円", with: "")
            // 直前の値に、この設定または変換処理を続けて適用します。
            .replacingOccurrences(of: " ", with: "") // スペース除去
            // 直前の値に、この設定または変換処理を続けて適用します。
            .replacingOccurrences(of: "　", with: "") // 全角スペース除去
        
        // 数字抽出
        // 数字が連続する部分を探す正規表現を定義します。
        let pattern = #"[0-9]+"#
        // 必要な値があるか確かめ、なければ後続の処理を止めます。
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }
        // 文字列内で見つかった数字の候補をすべて取得します。
        let results = regex.matches(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned))
        
        // 右端（最後）の数字を採用
        // この条件が成り立つ場合だけ、続く処理を行います。
        if let lastResult = results.last, let range = Range(lastResult.range, in: cleaned) {
            // この条件が成り立つ場合だけ、続く処理を行います。
            if let num = Int(cleaned[range]) {
                // フィルタリング
                // この条件が成り立つ場合だけ、続く処理を行います。
                if num <= 10 { return 0 } // 小さすぎる
                // この条件が成り立つ場合だけ、続く処理を行います。
                if num > 3000000 { return 0 } // 大きすぎる
                // 年号除外
                // 今年の西暦を取得して金額候補から年号を除きます。
                let currentYear = Calendar.current.component(.year, from: Date())
                // この条件が成り立つ場合だけ、続く処理を行います。
                if abs(num - currentYear) <= 1 { return 0 }
                
                // 計算または取得した値を呼び出し元へ返します。
                return num
            // ここまでの処理またはデータ定義を閉じます。
            }
        // ここまでの処理またはデータ定義を閉じます。
        }
        // 計算または取得した値を呼び出し元へ返します。
        return 0
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // 金額判定に使わない文字列かを調べる入口を定義します。
    private static func isNoise(_ text: String) -> Bool {
        // 金額や店名の候補から除外する語を定義します。
        let blacklist = [
            // 判定に使う文字列または数字の変換対応を一覧に追加します。
            "No.", "No", "TEL", "Tel", "Fax", "電話", "会員", "ポイント",
            // 判定に使う文字列または数字の変換対応を一覧に追加します。
            "預", "釣", "税", "値引", "割引", "番号", "日時", "店", "レジ"
        // ここで一覧または辞書を閉じます。
        ]
        // 配列の各要素を順番に取り出して処理します。
        for word in blacklist {
            // この条件が成り立つ場合だけ、続く処理を行います。
            if text.contains(word) { return true }
        // ここまでの処理またはデータ定義を閉じます。
        }
        // 計算または取得した値を呼び出し元へ返します。
        return false
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // 店名らしい文字列を候補から選ぶ入口を定義します。
    private static func extractTitle(from candidates: [String]) -> String {
        // 金額や店名の候補から除外する語を定義します。
        let blacklist = ["レシート", "領収書", "クレジット", "売上", "伝票", "様", "御中", "店", "支店"]
        // 配列の各要素を順番に取り出して処理します。
        for text in candidates {
            // この条件が成り立つ場合だけ、続く処理を行います。
            if text.count < 2 || Int(text) != nil { continue }
            
            // isBadとして後続の処理で使う値を作成または更新します。
            var isBad = false
            // 配列の各要素を順番に取り出して処理します。
            for word in blacklist {
                // この条件が成り立つ場合だけ、続く処理を行います。
                if text.contains(word) { isBad = true; break }
            // ここまでの処理またはデータ定義を閉じます。
            }
            // この条件が成り立つ場合だけ、続く処理を行います。
            if !isBad { return text }
        // ここまでの処理またはデータ定義を閉じます。
        }
        // 計算または取得した値を呼び出し元へ返します。
        return "未分類"
    // ここまでの処理またはデータ定義を閉じます。
    }
// ここまでの処理またはデータ定義を閉じます。
}
