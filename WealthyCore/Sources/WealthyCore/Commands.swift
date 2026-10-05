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
    case createWallet(WalletValue, openingBalance: Int = 0, openingDay: LedgerDay? = nil)
    case updateWallet(WalletValue)
    case reconcileWallet(UUID, actualBalance: Int, day: LedgerDay)
    case archiveWallet(UUID, archived: Bool)
    case deleteWallet(UUID)
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
    case setBudget(BudgetValue)
    case removeBudget(UUID)
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
        for id in state.wallets.map(\.id) + state.categories.map(\.id) + state.entries.map(\.id)
            + state.receipts.map(\.id) + state.rules.map(\.id) + state.budgets.map(\.id) + state.pointCards.map(\.id) {
            guard ids.insert(id).inserted else { throw CoreError.duplicateID(id) }
        }
        var walletNames = Set<String>()
        for wallet in state.wallets {
            guard try CoreCurrency.normalizedCode(wallet.currencyCode) == wallet.currencyCode else { throw CoreError.invalidField("currencyCode", wallet.id) }
            guard !normalizedName(wallet.name).isEmpty else { throw CoreError.invalidField("name", wallet.id) }
            if !wallet.isArchived, !walletNames.insert(normalizedName(wallet.name)).inserted { throw CoreError.duplicateName(wallet.name) }
            if let method = wallet.paymentMethodKey {
                guard paymentMethods.contains(method) || (method.hasPrefix("custom:") && !normalizedName(String(method.dropFirst(7))).isEmpty)
                else { throw CoreError.invalidField("paymentMethodKey", wallet.id) }
            }
        }
        var categoryNames = Set<String>(), systemKeys = Set<String>()
        for category in state.categories {
            guard category.customName != nil || category.systemKey != nil else { throw CoreError.invalidField("categoryName", category.id) }
            if let name = category.customName {
                guard !normalizedName(name).isEmpty else { throw CoreError.invalidField("customName", category.id) }
                if !category.isArchived, !categoryNames.insert(category.kind.rawValue + ":" + normalizedName(name)).inserted { throw CoreError.duplicateName(name) }
            }
            if let key = category.systemKey {
                guard !key.isEmpty, systemKeys.insert(category.kind.rawValue + ":" + key).inserted else { throw CoreError.invalidField("systemKey", category.id) }
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
    static let paymentMethods = ["cash", "sbiShinsei", "docomoSMTB", "paypay", "paypayCredit", "rakutenPay", "rakutenCard", "suica", "pasmo", "icoca", "waon", "nanaco", "quicpay", "id", "auPay", "dPay", "merpay", "visa", "mastercard", "jcb", "amex", "creditCard", "debitCard", "bankTransfer"]
    public static func safeFilename(_ name: String) -> Bool {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        return !name.isEmpty && name.utf8.count <= 255 && name != "." && name != ".." && name.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
    static func validateEntry(_ e: EntryValue, in state: LedgerState, active: Bool) throws {
        guard e.amount > 0 else { throw CoreError.invalidField("amount", e.id) }
        if e.source == .openingBalance || e.source == .reconciliation {
            guard e.kind == .adjustment else { throw CoreError.invalidField("source", e.id) }
        }
        _ = try LedgerDay(year: e.day.year, month: e.day.month, day: e.day.day)
        let code = try CoreCurrency.normalizedCode(e.currencyCode)
        guard code == e.currencyCode else { throw CoreError.invalidField("currencyCode", e.id) }
        guard let w = state.wallets.first(where: { $0.id == e.walletID }) else { throw CoreError.danglingReference("walletID", e.walletID) }
        guard w.currencyCode == code else { throw CoreError.currencyMismatch(w.id) }
        if active && w.isArchived { throw CoreError.archivedWallet(w.id) }
        if e.kind == .transfer {
            guard let target = e.counterpartWalletID else { throw CoreError.invalidField("counterpartWalletID", e.id) }
            guard target != w.id else { throw CoreError.sameWalletTransfer(w.id) }
            guard let other = state.wallets.first(where: { $0.id == target }) else { throw CoreError.danglingReference("counterpartWalletID", target) }
            guard other.currencyCode == code else { throw CoreError.crossCurrencyTransfer(w.id, other.id) }
            if active && other.isArchived { throw CoreError.archivedWallet(other.id) }
        } else if e.counterpartWalletID != nil { throw CoreError.invalidField("counterpartWalletID", e.id) }
        if e.kind == .adjustment {
            guard e.direction != nil else { throw CoreError.invalidField("direction", e.id) }
        } else if e.direction != nil { throw CoreError.invalidField("direction", e.id) }
        if let id = e.categoryID {
            guard e.kind == .expense || e.kind == .income else { throw CoreError.invalidField("categoryID", e.id) }
            guard let c = state.categories.first(where: { $0.id == id }) else { throw CoreError.danglingReference("categoryID", id) }
            guard c.kind.rawValue == e.kind.rawValue else { throw CoreError.categoryKindMismatch(id) }
            if active && c.isArchived { throw CoreError.archivedCategory(id) }
        }
        if let id = e.receiptID, !state.receipts.contains(where: { $0.id == id }) { throw CoreError.danglingReference("receiptID", id) }
        if let id = e.recurringRuleID, !state.rules.contains(where: { $0.id == id }) { throw CoreError.danglingReference("recurringRuleID", id) }
        if (e.recurringRuleID == nil) != (e.occurrenceDay == nil) { throw CoreError.invalidField("occurrenceDay", e.id) }
    }
}

/// Decimal accumulation preserves totals beyond a single entry's integer range.
public enum LedgerMath {
    public static func balance(_ walletID: UUID, in state: LedgerState, through day: LedgerDay? = nil) -> Decimal {
        state.entries.reduce(Decimal.zero) { total, e in
            guard day == nil || e.day <= day! else { return total }
            let amount = Decimal(e.amount)
            if e.kind == .transfer && e.counterpartWalletID == walletID { return total + amount }
            guard e.walletID == walletID else { return total }
            switch e.kind {
            case .expense, .transfer: return total - amount
            case .income: return total + amount
            case .adjustment: return total + (e.direction == .increase ? amount : -amount)
            }
        }
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
        case let .createWallet(wallet, opening, openingDay):
            var wallet = wallet
            wallet.currencyCode = try CoreCurrency.normalizedCode(wallet.currencyCode)
            state.wallets.append(wallet)
            if opening != 0 {
                guard opening != Int.min else { throw CoreError.invalidField("openingBalance", wallet.id) }
                let day = try openingDay ?? LedgerDay(date: wallet.createdAt, calendar: calendar)
                state.entries.append(EntryValue(kind: .adjustment, amount: abs(opening), currencyCode: wallet.currencyCode, day: day, walletID: wallet.id, direction: opening > 0 ? .increase : .decrease, timestamp: now, source: .openingBalance, createdAt: now, updatedAt: now))
            }
        case let .updateWallet(wallet):
            let i = try index(wallet.id, in: state.wallets.map(\.id), type: "wallet")
            guard wallet.currencyCode == state.wallets[i].currencyCode else { throw CoreError.invalidField("currencyCode", wallet.id) }
            guard wallet.isProvisional == state.wallets[i].isProvisional, wallet.isArchived == state.wallets[i].isArchived, wallet.createdAt == state.wallets[i].createdAt else { throw CoreError.invalidField("walletMetadata", wallet.id) }
            state.wallets[i] = wallet
        case let .reconcileWallet(id, actual, day):
            let i = try index(id, in: state.wallets.map(\.id), type: "wallet")
            guard !state.wallets[i].isArchived else { throw CoreError.archivedWallet(id) }
            let diff = Decimal(actual) - LedgerMath.balance(id, in: state, through: day)
            if diff != 0 {
                let absolute = diff < 0 ? -diff : diff
                guard absolute <= Decimal(Int.max) else { throw CoreError.invalidField("reconciliationAmount", id) }
                let amount = NSDecimalNumber(decimal: absolute).intValue
                state.entries.append(EntryValue(kind: .adjustment, amount: amount, currencyCode: state.wallets[i].currencyCode, day: day, walletID: id, direction: diff > 0 ? .increase : .decrease, timestamp: now, source: .reconciliation, createdAt: now, updatedAt: now))
            }
            state.wallets[i].isProvisional = false
        case let .archiveWallet(id, archived):
            let i = try index(id, in: state.wallets.map(\.id), type: "wallet"); state.wallets[i].isArchived = archived
        case let .deleteWallet(id):
            let i = try index(id, in: state.wallets.map(\.id), type: "wallet")
            guard !state.entries.contains(where: { ($0.walletID == id || $0.counterpartWalletID == id) && $0.source != .openingBalance }),
                  !state.rules.contains(where: { $0.walletID == id || $0.counterpartWalletID == id }) else { throw CoreError.walletHasHistory(id) }
            state.entries.removeAll { $0.walletID == id }; state.wallets.remove(at: i)
        case let .addEntry(entry, receipt):
            guard entry.kind != .adjustment else { throw CoreError.invalidField("kind", entry.id) }
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
            guard (entry.kind == .adjustment) == (stored.kind == .adjustment) else { throw CoreError.invalidField("kind", entry.id) }
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
            guard category.kind == state.categories[i].kind, category.isArchived == state.categories[i].isArchived, category.systemKey == state.categories[i].systemKey else { throw CoreError.invalidField("categoryMetadata", category.id) }
            state.categories[i] = category
        case let .archiveCategory(id, archived):
            let i = try index(id, in: state.categories.map(\.id), type: "category"); state.categories[i].isArchived = archived
        case let .deleteCategory(id):
            let i = try index(id, in: state.categories.map(\.id), type: "category"); state.categories.remove(at: i)
            for n in state.entries.indices where state.entries[n].categoryID == id { state.entries[n].categoryID = nil }
            state.budgets.removeAll { $0.categoryID == id }
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
