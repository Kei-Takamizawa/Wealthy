import Foundation
import Testing
@testable import WealthyCore

@Suite("History and recurring regression cases")
struct EdgeTests {
    var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }

    @Test("R5 an existing occurrence with a stale cursor does not duplicate or block other rules")
    @MainActor
    func existingOccurrenceAndOtherRules() throws {
        let start = try LedgerDay(year: 2027, month: 1, day: 1)
        let due = try LedgerDay(year: 2027, month: 1, day: 31)
        let now = try due.date(calendar: calendar)
        let core = try LedgerCore(store: try LedgerStore(inMemory: true, seed: false), calendar: calendar)
        let envelope = EnvelopeValue(id: EnvelopeValue.householdID, name: "Cash", createdAt: Date(timeIntervalSince1970: 0))
        let stale = RuleValue(title: "Already posted", amount: 100, currencyCode: "JPY", envelopeID: envelope.id,
            schedule: .monthly(day: 31), startDay: start, createdAt: now)
        let other = RuleValue(title: "Other rule", amount: 50, currencyCode: "JPY", envelopeID: envelope.id,
            schedule: .monthly(day: 31), startDay: start, createdAt: now)
        try core.run(.updateEnvelope(envelope), now: now)
        try core.run(.createRule(stale), now: now)
        try core.run(.createRule(other), now: now)
        let existing = EntryValue(kind: .expense, amount: 100, currencyCode: "JPY", day: due,
            envelopeID: envelope.id, timestamp: now, title: "Already posted", source: .recurring,
            recurringRuleID: stale.id, occurrenceDay: due, createdAt: now, updatedAt: now)
        var state = try core.snapshot()
        state.entries.append(existing)
        try CoreValidation.validate(state)
        try core.store.replace(state)
        try core.reload()
        let historyCount = core.undoCount
        let result = try core.postRecurring(through: due, now: now)
        #expect(result.failures.isEmpty)
        #expect(result.posted.count == 1 && result.posted[0].recurringRuleID == other.id)
        let after = try core.snapshot()
        #expect(after.entries.count == 2 && after.entries.first == existing)
        #expect(after.rules.first { $0.id == stale.id }?.lastPostedDay == due)
        #expect(after.rules.first { $0.id == stale.id }?.lastProcessedDay == due)
        #expect(core.undoCount == historyCount)
        #expect(try core.postRecurring(through: due, now: now).posted.isEmpty)
    }

    @Test("U2 undo preserves unrelated external additions and field changes")
    @MainActor
    func undoPreservesUnrelatedExternalChanges() throws {
        let day = try LedgerDay(year: 2027, month: 1, day: 5)
        let now = try day.date(calendar: calendar)
        let core = try LedgerCore(store: try LedgerStore(inMemory: true, seed: false), calendar: calendar)
        var envelope = EnvelopeValue(id: EnvelopeValue.householdID, name: "Cash", createdAt: Date(timeIntervalSince1970: 0))
        try core.run(.updateEnvelope(envelope), now: now)
        core.clearUndoHistory()
        let expense = EntryValue(kind: .expense, amount: 100, currencyCode: "JPY", day: day,
            envelopeID: envelope.id, timestamp: now, createdAt: now, updatedAt: now)
        try core.run(.addEntry(expense), now: now)
        let externalEnvelope = EnvelopeValue(kind: .child, name: "External", createdAt: now)
        let externalIncome = EntryValue(kind: .income, amount: 500, currencyCode: "USD", day: day,
            envelopeID: externalEnvelope.id, timestamp: now, createdAt: now, updatedAt: now)
        envelope.name = "Externally renamed"
        var current = try core.snapshot()
        current.envelopes = [envelope, externalEnvelope]
        current.entries.append(externalIncome)
        try CoreValidation.validate(current)
        try core.store.replace(current)
        try core.reload()
        var expected = current
        expected.entries.removeAll { $0.id == expense.id }
        let result = try core.undo(now: now)
        #expect(result != nil)
        #expect(try core.snapshot() == expected)
        #expect(core.undoCount == 0)
        #expect(try core.undo(now: now) == nil)
    }

    @Test("Command payloads remain Codable and Sendable across actor boundaries")
    func commandCrossActorRoundTrip() async throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let envelope = EnvelopeValue(name: "Voice envelope", createdAt: now)
        let command = LedgerCommand.updateEnvelope(envelope)
        let decoded = try await Task.detached {
            try JSONDecoder().decode(LedgerCommand.self, from: JSONEncoder().encode(command))
        }.value
        #expect(decoded == command)
    }
    @Test("Renames preserve ID assignments; review clearing and metadata edits undo exactly")
    @MainActor
    func metadataAndReviewCommands() throws {
        let day = try LedgerDay(year: 2027, month: 1, day: 5)
        let now = try day.date(calendar: calendar)
        let core = try LedgerCore(store: try LedgerStore(inMemory: true, seed: false), calendar: calendar)
        var envelope = EnvelopeValue(id: EnvelopeValue.householdID, name: "Cash", createdAt: Date(timeIntervalSince1970: 0))
        var category = CategoryValue(kind: .expense, customName: "Food")
        try core.run(.updateEnvelope(envelope), now: now)
        try core.run(.createCategory(category), now: now)
        let expense = EntryValue(kind: .expense, amount: 100, currencyCode: "JPY", day: day,
            envelopeID: envelope.id, timestamp: now, categoryID: category.id, reviewFlags: [.amountUncertain, .dateFromCaptureTime],
            createdAt: now, updatedAt: now)
        try core.run(.addEntry(expense), now: now)
        let original = try core.snapshot()
        envelope.name = "Household renamed"
        try core.run(.updateEnvelope(envelope), now: now)
        category.customName = "Meals"; category.colorKey = "orange"; category.iconKey = "fork.knife"; category.sortOrder = 2
        try core.run(.updateCategory(category), now: now)
        let renamed = try core.snapshot()
        #expect(renamed.envelopes == [envelope] && renamed.categories == [category])
        #expect(renamed.entries == [expense])
        let reviewPreview = core.preview(.markReviewed(expense.id), now: now)
        #expect(reviewPreview.isValid)
        #expect(try core.snapshot() == renamed)
        try core.run(.markReviewed(expense.id), now: now.addingTimeInterval(1))
        let reviewed = try #require(core.snapshot().entries.first)
        #expect(!reviewed.needsReview && reviewed.updatedAt == now.addingTimeInterval(1))
        _ = try core.undo(now: now)
        #expect(try core.snapshot() == renamed)
        _ = try core.undo(now: now)
        _ = try core.undo(now: now)
        #expect(try core.snapshot() == original)
        try core.run(.archiveCategory(category.id, archived: true), now: now)
        try core.run(.archiveCategory(category.id, archived: false), now: now)
        #expect(try core.snapshot().categories == original.categories)
    }

}
