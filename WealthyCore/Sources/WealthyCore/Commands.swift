import Foundation
import Observation

/// A draft attachment remains a value until its entry command commits.
public struct ReceiptInput: Codable, Sendable, Equatable {
    public var metadata: ReceiptValue
    public var image: Data
    public init(metadata: ReceiptValue, image: Data) { self.metadata = metadata; self.image = image }
}

/// Every user mutation uses stable IDs and serializable, framework-independent values.
public enum LedgerCommand: Codable, Sendable, Equatable {
    case createEnvelope(EnvelopeValue)
    case updateEnvelope(EnvelopeValue)
    case archiveEnvelope(UUID, archived: Bool)
    case deleteEnvelope(UUID)
    case addEntry(EntryValue, receipt: ReceiptInput? = nil)
    case updateEntry(EntryValue, receipt: ReceiptInput? = nil)
    case deleteEntry(UUID)
    case markReviewed(UUID)
    case createCategory(CategoryValue)
    case updateCategory(CategoryValue)
    case archiveCategory(UUID, archived: Bool)
    case deleteCategory(UUID)
    case createRule(RuleValue)
    case updateRule(RuleValue)
    case pauseRule(UUID, paused: Bool)
    case deleteRule(UUID)
    case setTarget(TargetValue)
    case removeTarget(UUID)
    case markNoSpend(LedgerDay, envelopeID: UUID = EnvelopeValue.householdID)
    case unmarkNoSpend(LedgerDay, envelopeID: UUID = EnvelopeValue.householdID)
    case updateSettings(LedgerSettings)
    case createPointCard(PointCardValue)
    case updatePointCard(PointCardValue)
    case deletePointCard(UUID)
}

/// Validation is independent of persistence; historical archived assignments remain valid.
public enum CoreValidation {
    public static func normalizedName(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.widthInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }
    public static func validate(_ state: LedgerState) throws {
        var ids = Set<UUID>()
        for id in state.allIDs {
            guard ids.insert(id).inserted else { throw CoreError.duplicateID(id) }
        }
        guard (1...7).contains(state.settings.weekStart) else { throw CoreError.invalidField("weekStart", state.settings.id) }
        var kinds = Set<EnvelopeKind>()
        for envelope in state.envelopes {
            guard !normalizedName(envelope.name).isEmpty else { throw CoreError.invalidField("name", envelope.id) }
            guard kinds.insert(envelope.kind).inserted else { throw CoreError.invalidField("duplicateEnvelopeKind", envelope.id) }
        }
        guard state.envelopes.contains(where: { $0.id == EnvelopeValue.householdID && $0.kind == .household }) else { throw CoreError.danglingReference("householdEnvelope", EnvelopeValue.householdID) }
        var categoryNames = Set<String>(), systemKeys = Set<String>()
        for category in state.categories {
            guard state.envelopes.contains(where: { $0.id == category.envelopeID }) else { throw CoreError.danglingReference("envelopeID", category.envelopeID) }

            guard category.customName != nil || category.systemKey != nil else { throw CoreError.invalidField("categoryName", category.id) }
            if let name = category.customName {
                guard !normalizedName(name).isEmpty else { throw CoreError.invalidField("customName", category.id) }
                if !category.isArchived, !categoryNames.insert(category.envelopeID.uuidString + ":" + category.kind.rawValue + ":" + normalizedName(name)).inserted { throw CoreError.duplicateName(name) }
            }
            if let key = category.systemKey {
                guard !key.isEmpty, systemKeys.insert(category.envelopeID.uuidString + ":" + category.kind.rawValue + ":" + key).inserted else { throw CoreError.invalidField("systemKey", category.id) }
            }
        }
        for receipt in state.receipts {
            guard safeFilename(receipt.fileName) else { throw CoreError.unsafeFilename(receipt.fileName) }
            if let hash = receipt.imageSHA256 {
                guard hash.utf8.count == 64, hash.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) })
                else { throw CoreError.invalidField("imageSHA256", receipt.id) }
            }
        }
        for entry in state.entries { try validateEntry(entry, in: state, active: false) }
        try validatePlanning(state)
    }
    public static func safeFilename(_ name: String) -> Bool {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        return !name.isEmpty && name.utf8.count <= 255 && name != "." && name != ".." && name.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
    static func validateEntry(_ e: EntryValue, in state: LedgerState, active: Bool) throws {
        guard e.amount > 0 else { throw CoreError.invalidField("amount", e.id) }
        _ = try LedgerDay(year: e.day.year, month: e.day.month, day: e.day.day)
        guard try CoreCurrency.normalizedCode(e.currencyCode) == e.currencyCode else { throw CoreError.invalidField("currencyCode", e.id) }
        guard let envelope = state.envelopes.first(where: { $0.id == e.envelopeID }) else { throw CoreError.danglingReference("envelopeID", e.envelopeID) }
        if active && envelope.isArchived { throw CoreError.invalidField("archivedEnvelope", envelope.id) }
        if (e.currencyCode != "JPY" || TaxRuleBook().rule(on: e.day) == nil), e.taxRate != nil { throw CoreError.invalidField("taxRate", e.id) }
        if let id = e.categoryID {
            guard e.kind == .expense || e.kind == .income else { throw CoreError.invalidField("categoryID", e.id) }
            guard let c = state.categories.first(where: { $0.id == id }) else { throw CoreError.danglingReference("categoryID", id) }
            guard c.envelopeID == e.envelopeID else { throw CoreError.invalidField("categoryEnvelope", id) }
            guard c.kind.rawValue == e.kind.rawValue else { throw CoreError.categoryKindMismatch(id) }
            if active && c.isArchived { throw CoreError.archivedCategory(id) }
        }
        if let id = e.receiptID, !state.receipts.contains(where: { $0.id == id }) { throw CoreError.danglingReference("receiptID", id) }
        if (e.recurringRuleID == nil) != (e.occurrenceDay == nil) { throw CoreError.invalidField("occurrenceDay", e.id) }
        if e.source != .recurring && e.recurringRuleID != nil { throw CoreError.invalidField("source", e.id) }
    }
}

/// Main-actor isolation matches the app while keeping all API results Sendable.
@Observable @MainActor public final class LedgerCore {
    public let store: LedgerStore
    public var calendar: Calendar
    /// The validated working state; reading it never fetches SwiftData models.
    public private(set) var state: LedgerState
    /// Increases once after successful persisted changes or a changed external reload.
    public private(set) var revision = 0
    private var history: [LedgerChanges] = []

    /// Loads and fully validates the initial store before exposing observable state.
    public init(store: LedgerStore, calendar: Calendar = .current) throws {
        let initial = try store.read()
        try CoreValidation.validate(initial)
        self.store = store; self.calendar = calendar; state = initial
    }
    /// Returns the cached detached state without fetching from persistence.
    public func snapshot() throws -> LedgerState { state }
    /// Number of retained command changes available to undo.
    public var undoCount: Int { history.count }
    var undoRetainedRecordCount: Int { history.reduce(0) { $0 + $1.recordCount } }
    var latestUndoRecordCount: Int { history.last?.recordCount ?? 0 }
    /// Discards undo history without changing persisted records or revision.
    public func clearUndoHistory() { history.removeAll() }

    /// Reloads external writes without discarding undo history; touched records remain conflict checked.
    public func reload() throws {
        let loaded = try store.read()
        try CoreValidation.validate(loaded)
        if loaded != state { state = loaded; revision += 1 }
    }

    /// Commits a validated candidate without creating undo history, for recurring and cleanup operations.
    func commit(_ candidate: LedgerState, filesChanged: Bool = false, restoring: LedgerChanges? = nil) throws {
        try CoreValidation.validateChanges(before: state, after: candidate)
        let changes = LedgerChanges(before: state, after: candidate, orders: store.orders, restoring: restoring)
        try store.apply(changes, forceSave: filesChanged, checkingUndo: restoring != nil)
        if !changes.isEmpty || filesChanged { state = candidate; revision += 1 }
    }

    /// Accepts already validated replacement data only after the restore transaction has succeeded.
    func acceptRestoredState(_ value: LedgerState, filesChanged: Bool) {
        if value != state || filesChanged { state = value; revision += 1 }
        clearUndoHistory()
    }

    /// Validates a draft using the same rules as execution without writing records or images.
    public func preview(_ command: LedgerCommand, now: Date) -> CommandPreview {
        do {
            let before = state
            var after = before
            try apply(command, to: &after, now: now)
            try CoreValidation.validateChanges(before: before, after: after)
            try validateImages(command)
            let summary = try StateChanges.result(before: before, after: after, today: try LedgerDay(date: now, calendar: calendar), calendar: calendar).summary
            return CommandPreview(errors: [], summary: summary)
        } catch { return CommandPreview(errors: [error as? CoreError ?? .saveFailed], summary: nil) }
    }
    /// Validates and commits one command, publishing state only after the transaction succeeds.
    @discardableResult public func run(_ command: LedgerCommand, now: Date) throws -> CommandResult {
        let before = state
        var after = before
        try apply(command, to: &after, now: now)
        try CoreValidation.validateChanges(before: before, after: after)
        try validateImages(command)
        let result = try StateChanges.result(before: before, after: after, today: try LedgerDay(date: now, calendar: calendar), calendar: calendar)
        let changes = LedgerChanges(before: before, after: after, orders: store.orders)
        let fileChanges = try ReceiptFiles.changes(images(command), directory: store.receiptsDirectory, removing: [])
        try ReceiptFiles.write(images(command), directory: store.receiptsDirectory) { try store.apply(changes, forceSave: fileChanges) }
        if !changes.isEmpty || fileChanges { state = after; revision += 1 }
        if before != after {
            history.append(changes)
            if history.count > 20 { history.removeFirst(history.count - 20) }
        }
        return result
    }
    /// Undoes changed records while preserving unrelated externally added records.
    @discardableResult public func undo(now: Date) throws -> CommandResult? {
        guard let step = history.last else { return nil }
        let current = state
        let previous: LedgerState
        do {
            previous = try step.inverse(current: current, orders: store.orders)
            try CoreValidation.validateChanges(before: current, after: previous)
        } catch { throw CoreError.undoConflict }
        let result = try StateChanges.result(before: current, after: previous, today: try LedgerDay(date: now, calendar: calendar), calendar: calendar)
        try commit(previous, restoring: step)
        history.removeLast()
        return result
    }
    /// Atomically removes unreferenced receipt metadata and files, only after abandoning undo history.
    public func cleanupOrphanReceipts() throws -> [String] {
        guard history.isEmpty else { throw CoreError.historyNotEmpty }
        var candidate = state
        let referencedIDs = Set(candidate.entries.compactMap(\.receiptID))
        candidate.receipts.removeAll { !referencedIDs.contains($0.id) }
        let names = Set(candidate.receipts.map(\.fileName))
        let orphanFiles = try ReceiptFiles.orphans(referenced: names, directory: store.receiptsDirectory)
        try ReceiptFiles.removeOrphans(Set(orphanFiles), directory: store.receiptsDirectory) {
            try commit(candidate, filesChanged: !orphanFiles.isEmpty)
        }
        return orphanFiles
    }
    private func images(_ command: LedgerCommand) -> [String: Data] {
        switch command {
        case let .addEntry(_, receipt), let .updateEntry(_, receipt):
            if let receipt { return [receipt.metadata.fileName: receipt.image] }
        default: break
        }
        return [:]
    }
    private func validateImages(_ command: LedgerCommand) throws {
        for (name, data) in images(command) {
            guard CoreValidation.safeFilename(name) else { throw CoreError.unsafeFilename(name) }
            guard ReceiptFiles.isValidImage(data) else { throw CoreError.invalidImage(name) }
            let url = store.receiptsDirectory.appendingPathComponent(name)
            if let values = try? url.resourceValues(forKeys: [.isSymbolicLinkKey]), values.isSymbolicLink == true { throw CoreError.fileFailure(name) }
            if FileManager.default.fileExists(atPath: url.path) {
                guard let existing = try? Data(contentsOf: url), existing == data else { throw CoreError.fileFailure(name) }
            }
        }
    }
    func apply(_ command: LedgerCommand, to state: inout LedgerState, now: Date) throws {
        switch command {
        case let .createEnvelope(envelope):
            state.envelopes.append(envelope)
            if envelope.kind == .child { state.categories.append(contentsOf: CategoryPresets.child(envelopeID: envelope.id)) }
        case let .updateEnvelope(envelope):
            let i = try index(envelope.id, in: state.envelopes.map(\.id), type: "envelope")
            let old = state.envelopes[i]
            guard envelope.kind == old.kind, envelope.createdAt == old.createdAt, envelope.isArchived == old.isArchived else { throw CoreError.invalidField("envelopeMetadata", envelope.id) }
            state.envelopes[i] = envelope
        case let .archiveEnvelope(id, archived):
            let i = try index(id, in: state.envelopes.map(\.id), type: "envelope")
            state.envelopes[i].isArchived = archived
        case let .deleteEnvelope(id):
            let i = try index(id, in: state.envelopes.map(\.id), type: "envelope")
            guard id != EnvelopeValue.householdID, !state.entries.contains(where: { $0.envelopeID == id }), !state.rules.contains(where: { $0.envelopeID == id }) else { throw CoreError.invalidField("envelopeHasHistory", id) }
            state.envelopes.remove(at: i)
            state.categories.removeAll { $0.envelopeID == id }
            state.targets.removeAll { $0.envelopeID == id }
            state.noSpendMarks.removeAll { $0.envelopeID == id }
        case let .addEntry(entry, receipt):
            guard [.manual, .receipt, .voice].contains(entry.source) else { throw CoreError.invalidField("source", entry.id) }
            guard entry.recurringRuleID == nil else { throw CoreError.invalidField("recurringRuleID", entry.id) }
            guard entry.occurrenceDay == nil else { throw CoreError.invalidField("occurrenceDay", entry.id) }
            var entry = entry
            try attach(receipt, to: &entry, state: &state)
            try CoreValidation.validateEntry(entry, in: state, active: true)
            state.entries.append(entry)
        case let .updateEntry(entry, receipt):
            let i = try index(entry.id, in: state.entries.map(\.id), type: "entry")
            let stored = state.entries[i]
            guard entry.source == stored.source else { throw CoreError.invalidField("source", entry.id) }
            guard entry.recurringRuleID == stored.recurringRuleID else { throw CoreError.invalidField("recurringRuleID", entry.id) }
            guard entry.occurrenceDay == stored.occurrenceDay else { throw CoreError.invalidField("occurrenceDay", entry.id) }
            var entry = entry
            try attach(receipt, to: &entry, state: &state)
            try CoreValidation.validateEntry(entry, in: state, active: true)
            entry.createdAt = state.entries[i].createdAt; entry.updatedAt = now
            state.entries[i] = entry
        case let .deleteEntry(id):
            let i = try index(id, in: state.entries.map(\.id), type: "entry"); state.entries.remove(at: i)
        case let .markReviewed(id):
            let i = try index(id, in: state.entries.map(\.id), type: "entry"); state.entries[i].reviewFlags = []; state.entries[i].updatedAt = now
        case let .createCategory(category): state.categories.append(category)
        case let .updateCategory(category):
            let i = try index(category.id, in: state.categories.map(\.id), type: "category")
            guard category.envelopeID == state.categories[i].envelopeID, category.kind == state.categories[i].kind, category.isArchived == state.categories[i].isArchived, category.systemKey == state.categories[i].systemKey else { throw CoreError.invalidField("categoryMetadata", category.id) }
            state.categories[i] = category
        case let .archiveCategory(id, archived):
            let i = try index(id, in: state.categories.map(\.id), type: "category"); state.categories[i].isArchived = archived
        case let .deleteCategory(id):
            let i = try index(id, in: state.categories.map(\.id), type: "category")
            if state.categories[i].systemKey != nil && (state.entries.contains(where: { $0.categoryID == id }) || state.rules.contains(where: { $0.categoryID == id }) || state.targets.contains(where: { $0.categoryID == id })) { throw CoreError.invalidField("usedSystemCategory", id) }
            let currentMonth = LedgerMonth(day: try LedgerDay(date: now, calendar: calendar))
            guard !state.targets.contains(where: { $0.categoryID == id && $0.effectiveMonth != currentMonth }) else {
                throw CoreError.invalidField("historicalCategoryTarget", id)
            }
            state.categories.remove(at: i)
            for n in state.entries.indices where state.entries[n].categoryID == id { state.entries[n].categoryID = nil }
            state.targets.removeAll { $0.categoryID == id }
            for n in state.rules.indices where state.rules[n].categoryID == id { state.rules[n].categoryID = nil }
        default: try applyPlanning(command, to: &state, now: now)
        }
    }
    func attach(_ receipt: ReceiptInput?, to entry: inout EntryValue, state: inout LedgerState) throws {
        guard var receipt else { return }
        receipt.metadata.imageSHA256 = ReceiptFiles.imageHash(receipt.image)
        if let existing = state.receipts.first(where: { $0.id == receipt.metadata.id }) {
            guard existing == receipt.metadata else { throw CoreError.duplicateID(existing.id) }
        } else { state.receipts.append(receipt.metadata) }
        entry.receiptID = receipt.metadata.id
    }
    func index(_ id: UUID, in ids: [UUID], type: String) throws -> Int {
        guard let index = ids.firstIndex(of: id) else { throw CoreError.missingRecord(type, id) }
        return index
    }
}
