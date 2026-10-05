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
        if isNew {
            try replace(LedgerState())
            if seed { try seedDefaults() }
        }
    }

    /// Returns detached values in their persisted sequence order.
    public func read() throws -> LedgerState {
        let context = makeContext()
        let envelopes = try context.fetch(FetchDescriptor<WealthySchemaV1.Envelope>(sortBy: [SortDescriptor(\.recordOrder)]))
            .sorted { $0.recordOrder == $1.recordOrder ? $0.id.uuidString < $1.id.uuidString : $0.recordOrder < $1.recordOrder }
        let categories = try context.fetch(FetchDescriptor<WealthySchemaV1.Category>(sortBy: [SortDescriptor(\.recordOrder)]))
            .sorted { $0.recordOrder == $1.recordOrder ? $0.id.uuidString < $1.id.uuidString : $0.recordOrder < $1.recordOrder }
        let entries = try context.fetch(FetchDescriptor<WealthySchemaV1.LedgerEntry>(sortBy: [SortDescriptor(\.recordOrder)]))
            .sorted { $0.recordOrder == $1.recordOrder ? $0.id.uuidString < $1.id.uuidString : $0.recordOrder < $1.recordOrder }
        let receipts = try context.fetch(FetchDescriptor<WealthySchemaV1.ReceiptAttachment>(sortBy: [SortDescriptor(\.recordOrder)]))
            .sorted { $0.recordOrder == $1.recordOrder ? $0.id.uuidString < $1.id.uuidString : $0.recordOrder < $1.recordOrder }
        let rules = try context.fetch(FetchDescriptor<WealthySchemaV1.RecurringRule>(sortBy: [SortDescriptor(\.recordOrder)]))
            .sorted { $0.recordOrder == $1.recordOrder ? $0.id.uuidString < $1.id.uuidString : $0.recordOrder < $1.recordOrder }
        let targets = try context.fetch(FetchDescriptor<WealthySchemaV1.Target>(sortBy: [SortDescriptor(\.recordOrder)]))
            .sorted { $0.recordOrder == $1.recordOrder ? $0.id.uuidString < $1.id.uuidString : $0.recordOrder < $1.recordOrder }
        let noSpendMarks = try context.fetch(FetchDescriptor<WealthySchemaV1.NoSpendMark>(sortBy: [SortDescriptor(\.recordOrder)]))
            .sorted { $0.recordOrder == $1.recordOrder ? $0.id.uuidString < $1.id.uuidString : $0.recordOrder < $1.recordOrder }
        let settings = try context.fetch(FetchDescriptor<WealthySchemaV1.Settings>(sortBy: [SortDescriptor(\.recordOrder)]))
            .sorted { $0.recordOrder == $1.recordOrder ? $0.id.uuidString < $1.id.uuidString : $0.recordOrder < $1.recordOrder }
        guard settings.count <= 1 else { throw CoreError.invalidField("duplicateSettings", LedgerSettings.defaultID) }
        let pointCards = try context.fetch(FetchDescriptor<WealthySchemaV1.PointCard>(sortBy: [SortDescriptor(\.recordOrder)]))
            .sorted { $0.recordOrder == $1.recordOrder ? $0.id.uuidString < $1.id.uuidString : $0.recordOrder < $1.recordOrder }
        let state = try LedgerState(envelopes: envelopes.map { try $0.value() }, categories: categories.map { try $0.value() },
                               entries: entries.map { try $0.value() }, receipts: receipts.map { try $0.value() },
                               rules: rules.map { try $0.value() }, targets: targets.map { try $0.value() },
                               noSpendMarks: noSpendMarks.map { try $0.value() },
                               settings: try settings.first?.value() ?? LedgerSettings(),
                               pointCards: pointCards.map { try $0.value() })
        orders.envelopes = Dictionary(envelopes.map { ($0.id, $0.recordOrder) }, uniquingKeysWith: { first, _ in first })
        orders.categories = Dictionary(categories.map { ($0.id, $0.recordOrder) }, uniquingKeysWith: { first, _ in first })
        orders.entries = Dictionary(entries.map { ($0.id, $0.recordOrder) }, uniquingKeysWith: { first, _ in first })
        orders.receipts = Dictionary(receipts.map { ($0.id, $0.recordOrder) }, uniquingKeysWith: { first, _ in first })
        orders.rules = Dictionary(rules.map { ($0.id, $0.recordOrder) }, uniquingKeysWith: { first, _ in first })
        orders.targets = Dictionary(targets.map { ($0.id, $0.recordOrder) }, uniquingKeysWith: { first, _ in first })
        orders.noSpendMarks = Dictionary(noSpendMarks.map { ($0.id, $0.recordOrder) }, uniquingKeysWith: { first, _ in first })
        orders.settings = Dictionary(settings.map { ($0.id, $0.recordOrder) }, uniquingKeysWith: { first, _ in first })
        orders.pointCards = Dictionary(pointCards.map { ($0.id, $0.recordOrder) }, uniquingKeysWith: { first, _ in first })
        return state
    }

    /// Replaces all records in one save; callers validate before this low-level operation.
    func replace(_ state: LedgerState) throws {
        let context = makeContext()
        do {
            for item in try context.fetch(FetchDescriptor<WealthySchemaV1.Envelope>()) { context.delete(item) }
            for item in try context.fetch(FetchDescriptor<WealthySchemaV1.Category>()) { context.delete(item) }
            for item in try context.fetch(FetchDescriptor<WealthySchemaV1.LedgerEntry>()) { context.delete(item) }
            for item in try context.fetch(FetchDescriptor<WealthySchemaV1.ReceiptAttachment>()) { context.delete(item) }
            for item in try context.fetch(FetchDescriptor<WealthySchemaV1.RecurringRule>()) { context.delete(item) }
            for item in try context.fetch(FetchDescriptor<WealthySchemaV1.Target>()) { context.delete(item) }
            for item in try context.fetch(FetchDescriptor<WealthySchemaV1.NoSpendMark>()) { context.delete(item) }
            for item in try context.fetch(FetchDescriptor<WealthySchemaV1.Settings>()) { context.delete(item) }
            for item in try context.fetch(FetchDescriptor<WealthySchemaV1.PointCard>()) { context.delete(item) }
            for (index, item) in state.envelopes.enumerated() { context.insert(WealthySchemaV1.Envelope(item, order: index)) }
            for (index, item) in state.categories.enumerated() { context.insert(WealthySchemaV1.Category(item, order: index)) }
            for (index, item) in state.entries.enumerated() { context.insert(WealthySchemaV1.LedgerEntry(item, order: index)) }
            for (index, item) in state.receipts.enumerated() { context.insert(WealthySchemaV1.ReceiptAttachment(item, order: index)) }
            for (index, item) in state.rules.enumerated() { context.insert(WealthySchemaV1.RecurringRule(item, order: index)) }
            for (index, item) in state.targets.enumerated() { context.insert(WealthySchemaV1.Target(item, order: index)) }
            for (index, item) in state.noSpendMarks.enumerated() { context.insert(WealthySchemaV1.NoSpendMark(item, order: index)) }
            for (index, item) in [state.settings].enumerated() { context.insert(WealthySchemaV1.Settings(item, order: index)) }
            for (index, item) in state.pointCards.enumerated() { context.insert(WealthySchemaV1.PointCard(item, order: index)) }
            if failNextSave { failNextSave = false; throw CoreError.saveFailed }
            try context.save()
            orders.envelopes = Dictionary(state.envelopes.enumerated().map { ($0.element.id, $0.offset) }, uniquingKeysWith: { first, _ in first })
            orders.categories = Dictionary(state.categories.enumerated().map { ($0.element.id, $0.offset) }, uniquingKeysWith: { first, _ in first })
            orders.entries = Dictionary(state.entries.enumerated().map { ($0.element.id, $0.offset) }, uniquingKeysWith: { first, _ in first })
            orders.receipts = Dictionary(state.receipts.enumerated().map { ($0.element.id, $0.offset) }, uniquingKeysWith: { first, _ in first })
            orders.rules = Dictionary(state.rules.enumerated().map { ($0.element.id, $0.offset) }, uniquingKeysWith: { first, _ in first })
            orders.targets = Dictionary(state.targets.enumerated().map { ($0.element.id, $0.offset) }, uniquingKeysWith: { first, _ in first })
            orders.noSpendMarks = Dictionary(state.noSpendMarks.enumerated().map { ($0.element.id, $0.offset) }, uniquingKeysWith: { first, _ in first })
            orders.settings = [state.settings.id: 0]
            orders.pointCards = Dictionary(state.pointCards.enumerated().map { ($0.element.id, $0.offset) }, uniquingKeysWith: { first, _ in first })
        } catch {
            context.rollback()
            if let error = error as? CoreError { throw error }
            throw CoreError.saveFailed
        }
    }

    /// Seeds the default household and its reference categories.
    public func seedDefaults() throws {
        let before = try read()
        var state = before
        if !state.envelopes.contains(where: { $0.kind == .household }) {
            state.envelopes.append(EnvelopeValue(id: EnvelopeValue.householdID, name: "Household"))
        }
        let envelopeID = state.envelopes.first(where: { $0.kind == .household })!.id
        for category in CategoryPresets.household(envelopeID: envelopeID) where !state.categories.contains(where: {
            $0.envelopeID == envelopeID && $0.kind == category.kind && $0.systemKey == category.systemKey
        }) { state.categories.append(category) }
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
            try persist(changes.envelopes, as: WealthySchemaV1.Envelope.self, orders: &nextOrders.envelopes, context: context, writes: &writes, checkingUndo: checkingUndo)
            try persist(changes.categories, as: WealthySchemaV1.Category.self, orders: &nextOrders.categories, context: context, writes: &writes, checkingUndo: checkingUndo)
            try persist(changes.entries, as: WealthySchemaV1.LedgerEntry.self, orders: &nextOrders.entries, context: context, writes: &writes, checkingUndo: checkingUndo)
            try persist(changes.receipts, as: WealthySchemaV1.ReceiptAttachment.self, orders: &nextOrders.receipts, context: context, writes: &writes, checkingUndo: checkingUndo)
            try persist(changes.rules, as: WealthySchemaV1.RecurringRule.self, orders: &nextOrders.rules, context: context, writes: &writes, checkingUndo: checkingUndo)
            try persist(changes.targets, as: WealthySchemaV1.Target.self, orders: &nextOrders.targets, context: context, writes: &writes, checkingUndo: checkingUndo)
            try persist(changes.noSpendMarks, as: WealthySchemaV1.NoSpendMark.self, orders: &nextOrders.noSpendMarks, context: context, writes: &writes, checkingUndo: checkingUndo)
            try persist(changes.settings, as: WealthySchemaV1.Settings.self, orders: &nextOrders.settings, context: context, writes: &writes, checkingUndo: checkingUndo)
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
