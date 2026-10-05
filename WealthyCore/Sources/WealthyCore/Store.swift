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
    private let context: ModelContext

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
        context = ModelContext(container)
        context.autosaveEnabled = false
        if seed && isNew { try seedDefaults() }
    }

    /// Returns detached values in their persisted sequence order.
    public func read() throws -> LedgerState {
        let wallets = try context.fetch(FetchDescriptor<WealthySchemaV1.Wallet>(sortBy: [SortDescriptor(\.recordOrder)]))
        let categories = try context.fetch(FetchDescriptor<WealthySchemaV1.Category>(sortBy: [SortDescriptor(\.recordOrder)]))
        let entries = try context.fetch(FetchDescriptor<WealthySchemaV1.LedgerEntry>(sortBy: [SortDescriptor(\.recordOrder)]))
        let receipts = try context.fetch(FetchDescriptor<WealthySchemaV1.ReceiptAttachment>(sortBy: [SortDescriptor(\.recordOrder)]))
        let rules = try context.fetch(FetchDescriptor<WealthySchemaV1.RecurringRule>(sortBy: [SortDescriptor(\.recordOrder)]))
        let budgets = try context.fetch(FetchDescriptor<WealthySchemaV1.Budget>(sortBy: [SortDescriptor(\.recordOrder)]))
        let pointCards = try context.fetch(FetchDescriptor<WealthySchemaV1.PointCard>(sortBy: [SortDescriptor(\.recordOrder)]))
        return try LedgerState(wallets: wallets.map { try $0.value() }, categories: categories.map { try $0.value() },
                               entries: entries.map { try $0.value() }, receipts: receipts.map { try $0.value() },
                               rules: rules.map { try $0.value() }, budgets: budgets.map { try $0.value() },
                               pointCards: pointCards.map { try $0.value() })
    }

    /// Replaces all records in one save; callers validate before this low-level operation.
    func replace(_ state: LedgerState) throws {
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
        } catch {
            context.rollback()
            if let error = error as? CoreError { throw error }
            throw CoreError.saveFailed
        }
    }

    /// Inserts the ten initial categories by stable system key, never a wallet.
    public func seedDefaults() throws {
        var state = try read()
        let defaults: [(CategoryKind, String)] = [
            (.expense, "catFood"), (.expense, "catTransport"), (.expense, "catDaily"),
            (.expense, "catHobby"), (.expense, "catClothing"), (.expense, "catOthers"),
            (.expense, "categoryFixedCosts"), (.income, "incomeSalary"), (.income, "incomeBonus"), (.income, "incomeOther")
        ]
        for (index, item) in defaults.enumerated() where !state.categories.contains(where: { $0.kind == item.0 && $0.systemKey == item.1 }) {
            state.categories.append(CategoryValue(kind: item.0, systemKey: item.1, sortOrder: index))
        }
        if try read() != state { try replace(state) }
    }
}
