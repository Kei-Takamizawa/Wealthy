import Foundation
import Testing
@testable import WealthyCore

@Suite("Recurring and supporting commands")
@MainActor
struct RecurringTests {
    var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }
    func day(_ year: Int, _ month: Int, _ date: Int) -> LedgerDay {
        try! LedgerDay(year: year, month: month, day: date)
    }
    func now(_ day: LedgerDay) throws -> Date { try day.date(calendar: calendar) }
    func core() throws -> LedgerCore {
        try LedgerCore(store: try LedgerStore(inMemory: true, seed: false), calendar: calendar)
    }
    func setup(_ core: LedgerCore, start: LedgerDay, schedule: RecurringSchedule = .monthly(day: 31)) throws -> RuleValue {
        let rule = RuleValue(title: "Rent", amount: 100, currencyCode: "JPY",                              schedule: schedule, startDay: start, createdAt: try now(start))
        try core.run(.createRule(rule), now: now(start))
        return rule
    }

    @Test("R1 monthly day31 clamps Jan Feb leap Feb and Apr")
    func monthEndClamping() throws {
        for (year, month, expected) in [(2027, 1, 31), (2027, 2, 28), (2028, 2, 29), (2027, 4, 30)] {
            let core = try core(), start = day(year, month, 1), end = day(year, month, expected)
            let rule = try setup(core, start: start)
            let result = try core.postRecurring(through: end, now: now(end))
            #expect(result.failures.isEmpty)
            #expect(result.posted.map(\.day) == [end])
            #expect(result.posted.first?.recurringRuleID == rule.id)
            #expect(result.posted.first?.occurrenceDay == end)
            #expect(result.posted.first?.source == .recurring)
        }
    }

    @Test("R2 three missed months catch up and persisted cursor prevents repeats")
    func catchUpAndRelaunch() throws {
        let core = try core(), start = day(2027, 1, 1), end = day(2027, 3, 31)
        let rule = try setup(core, start: start)
        let result = try core.postRecurring(through: end, now: now(end))
        #expect(result.posted.map(\.day) == [day(2027, 1, 31), day(2027, 2, 28), end])
        #expect(result.failures.isEmpty)
        let newSession = try LedgerCore(store: core.store, calendar: calendar)
        let repeated = try newSession.postRecurring(through: end, now: now(end))
        #expect(repeated.posted.isEmpty && repeated.failures.isEmpty)
        #expect(try newSession.snapshot().rules.first { $0.id == rule.id }?.lastPostedDay == end)
    }

    @Test("R3 future paused resume and ended rules respect the cutoff")
    func pauseResumeAndEnd() throws {
        let core = try core(), start = day(2027, 1, 1)
        let rule = try setup(core, start: start)
        let future = try core.postRecurring(through: day(2027, 1, 30), now: now(day(2027, 1, 30)))
        #expect(future.posted.isEmpty)
        try core.run(.pauseRule(rule.id, paused: true), now: now(day(2027, 1, 30)))
        #expect(try core.postRecurring(through: day(2027, 3, 31), now: now(day(2027, 3, 31))).posted.isEmpty)
        try core.run(.pauseRule(rule.id, paused: false), now: now(day(2027, 3, 31)))
        let resumed = try core.postRecurring(through: day(2027, 4, 30), now: now(day(2027, 4, 30)))
        #expect(resumed.posted.map(\.day) == [day(2027, 4, 30)])
        var updated = try #require(core.snapshot().rules.first)
        updated.endDay = day(2027, 5, 31)
        try core.run(.updateRule(updated), now: now(day(2027, 4, 30)))
        #expect(try core.postRecurring(through: day(2027, 5, 31), now: now(day(2027, 5, 31))).posted.map(\.day) == [day(2027, 5, 31)])
        #expect(try core.postRecurring(through: day(2027, 6, 30), now: now(day(2027, 6, 30))).posted.isEmpty)
        let expired = try self.core()
        var expiredRule = try setup(expired, start: start)
        expiredRule.endDay = day(2027, 1, 31)
        try expired.run(.updateRule(expiredRule), now: now(start))
        #expect(try expired.postRecurring(through: day(2027, 2, 28), now: now(day(2027, 2, 28))).posted.map(\.day) == [day(2027, 1, 31)])
    }

    @Test("R4 yearly leap-day fallback and weekly weekday")
    func yearlyAndWeekly() throws {
        let yearly = try core(), start = day(2027, 1, 1)
        _ = try setup(yearly, start: start, schedule: .yearly(month: 2, day: 29))
        let end = day(2028, 2, 29)
        #expect(try yearly.postRecurring(through: end, now: now(end)).posted.map(\.day) == [day(2027, 2, 28), end])
        let weekly = try core()
        _ = try setup(weekly, start: day(2027, 1, 1), schedule: .weekly(weekday: 2))
        let result = try weekly.postRecurring(through: day(2027, 1, 15), now: now(day(2027, 1, 15)))
        #expect(result.posted.map(\.day) == [day(2027, 1, 4), day(2027, 1, 11)])
    }

    @Test("R5 deleting posted entry cannot repost; invalid rules do not block others")
    func deletionAndFailures() throws {
        let core = try core(), start = day(2027, 1, 1), end = day(2027, 3, 31)
        let bad = try setup(core, start: start)
        let child = EnvelopeValue(kind: .child, name: "Child")
        try core.run(.createEnvelope(child), now: now(start))
        let good = RuleValue(amount: 50, currencyCode: "JPY", envelopeID: child.id,
                             schedule: .monthly(day: 31), startDay: start, createdAt: try now(start))
        try core.run(.createRule(good), now: now(start))
        try core.run(.archiveEnvelope(bad.envelopeID, archived: true), now: now(start))
        let result = try core.postRecurring(through: end, now: now(end))
        #expect(result.posted.count == 3 && result.failures.count == 3)
        #expect(result.failures.allSatisfy { $0.ruleID == bad.id && $0.error == .invalidField("archivedEnvelope", bad.envelopeID) })
        #expect(result.failures.map(\.day) == [day(2027, 1, 31), day(2027, 2, 28), end])
        let firstID = try #require(result.posted.first?.id)
        try core.run(.deleteEntry(firstID), now: now(end))
        let second = try core.postRecurring(through: end, now: now(end))
        #expect(second.posted.isEmpty && second.failures.isEmpty)
        #expect(try core.snapshot().entries.count == 2)
    }

    @Test("U2 recurring bypasses undo history and conflicts with envelope creation undo")
    func recurringHistory() throws {
        let core = try core(), start = day(2027, 1, 1), end = day(2027, 1, 31)
        let rule = try setup(core, start: start)
        core.clearUndoHistory()
        let beforeCount = core.undoCount
        _ = try core.postRecurring(through: end, now: now(end))
        #expect(core.undoCount == beforeCount)
        #expect(try core.undo(now: now(end)) == nil)
        let other = try self.core()
        let child = EnvelopeValue(kind: .child, name: "Child")
        try other.run(.createEnvelope(child), now: now(start))
        var state = try other.snapshot()
        var injected = rule; injected.id = UUID(); injected.envelopeID = child.id
        state.rules = [injected]
        try other.store.replace(state)
        try other.reload()
        _ = try other.postRecurring(through: end, now: now(end))
        let postedState = try other.snapshot()
        #expect(throws: CoreError.undoConflict) { try other.undo(now: now(end)) }
        #expect(try other.snapshot() == postedState)
    }

    @Test("Recurring batch save failure leaves records cursors and history unchanged")
    func recurringSaveFailure() throws {
        let core = try core(), start = day(2027, 1, 1), end = day(2027, 3, 31)
        _ = try setup(core, start: start)
        let before = try core.snapshot(), count = core.undoCount
        core.store.failNextSave = true
        #expect(throws: CoreError.saveFailed) { try core.postRecurring(through: end, now: now(end)) }
        #expect(try core.snapshot() == before)
        #expect(core.undoCount == count)
        #expect(try core.postRecurring(through: end, now: now(end)).posted.count == 3)
    }

    @Test("Rule create update pause resume delete retains posted entries")
    func ruleCRUD() throws {
        let core = try core(), start = day(2027, 1, 1), end = day(2027, 1, 31)
        var rule = try setup(core, start: start)
        rule.title = "Updated"; rule.amount = 200; rule.schedule = .monthly(day: 15)
        try core.run(.updateRule(rule), now: now(start))
        #expect(try core.snapshot().rules.first?.amount == 200)
        try core.run(.pauseRule(rule.id, paused: true), now: now(start))
        #expect(try core.snapshot().rules.first?.isPaused == true)
        try core.run(.pauseRule(rule.id, paused: false), now: now(start))
        let posted = try core.postRecurring(through: end, now: now(end))
        #expect(posted.posted.count == 1)
        try core.run(.deleteRule(rule.id), now: now(end))
        let state = try core.snapshot()
        #expect(state.rules.isEmpty)
        #expect(state.entries.first?.id == posted.posted.first?.id)
        #expect(state.entries.first == posted.posted.first)
    }

    @Test("Target upsert preserves IDs and point-card CRUD preserves integer points")
    func targetAndPointCardCRUD() throws {
        let core = try core(), today = day(2027, 1, 1)
        let target = TargetValue(currencyCode: "JPY", amountMinor: 1_000, effectiveMonth: LedgerMonth(day: today))
        try core.run(.setTarget(target), now: now(today))
        try core.run(.setTarget(TargetValue(currencyCode: "JPY", amountMinor: 2_000, effectiveMonth: LedgerMonth(day: today))), now: now(today))
        let stored = try #require(core.snapshot().targets.first)
        #expect(stored.id == target.id && stored.amountMinor == 2_000)
        #expect(try core.snapshot().targets.count == 1)
        try core.run(.removeTarget(stored.id), now: now(today))
        #expect(try core.snapshot().targets.isEmpty)
        var card = PointCardValue(name: "Rewards", memberNumber: "000123", points: 0)
        try core.run(.createPointCard(card), now: now(today))
        card.points = 42; card.expiryDay = day(2028, 1, 1)
        try core.run(.updatePointCard(card), now: now(today))
        #expect(try core.snapshot().pointCards == [card])
        #expect(try core.snapshot().entries.isEmpty)
        try core.run(.deletePointCard(card.id), now: now(today))
        #expect(try core.snapshot().pointCards.isEmpty)
    }

    @Test("Invalid rule target and points commands reject atomically")
    func supportingCommandValidation() throws {
        let core = try core(), start = day(2027, 1, 1)
        var rule = try setup(core, start: start)
        let before = try core.snapshot()
        rule.id = UUID(); rule.amount = 0
        #expect(throws: CoreError.invalidField("amount", rule.id)) { try core.run(.createRule(rule), now: now(start)) }
        #expect(try core.snapshot() == before)
        let target = TargetValue(currencyCode: "JPY", amountMinor: -1, effectiveMonth: LedgerMonth(day: start))
        #expect(throws: CoreError.invalidField("amountMinor", target.id)) { try core.run(.setTarget(target), now: now(start)) }
        let card = PointCardValue(name: "Bad", points: -1)
        #expect(throws: CoreError.invalidField("points", card.id)) { try core.run(.createPointCard(card), now: now(start)) }
        #expect(try core.snapshot() == before)
    }
    @Test("R2 a reopened disk store retains recurring occurrence cursors")
    func persistedRelaunch() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("RecurringRelaunch-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let start = day(2027, 1, 1), end = day(2027, 3, 31)
        let posted: LedgerState
        let ruleID: UUID
        do {
            let session = try LedgerCore(store: try LedgerStore(inMemory: false, directory: directory, seed: false), calendar: calendar)
            ruleID = try setup(session, start: start).id
            #expect(try session.postRecurring(through: end, now: now(end)).posted.count == 3)
            posted = try session.snapshot()
        }
        let reopened = try LedgerCore(store: try LedgerStore(inMemory: false, directory: directory, seed: false), calendar: calendar)
        #expect(try reopened.snapshot() == posted)
        #expect(try reopened.snapshot().rules.first { $0.id == ruleID }?.lastPostedDay == end)
        let repeated = try reopened.postRecurring(through: end, now: now(end))
        #expect(repeated.posted.isEmpty && repeated.failures.isEmpty)
        #expect(try reopened.snapshot().entries.count == 3)
    }

    @Test("R3 resume skips only paused days and catches pre-pause backlog")
    func pausePreservesEarlierBacklog() throws {
        let core = try core(), start = day(2027, 1, 1)
        _ = try setup(core, start: start, schedule: .monthly(day: 1))
        let ruleID = try #require(core.snapshot().rules.first?.id)
        try core.run(.pauseRule(ruleID, paused: true), now: now(day(2027, 1, 15)))
        try core.run(.pauseRule(ruleID, paused: false), now: now(day(2027, 3, 15)))
        let result = try core.postRecurring(through: day(2027, 4, 1), now: now(day(2027, 4, 1)))
        #expect(result.failures.isEmpty)
        #expect(result.posted.map(\.day) == [start, day(2027, 4, 1)])
        #expect(try core.postRecurring(through: day(2027, 4, 1), now: now(day(2027, 4, 1))).posted.isEmpty)
    }

    @Test("Fixed-cost classification is copied at posting and survives rule edit and deletion")
    func fixedCostSnapshot() throws {
        let core = try core(), start = day(2027, 1, 1)
        var rule = try setup(core, start: start)
        rule.isFixedCost = true
        try core.run(.updateRule(rule), now: now(start))
        let first = try core.postRecurring(through: day(2027, 1, 31), now: now(day(2027, 1, 31)))
        #expect(first.posted.first?.isFixedCost == true)
        rule = try #require(core.state.rules.first); rule.isFixedCost = false
        try core.run(.updateRule(rule), now: now(day(2027, 2, 1)))
        let second = try core.postRecurring(through: day(2027, 2, 28), now: now(day(2027, 2, 28)))
        #expect(second.posted.first?.isFixedCost == false)
        let records = core.state.entries
        try core.run(.deleteRule(rule.id), now: now(day(2027, 2, 28)))
        #expect(core.state.entries == records)
        try CoreValidation.validate(core.state)
        #expect(try core.store.read().entries == records)
    }

}
