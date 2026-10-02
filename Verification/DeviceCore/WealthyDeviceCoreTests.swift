import XCTest
import UIKit
import FoundationModels
import SwiftData
@testable import Wealthy

@MainActor
final class WealthyDeviceCoreTests: XCTestCase {
    private func context() throws -> ModelContext {
        let schema = Schema([Asset.self, Expense.self, RecurringItem.self, Category.self, PointCard.self, ChatMessageModel.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let context = ModelContext(container); context.autosaveEnabled = false
        return context
    }

    func testLedgerAndDiscardedEdits() throws {
        let context = try context()
        let draft = Expense(title: "Device receipt", amount: 1200, date: Date(), assetName: nil, paymentMethod: "cash", balanceApplied: false)
        try ExpenseLedger.saveDraft(draft, replacing: nil, context: context)
        let wallet = try XCTUnwrap(context.fetch(FetchDescriptor<Asset>()).first)
        XCTAssertEqual(wallet.balance, -1200); XCTAssertTrue(wallet.isAutoCreated)
        let edit = ExpenseLedger.draft(for: draft); edit.amount = 700
        try context.save()
        XCTAssertEqual(draft.amount, 1200); XCTAssertEqual(wallet.balance, -1200)
        try ExpenseLedger.saveDraft(edit, replacing: draft, context: context)
        XCTAssertEqual(wallet.balance, -700)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Expense>()), 1)
        try ExpenseLedger.delete(draft, context: context)
        XCTAssertEqual(wallet.balance, 0)
    }

    func testBackupWithPointsImagesAndNoChat() throws {
        let context = try context()
        let filename = "device-verification-\(UUID().uuidString).png"
        let imageURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
        let image = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { renderer in
            UIColor.orange.setFill(); renderer.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
        let originalImageData = try XCTUnwrap(image.pngData())
        try originalImageData.write(to: imageURL)
        defer { try? FileManager.default.removeItem(at: imageURL) }
        context.insert(Asset(name: "Device Cash", balance: -1200, paymentMethod: "cash", isAutoCreated: true))
        context.insert(Expense(title: "Device receipt", amount: 1200, date: Date(), imageFilename: filename, assetName: "Device Cash", paymentMethod: "cash"))
        context.insert(PointCard(name: "Device points", memberNumber: "test-only", points: 900))
        context.insert(ChatMessageModel(role: "user", content: "device-verification-chat-only"))
        try context.save()
        let manager = BackupManager.shared
        let summary = try manager.receiptImageSummary(context: context)
        XCTAssertEqual(summary.uniqueImageCount, 1); XCTAssertGreaterThan(summary.totalBytes, 0)
        let data = try manager.createBackupData(context: context, includeReceiptImages: true)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["schemaVersion"] as? Int, 4)
        XCTAssertNil(json["chatMessages"])
        XCTAssertNil(json["chats"])
        XCTAssertFalse(String(decoding: data, as: UTF8.self).contains("device-verification-chat-only"))
        let restored = try self.context()
        let backupURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
        try data.write(to: backupURL)
        defer { try? FileManager.default.removeItem(at: backupURL) }
        try manager.restoreBackup(from: backupURL, context: restored)
        XCTAssertEqual(try restored.fetch(FetchDescriptor<PointCard>()).first?.points, 900)
        XCTAssertEqual(try restored.fetch(FetchDescriptor<Asset>()).first?.balance, -1200)
        let restoredFilename = try XCTUnwrap(restored.fetch(FetchDescriptor<Expense>()).first?.imageFilename)
        XCTAssertNotEqual(restoredFilename, filename)
        let restoredImageURL = manager.imageDirectory.appendingPathComponent(restoredFilename)
        defer { try? FileManager.default.removeItem(at: restoredImageURL) }
        XCTAssertTrue(FileManager.default.fileExists(atPath: restoredImageURL.path))
        let restoredImageData = try Data(contentsOf: restoredImageURL)
        XCTAssertEqual(restoredImageData, originalImageData)
        XCTAssertNotNil(UIImage(data: restoredImageData))
    }


    func testLargeHistoricalTotalsRemainDisplayable() throws {
        let context = try context()
        let maximum = Expense(title: "Large expense", amount: Int.max, date: Date(), paymentMethod: "cash", balanceApplied: false)
        let one = Expense(title: "Small expense", amount: 1, date: Date(), paymentMethod: "cash", balanceApplied: false)
        for expense in [maximum, one] { try ExpenseLedger.saveDraft(expense, replacing: nil, context: context) }
        XCTAssertEqual(try context.fetch(FetchDescriptor<Asset>()).first?.balance, Int.min)
        let expected = Decimal(string: "9223372036854775808")!
        let daily = ModernBarChart(month: Date(), expenses: [maximum, one], lm: LanguageManager()).dailyData
        XCTAssertEqual(daily.first { $0.day == Calendar.current.component(.day, from: Date()) }?.amount, expected)
        let pie = ModernPieChart(expenses: [maximum, one], categories: [], lm: LanguageManager()).data
        XCTAssertEqual(pie.first?.amount, expected)
        XCTAssertFalse(AppLocalization.amount(expected, currencyCode: "JPY", language: .english).isEmpty)
    }

    func testMultipleCurrencyLedgerAndBackup() throws {
        let context = try context()
        let yen = Expense(title: "JPY expense", amount: 1200, date: Date(), assetName: nil, paymentMethod: "cash", balanceApplied: false)
        let dollars = Expense(title: "USD income", amount: 10000, date: Date(), assetName: nil, isIncome: true, paymentMethod: "cash", balanceApplied: false, currencyCode: "USD")
        let dollarExpense = Expense(title: "USD expense", amount: 1234, date: Date(), assetName: nil, paymentMethod: "cash", balanceApplied: false, currencyCode: "USD")
        let dinars = Expense(title: "KWD expense", amount: 12345, date: Date(), assetName: nil, paymentMethod: "cash", balanceApplied: false, currencyCode: "KWD")
        for entry in [yen, dollars, dollarExpense, dinars] { try ExpenseLedger.saveDraft(entry, replacing: nil, context: context) }
        let wallets = try context.fetch(FetchDescriptor<Asset>())
        let balances = Dictionary(uniqueKeysWithValues: wallets.map { ($0.effectiveCurrencyCode, $0.balance) })
        XCTAssertEqual(balances, ["JPY": -1200, "USD": 8766, "KWD": -12345])
        XCTAssertEqual(CurrencyPolicy.inputText(1234, currencyCode: "USD", locale: Locale(identifier: "en_US")), "12.34")
        XCTAssertEqual(CurrencyPolicy.inputText(12345, currencyCode: "KWD", locale: Locale(identifier: "en_US")), "12.345")
        let data = try BackupManager.shared.createBackupData(context: context, includeReceiptImages: false)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("currency-\(UUID().uuidString).json")
        try data.write(to: url); defer { try? FileManager.default.removeItem(at: url) }
        let restored = try self.context()
        try BackupManager.shared.restoreBackup(from: url, context: restored)
        let restoredBalances = Dictionary(uniqueKeysWithValues: try restored.fetch(FetchDescriptor<Asset>()).map { ($0.effectiveCurrencyCode, $0.balance) })
        XCTAssertEqual(restoredBalances, balances)
        XCTAssertEqual(try restored.fetch(FetchDescriptor<Expense>()).first { $0.title == "USD expense" }?.amount, 1234)
        XCTAssertEqual(try restored.fetch(FetchDescriptor<Expense>()).first { $0.title == "KWD expense" }?.effectiveCurrencyCode, "KWD")
    }

    func testReceiptImageMeasurement() async throws {
        let bundle = Bundle(for: Self.self)
        guard let manifest = bundle.url(forResource: "manifest", withExtension: "json", subdirectory: "ReceiptFixtures") else {
            throw XCTSkip("No private receipt fixtures supplied to the temporary test project.")
        }
        let labels = try JSONSerialization.jsonObject(with: Data(contentsOf: manifest)) as! [[String: Any]]
        let oldChoice = UserDefaults.standard.object(forKey: "selectedLanguage")
        defer {
            if let oldChoice { UserDefaults.standard.set(oldChoice, forKey: "selectedLanguage") }
            else { UserDefaults.standard.removeObject(forKey: "selectedLanguage") }
        }
        UserDefaults.standard.set("日本語", forKey: "selectedLanguage")
        let service = LocalLLMService()
        XCTAssertTrue(service.isReady, service.loadStatus)
        let captureDate = Date(timeIntervalSince1970: 1_800_000_000)
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let categories = ["食費", "交通費", "日用品", "趣味", "衣服", "その他"]
        var results: [[String: Any]] = []
        for label in labels {
            let id = label["id"] as! String
            let file = bundle.url(forResource: id, withExtension: label["extension"] as? String, subdirectory: "ReceiptFixtures")!
            let image = try XCTUnwrap(UIImage(contentsOfFile: file.path))
            let start = Date()
            let scan = await ReceiptScanner.scan(image: image, capturedAt: captureDate)
            let payment = ReceiptPaymentPolicy.detect(scan.rawText)
            var result: [String: Any] = ["id": id, "amount": scan.legacyAmount,
                "date": formatter.string(from: scan.receiptDate), "dateWasPrinted": scan.dateWasPrinted,
                "rawText": scan.rawText, "payment": payment.method ?? "review", "paymentNeedsReview": payment.needsReview]
            result["expected"] = label
            do {
                let modelJSON = try await service.extractReceiptData(prompt: scan.rawText, categories: categories)
                result["model"] = try JSONSerialization.jsonObject(with: Data(modelJSON.utf8))
            } catch {
                result["modelError"] = error.localizedDescription
                result["fallbackCategory"] = ReceiptCategoryPolicy.suggestedCategory(
                    text: scan.rawText, existingCategories: categories, language: "ja")
            }
            result["seconds"] = Date().timeIntervalSince(start)
            if !scan.dateWasPrinted { XCTAssertEqual(scan.receiptDate, captureDate, id) }
            results.append(result)
            print("DEVICE_RECEIPT_MEASUREMENT: \(results.count)/\(labels.count)")
        }
        let locales = Dictionary(uniqueKeysWithValues: AppLanguage.allCases.map {
            ($0.languageIdentifier, SystemLanguageModel.default.supportsLocale($0.locale))
        })
        let data = try JSONSerialization.data(withJSONObject: ["receipts":results, "supportedLocales":locales], options: [.prettyPrinted, .sortedKeys])
        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")
        attachment.name = "private-device-receipt-measurement"; attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertEqual(results.count, labels.count)
    }
}
