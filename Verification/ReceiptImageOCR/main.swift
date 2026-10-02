import Foundation
import Vision
import ImageIO
import FoundationModels

struct StoredElement: Codable {
    let text: String
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

struct Measurement: Codable {
    let file: String
    let rows: [String]
    let elements: [StoredElement]
    let amount: Int
    let title: String
    let printedDate: String?
    // AIに依存しない用途の分類結果を保持します。
    let category: String
    // 実測処理時間を秒で保持します。
    let seconds: Double
    let error: String?
}
var results: [Measurement] = []
let inputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let files = try FileManager.default.contentsOfDirectory(at: inputDirectory, includingPropertiesForKeys: nil).filter { ["jpg", "jpeg", "png", "webp"].contains($0.pathExtension.lowercased()) }.sorted { $0.lastPathComponent < $1.lastPathComponent }
for file in files {
    let started = Date()
    do {
        guard let source = CGImageSourceCreateWithURL(file as CFURL, nil), let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { throw NSError(domain: "ReceiptImageOCR", code: 1) }
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let orientation = CGImagePropertyOrientation(rawValue: properties?[kCGImagePropertyOrientation] as? UInt32 ?? 1) ?? .up
        let request = VNRecognizeTextRequest()
        request.recognitionLanguages = ["ja-JP", "en-US"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.customWords = ["合計", "総合計", "税込合計", "お支払", "請求金額", "領収書", "小計", "お預り", "お釣り", "TOTAL", "Total", "total", "円", "税込"]
        request.minimumTextHeight = 0
        try VNImageRequestHandler(cgImage: image, orientation: orientation, options: [:]).perform([request])
        let elements = (request.results ?? []).compactMap { observation -> ReceiptTextParser.Element? in
            guard let text = observation.topCandidates(1).first?.string else { return nil }
            return ReceiptTextParser.Element(text: text, frame: observation.boundingBox)
        }
        let rows = ReceiptTextParser.orderedRows(elements: elements).map { $0.map(\.text).joined(separator: " ") }
        results.append(Measurement(file: file.lastPathComponent, rows: rows, elements: elements.map { StoredElement(text: $0.text, x: $0.frame.minX, y: $0.frame.minY, width: $0.frame.width, height: $0.frame.height) }, amount: ReceiptTextParser.totalAmount(elements: elements), title: ReceiptTextParser.title(elements: elements), printedDate: ReceiptTextParser.printedDate(in: rows.joined(separator: "\n")).map { DateFormatter.receiptDateFormatter.string(from: $0) }, category: ReceiptCategoryPolicy.suggestedCategory(text: rows.joined(separator: "\n"), existingCategories: ["食費", "交通費", "日用品", "趣味", "衣服", "その他"]), seconds: Date().timeIntervalSince(started), error: nil))
    } catch {
        results.append(Measurement(file: file.lastPathComponent, rows: [], elements: [], amount: 0, title: "", printedDate: nil, category: "未分類", seconds: Date().timeIntervalSince(started), error: String(describing: error)))
    }
}
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
try encoder.encode(results).write(to: outputURL)
if results.contains(where: { $0.error != nil }) { throw NSError(domain: "ReceiptImageOCR", code: 2, userInfo: [NSLocalizedDescriptionKey: "One or more OCR operations failed; inspect the private result JSON."]) }
print("Processed \(results.count) receipt images. OCR text stays in \(outputURL.path).")
print("Foundation Models availability: \(SystemLanguageModel.default.availability)")

// 日付表記の比較に使う書式を明示します。
extension DateFormatter {
    // タイムゾーンはアプリの日付と同じ端末設定を使用します。
    static var receiptDateFormatter: DateFormatter {
        // 年月日だけを比較する書式を生成します。
        let formatter = DateFormatter()
        // 西暦の年月日を固定順序にします。
        formatter.calendar = Calendar(identifier: .gregorian)
        // 日付文字列をYYYY-MM-DDで返します。
        formatter.dateFormat = "yyyy-MM-dd"
        // 作成した書式を返します。
        return formatter
    // 書式の作成処理を閉じます。
    }
// 日付書式の拡張を閉じます。
}
