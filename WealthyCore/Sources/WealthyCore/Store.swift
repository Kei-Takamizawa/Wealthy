import Foundation
import SwiftData

/// Isolated persistence for the new ledger. Use LedgerCore for validated mutations.
@MainActor
public final class LedgerStore {
    let container: ModelContainer
    public let receiptsDirectory: URL
    public let storeURL: URL?
    /// A deterministic failure injection consumed by the next save attempt.
    var failNextSave = false
    private(set) var orders = RecordOrders()
    private(set) var lastWrites = PersistenceWrites()

    public init(inMemory: Bool = true, directory: URL? = nil, seed: Bool = true) throws {
        let base: URL
        if let directory { base = directory }
        else if inMemory { base = FileManager.default.temporaryDirectory.appendingPathComponent("WealthyCore-\(UUID().uuidString)", isDirectory: true) }
        else {
            base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                               appropriateFor: nil, create: true)
        }
        let url = base.appendingPathComponent("WealthyLedger.store")
        let isNew = inMemory || !FileManager.default.fileExists(atPath: url.path)
        receiptsDirectory = base.appendingPathComponent("WealthyLedgerReceipts", isDirectory: true)
        storeURL = inMemory ? nil : url
        do { try FileManager.default.createDirectory(at: receiptsDirectory, withIntermediateDirectories: true) }
        catch { throw CoreError.fileFailure("receiptsDirectory") }
        let schema = Schema(versionedSchema: WealthySchemaV1.self)
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration("WealthyLedger", schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        } else {
            configuration = ModelConfiguration("WealthyLedger", schema: schema, url: url, cloudKitDatabase: .none)
        }
        container = try ModelContainer(for: schema, migrationPlan: WealthyMigrationPlan.self, configurations: [configuration])
        if seed && isNew { try seedDefaults() }
    }

    /// Returns detached values in their persisted sequence order.
    public func read() throws -> LedgerState {
        let context = makeContext()
        let wallets = try context.fetch(FetchDescriptor<WealthySchemaV1.Wallet>(sortBy: [SortDescriptor(\.recordOrder)]))
            .sorted { $0.recordOrder == $1.recordOrder ? $0.id.uuidString < $1.id.uuidString : $0.recordOrder < $1.recordOrder }
        let categories = try context.fetch(FetchDescriptor<WealthySchemaV1.Category>(sortBy: [SortDescriptor(\.recordOrder)]))
            .sorted { $0.recordOrder == $1.recordOrder ? $0.id.uuidString < $1.id.uuidString : $0.recordOrder < $1.recordOrder }
        let entries = try context.fetch(FetchDescriptor<WealthySchemaV1.LedgerEntry>(sortBy: [SortDescriptor(\.recordOrder)]))
            .sorted { $0.recordOrder == $1.recordOrder ? $0.id.uuidString < $1.id.uuidString : $0.recordOrder < $1.recordOrder }
        let receipts = try context.fetch(FetchDescriptor<WealthySchemaV1.ReceiptAttachment>(sortBy: [SortDescriptor(\.recordOrder)]))
            .sorted { $0.recordOrder == $1.recordOrder ? $0.id.uuidString < $1.id.uuidString : $0.recordOrder < $1.recordOrder }
        let rules = try context.fetch(FetchDescriptor<WealthySchemaV1.RecurringRule>(sortBy: [SortDescriptor(\.recordOrder)]))
            .sorted { $0.recordOrder == $1.recordOrder ? $0.id.uuidString < $1.id.uuidString : $0.recordOrder < $1.recordOrder }
        let budgets = try context.fetch(FetchDescriptor<WealthySchemaV1.Budget>(sortBy: [SortDescriptor(\.recordOrder)]))
            .sorted { $0.recordOrder == $1.recordOrder ? $0.id.uuidString < $1.id.uuidString : $0.recordOrder < $1.recordOrder }
        let pointCards = try context.fetch(FetchDescriptor<WealthySchemaV1.PointCard>(sortBy: [SortDescriptor(\.recordOrder)]))
            .sorted { $0.recordOrder == $1.recordOrder ? $0.id.uuidString < $1.id.uuidString : $0.recordOrder < $1.recordOrder }
        let state = try LedgerState(wallets: wallets.map { try $0.value() }, categories: categories.map { try $0.value() },
                               entries: entries.map { try $0.value() }, receipts: receipts.map { try $0.value() },
                               rules: rules.map { try $0.value() }, budgets: budgets.map { try $0.value() },
                               pointCards: pointCards.map { try $0.value() })
        orders.wallets = Dictionary(wallets.map { ($0.id, $0.recordOrder) }, uniquingKeysWith: { first, _ in first })
        orders.categories = Dictionary(categories.map { ($0.id, $0.recordOrder) }, uniquingKeysWith: { first, _ in first })
        orders.entries = Dictionary(entries.map { ($0.id, $0.recordOrder) }, uniquingKeysWith: { first, _ in first })
        orders.receipts = Dictionary(receipts.map { ($0.id, $0.recordOrder) }, uniquingKeysWith: { first, _ in first })
        orders.rules = Dictionary(rules.map { ($0.id, $0.recordOrder) }, uniquingKeysWith: { first, _ in first })
        orders.budgets = Dictionary(budgets.map { ($0.id, $0.recordOrder) }, uniquingKeysWith: { first, _ in first })
        orders.pointCards = Dictionary(pointCards.map { ($0.id, $0.recordOrder) }, uniquingKeysWith: { first, _ in first })
        return state
    }

    /// Replaces all records in one save; callers validate before this low-level operation.
    func replace(_ state: LedgerState) throws {
        let context = makeContext()
        do {
            for item in try context.fetch(FetchDescriptor<WealthySchemaV1.Wallet>()) { context.delete(item) }
            for item in try context.fetch(FetchDescriptor<WealthySchemaV1.Category>()) { context.delete(item) }
            for item in try context.fetch(FetchDescriptor<WealthySchemaV1.LedgerEntry>()) { context.delete(item) }
            for item in try context.fetch(FetchDescriptor<WealthySchemaV1.ReceiptAttachment>()) { context.delete(item) }
            for item in try context.fetch(FetchDescriptor<WealthySchemaV1.RecurringRule>()) { context.delete(item) }
            for item in try context.fetch(FetchDescriptor<WealthySchemaV1.Budget>()) { context.delete(item) }
            for item in try context.fetch(FetchDescriptor<WealthySchemaV1.PointCard>()) { context.delete(item) }
            for (index, item) in state.wallets.enumerated() { context.insert(WealthySchemaV1.Wallet(item, order: index)) }
            for (index, item) in state.categories.enumerated() { context.insert(WealthySchemaV1.Category(item, order: index)) }
            for (index, item) in state.entries.enumerated() { context.insert(WealthySchemaV1.LedgerEntry(item, order: index)) }
            for (index, item) in state.receipts.enumerated() { context.insert(WealthySchemaV1.ReceiptAttachment(item, order: index)) }
            for (index, item) in state.rules.enumerated() { context.insert(WealthySchemaV1.RecurringRule(item, order: index)) }
            for (index, item) in state.budgets.enumerated() { context.insert(WealthySchemaV1.Budget(item, order: index)) }
            for (index, item) in state.pointCards.enumerated() { context.insert(WealthySchemaV1.PointCard(item, order: index)) }
            if failNextSave { failNextSave = false; throw CoreError.saveFailed }
            try context.save()
            orders.wallets = Dictionary(state.wallets.enumerated().map { ($0.element.id, $0.offset) }, uniquingKeysWith: { first, _ in first })
            orders.categories = Dictionary(state.categories.enumerated().map { ($0.element.id, $0.offset) }, uniquingKeysWith: { first, _ in first })
            orders.entries = Dictionary(state.entries.enumerated().map { ($0.element.id, $0.offset) }, uniquingKeysWith: { first, _ in first })
            orders.receipts = Dictionary(state.receipts.enumerated().map { ($0.element.id, $0.offset) }, uniquingKeysWith: { first, _ in first })
            orders.rules = Dictionary(state.rules.enumerated().map { ($0.element.id, $0.offset) }, uniquingKeysWith: { first, _ in first })
            orders.budgets = Dictionary(state.budgets.enumerated().map { ($0.element.id, $0.offset) }, uniquingKeysWith: { first, _ in first })
            orders.pointCards = Dictionary(state.pointCards.enumerated().map { ($0.element.id, $0.offset) }, uniquingKeysWith: { first, _ in first })
        } catch {
            context.rollback()
            if let error = error as? CoreError { throw error }
            throw CoreError.saveFailed
        }
    }

    /// Inserts the ten initial categories by stable system key, never a wallet.
    public func seedDefaults() throws {
        let before = try read()
        var state = before
        let defaults: [(CategoryKind, String)] = [
            (.expense, "catFood"), (.expense, "catTransport"), (.expense, "catDaily"),
            (.expense, "catHobby"), (.expense, "catClothing"), (.expense, "catOthers"),
            (.expense, "categoryFixedCosts"), (.income, "incomeSalary"), (.income, "incomeBonus"), (.income, "incomeOther")
        ]
        for (index, item) in defaults.enumerated() where !state.categories.contains(where: { $0.kind == item.0 && $0.systemKey == item.1 }) {
            state.categories.append(CategoryValue(kind: item.0, systemKey: item.1, sortOrder: index))
        }
        if before != state { try apply(LedgerChanges(before: before, after: state, orders: orders)) }
    }

    private func makeContext() -> ModelContext {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }

    /// Writes UUID-selected rows in place and publishes diagnostics only after a successful save.
    func apply(_ changes: LedgerChanges, forceSave: Bool = false, checkingUndo: Bool = false) throws {
        guard !changes.isEmpty || forceSave else { lastWrites = PersistenceWrites(); return }
        let context = makeContext()
        var writes = PersistenceWrites()
        var nextOrders = orders
        do {
            try persist(changes.wallets, as: WealthySchemaV1.Wallet.self, orders: &nextOrders.wallets, context: context, writes: &writes, checkingUndo: checkingUndo)
            try persist(changes.categories, as: WealthySchemaV1.Category.self, orders: &nextOrders.categories, context: context, writes: &writes, checkingUndo: checkingUndo)
            try persist(changes.entries, as: WealthySchemaV1.LedgerEntry.self, orders: &nextOrders.entries, context: context, writes: &writes, checkingUndo: checkingUndo)
            try persist(changes.receipts, as: WealthySchemaV1.ReceiptAttachment.self, orders: &nextOrders.receipts, context: context, writes: &writes, checkingUndo: checkingUndo)
            try persist(changes.rules, as: WealthySchemaV1.RecurringRule.self, orders: &nextOrders.rules, context: context, writes: &writes, checkingUndo: checkingUndo)
            try persist(changes.budgets, as: WealthySchemaV1.Budget.self, orders: &nextOrders.budgets, context: context, writes: &writes, checkingUndo: checkingUndo)
            try persist(changes.pointCards, as: WealthySchemaV1.PointCard.self, orders: &nextOrders.pointCards, context: context, writes: &writes, checkingUndo: checkingUndo)
            if failNextSave { failNextSave = false; throw CoreError.saveFailed }
            try context.save()
            writes.saves = 1
            orders = nextOrders
            lastWrites = writes
        } catch {
            context.rollback()
            if let error = error as? CoreError { throw error }
            throw CoreError.saveFailed
        }
    }

    private func persist<Record: LedgerRecord>(_ changes: [RecordChange<Record.Value>], as type: Record.Type,
        orders: inout [UUID: Int], context: ModelContext, writes: inout PersistenceWrites, checkingUndo: Bool) throws {
        for change in changes {
            // Guard persisted touched rows too, so unseen external edits cannot be lost during undo.
            let persisted: Record?
            if checkingUndo {
                persisted = try Record.fetch(change.id, in: context)
                guard (try? persisted?.value()) == change.before, persisted?.recordOrder == change.beforeOrder
                else { throw CoreError.undoConflict }
            } else { persisted = nil }
            if let value = change.after {
                if change.before != nil {
                    guard let record = try persisted ?? Record.fetch(change.id, in: context) else { throw checkingUndo ? CoreError.undoConflict : CoreError.saveFailed }
                    record.update(value)
                    writes.updates += 1
                } else {
                    context.insert(Record(value, order: change.afterOrder!))
                    writes.inserts += 1
                }
                orders[change.id] = change.afterOrder
            } else {
                guard let record = try persisted ?? Record.fetch(change.id, in: context) else { throw checkingUndo ? CoreError.undoConflict : CoreError.saveFailed }
                context.delete(record)
                orders.removeValue(forKey: change.id)
                writes.deletes += 1
            }
        }
    }
}
