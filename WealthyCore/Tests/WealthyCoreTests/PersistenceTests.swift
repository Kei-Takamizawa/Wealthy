import Foundation
import Observation
import SwiftData
import Testing
@testable import WealthyCore

@Suite("Incremental persistence and observable state")
@MainActor
struct PersistenceTests {
    let now = Date(timeIntervalSince1970: 1_791_158_400)
    var day: LedgerDay { try! LedgerDay(year: 2026, month: 10, day: 5) }
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
    func entry(_ envelope: EnvelopeValue, amount: Int = 100) -> EntryValue {
        EntryValue(kind: .expense, amount: amount, currencyCode: "JPY", day: day,
            envelopeID: envelope.id, timestamp: now, createdAt: now, updatedAt: now)
    }
    func makeCore(_ state: LedgerState = LedgerState()) throws -> LedgerCore {
        let store = try LedgerStore(inMemory: true, seed: false)
        try store.replace(state)
        return try LedgerCore(store: store, calendar: calendar)
    }
    func identities(_ core: LedgerCore) throws -> [UUID: PersistentIdentifier] {
        let context = ModelContext(core.store.container)
        var result: [UUID: PersistentIdentifier] = [:]
        for value in try context.fetch(FetchDescriptor<WealthySchemaV1.Envelope>()) { result[value.id] = value.persistentModelID }
        for value in try context.fetch(FetchDescriptor<WealthySchemaV1.Category>()) { result[value.id] = value.persistentModelID }
        for value in try context.fetch(FetchDescriptor<WealthySchemaV1.LedgerEntry>()) { result[value.id] = value.persistentModelID }
        for value in try context.fetch(FetchDescriptor<WealthySchemaV1.ReceiptAttachment>()) { result[value.id] = value.persistentModelID }
        for value in try context.fetch(FetchDescriptor<WealthySchemaV1.RecurringRule>()) { result[value.id] = value.persistentModelID }
        for value in try context.fetch(FetchDescriptor<WealthySchemaV1.Target>()) { result[value.id] = value.persistentModelID }
        for value in try context.fetch(FetchDescriptor<WealthySchemaV1.PointCard>()) { result[value.id] = value.persistentModelID }
        for value in try context.fetch(FetchDescriptor<WealthySchemaV1.NoSpendMark>()) { result[value.id] = value.persistentModelID }
        for value in try context.fetch(FetchDescriptor<WealthySchemaV1.Settings>()) { result[value.id] = value.persistentModelID }
        return result
    }
    func expectPreserved(_ old: [UUID: PersistentIdentifier], _ core: LedgerCore, excluding: Set<UUID>) throws {
        let new = try identities(core)
        for (id, identity) in old where !excluding.contains(id) { #expect(new[id] == identity) }
        try CoreValidation.validate(core.state)
        #expect(try core.store.read() == core.state)
    }

    @Test("P1 individual entry commands write exactly one record and one save")
    func singleEntryWrites() throws {
        let envelope = EnvelopeValue(id: EnvelopeValue.householdID, name: "Household")
        let core = try makeCore(LedgerState(envelopes: [envelope], entries: [entry(envelope)]))
        var added = entry(envelope, amount: 200)
        var previous = try identities(core)
        try core.run(.addEntry(added), now: now)
        #expect(core.store.lastWrites == PersistenceWrites(inserts: 1, updates: 0, deletes: 0, saves: 1))
        try expectPreserved(previous, core, excluding: [added.id])
        previous = try identities(core)
        added.amount = 300
        try core.run(.updateEntry(added), now: now.addingTimeInterval(1))
        #expect(core.store.lastWrites == PersistenceWrites(inserts: 0, updates: 1, deletes: 0, saves: 1))
        // An in-place update also preserves the touched row's persistent identity.
        try expectPreserved(previous, core, excluding: [])
        try core.run(.deleteEntry(added.id), now: now)
        #expect(core.store.lastWrites == PersistenceWrites(inserts: 0, updates: 0, deletes: 1, saves: 1))
        try expectPreserved(previous, core, excluding: [added.id])
    }

    @Test("P2 P3 envelope category cascade recurring and undo preserve untouched identities")
    func relationalWritesAndIdentity() throws {
        let envelope = EnvelopeValue(id: EnvelopeValue.householdID, name: "Household")
        let other = EnvelopeValue(kind: .child, name: "Child")
        let category = CategoryValue(kind: .expense, customName: "Food")
        let unused = CategoryValue(kind: .expense, customName: "Other")
        var expense = entry(envelope); expense.categoryID = category.id
        let rule = RuleValue(amount: 50, currencyCode: "JPY", envelopeID: envelope.id, categoryID: category.id,
            schedule: .monthly(day: 5), startDay: day, createdAt: now)
        let target = TargetValue(categoryID: category.id, currencyCode: "JPY", amountMinor: 1_000, effectiveMonth: LedgerMonth(day: day))
        let card = PointCardValue(name: "Points", points: 5)
        let core = try makeCore(LedgerState(envelopes: [envelope, other], categories: [category, unused],
            entries: [expense], rules: [rule], targets: [target], pointCards: [card]))
        let childEntry = EntryValue(kind: .expense, amount: 50, currencyCode: "JPY", day: day, envelopeID: other.id)
        var old = try identities(core)
        try core.run(.addEntry(childEntry), now: now)
        try expectPreserved(old, core, excluding: [childEntry.id])
        old = try identities(core)
        try core.undo(now: now)
        try expectPreserved(old, core, excluding: [childEntry.id])
        old = try identities(core)
        let before = core.state
        try core.run(.deleteCategory(category.id), now: now)
        #expect(core.store.lastWrites == PersistenceWrites(inserts: 0, updates: 2, deletes: 2, saves: 1))
        try expectPreserved(old, core, excluding: [category.id, expense.id, rule.id, target.id])
        try core.undo(now: now)
        #expect(core.state == before)
        try expectPreserved(old, core, excluding: [category.id, target.id])
        old = try identities(core)
        let posted = try core.postRecurring(through: day, now: now)
        #expect(posted.posted.count == 1)
        try expectPreserved(old, core, excluding: [rule.id])
    }

    @Test("P4 P6 save failures no-ops preview and empty undo leave cached state and revision unchanged")
    func revisionAndFailure() throws {
        let envelope = EnvelopeValue(id: EnvelopeValue.householdID, name: "Household")
        let core = try makeCore(LedgerState(envelopes: [envelope]))
        #expect(core.revision == 0)
        #expect(core.preview(.addEntry(entry(envelope)), now: now).isValid)
        #expect(core.revision == 0)
        try core.undo(now: now)
        #expect(core.revision == 0)
        try core.run(.archiveEnvelope(envelope.id, archived: false), now: now)
        #expect(core.revision == 0 && core.undoCount == 0)
        let before = core.state, old = try identities(core)
        core.store.failNextSave = true
        #expect(throws: CoreError.saveFailed) { try core.run(.addEntry(entry(envelope)), now: now) }
        #expect(core.state == before && core.revision == 0 && core.undoCount == 0)
        try expectPreserved(old, core, excluding: [])
        try core.run(.addEntry(entry(envelope)), now: now)
        #expect(core.revision == 1 && core.undoCount == 1)
        let added = core.state
        core.store.failNextSave = true
        #expect(throws: CoreError.saveFailed) { try core.undo(now: now) }
        #expect(core.state == added && core.revision == 1 && core.undoCount == 1)
        try core.undo(now: now)
        #expect(core.state == before && core.revision == 2 && core.undoCount == 0)
    }

    @Test("P6 reload reads a separate ModelContext and retains undo history")
    func externalContextReload() throws {
        let envelope = EnvelopeValue(id: EnvelopeValue.householdID, name: "Household")
        let core = try makeCore(LedgerState(envelopes: [envelope]))
        let added = entry(envelope)
        try core.run(.addEntry(added), now: now)
        let context = ModelContext(core.store.container)
        context.autosaveEnabled = false
        let persisted = try #require(context.fetch(FetchDescriptor<WealthySchemaV1.LedgerEntry>()).first)
        persisted.title = "External title"
        try context.save()
        #expect(core.state.entries.first?.title == "")
        try core.reload()
        #expect(core.state.entries.first?.title == "External title")
        #expect(core.revision == 2 && core.undoCount == 1)
        try core.reload()
        #expect(core.revision == 2)
        #expect(throws: CoreError.undoConflict) { try core.undo(now: now) }
        #expect(core.revision == 2 && core.undoCount == 1)
    }

    @Test("P7 deletion undo restores sparse recordOrder without moving surviving records")
    func sparseOrderUndo() throws {
        let envelope = EnvelopeValue(id: EnvelopeValue.householdID, name: "Household")
        let entries = [entry(envelope, amount: 1), entry(envelope, amount: 2), entry(envelope, amount: 3)]
        let core = try makeCore(LedgerState(envelopes: [envelope], entries: entries))
        let before = core.state, orders = core.store.orders.entries
        try core.run(.deleteEntry(entries[0].id), now: now)
        try core.run(.deleteEntry(entries[1].id), now: now)
        try core.undo(now: now)
        try core.undo(now: now)
        #expect(core.state == before)
        #expect(core.store.orders.entries == orders)
        #expect(try core.store.read() == before)
    }

    @Test("Incremental validation agrees with full validation after every command")
    func everyCommandFullValidation() throws {
        let core = try makeCore()
        var envelope = core.state.envelopes[0]
        let other = EnvelopeValue(kind: .child, name: "Child")
        var category = CategoryValue(kind: .expense, customName: "Food")
        var rule = RuleValue(amount: 20, currencyCode: "JPY", envelopeID: envelope.id, categoryID: category.id,
            schedule: .monthly(day: 5), startDay: day, createdAt: now)
        var card = PointCardValue(name: "Points", points: 0)
        let target = TargetValue(categoryID: category.id, currencyCode: "JPY", amountMinor: 100, effectiveMonth: LedgerMonth(day: day))
        let expense = entry(envelope)
        func run(_ command: LedgerCommand) throws {
            try core.run(command, now: now)
            try CoreValidation.validate(core.state)
            #expect(try core.store.read() == core.state)
        }
        try run(.updateEnvelope(envelope)); try run(.createEnvelope(other))
        envelope.name = "Renamed"; try run(.updateEnvelope(envelope))
        try run(.archiveEnvelope(envelope.id, archived: true)); try run(.archiveEnvelope(envelope.id, archived: false))
        try run(.createCategory(category)); category.customName = "Meals"; try run(.updateCategory(category))
        try run(.archiveCategory(category.id, archived: true)); try run(.archiveCategory(category.id, archived: false))
        try run(.addEntry(expense)); var changed = expense; changed.amount = 200; try run(.updateEntry(changed))
        try run(.markReviewed(expense.id)); try run(.deleteEntry(expense.id))
        try run(.createRule(rule)); rule.title = "Rule"; try run(.updateRule(rule))
        try run(.pauseRule(rule.id, paused: true)); try run(.pauseRule(rule.id, paused: false))
        try run(.setTarget(target)); try run(.removeTarget(target.id))
        try run(.markNoSpend(day, envelopeID: envelope.id)); try run(.unmarkNoSpend(day, envelopeID: envelope.id))
        try run(.updateSettings(LedgerSettings(includeFixedCostsInTargets: true)))
        try run(.createPointCard(card)); card.points = 10; try run(.updatePointCard(card)); try run(.deletePointCard(card.id))
        try run(.deleteRule(rule.id)); try run(.deleteCategory(category.id)); try run(.deleteEnvelope(other.id))
        while core.undoCount > 0 { try core.undo(now: now); try CoreValidation.validate(core.state) }
    }
    @Test("New domain entities preserve incremental writes and exact undo")
    func newDomainWrites() throws {
        let core = try makeCore()
        let child = EnvelopeValue(kind: .child, name: "Child")
        let before = core.state
        try core.run(.createEnvelope(child), now: now)
        // Child creation includes its seven reference categories in the same save.
        #expect(core.store.lastWrites == PersistenceWrites(inserts: 8, updates: 0, deletes: 0, saves: 1))
        try core.undo(now: now)
        #expect(core.state == before)
        let target = TargetValue(currencyCode: "JPY", amountMinor: 1_000, effectiveMonth: LedgerMonth(day: day))
        try core.run(.setTarget(target), now: now)
        #expect(core.store.lastWrites == PersistenceWrites(inserts: 1, updates: 0, deletes: 0, saves: 1))
        var changed = target; changed.amountMinor = 2_000
        try core.run(.setTarget(changed), now: now)
        #expect(core.store.lastWrites == PersistenceWrites(inserts: 0, updates: 1, deletes: 0, saves: 1))
        try core.run(.removeTarget(target.id), now: now)
        #expect(core.store.lastWrites == PersistenceWrites(inserts: 0, updates: 0, deletes: 1, saves: 1))
        try core.run(.markNoSpend(day), now: now)
        #expect(core.store.lastWrites == PersistenceWrites(inserts: 1, updates: 0, deletes: 0, saves: 1))
        try core.run(.unmarkNoSpend(day), now: now)
        #expect(core.store.lastWrites == PersistenceWrites(inserts: 0, updates: 0, deletes: 1, saves: 1))
        try core.run(.updateSettings(LedgerSettings(includeFixedCostsInTargets: true)), now: now)
        #expect(core.store.lastWrites == PersistenceWrites(inserts: 0, updates: 1, deletes: 0, saves: 1))
        while core.undoCount > 0 { try core.undo(now: now) }
        #expect(core.state == before)
        #expect(try core.store.read() == before)
    }

}
