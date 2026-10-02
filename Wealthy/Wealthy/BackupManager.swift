import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ReceiptImageSummary {
    let uniqueImageCount: Int
    let totalBytes: Int64
    let missingImageCount: Int
}

struct BackupManager {
    static let shared = BackupManager()
    let imageDirectory: URL

    init(imageDirectory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]) {
        self.imageDirectory = imageDirectory
    }

    private func imageData(named filename: String) throws -> Data {
        guard BackupArchiveCodec.isSafeFilename(filename) else { throw BackupArchiveError.unsafeFilename }
        let url = imageDirectory.appendingPathComponent(filename)
        let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
        guard values.isRegularFile == true, values.isSymbolicLink != true else { throw BackupArchiveError.missingImage }
        return try Data(contentsOf: url)
    }

    @MainActor
    func receiptImageSummary(context: ModelContext) throws -> ReceiptImageSummary {
        let names = Set(try context.fetch(FetchDescriptor<Expense>()).compactMap(\.imageFilename))
        var bytes: Int64 = 0
        var missing = 0
        for name in names {
            do {
                let data = try imageData(named: name)
                guard BackupArchiveCodec.isValidImage(data) else { throw BackupArchiveError.invalidImage }
                bytes += Int64(data.count)
            } catch { missing += 1 }
        }
        return ReceiptImageSummary(uniqueImageCount: names.count - missing, totalBytes: bytes, missingImageCount: missing)
    }

    @MainActor
    func createBackupData(context: ModelContext, includeReceiptImages: Bool) throws -> Data {
        let assets = try context.fetch(FetchDescriptor<Asset>())
        let expenses = try context.fetch(FetchDescriptor<Expense>())
        let recurring = try context.fetch(FetchDescriptor<RecurringItem>())
        let categories = try context.fetch(FetchDescriptor<Category>())
        let pointCards = try context.fetch(FetchDescriptor<PointCard>())
        var imageDataByName: [String: Data] = [:]
        if includeReceiptImages {
            // All referenced images must be readable; records-only remains available if any are missing.
            for name in Set(expenses.compactMap(\.imageFilename)) {
                let data: Data
                do { data = try imageData(named: name) } catch { throw BackupArchiveError.missingImage }
                guard BackupArchiveCodec.isValidImage(data) else { throw BackupArchiveError.invalidImage }
                imageDataByName[name] = data
            }
        }
        let archive = BackupArchive(
            assets: assets.map { .init(name: $0.name, balance: $0.balance, colorHex: $0.colorHex, paymentMethod: $0.paymentMethod, isAutoCreated: $0.isAutoCreated, currencyCode: $0.currencyCode) },
            expenses: expenses.map { .init(title: $0.title, amount: $0.amount, date: $0.date,
                imageFilename: $0.imageFilename.flatMap { imageDataByName[$0] == nil ? nil : $0 },
                assetName: $0.assetName, isIncome: $0.isIncome, categoryName: $0.categoryName,
                paymentMethod: $0.paymentMethod, balanceApplied: $0.balanceApplied, paymentNeedsReview: $0.paymentNeedsReview, currencyCode: $0.currencyCode) },
            recurringItems: recurring.map { .init(title: $0.title, amount: $0.amount, dayOfMonth: $0.dayOfMonth,
                isIncome: $0.isIncome, assetName: $0.assetName, lastProcessedDate: $0.lastProcessedDate, currencyCode: $0.currencyCode) },
            categories: categories.map { .init(name: $0.name, icon: $0.icon, colorHex: $0.colorHex) },
            receiptImagesIncluded: includeReceiptImages,
            receiptImages: imageDataByName.keys.sorted().map { .init(filename: $0, data: imageDataByName[$0]!) },
            pointCards: pointCards.map { .init(name: $0.name, memberNumber: $0.memberNumber, points: $0.points, expiryDate: $0.expiryDate) }
        )
        return try BackupArchiveCodec.encode(archive)
    }

    @MainActor
    func createBackupURL(context: ModelContext, includeReceiptImages: Bool = false) throws -> URL {
        let data = try createBackupData(context: context, includeReceiptImages: includeReceiptImages)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("wealthy_backup_\(UUID().uuidString).json")
        try data.write(to: url, options: .atomic)
        return url
    }

    @MainActor
    func restoreBackup(from url: URL, context: ModelContext) throws {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        try restoreBackup(data: Data(contentsOf: url), context: context)
    }

    @MainActor
    func restoreBackup(data: Data, context: ModelContext, saveContext: (() throws -> Void)? = nil) throws {
        // Validate the entire archive before touching persisted records or receipt files.
        let archive = try BackupArchiveCodec.decode(data)
        let save = saveContext ?? { try context.save() }
        let fm = FileManager.default
        try fm.createDirectory(at: imageDirectory, withIntermediateDirectories: true)
        let staging = imageDirectory.appendingPathComponent(".wealthy-restore-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: staging, withIntermediateDirectories: false)
        defer { try? fm.removeItem(at: staging) }
        var filenames: [String: String] = [:]
        var installedURLs: [URL] = []
        var contextChanged = false
        do {
            for image in archive.receiptImages {
                // Fresh names prevent overwrite of both active and unrelated existing files.
                let newName = "\(UUID().uuidString).receipt"
                filenames[image.filename] = newName
                try image.data.write(to: staging.appendingPathComponent(newName), options: .atomic)
            }
            // Persist current edits before the replace transaction, so rollback preserves them.
            try save()
            let oldAssets = try context.fetch(FetchDescriptor<Asset>())
            let oldExpenses = try context.fetch(FetchDescriptor<Expense>())
            let oldRecurring = try context.fetch(FetchDescriptor<RecurringItem>())
            let oldCategories = try context.fetch(FetchDescriptor<Category>())
            let oldChats = try context.fetch(FetchDescriptor<ChatMessageModel>())
            let oldPointCards = try context.fetch(FetchDescriptor<PointCard>())
            let oldNames = Set(oldExpenses.compactMap(\.imageFilename))
            for name in filenames.values {
                let destination = imageDirectory.appendingPathComponent(name)
                try fm.moveItem(at: staging.appendingPathComponent(name), to: destination)
                installedURLs.append(destination)
            }
            contextChanged = true
            // Individual deletes participate in save/rollback; bulk model deletes do not.
            oldAssets.forEach { context.delete($0) }
            oldExpenses.forEach { context.delete($0) }
            oldRecurring.forEach { context.delete($0) }
            oldCategories.forEach { context.delete($0) }
            oldChats.forEach { context.delete($0) }
            oldPointCards.forEach { context.delete($0) }
            for dto in archive.assets { context.insert(Asset(name: dto.name, balance: dto.balance, colorHex: dto.colorHex, paymentMethod: dto.paymentMethod, isAutoCreated: dto.isAutoCreated ?? false, currencyCode: dto.currencyCode)) }
            for dto in archive.expenses {
                context.insert(Expense(title: dto.title, amount: dto.amount, date: dto.date,
                    imageFilename: dto.imageFilename.flatMap { filenames[$0] }, assetName: dto.assetName,
                    isIncome: dto.isIncome, categoryName: dto.categoryName, paymentMethod: dto.paymentMethod,
                    balanceApplied: dto.balanceApplied ?? true, paymentNeedsReview: dto.paymentNeedsReview ?? false, currencyCode: dto.currencyCode))
            }
            for dto in archive.recurringItems {
                let item = RecurringItem(title: dto.title, amount: dto.amount, dayOfMonth: dto.dayOfMonth, isIncome: dto.isIncome, assetName: dto.assetName, currencyCode: dto.currencyCode)
                item.lastProcessedDate = dto.lastProcessedDate
                context.insert(item)
            }
            for dto in archive.categories { context.insert(Category(name: dto.name, icon: dto.icon, colorHex: dto.colorHex)) }
            for dto in archive.pointCards { context.insert(PointCard(name: dto.name, memberNumber: dto.memberNumber, points: dto.points, expiryDate: dto.expiryDate)) }
            try save()
            // Remove only formerly referenced safe regular files after a successful database commit.
            for name in oldNames where BackupArchiveCodec.isSafeFilename(name) {
                let url = imageDirectory.appendingPathComponent(name)
                if let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey]),
                   values.isRegularFile == true, values.isSymbolicLink != true { try? fm.removeItem(at: url) }
            }
        } catch {
            if contextChanged { context.rollback() }
            installedURLs.forEach { try? fm.removeItem(at: $0) }
            throw error
        }
    }
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data = Data()) { self.data = data }
    init(text: String) { data = Data(text.utf8) }
    init(configuration: ReadConfiguration) throws {
        guard let contents = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        data = contents
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
