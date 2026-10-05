import Foundation
import ImageIO

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
        let names = Set(images.keys).union(removing).sorted()
        for name in names {
            guard isSafeFilename(name) else { throw CoreError.unsafeFilename(name) }
            if let image = images[name], !isValidImage(image) { throw CoreError.invalidImage(name) }
        }
        try validateDirectory(directory)

        // Read all originals before the first mutation, including files shared by several entries.
        var originals: [String: Data] = [:]
        var existingNames = Set<String>()
        for name in names {
            let url = directory.appendingPathComponent(name)
            if try existingRegularFile(url) {
                do { originals[name] = try Data(contentsOf: url); existingNames.insert(name) }
                catch { throw CoreError.fileFailure(name) }
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
                        try originals[name]!.write(to: url, options: .atomic)
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
