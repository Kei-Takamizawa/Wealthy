//
//  ReceiptScanner.swift
//  家計簿
//
//  Created by Harrison on 12/26/25.
//

import Foundation
import Vision
import UIKit

class ReceiptScanner {
    
    struct ScannedElement {
        let text: String
        let frame: CGRect
    }
    
    struct ReceiptScanResult {
        let rawText: String
        let legacyTitle: String
        let legacyAmount: Int
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
    
    private static func findTotalAmount(elements: [ScannedElement]) -> Int {
        // キーワードによる特定
        let totalKeywords = ["合計", "合　計", "お支払", "請求金額", "Total", "TOTAL"]
        
        // 1. 下にある「合計」キーワードを探す
        // Y座標が低い順（下にある順）に並べ替える
        let sortedElements = elements.sorted { $0.frame.origin.y < $1.frame.origin.y }
        var totalLabel: ScannedElement? = nil
        
        for element in sortedElements {
            for keyword in totalKeywords {
                if element.text.contains(keyword) {
                    totalLabel = element
                    break
                }
            }
            if totalLabel != nil { break } // 一番下の合計を見つけたら終了
        }
        
        // 2. キーワードが見つかった場合：その高さ（Y座標）周辺にある数字を探す
        if let label = totalLabel {
            let centerY = label.frame.midY
            let tolerance = label.frame.height * 0.8 // 許容範囲
            
            var bestAmount = 0
            var maxX: CGFloat = -1.0
            
            for element in elements {
                if element.text == label.text { continue }
                
                // 高さが合っているか
                if abs(element.frame.midY - centerY) < tolerance {
                    let val = extractNumber(element.text)
                    if val > 0 {
                        // より右側にあるものを優先（合計 ... 1000）
                        if element.frame.minX > maxX {
                            maxX = element.frame.minX
                            bestAmount = val
                        }
                    }
                }
            }
            if bestAmount > 0 { return bestAmount }
        }
        
        // 3. キーワード失敗時の「ボトム・ビッグ・ナンバー」作戦
        // 画面の下半分(Y < 0.5)にあり、文字が大きいor右にある数字を探す
        var maxScore: Double = -1.0
        var bestCandidate = 0
        
        for element in elements {
            // 下半分以外は無視（レシートの合計が上半分にあることはまずない）
            if element.frame.minY > 0.5 { continue }
            
            // ノイズチェック
            if isNoise(element.text) { continue }
            
            let val = extractNumber(element.text)
            if val <= 0 { continue }
            
            // スコアリング
            // 高さ（文字サイズ）を最重要視
            let sizeScore = Double(element.frame.height) * 2000
            // 位置（右にあるほど良い）
            let xScore = Double(element.frame.minX) * 100
            // 位置（下にあるほど良い = Yが小さいほど良い... Visionでは0が下）
            let yScore = (1.0 - Double(element.frame.minY)) * 500
            
            let totalScore = sizeScore + xScore + yScore
            
            if totalScore > maxScore {
                maxScore = totalScore
                bestCandidate = val
            }
        }
        
        return bestCandidate
    }
    
    // 強力な数字クリーニング
    private static func extractNumber(_ text: String) -> Int {
        // 全角数字を半角に変換
        let widthMap: [String: String] = [
            "０":"0", "１":"1", "２":"2", "３":"3", "４":"4",
            "５":"5", "６":"6", "７":"7", "８":"8", "９":"9"
        ]
        var converted = text
        for (full, half) in widthMap {
            converted = converted.replacingOccurrences(of: full, with: half)
        }
        
        // 記号やスペースを削除（"1 980" -> "1980"）
        let cleaned = converted
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: "円", with: "")
            .replacingOccurrences(of: " ", with: "") // スペース除去
            .replacingOccurrences(of: "　", with: "") // 全角スペース除去
        
        // 数字抽出
        let pattern = #"[0-9]+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }
        let results = regex.matches(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned))
        
        // 右端（最後）の数字を採用
        if let lastResult = results.last, let range = Range(lastResult.range, in: cleaned) {
            if let num = Int(cleaned[range]) {
                // フィルタリング
                if num <= 10 { return 0 } // 小さすぎる
                if num > 3000000 { return 0 } // 大きすぎる
                // 年号除外
                let currentYear = Calendar.current.component(.year, from: Date())
                if abs(num - currentYear) <= 1 { return 0 }
                
                return num
            }
        }
        return 0
    }
    
    private static func isNoise(_ text: String) -> Bool {
        let blacklist = [
            "No.", "No", "TEL", "Tel", "Fax", "電話", "会員", "ポイント",
            "預", "釣", "税", "値引", "割引", "番号", "日時", "店", "レジ"
        ]
        for word in blacklist {
            if text.contains(word) { return true }
        }
        return false
    }
    
    private static func extractTitle(from candidates: [String]) -> String {
        let blacklist = ["レシート", "領収書", "クレジット", "売上", "伝票", "様", "御中", "店", "支店"]
        for text in candidates {
            if text.count < 2 || Int(text) != nil { continue }
            
            var isBad = false
            for word in blacklist {
                if text.contains(word) { isBad = true; break }
            }
            if !isBad { return text }
        }
        return "未分類"
    }
}
