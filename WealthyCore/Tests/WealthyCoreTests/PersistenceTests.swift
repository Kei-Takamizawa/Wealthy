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
    func entry(_ wallet: WalletValue, amount: Int = 100) -> EntryValue {
        EntryValue(kind: .expense, amount: amount, currencyCode: wallet.currencyCode, day: day,
            walletID: wallet.id, timestamp: now, createdAt: now, updatedAt: now)
    }
    func makeCore(_ state: LedgerState = LedgerState()) throws -> LedgerCore {
        let store = try LedgerStore(inMemory: true, seed: false)
        try store.replace(state)
        return try LedgerCore(store: store, calendar: calendar)
    }
    func identities(_ core: LedgerCore) throws -> [UUID: PersistentIdentifier] {
        let context = ModelContext(core.store.container)
        var result: [UUID: PersistentIdentifier] = [:]
        for value in try context.fetch(FetchDescriptor<WealthySchemaV1.Wallet>()) { result[value.id] = value.persistentModelID }
        for value in try context.fetch(FetchDescriptor<WealthySchemaV1.Category>()) { result[value.id] = value.persistentModelID }
        for value in try context.fetch(FetchDescriptor<WealthySchemaV1.LedgerEntry>()) { result[value.id] = value.persistentModelID }
        for value in try context.fetch(FetchDescriptor<WealthySchemaV1.ReceiptAttachment>()) { result[value.id] = value.persistentModelID }
        for value in try context.fetch(FetchDescriptor<WealthySchemaV1.RecurringRule>()) { result[value.id] = value.persistentModelID }
        for value in try context.fetch(FetchDescriptor<WealthySchemaV1.Budget>()) { result[value.id] = value.persistentModelID }
        for value in try context.fetch(FetchDescriptor<WealthySchemaV1.PointCard>()) { result[value.id] = value.persistentModelID }
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
        let wallet = WalletValue(name: "Cash", currencyCode: "JPY")
        let core = try makeCore(LedgerState(wallets: [wallet], entries: [entry(wallet)]))
        var added = entry(wallet, amount: 200)
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

    @Test("P2 P3 transfer reconcile category cascade recurring and undo preserve untouched identities")
    func relationalWritesAndIdentity() throws {
        let wallet = WalletValue(name: "Cash", currencyCode: "JPY")
        let other = WalletValue(name: "Bank", currencyCode: "JPY")
        let category = CategoryValue(kind: .expense, customName: "Food")
        let unused = CategoryValue(kind: .expense, customName: "Other")
        var expense = entry(wallet); expense.categoryID = category.id
        let rule = RuleValue(amount: 50, currencyCode: "JPY", walletID: wallet.id, categoryID: category.id,
            schedule: .monthly(day: 5), startDay: day, createdAt: now)
        let budget = BudgetValue(currencyCode: "JPY", categoryID: category.id, monthlyAmount: 1_000)
        let card = PointCardValue(name: "Points", points: 5)
        let core = try makeCore(LedgerState(wallets: [wallet, other], categories: [category, unused],
            entries: [expense], rules: [rule], budgets: [budget], pointCards: [card]))
        var transfer = entry(wallet); transfer.kind = .transfer; transfer.counterpartWalletID = other.id
        var old = try identities(core)
        try core.run(.addEntry(transfer), now: now)
        try expectPreserved(old, core, excluding: [transfer.id])
        old = try identities(core)
        try core.run(.reconcileWallet(wallet.id, actualBalance: 100, day: day), now: now)
        try expectPreserved(old, core, excluding: [])
        old = try identities(core)
        try core.undo(now: now)
        try expectPreserved(old, core, excluding: Set(old.keys).subtracting(core.state.allIDs))
        old = try identities(core)
        let before = core.state
        try core.run(.deleteCategory(category.id), now: now)
        #expect(core.store.lastWrites == PersistenceWrites(inserts: 0, updates: 2, deletes: 2, saves: 1))
        try expectPreserved(old, core, excluding: [category.id, expense.id, rule.id, budget.id])
        try core.undo(now: now)
        #expect(core.state == before)
        try expectPreserved(old, core, excluding: [category.id, budget.id])
        old = try identities(core)
        let posted = try core.postRecurring(through: day, now: now)
        #expect(posted.posted.count == 1)
        try expectPreserved(old, core, excluding: [rule.id])
    }

    @Test("P4 P6 save failures no-ops preview and empty undo leave cached state and revision unchanged")
    func revisionAndFailure() throws {
        let wallet = WalletValue(name: "Cash", currencyCode: "JPY")
        let core = try makeCore(LedgerState(wallets: [wallet]))
        #expect(core.revision == 0)
        #expect(core.preview(.addEntry(entry(wallet)), now: now).isValid)
        #expect(core.revision == 0)
        try core.undo(now: now)
        #expect(core.revision == 0)
        try core.run(.archiveWallet(wallet.id, archived: false), now: now)
        #expect(core.revision == 0 && core.undoCount == 0)
        let before = core.state, old = try identities(core)
        core.store.failNextSave = true
        #expect(throws: CoreError.saveFailed) { try core.run(.addEntry(entry(wallet)), now: now) }
        #expect(core.state == before && core.revision == 0 && core.undoCount == 0)
        try expectPreserved(old, core, excluding: [])
        try core.run(.addEntry(entry(wallet)), now: now)
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
        let wallet = WalletValue(name: "Cash", currencyCode: "JPY")
        let core = try makeCore(LedgerState(wallets: [wallet]))
        let added = entry(wallet)
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
        let wallet = WalletValue(name: "Cash", currencyCode: "JPY")
        let entries = [entry(wallet, amount: 1), entry(wallet, amount: 2), entry(wallet, amount: 3)]
        let core = try makeCore(LedgerState(wallets: [wallet], entries: entries))
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
        var wallet = WalletValue(name: "Cash", currencyCode: "JPY")
        let other = WalletValue(name: "Bank", currencyCode: "JPY")
        var category = CategoryValue(kind: .expense, customName: "Food")
        var rule = RuleValue(amount: 20, currencyCode: "JPY", walletID: wallet.id, categoryID: category.id,
            schedule: .monthly(day: 5), startDay: day, createdAt: now)
        var card = PointCardValue(name: "Points", points: 0)
        let budget = BudgetValue(currencyCode: "JPY", categoryID: category.id, monthlyAmount: 100)
        let expense = entry(wallet)
        func run(_ command: LedgerCommand) throws {
            try core.run(command, now: now)
            try CoreValidation.validate(core.state)
            #expect(try core.store.read() == core.state)
        }
        try run(.createWallet(wallet)); try run(.createWallet(other))
        wallet.name = "Renamed"; try run(.updateWallet(wallet))
        try run(.archiveWallet(wallet.id, archived: true)); try run(.archiveWallet(wallet.id, archived: false))
        try run(.reconcileWallet(wallet.id, actualBalance: 50, day: day))
        try run(.createCategory(category)); category.customName = "Meals"; try run(.updateCategory(category))
        try run(.archiveCategory(category.id, archived: true)); try run(.archiveCategory(category.id, archived: false))
        try run(.addEntry(expense)); var changed = expense; changed.amount = 200; try run(.updateEntry(changed))
        try run(.markReviewed(expense.id)); try run(.deleteEntry(expense.id))
        try run(.createRule(rule)); rule.title = "Rule"; try run(.updateRule(rule))
        try run(.pauseRule(rule.id, paused: true)); try run(.pauseRule(rule.id, paused: false))
        try run(.setBudget(budget)); try run(.removeBudget(budget.id))
        try run(.createPointCard(card)); card.points = 10; try run(.updatePointCard(card)); try run(.deletePointCard(card.id))
        try run(.deleteRule(rule.id)); try run(.deleteCategory(category.id)); try run(.deleteWallet(other.id))
        while core.undoCount > 0 { try core.undo(now: now); try CoreValidation.validate(core.state) }
    }
}
