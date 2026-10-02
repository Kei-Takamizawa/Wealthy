// このファイルで使う日付や文字列などの基本機能を読み込みます。
import Foundation
// 画像内の文字を認識するVisionの機能を読み込みます。
import Vision
// UIImageと画面座標などのUIKitの型を読み込みます。
import UIKit
// 画像の向きを表すCGImagePropertyOrientationを明示的に読み込みます。
import ImageIO

// レシート画像から文字と位置を読み取る処理をまとめます。
class ReceiptScanner {
    // 認識された一つの文字列と画像内での位置を、解析側と共有する型として定義します。
    typealias ScannedElement = ReceiptTextParser.Element

    // 呼び出し元との互換性を保つため、従来の結果形式を定義します。
    struct ReceiptScanResult {
        // OCRが行ごとに並べた全文を保持します。
        let rawText: String
        // OCR開始前に確定した画像の撮影日時を保持します。
        let capturedAt: Date
        // 印字日付が読める場合はその日付、それ以外は撮影日時を使います。
        let receiptDate: Date
        // 日付をレシートから読み取れたか、撮影日時を使ったかを区別します。
        let dateWasPrinted: Bool
        // 従来の呼び出し元へ返す店名候補を保持します。
        let legacyTitle: String
        // 従来の呼び出し元へ返す合計金額候補を保持します。
        let legacyAmount: Int
    // 結果形式の定義を閉じます。
    }

    // 画像を一度だけOCRに通し、全文と互換用の店名・金額を返します。
    static func scan(image: UIImage, capturedAt: Date = Date()) async -> ReceiptScanResult {
        // 非同期の呼び出し元へ処理完了時に結果を返す継続を作ります。
        return await withCheckedContinuation { continuation in
            // Visionが必要とするCGImageを取得し、取得できなければ既存の失敗結果を返します。
            guard let cgImage = image.cgImage else {
                // 画像データを取得できない場合はErrorを返して待機を終えます。
                continuation.resume(returning: ReceiptScanResult(rawText: "", capturedAt: capturedAt, receiptDate: capturedAt, dateWasPrinted: false, legacyTitle: "Error", legacyAmount: 0))
                // 画像を使えないためOCR処理を開始せずに終了します。
                return
            // CGImage取得の条件分岐を閉じます。
            }
            // UIKitの画像向きを保持しながら、画面操作を止めない別スレッドでOCRを実行します。
            DispatchQueue.global(qos: .userInitiated).async {
                // OCRの言語・精度・単語補正を指定する要求を作成します。
                let request = VNRecognizeTextRequest()
                // 日本語と英語のレシート文字を認識対象にします。
                request.recognitionLanguages = ["ja-JP", "en-US"]
                // 処理速度より文字認識の精度を優先します。
                request.recognitionLevel = .accurate
                // 言語モデルによる認識文字の補正を有効にします。
                request.usesLanguageCorrection = true
                // レシートで見かける語をOCRの辞書に加え、合計欄などの認識を助けます。
                request.customWords = ["合計", "総合計", "税込合計", "お支払", "請求金額", "領収書", "小計", "お預り", "お釣り", "TOTAL", "Total", "total", "円", "税込"]
                // 文字の高さを理由に候補を除外しない設定にします。
                request.minimumTextHeight = 0
                // UIImageの向きをCGImage形式へ変換し、その向きで画像を読み込むハンドラーを作ります。
                let handler = VNImageRequestHandler(cgImage: cgImage, orientation: cgImageOrientation(from: image.imageOrientation), options: [:])
                // Visionの文字認識を実行し、失敗した場合は待機中の呼び出し元へエラーを返します。
                do {
                    // この画像に対するOCR要求を一度だけ実行します。
                    try handler.perform([request])
                // OCR要求が失敗した場合の処理を開始します。
                } catch {
                    // 失敗結果を一度返して呼び出し元の待機を終えます。
                    continuation.resume(returning: ReceiptScanResult(rawText: "", capturedAt: capturedAt, receiptDate: capturedAt, dateWasPrinted: false, legacyTitle: "Error", legacyAmount: 0))
                    // OCR結果を利用できないため後続の処理を行いません。
                    return
                // OCR要求のエラー処理を閉じます。
                }
                // Visionから結果配列を取得し、存在しなければ既存の未分類結果を返します。
                guard let observations = request.results else {
                    // 認識結果がないことを示す未分類結果を返します。
                    continuation.resume(returning: ReceiptScanResult(rawText: "", capturedAt: capturedAt, receiptDate: capturedAt, dateWasPrinted: false, legacyTitle: "未分類", legacyAmount: 0))
                    // 文字列がないため以降の組み立てを行いません。
                    return
                // OCR結果取得の条件分岐を閉じます。
                }
                // 認識文字と各文字の画像内位置を解析用の配列へ保存します。
                let elements: [ScannedElement] = observations.compactMap { observation in
                    // 最も確からしい候補がない認識枠は解析対象から外します。
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    // 候補文字列とVisionが返した矩形位置を解析要素にして返します。
                    return ScannedElement(text: candidate.string, frame: observation.boundingBox)
                // 認識枠を解析要素へ変換する処理を閉じます。
                }
                // 位置情報を基に文字列を読み順の行へ並べ替えます。
                let orderedRows = ReceiptTextParser.orderedRows(elements: elements)
                // 各行の文字を空白でつなぎ、行どうしを改行でつないで全文を作ります。
                let fullText = orderedRows.map { row in row.map { $0.text }.joined(separator: " ") }.joined(separator: "\n")
                // 共通パーサーで認識要素から互換用の合計金額を取得します。
                let fallbackAmount = ReceiptTextParser.totalAmount(elements: elements)
                // 共通パーサーで認識要素から互換用の店名を取得します。
                let fallbackTitle = ReceiptTextParser.title(elements: elements)
                // 全文・店名・金額を従来の返却形式にまとめます。
                // AIが印字日付を変更しないよう、純粋な日付パーサーの結果を保存します。
                let printedDate = ReceiptTextParser.printedDate(in: fullText)
                // 撮影日付をOCR開始前の日時から引き継ぎます。
                let result = ReceiptScanResult(rawText: fullText, capturedAt: capturedAt, receiptDate: printedDate ?? capturedAt, dateWasPrinted: printedDate != nil, legacyTitle: fallbackTitle, legacyAmount: fallbackAmount)
                // 正常結果を一度返して呼び出し元の待機を終えます。
                continuation.resume(returning: result)
            // バックグラウンドで実行するOCR処理を閉じます。
            }
        // 非同期継続を使う処理を閉じます。
        }
    // scan関数の定義を閉じます。
    }

    // UIImageが示す8種類の向きをVisionが使う画像向きへ対応付けます。
    private static func cgImageOrientation(from orientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        // 画像の向きごとに対応するCGImagePropertyOrientationを選びます。
        switch orientation {
        // 通常の上向き画像を同じ上向きとして扱います。
        case .up: return .up
        // 180度回転した画像を下向きとして扱います。
        case .down: return .down
        // 反時計回りに90度回転した画像を左向きとして扱います。
        case .left: return .left
        // 時計回りに90度回転した画像を右向きとして扱います。
        case .right: return .right
        // 左右反転した上向き画像を上向き反転として扱います。
        case .upMirrored: return .upMirrored
        // 左右反転した下向き画像を下向き反転として扱います。
        case .downMirrored: return .downMirrored
        // 左右反転した左向き画像を左向き反転として扱います。
        case .leftMirrored: return .leftMirrored
        // 左右反転した右向き画像を右向き反転として扱います。
        case .rightMirrored: return .rightMirrored
        // UIImageの将来の追加ケースも、既存の上向き扱いで安全に処理します。
        @unknown default: return .up
        // 画像向きの選択処理を閉じます。
        }
    // 画像向き変換関数の定義を閉じます。
    }
// ReceiptScanner型の定義を閉じます。
}
