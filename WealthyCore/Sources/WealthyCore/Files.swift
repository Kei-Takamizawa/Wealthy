import Foundation
import ImageIO
import CryptoKit

/// Receipt file operations are restricted to direct children of the new receipt directory.
public enum ReceiptFiles {
    /// Matches the legacy archive filename rule without accepting path components.
    public static func isSafeFilename(_ filename: String) -> Bool {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        return !filename.isEmpty && filename.utf8.count <= 255 && filename != "." && filename != ".."
            && filename.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    /// Requires one fully decodable frame and complete source/frame status.
    public static func isValidImage(_ data: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil), CGImageSourceGetCount(source) == 1 else { return false }
        guard CGImageSourceCreateImageAtIndex(source, 0, nil) != nil else { return false }
        return CGImageSourceGetStatus(source) == .statusComplete
            && CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete
    }

    /// Writes validated images and removes specified collisions before saving; failures restore original bytes.
    /// Existing filenames may be overwritten so backup restore can replace image contents.
    @MainActor
    public static func write(_ images: [String: Data], directory: URL, removing: Set<String> = [], commit: () throws -> Void) throws {
        try transact(images, directory: directory, removing: removing, allowOtherRegularFileNames: false, commit: commit)
    }

    /// Cleanup also handles regular orphan files with names that were never valid receipt metadata.
    @MainActor
    static func removeOrphans(_ names: Set<String>, directory: URL, commit: () throws -> Void) throws {
        try transact([:], directory: directory, removing: names, allowOtherRegularFileNames: true, commit: commit)
    }

    @MainActor
    private static func transact(_ images: [String: Data], directory: URL, removing: Set<String>,
                                 allowOtherRegularFileNames: Bool, commit: () throws -> Void) throws {
        let names = Set(images.keys).union(removing).sorted()
        for name in names {
            let directChild = !name.isEmpty && name != "." && name != ".." && !name.contains("/")
            guard isSafeFilename(name) || (allowOtherRegularFileNames && directChild) else { throw CoreError.unsafeFilename(name) }
            if let image = images[name], !isValidImage(image) { throw CoreError.invalidImage(name) }
        }
        try validateDirectory(directory)

        // Originals stay on disk; transactions never retain every old image in memory.
        let staging = directory.deletingLastPathComponent()
            .appendingPathComponent(".WealthyReceiptTransaction-\(UUID().uuidString)", isDirectory: true)
        do { try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: false) }
        catch { throw CoreError.fileFailure("receiptTransaction") }
        defer { try? FileManager.default.removeItem(at: staging) }
        var existingNames = Set<String>()
        for name in names {
            let url = directory.appendingPathComponent(name)
            if try existingRegularFile(url) {
                do {
                    try FileManager.default.copyItem(at: url, to: staging.appendingPathComponent(name))
                    existingNames.insert(name)
                } catch { throw CoreError.fileFailure(name) }
            }
        }

        var changedNames: [String] = []
        var currentName = "receiptFiles"
        var committing = false
        do {
            for name in names {
                currentName = name
                // Track before writing so failure cleanup also covers the attempted destination.
                changedNames.append(name)
                if let image = images[name] {
                    try image.write(to: directory.appendingPathComponent(name), options: .atomic)
                } else if existingNames.contains(name) {
                    try FileManager.default.removeItem(at: directory.appendingPathComponent(name))
                }
            }
            committing = true
            try commit()
        } catch {
            var rollbackFailure: String?
            for name in changedNames.reversed() {
                let url = directory.appendingPathComponent(name)
                do {
                    // Never follow a path that became a symlink while the transaction was running.
                    _ = try existingRegularFile(url)
                    if existingNames.contains(name) {
                        try Data(contentsOf: staging.appendingPathComponent(name)).write(to: url, options: .atomic)
                    } else if FileManager.default.fileExists(atPath: url.path) {
                        try FileManager.default.removeItem(at: url)
                    }
                } catch { rollbackFailure = rollbackFailure ?? name }
            }
            if let rollbackFailure { throw CoreError.fileFailure("rollback:\(rollbackFailure)") }
            if let error = error as? CoreError { throw error }
            throw committing ? CoreError.saveFailed : CoreError.fileFailure(currentName)
        }
    }

    /// Lowercase SHA-256 of the saved image bytes.
    static func imageHash(_ bytes: Data) -> String {
        SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
    }

    /// Hashes a regular file with bounded buffers; a missing image has no known hash.
    static func imageHash(named name: String, directory: URL) throws -> String? {
        guard isSafeFilename(name) else { throw CoreError.unsafeFilename(name) }
        try validateDirectory(directory)
        let url = directory.appendingPathComponent(name)
        guard try existingRegularFile(url) else { return nil }
        do {
            let file = try FileHandle(forReadingFrom: url)
            defer { try? file.close() }
            var hash = SHA256()
            while let chunk = try file.read(upToCount: 65_536), !chunk.isEmpty { hash.update(data: chunk) }
            return hash.finalize().map { String(format: "%02x", $0) }.joined()
        } catch { throw CoreError.fileFailure(name) }
    }

    /// Detects a byte change before the transaction so observers receive exactly one revision.
    static func changes(_ images: [String: Data], directory: URL, removing: Set<String>) throws -> Bool {
        try validateDirectory(directory)
        var changed = false
        for name in Set(images.keys).union(removing) {
            guard isSafeFilename(name) else { throw CoreError.unsafeFilename(name) }
            let url = directory.appendingPathComponent(name)
            let exists = try existingRegularFile(url)
            if let image = images[name] {
                if !exists { changed = true }
                else {
                    do { if try Data(contentsOf: url) != image { changed = true } }
                    catch { throw CoreError.fileFailure(name) }
                }
            } else if exists { changed = true }
        }
        return changed
    }

    /// Enumerates removable regular files without deleting them; callers combine files and metadata atomically.
    static func orphans(referenced: Set<String>, directory: URL) throws -> [String] {
        try validateDirectory(directory)
        let urls: [URL]
        do {
            urls = try FileManager.default.contentsOfDirectory(at: directory,
                includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey], options: [])
        } catch { throw CoreError.fileFailure("receiptsDirectory") }
        return try urls.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }).compactMap { url in
            let name = url.lastPathComponent
            guard !referenced.contains(name) else { return nil }
            let values: URLResourceValues
            do { values = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey]) }
            catch { throw CoreError.fileFailure(name) }
            return values.isSymbolicLink != true && values.isRegularFile == true ? name : nil
        }
    }

    /// Deletes only unreferenced regular files directly inside the new receipts directory.
    /// Symlinks and directories are preserved; callers invoke this only without undo history.
    public static func cleanup(referenced: Set<String>, directory: URL) throws -> [String] {
        try validateDirectory(directory)
        let urls: [URL]
        do {
            urls = try FileManager.default.contentsOfDirectory(at: directory,
                includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey], options: [])
        } catch { throw CoreError.fileFailure("receiptsDirectory") }
        var removed: [String] = []
        for url in urls.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let name = url.lastPathComponent
            guard !referenced.contains(name) else { continue }
            let values: URLResourceValues
            do { values = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey]) }
            catch { throw CoreError.fileFailure(name) }
            guard values.isSymbolicLink != true, values.isRegularFile == true else { continue }
            do { try FileManager.default.removeItem(at: url) }
            catch { throw CoreError.fileFailure(name) }
            removed.append(name)
        }
        return removed
    }

    private static func validateDirectory(_ directory: URL) throws {
        let values: URLResourceValues
        do { values = try directory.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey]) }
        catch { throw CoreError.fileFailure("receiptsDirectory") }
        guard directory.isFileURL, values.isDirectory == true, values.isSymbolicLink != true else {
            throw CoreError.fileFailure("receiptsDirectory")
        }
    }

    /// A dangling symlink also has attributes, so it is rejected before fileExists is consulted.
    private static func existingRegularFile(_ url: URL) throws -> Bool {
        let attributes: [FileAttributeKey: Any]
        do { attributes = try FileManager.default.attributesOfItem(atPath: url.path) }
        catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoSuchFileError { return false }
        catch { throw CoreError.fileFailure(url.lastPathComponent) }
        guard attributes[.type] as? FileAttributeType == .typeRegular else {
            throw CoreError.fileFailure(url.lastPathComponent)
        }
        return true
    }
}
