import Foundation
import SwiftData
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Only the role enum is stubbed; the actual chat model, backup manager, codec and finance models are compiled.
enum LocalLLMService {
    struct ChatMessage { enum MessageRole { case user, assistant, system } }
}

@MainActor
final class Checks {
    var count = 0
    func expect(_ condition: Bool, _ name: String) {
        count += 1
        guard condition else { fatalError("FAIL: \(name)") }
    }
    func rejects(_ name: String, _ action: () throws -> Void) {
        count += 1
        do { try action(); fatalError("FAIL: \(name) was accepted") } catch { }
    }
}

func png() throws -> Data {
    let context = CGContext(data: nil, width: 2, height: 2, bitsPerComponent: 8, bytesPerRow: 8,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
    let data = NSMutableData()
    let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    guard CGImageDestinationFinalize(destination) else { throw BackupArchiveError.invalidImage }
    return data as Data
}

@MainActor
func context() throws -> ModelContext {
    let schema = Schema([Asset.self, Expense.self, RecurringItem.self, Category.self, ChatMessageModel.self])
    let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
    let context = ModelContext(container)
    context.autosaveEnabled = false
    return context
}

func modified(_ data: Data, _ edit: (inout [String: Any]) -> Void) throws -> Data {
    var object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    edit(&object)
    return try JSONSerialization.data(withJSONObject: object)
}

@MainActor
func run() throws {
    let checks = Checks()
    let fm = FileManager.default
    let root = fm.temporaryDirectory.appendingPathComponent("wealthy-backup-checks-\(UUID())")
    try fm.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? fm.removeItem(at: root) }
    let sourceURL = root.appendingPathComponent("source")
    let targetURL = root.appendingPathComponent("target")
    try fm.createDirectory(at: sourceURL, withIntermediateDirectories: true)
    try fm.createDirectory(at: targetURL, withIntermediateDirectories: true)
    let source = try context()
    let sourceManager = BackupManager(imageDirectory: sourceURL)
    let image = try png()
    try image.write(to: sourceURL.appendingPathComponent("receipt.png"))
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    source.insert(Asset(name: "財布", balance: 12345, colorHex: "FFA500"))
    source.insert(Category(name: "食費", icon: "fork.knife", colorHex: "FFFFFF"))
    source.insert(Expense(title: "お店", amount: 980, date: date, imageFilename: "receipt.png", assetName: "財布", isIncome: false, categoryName: "食費"))
    source.insert(Expense(title: "共有画像", amount: 20, date: date, imageFilename: "receipt.png", isIncome: true))
    let recurring = RecurringItem(title: "定期", amount: 1200, dayOfMonth: 10, isIncome: false, assetName: "財布")
    recurring.lastProcessedDate = date
    source.insert(recurring)
    source.insert(ChatMessageModel(role: "user", content: "private-chat-sentinel"))
    try source.save()
    let summary = try sourceManager.receiptImageSummary(context: source)
    checks.expect(summary.uniqueImageCount == 1, "deduplicated image count")
    checks.expect(summary.totalBytes == image.count, "raw image byte size")
    checks.expect(summary.missingImageCount == 0, "existing images available")
    let data = try sourceManager.createBackupData(context: source, includeReceiptImages: true)
    let json = String(decoding: data, as: UTF8.self)
    checks.expect(!json.contains("private-chat-sentinel") && !json.contains("chatMessages"), "chat never exported")
    let archive = try BackupArchiveCodec.decode(data)
    checks.expect(archive.schemaVersion == 2, "version 2")
    checks.expect(archive.receiptImages.count == 1, "one image payload for two references")
    checks.expect(archive.receiptImages[0].data == image, "byte-exact embedded image")
    let target = try context()
    let targetManager = BackupManager(imageDirectory: targetURL)
    try Data("unrelated-file".utf8).write(to: targetURL.appendingPathComponent("receipt.png"))
    try Data("old-image".utf8).write(to: targetURL.appendingPathComponent("old.png"))
    target.insert(Expense(title: "old", amount: 1, date: date, imageFilename: "old.png"))
    target.insert(ChatMessageModel(role: "user", content: "old-chat"))
    try target.save()
    try targetManager.restoreBackup(data: data, context: target)
    let restored = try target.fetch(FetchDescriptor<Expense>()).sorted { $0.amount < $1.amount }
    checks.expect(restored.count == 2, "all expenses restored")
    checks.expect(restored.last?.title == "お店" && restored.last?.amount == 980, "expense facts preserved")
    checks.expect(restored.last?.date == date, "expense date preserved")
    checks.expect(restored.last?.assetName == "財布" && restored.last?.categoryName == "食費", "wallet/category preserved")
    checks.expect(restored.first?.isIncome == true, "income flag preserved")
    let restoredName = restored[0].imageFilename!
    checks.expect(restoredName == restored[1].imageFilename, "shared references remain shared")
    checks.expect(restoredName != "receipt.png", "filename remapped")
    checks.expect(try Data(contentsOf: targetURL.appendingPathComponent(restoredName)) == image, "receipt file restored exactly")
    checks.expect(try Data(contentsOf: targetURL.appendingPathComponent("receipt.png")) == Data("unrelated-file".utf8), "unrelated filename collision untouched")
    checks.expect(!fm.fileExists(atPath: targetURL.appendingPathComponent("old.png").path), "old referenced image removed after success")
    checks.expect(try target.fetchCount(FetchDescriptor<ChatMessageModel>()) == 0, "chat not restored")
    checks.expect(try target.fetch(FetchDescriptor<Asset>()).first?.balance == 12345, "asset restored")
    checks.expect(try target.fetch(FetchDescriptor<Category>()).first?.icon == "fork.knife", "category restored")
    checks.expect(try target.fetch(FetchDescriptor<RecurringItem>()).first?.lastProcessedDate == date, "recurring date restored")

    let recordsOnly = try sourceManager.createBackupData(context: source, includeReceiptImages: false)
    let recordsArchive = try BackupArchiveCodec.decode(recordsOnly)
    checks.expect(recordsArchive.receiptImages.isEmpty, "records-only has no image bytes")
    checks.expect(recordsArchive.expenses.allSatisfy { $0.imageFilename == nil }, "records-only has no broken references")
    try targetManager.restoreBackup(data: recordsOnly, context: target)
    checks.expect(try target.fetch(FetchDescriptor<Expense>()).allSatisfy { $0.imageFilename == nil }, "records-only restores without references")
    checks.expect(!fm.fileExists(atPath: targetURL.appendingPathComponent(restoredName).path), "replaced image removed")

    let legacy = try modified(recordsOnly) {
        $0.removeValue(forKey: "schemaVersion")
        $0.removeValue(forKey: "receiptImagesIncluded")
        $0.removeValue(forKey: "receiptImages")
        $0["chatMessages"] = [["role": "user", "content": "legacy-private-chat", "timestamp": "2020-01-01T00:00:00Z"]]
        var expenses = $0["expenses"] as! [[String: Any]]
        expenses[0]["imageFilename"] = "legacy-unavailable.png"
        $0["expenses"] = expenses
    }
    try targetManager.restoreBackup(data: legacy, context: target)
    checks.expect(try target.fetchCount(FetchDescriptor<Expense>()) == 2, "legacy records restored")
    checks.expect(try target.fetch(FetchDescriptor<Expense>()).allSatisfy { $0.imageFilename == nil }, "legacy path-only image references cleared")
    checks.expect(try target.fetchCount(FetchDescriptor<ChatMessageModel>()) == 0, "legacy chats ignored")
    let badChatLegacy = try modified(legacy) { $0["chatMessages"] = "malformed obsolete field" }
    try targetManager.restoreBackup(data: badChatLegacy, context: target)
    checks.expect(try target.fetchCount(FetchDescriptor<Expense>()) == 2, "obsolete chats not decoded")

    try targetManager.restoreBackup(data: data, context: target)
    let preservedName = try target.fetch(FetchDescriptor<Expense>())[0].imageFilename!
    target.insert(ChatMessageModel(role: "user", content: "keep-on-failure"))
    try target.save()
    func assertPreserved(_ label: String) throws {
        checks.expect(try target.fetchCount(FetchDescriptor<Expense>()) == 2, "\(label) retains records")
        checks.expect(try target.fetchCount(FetchDescriptor<ChatMessageModel>()) == 1, "\(label) retains current chat")
        checks.expect(try Data(contentsOf: targetURL.appendingPathComponent(preservedName)) == image, "\(label) retains original image")
    }
    let badCases: [(String, Data)] = [
        ("future schema", try modified(data) { $0["schemaVersion"] = 999 }),
        ("bad base64", try modified(data) { var images = $0["receiptImages"] as! [[String: Any]]; images[0]["data"] = "!not-base64!"; $0["receiptImages"] = images }),
        ("truncated image", try modified(data) { var images = $0["receiptImages"] as! [[String: Any]]; images[0]["data"] = image.prefix(image.count / 2).base64EncodedString(); $0["receiptImages"] = images }),
        ("bad image", try modified(data) { var images = $0["receiptImages"] as! [[String: Any]]; images[0]["data"] = Data("not-image".utf8).base64EncodedString(); $0["receiptImages"] = images }),
        ("traversal", try modified(data) { var images = $0["receiptImages"] as! [[String: Any]]; images[0]["filename"] = "../outside.png"; $0["receiptImages"] = images }),
        ("missing image ref", try modified(data) { $0["receiptImages"] = [] }),
        ("duplicate image", try modified(data) { var images = $0["receiptImages"] as! [[String: Any]]; images.append(images[0]); $0["receiptImages"] = images }),
        ("records-only unexpected ref", try modified(data) { $0["receiptImagesIncluded"] = false }),
        ("invalid recurring day", try modified(data) { var items = $0["recurringItems"] as! [[String: Any]]; items[0]["dayOfMonth"] = 32; $0["recurringItems"] = items }),
        ("truncated JSON", data.prefix(data.count / 2))
    ]
    for (name, invalid) in badCases {
        checks.rejects(name) { try targetManager.restoreBackup(data: invalid, context: target) }
        try assertPreserved(name)
    }
    checks.expect(!fm.fileExists(atPath: root.appendingPathComponent("outside.png").path), "no traversal file written")
    checks.expect(try fm.contentsOfDirectory(atPath: targetURL.path).allSatisfy { !$0.hasPrefix(".wealthy-restore-") }, "staging cleaned")
    var saveCalls = 0
    checks.rejects("injected database commit failure") {
        try targetManager.restoreBackup(data: recordsOnly, context: target, saveContext: {
            saveCalls += 1
            if saveCalls == 2 { throw CocoaError(.fileWriteUnknown) }
            try target.save()
        })
    }
    try assertPreserved("database commit rollback")
    checks.expect(try target.fetch(FetchDescriptor<Expense>()).contains { $0.imageFilename == preservedName }, "rollback keeps image reference")
    let filesBeforeRollback = try fm.contentsOfDirectory(atPath: targetURL.path).sorted()
    saveCalls = 0
    checks.rejects("injected image restore commit failure") {
        try targetManager.restoreBackup(data: data, context: target, saveContext: {
            saveCalls += 1
            if saveCalls == 2 { throw CocoaError(.fileWriteUnknown) }
            try target.save()
        })
    }
    try assertPreserved("image restore commit rollback")
    checks.expect(try fm.contentsOfDirectory(atPath: targetURL.path).sorted() == filesBeforeRollback, "rollback removes installed images and staging")
    let blockedURL = root.appendingPathComponent("blocked-directory")
    try Data("file blocks directory".utf8).write(to: blockedURL)
    checks.rejects("filesystem staging failure") { try BackupManager(imageDirectory: blockedURL).restoreBackup(data: data, context: target) }
    try assertPreserved("filesystem failure")
    source.insert(Expense(title: "missing", amount: 99, date: date, imageFilename: "missing.jpg"))
    let missingSummary = try sourceManager.receiptImageSummary(context: source)
    checks.expect(missingSummary.missingImageCount == 1, "missing image reported")
    checks.expect(missingSummary.totalBytes == image.count, "missing image excluded from bytes")
    checks.rejects("include missing image") { _ = try sourceManager.createBackupData(context: source, includeReceiptImages: true) }
    checks.expect(try BackupArchiveCodec.decode(sourceManager.createBackupData(context: source, includeReceiptImages: false)).expenses.count == 3, "records-only retains missing-image records")
    try fm.createSymbolicLink(at: sourceURL.appendingPathComponent("link.png"), withDestinationURL: sourceURL.appendingPathComponent("receipt.png"))
    source.insert(Expense(title: "symlink", amount: 1, date: date, imageFilename: "link.png"))
    checks.expect(try sourceManager.receiptImageSummary(context: source).missingImageCount == 2, "symlink not exported")
    checks.expect(!BackupArchiveCodec.isSafeFilename("/tmp/image.png") && !BackupArchiveCodec.isSafeFilename("..") && !BackupArchiveCodec.isSafeFilename("a\\b.png"), "absolute and non-leaf paths rejected")
    print("PASS: \(checks.count) backup checks (actual SwiftData in memory and temporary receipt files)")
}
try MainActor.assumeIsolated { try run() }
