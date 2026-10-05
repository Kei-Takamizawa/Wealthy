import Foundation
import Testing
@testable import WealthyCore

@Suite("Ledger invariants") @MainActor
struct LedgerTests {
    let now = Date(timeIntervalSince1970: 1_791_158_400)
    var calendar: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(secondsFromGMT: 0)!; return c }
    var day: LedgerDay { try! LedgerDay(year: 2026, month: 10, day: 5) }
    func entry(kind: EntryKind = .expense, amount: Int = 100, envelopeID: UUID = EnvelopeValue.householdID, category: UUID? = nil) -> EntryValue {
        EntryValue(kind: kind, amount: amount, currencyCode: "JPY", day: day, envelopeID: envelopeID, timestamp: now, categoryID: category, title: "Test", createdAt: now, updatedAt: now)
    }
    func makeCore() throws -> LedgerCore { try LedgerCore(store: LedgerStore(inMemory: true, seed: false), calendar: calendar) }
    func expectFailure(_ core: LedgerCore, _ command: LedgerCommand, _ error: CoreError) throws {
        let before = core.state
        #expect(throws: error) { try core.run(command, now: now) }
        #expect(core.state == before)
    }
    @Test("L1 expense and income persist with default household") func entryKinds() throws {
        let core = try makeCore()
        try core.run(.addEntry(entry()), now: now)
        try core.run(.addEntry(entry(kind: .income, amount: 500)), now: now)
        #expect(core.state.entries.map(\.kind) == [.expense, .income])
        #expect(core.state.entries.allSatisfy { $0.envelopeID == EnvelopeValue.householdID })
    }
    @Test("L2 cross-envelope category assignments fail atomically") func envelopeValidation() throws {
        let core = try makeCore(), child = EnvelopeValue(kind: .child, name: "Child")
        try core.run(.createEnvelope(child), now: now)
        let category = try #require(core.state.categories.first)
        let value = entry(category: category.id)
        try expectFailure(core, .addEntry(value), .invalidField("categoryEnvelope", category.id))
        let absent = UUID()
        try expectFailure(core, .addEntry(entry(envelopeID: absent)), .danglingReference("envelopeID", absent))
    }
    @Test("L3 versioned targets preserve historical months") func targetHistory() throws {
        let core = try makeCore(), october = try LedgerMonth(year: 2026, month: 10), september = try LedgerMonth(year: 2026, month: 9)
        let target = TargetValue(currencyCode: "JPY", amountMinor: 1000, effectiveMonth: october)
        try core.run(.setTarget(target), now: now)
        var old = target; old.effectiveMonth = september
        try expectFailure(core, .setTarget(old), .invalidField("effectiveMonth", old.id))
        #expect(core.state.targets == [target])
    }
    @Test("L4 multi-currency entries and unsupported codes") func currencies() throws {
        let core = try makeCore()
        var value = entry(); value.currencyCode = "USD"
        try core.run(.addEntry(value), now: now)
        var invalid = entry(); invalid.currencyCode = "ZZZ"
        try expectFailure(core, .addEntry(invalid), .unsupportedCurrency("ZZZ"))
        #expect(throws: CoreError.unsupportedCurrency("ZZZ")) { try CoreCurrency.normalizedCode("ZZZ") }
    }
    @Test("L5 nonpositive amounts and parse overflow reject atomically") func amounts() throws {
        let core = try makeCore()
        for amount in [0, -1, Int.min] { let e = entry(amount: amount); try expectFailure(core, .addEntry(e), .invalidField("amount", e.id)) }
        #expect(try CoreCurrency.parseMinorUnits("9223372036854775808", currencyCode: "JPY", locale: Locale(identifier: "en_US_POSIX")) == nil)
        try core.run(.addEntry(entry(kind: .income, amount: Int.max)), now: now)
        try core.run(.addEntry(entry(kind: .income, amount: Int.max)), now: now)
        #expect(core.state.entries.count == 2)
        let period = try LedgerPeriod.month(containing: day, calendar: calendar)
        #expect(LedgerQueries.periodSummary(in: core.state, period: period, currencyCode: "JPY").income == Decimal(Int.max) * 2)
    }
    @Test("L6 archived envelopes preserve historical entries and reject assignments") func archiveEnvelope() throws {
        let core = try makeCore(), child = EnvelopeValue(kind: .child, name: "Child")
        try core.run(.createEnvelope(child), now: now)
        try core.run(.addEntry(entry(envelopeID: child.id)), now: now)
        try core.run(.archiveEnvelope(child.id, archived: true), now: now)
        try expectFailure(core, .addEntry(entry(envelopeID: child.id)), .invalidField("archivedEnvelope", child.id))
        #expect(core.state.entries.count == 1)
        try core.run(.archiveEnvelope(child.id, archived: false), now: now)
        try core.run(.addEntry(entry(envelopeID: child.id)), now: now)
        #expect(core.state.entries.count == 2)
    }
    @Test("L7 entry amount envelope and kind updates preserve identity") func updateEntry() throws {
        let core = try makeCore(), child = EnvelopeValue(kind: .child, name: "Child")
        try core.run(.createEnvelope(child), now: now)
        var value = entry(); try core.run(.addEntry(value), now: now)
        value.amount = 200; try core.run(.updateEntry(value), now: now)
        value.envelopeID = child.id; value.kind = .income; try core.run(.updateEntry(value), now: now)
        #expect(core.state.entries.first?.id == value.id)
        #expect(core.state.entries.first?.envelopeID == child.id && core.state.entries.first?.amount == 200)
    }
    @Test("L8 envelope deletion guards historical entries") func deleteEnvelope() throws {
        let core = try makeCore(), child = EnvelopeValue(kind: .child, name: "Child")
        try core.run(.createEnvelope(child), now: now)
        try core.run(.addEntry(entry(envelopeID: child.id)), now: now)
        try expectFailure(core, .deleteEnvelope(child.id), .invalidField("envelopeHasHistory", child.id))
        try core.run(.deleteEntry(try #require(core.state.entries.first?.id)), now: now)
        try core.run(.deleteEnvelope(child.id), now: now)
        #expect(!core.state.envelopes.contains { $0.id == child.id })
    }
    @Test("L9 category kinds and archived categories enforce assignments") func categoryValidation() throws {
        let core = try makeCore(), category = CategoryValue(kind: .expense, customName: "Food")
        try core.run(.createCategory(category), now: now)
        try expectFailure(core, .addEntry(entry(kind: .income, category: category.id)), .categoryKindMismatch(category.id))
        try core.run(.addEntry(entry(category: category.id)), now: now)
        try core.run(.archiveCategory(category.id, archived: true), now: now)
        try expectFailure(core, .addEntry(entry(category: category.id)), .archivedCategory(category.id))
        #expect(core.state.entries.first?.categoryID == category.id)
    }
    @Test("L10 custom category deletion clears entries rules and category targets") func deleteCategory() throws {
        let core = try makeCore(), category = CategoryValue(kind: .expense, customName: "Food")
        var state = core.state; state.categories = [category]; state.entries = [entry(category: category.id)]
        state.rules = [RuleValue(amount: 100, currencyCode: "JPY", categoryID: category.id, schedule: .monthly(day: 5), startDay: day)]
        let month = try LedgerMonth(year: 2026, month: 10)
        state.targets = [TargetValue(currencyCode: "JPY", amountMinor: 1000, effectiveMonth: month), TargetValue(categoryID: category.id, currencyCode: "JPY", amountMinor: 500, effectiveMonth: month)]
        try core.store.replace(state); try core.reload(); try core.run(.deleteCategory(category.id), now: now)
        #expect(core.state.categories.isEmpty && core.state.entries.first?.categoryID == nil)
        #expect(core.state.rules.first?.categoryID == nil && core.state.targets.count == 1)
        #expect(core.state.entries.first?.id == state.entries.first?.id)
    }
    @Test("L11 normalized category names uniqueness separate kinds and archived reuse") func normalizedNames() throws {
        let core = try makeCore(), food = CategoryValue(kind: .expense, customName: " ＦＯＯＤ "), duplicate = CategoryValue(kind: .expense, customName: "food")
        try core.run(.createCategory(food), now: now)
        try expectFailure(core, .createCategory(duplicate), .duplicateName("food"))
        try core.run(.createCategory(CategoryValue(kind: .income, customName: "food")), now: now)
        try core.run(.archiveCategory(food.id, archived: true), now: now)
        try core.run(.createCategory(duplicate), now: now)
        #expect(CoreValidation.normalizedName(" ＦＯＯＤ \n") == "food")
    }
    @Test("L12 injected save failure rolls back complete state") func saveFailure() throws {
        let core = try makeCore(), child = EnvelopeValue(kind: .child, name: "Child")
        core.store.failNextSave = true; try expectFailure(core, .createEnvelope(child), .saveFailed)
        #expect(core.state.envelopes.count == 1 && core.state.categories.isEmpty)
        core.store.failNextSave = true; try expectFailure(core, .addEntry(entry()), .saveFailed)
        #expect(core.state.entries.isEmpty)
    }
    @Test("Duplicate IDs reject all partial mutations") func duplicateIDs() throws {
        let core = try makeCore(), id = EnvelopeValue.householdID
        try expectFailure(core, .createEnvelope(EnvelopeValue(id: id, kind: .child, name: "Child")), .duplicateID(id))
        try expectFailure(core, .createCategory(CategoryValue(id: id, kind: .expense, customName: "Food")), .duplicateID(id))
    }
}
