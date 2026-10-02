import Foundation
import FoundationModels

/// Runs the app's real receipt method locally; inputs and results remain outside Git.
@main
struct EvaluateReceiptModel {
    @MainActor
    static func main() async throws {
        let input = URL(fileURLWithPath: CommandLine.arguments[1])
        let output = URL(fileURLWithPath: CommandLine.arguments[2])
        let records = try JSONSerialization.jsonObject(with: Data(contentsOf: input)) as! [[String: Any]]
        UserDefaults.standard.set("日本語", forKey: "selectedLanguage")
        let service = LocalLLMService()
        guard service.isReady else { throw NSError(domain: "ReceiptModelEvaluation", code: 1, userInfo: [NSLocalizedDescriptionKey: service.loadStatus]) }
        let categories = ["食費", "交通費", "日用品", "趣味", "衣服", "その他"]
        var results: [[String: Any]] = []
        for record in records {
            let text = (record["rows"] as? [String] ?? []).joined(separator: "\n")
            let started = Date()
            do {
                let json = try await service.extractReceiptData(prompt: text, categories: categories)
                let fields = try JSONSerialization.jsonObject(with: Data(json.utf8))
                results.append(["file": record["file"]!, "fields": fields, "seconds": Date().timeIntervalSince(started)])
            } catch {
                results.append(["file": record["file"]!, "error": String(describing: error), "seconds": Date().timeIntervalSince(started)])
            }
            try JSONSerialization.data(withJSONObject: results, options: [.prettyPrinted, .sortedKeys]).write(to: output)
            print("Processed \(results.count)/\(records.count) local model receipts")
        }
        for (index, text) in ["領収書 木材 鉄筋 合計 2500円 2024年6月1日", "領収書 処方箋 調剤費 合計 1200円 2024年6月1日", "RECEIPT bookstore paperback TOTAL USD$ 12.00 04/07/2024"].enumerated() {
            UserDefaults.standard.set(index == 2 ? "English" : "日本語", forKey: "selectedLanguage")
            do {
                let json = try await service.extractReceiptData(prompt: text, categories: [])
                results.append(["case": "no_existing_categories_\(index)", "fields": try JSONSerialization.jsonObject(with: Data(json.utf8))])
            } catch {
                results.append(["case": "no_existing_categories_\(index)", "error": String(describing: error)])
            }
        }
        try JSONSerialization.data(withJSONObject: results, options: [.prettyPrinted, .sortedKeys]).write(to: output)
        print("Completed \(results.count) on-device model measurements")
    }
}
