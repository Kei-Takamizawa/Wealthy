import Foundation
import ImageIO

/// Versioned JSON format. Chat history is deliberately absent, including when decoding legacy files.
struct BackupArchive: Codable {
    static let currentSchemaVersion = 4
    let schemaVersion: Int
    let assets: [AssetDTO]
    let expenses: [ExpenseDTO]
    let recurringItems: [RecurringItemDTO]
    let categories: [CategoryDTO]
    let pointCards: [PointCardDTO]
    let receiptImagesIncluded: Bool
    let receiptImages: [ReceiptImageDTO]
    let timestamp: Date
    let appVersion: String

    struct AssetDTO: Codable {
        let name: String; let balance: Int; let colorHex: String
        var paymentMethod: String? = nil
        var isAutoCreated: Bool? = nil
        var currencyCode: String? = nil
    }
    struct ExpenseDTO: Codable {
        let title: String
        let amount: Int
        let date: Date
        let imageFilename: String?
        let assetName: String?
        let isIncome: Bool
        let categoryName: String?
        var paymentMethod: String? = nil
        var balanceApplied: Bool? = nil
        var paymentNeedsReview: Bool? = nil
        var currencyCode: String? = nil
    }
    struct RecurringItemDTO: Codable {
        let title: String; let amount: Int; let dayOfMonth: Int; let isIncome: Bool
        let assetName: String; let lastProcessedDate: Date?
        var currencyCode: String? = nil
    }
    struct CategoryDTO: Codable { let name: String; let icon: String; let colorHex: String }
    struct PointCardDTO: Codable { let name: String; let memberNumber: String; let points: Int; let expiryDate: Date? }
    struct ReceiptImageDTO: Codable { let filename: String; let data: Data }

    init(assets: [AssetDTO], expenses: [ExpenseDTO], recurringItems: [RecurringItemDTO], categories: [CategoryDTO], receiptImagesIncluded: Bool, receiptImages: [ReceiptImageDTO], pointCards: [PointCardDTO] = [], timestamp: Date = Date(), appVersion: String = "0.1.0") {
        schemaVersion = Self.currentSchemaVersion
        self.assets = assets; self.expenses = expenses; self.recurringItems = recurringItems
        self.categories = categories; self.receiptImagesIncluded = receiptImagesIncluded
        self.pointCards = pointCards
        self.receiptImages = receiptImages; self.timestamp = timestamp; self.appVersion = appVersion
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, assets, expenses, recurringItems, categories, pointCards
        case receiptImagesIncluded, receiptImages, timestamp, appVersion
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        // The v0.1.0 format has no schema version or embedded images.
        schemaVersion = try values.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        guard (1...Self.currentSchemaVersion).contains(schemaVersion) else {
            throw BackupArchiveError.unsupportedSchema
        }
        assets = try values.decode([AssetDTO].self, forKey: .assets)
        expenses = try values.decode([ExpenseDTO].self, forKey: .expenses)
        recurringItems = try values.decode([RecurringItemDTO].self, forKey: .recurringItems)
        categories = try values.decode([CategoryDTO].self, forKey: .categories)
        pointCards = schemaVersion >= 3 ? try values.decode([PointCardDTO].self, forKey: .pointCards) : []
        timestamp = try values.decode(Date.self, forKey: .timestamp)
        appVersion = try values.decode(String.self, forKey: .appVersion)
        receiptImagesIncluded = schemaVersion == 1 ? false : try values.decode(Bool.self, forKey: .receiptImagesIncluded)
        receiptImages = schemaVersion == 1 ? [] : try values.decode([ReceiptImageDTO].self, forKey: .receiptImages)
    }
}

enum BackupArchiveError: Error, LocalizedError {
    case unsupportedSchema, unsafeFilename, duplicateImage, invalidImage, invalidImageReference, missingImage, invalidRecurringDay

    var errorDescription: String? {
        let key: String
        switch self {
        case .unsupportedSchema: key = "backupUnsupportedSchema"
        case .unsafeFilename: key = "backupUnsafeFilename"
        case .duplicateImage: key = "backupDuplicateImage"
        case .invalidImage: key = "backupInvalidImage"
        case .invalidImageReference: key = "backupInvalidImageReference"
        case .missingImage: key = "backupMissingImage"
        case .invalidRecurringDay: key = "backupInvalidRecurringDay"
        }
        return AppLocalization.text(key, language: .saved)
    }
}

enum BackupArchiveCodec {
    static func isSafeFilename(_ filename: String) -> Bool {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        return !filename.isEmpty && filename.utf8.count <= 255 && filename != "." && filename != ".."
            && filename.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    static func isValidImage(_ data: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil), CGImageSourceGetCount(source) == 1 else { return false }
        guard CGImageSourceCreateImageAtIndex(source, 0, nil) != nil else { return false }
        return CGImageSourceGetStatus(source) == .statusComplete
            && CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete
    }

    static func validate(_ archive: BackupArchive) throws {
        guard (1...BackupArchive.currentSchemaVersion).contains(archive.schemaVersion) else { throw BackupArchiveError.unsupportedSchema }
        let currencyCodes = archive.assets.map(\.currencyCode) + archive.expenses.map(\.currencyCode) + archive.recurringItems.map(\.currencyCode)
        guard currencyCodes.allSatisfy({ $0 == nil || CurrencyPolicy.isSupported($0!) }) else { throw CocoaError(.fileReadCorruptFile) }
        guard archive.pointCards.allSatisfy({ $0.points >= 0 }) else { throw CocoaError(.fileReadCorruptFile) }
        var imageNames = Set<String>()
        for image in archive.receiptImages {
            guard isSafeFilename(image.filename) else { throw BackupArchiveError.unsafeFilename }
            guard imageNames.insert(image.filename).inserted else { throw BackupArchiveError.duplicateImage }
            guard isValidImage(image.data) else { throw BackupArchiveError.invalidImage }
        }
        var referencedNames = Set<String>()
        for expense in archive.expenses {
            guard let name = expense.imageFilename else { continue }
            guard isSafeFilename(name) else { throw BackupArchiveError.unsafeFilename }
            if archive.schemaVersion >= 2 {
                guard archive.receiptImagesIncluded && imageNames.contains(name) else { throw BackupArchiveError.invalidImageReference }
                referencedNames.insert(name)
            }
        }
        guard archive.receiptImagesIncluded || archive.receiptImages.isEmpty else { throw BackupArchiveError.invalidImageReference }
        guard imageNames == referencedNames else { throw BackupArchiveError.invalidImageReference }
        guard archive.recurringItems.allSatisfy({ (1...31).contains($0.dayOfMonth) }) else { throw BackupArchiveError.invalidRecurringDay }
    }

    static func decode(_ data: Data) throws -> BackupArchive {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let archive = try decoder.decode(BackupArchive.self, from: data)
        try validate(archive)
        return archive
    }

    static func encode(_ archive: BackupArchive) throws -> Data {
        try validate(archive)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(archive)
    }
}
