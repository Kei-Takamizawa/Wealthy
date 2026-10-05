import Foundation

/// One unique referenced receipt filename and its original image bytes.
public struct BackupImage: Codable, Sendable, Equatable {
    public var fileName: String
    public var data: Data
    public init(fileName: String, data: Data) { self.fileName = fileName; self.data = data }
}

/// The count and byte size of unique receipt files referenced by entries.
public struct ImageSize: Codable, Sendable, Equatable {
    public var count: Int
    public var bytes: Int
    public init(count: Int, bytes: Int) { self.count = count; self.bytes = bytes }
}

/// Version 1 JSON archive, independent of the legacy application's backup format.
/// Omitting images preserves attachment metadata; absent image files are then permitted.
public struct LedgerBackupArchive: Codable, Sendable, Equatable {
    public static let currentFormat = "wealthy-ledger"
    public static let currentVersion = 1
    public var format: String
    public var version: Int
    public var exportDate: Date
    public var appVersion: String
    public var coreVersion: String
    public var state: LedgerState
    public var receiptImagesIncluded: Bool
    public var images: [BackupImage]

    public init(format: String = Self.currentFormat, version: Int = Self.currentVersion, exportDate: Date,
                appVersion: String, coreVersion: String, state: LedgerState,
                receiptImagesIncluded: Bool = false, images: [BackupImage] = []) {
        self.format = format; self.version = version; self.exportDate = exportDate
        self.appVersion = appVersion; self.coreVersion = coreVersion; self.state = state
        self.receiptImagesIncluded = receiptImagesIncluded; self.images = images
    }
}

/// Export and replacement restore share domain validation and transactional receipt writes.
@MainActor
public enum LedgerBackup {
    /// Measures each referenced filename once without loading image data into memory.
    public static func size(in core: LedgerCore) throws -> ImageSize {
        let state = try core.snapshot()
        try CoreValidation.validate(state)
        let names = referencedNames(in: state)
        var total = 0
        for name in names.sorted() {
            let attributes = try regularFileAttributes(name, directory: core.store.receiptsDirectory)
            guard let number = attributes[.size] as? NSNumber, number.uint64Value <= UInt64(Int.max) else {
                throw CoreError.invalidField("imageBytes", nil)
            }
            let sum = total.addingReportingOverflow(number.intValue)
            guard !sum.overflow else { throw CoreError.invalidField("imageBytes", nil) }
            total = sum.partialValue
        }
        return ImageSize(count: names.count, bytes: total)
    }

    /// Exports all records and optionally every referenced image, deduplicated by filename.
    /// Numeric Date encoding preserves subsecond timestamps for exact value round trips.
    public static func export(_ core: LedgerCore, includeImages: Bool, now: Date,
                              appVersion: String, coreVersion: String) throws -> Data {
        let state = try core.snapshot()
        try CoreValidation.validate(state)
        var images: [BackupImage] = []
        if includeImages {
            for name in referencedNames(in: state).sorted() {
                _ = try regularFileAttributes(name, directory: core.store.receiptsDirectory)
                let bytes: Data
                do { bytes = try Data(contentsOf: core.store.receiptsDirectory.appendingPathComponent(name)) }
                catch { throw CoreError.fileFailure(name) }
                guard ReceiptFiles.isValidImage(bytes) else { throw CoreError.invalidImage(name) }
                images.append(BackupImage(fileName: name, data: bytes))
            }
        }
        let archive = LedgerBackupArchive(exportDate: now, appVersion: appVersion, coreVersion: coreVersion,
                                          state: state, receiptImagesIncluded: includeImages, images: images)
        try validate(archive)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        do { return try encoder.encode(archive) }
        catch { throw CoreError.malformedBackup }
    }

    /// Replaces all records only after complete validation, retaining undo history on failure.
    /// Records-only restores retain only hash-matching local images. Successful restores clear undo.
    public static func restore(_ data: Data, into core: LedgerCore) throws {
        let archive = try decode(data)
        try validate(archive)
        let images = Dictionary(uniqueKeysWithValues: archive.images.map { ($0.fileName, $0.data) })
        var omitted = referencedNames(in: archive.state).subtracting(images.keys)
        if !archive.receiptImagesIncluded {
            let referenced = Set(archive.state.entries.compactMap(\.receiptID))
            let receipts = Dictionary(grouping: archive.state.receipts.filter { referenced.contains($0.id) }, by: \.fileName)
            for name in omitted.sorted() {
                guard let archivedReceipts = receipts[name], archivedReceipts.allSatisfy({ $0.imageSHA256 != nil }) else { continue }
                if let hash = try ReceiptFiles.imageHash(named: name, directory: core.store.receiptsDirectory),
                   archivedReceipts.allSatisfy({ $0.imageSHA256 == hash }) {
                    omitted.remove(name)
                }
            }
        }
        let filesChanged = try ReceiptFiles.changes(images, directory: core.store.receiptsDirectory, removing: omitted)
        let recordsChanged = core.state != archive.state
        try ReceiptFiles.write(images, directory: core.store.receiptsDirectory, removing: omitted) {
            if recordsChanged { try core.store.replace(archive.state) }
            else { try core.commit(core.state, filesChanged: filesChanged) }
        }
        if recordsChanged { core.acceptRestoredState(archive.state, filesChanged: filesChanged) }
        else { core.clearUndoHistory() }
    }

    private struct Header: Decodable {
        var format: String
        var version: Int
    }

    private static func decode(_ data: Data) throws -> LedgerBackupArchive {
        let object: [String: Any]
        do {
            guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw CoreError.malformedBackup
            }
            object = dictionary
        } catch { throw CoreError.malformedBackup }
        if object["format"] == nil {
            if let version = object["schemaVersion"] as? Int, (1...4).contains(version) {
                throw CoreError.legacyBackupNotSupported
            }
            // The oldest legacy archive omitted schemaVersion, implying version 1.
            if object["assets"] != nil && object["expenses"] != nil { throw CoreError.legacyBackupNotSupported }
        }
        let decoder = JSONDecoder()
        let header: Header
        do { header = try decoder.decode(Header.self, from: data) }
        catch { throw CoreError.malformedBackup }
        guard header.format == LedgerBackupArchive.currentFormat else { throw CoreError.invalidBackupFormat(header.format) }
        guard header.version == LedgerBackupArchive.currentVersion else { throw CoreError.unsupportedBackupVersion(header.version) }
        do { return try decoder.decode(LedgerBackupArchive.self, from: data) }
        catch let error as CoreError { throw error }
        catch { throw CoreError.malformedBackup }
    }

    private static func validate(_ archive: LedgerBackupArchive) throws {
        guard archive.format == LedgerBackupArchive.currentFormat else { throw CoreError.invalidBackupFormat(archive.format) }
        guard archive.version == LedgerBackupArchive.currentVersion else { throw CoreError.unsupportedBackupVersion(archive.version) }
        try CoreValidation.validate(archive.state)
        var imageNames = Set<String>()
        for image in archive.images {
            guard ReceiptFiles.isSafeFilename(image.fileName) else { throw CoreError.unsafeFilename(image.fileName) }
            guard imageNames.insert(image.fileName).inserted else { throw CoreError.invalidField("duplicateImage", nil) }
            guard ReceiptFiles.isValidImage(image.data) else { throw CoreError.invalidImage(image.fileName) }
        }
        if archive.receiptImagesIncluded {
            let referenced = referencedNames(in: archive.state)
            if let name = referenced.subtracting(imageNames).sorted().first { throw CoreError.invalidImage(name) }
            if let name = imageNames.subtracting(referenced).sorted().first { throw CoreError.invalidImage(name) }
        } else if !archive.images.isEmpty {
            throw CoreError.invalidField("receiptImagesIncluded", nil)
        }
    }

    private static func referencedNames(in state: LedgerState) -> Set<String> {
        let ids = Set(state.entries.compactMap(\.receiptID))
        return Set(state.receipts.filter { ids.contains($0.id) }.map(\.fileName))
    }

    /// Refuses nonregular files and symlink directories before reading image bytes.
    private static func regularFileAttributes(_ name: String, directory: URL) throws -> [FileAttributeKey: Any] {
        guard ReceiptFiles.isSafeFilename(name) else { throw CoreError.unsafeFilename(name) }
        let directoryAttributes: [FileAttributeKey: Any]
        let attributes: [FileAttributeKey: Any]
        do {
            directoryAttributes = try FileManager.default.attributesOfItem(atPath: directory.path)
            attributes = try FileManager.default.attributesOfItem(atPath: directory.appendingPathComponent(name).path)
        } catch { throw CoreError.fileFailure(name) }
        guard directoryAttributes[.type] as? FileAttributeType == .typeDirectory,
              attributes[.type] as? FileAttributeType == .typeRegular else { throw CoreError.fileFailure(name) }
        return attributes
    }
}
