import Foundation
import Testing
@testable import WealthyCore

@Suite("Safe to spend this week")
struct SafeLineTests {
    var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }
    func day(_ value: Int) throws -> LedgerDay { try LedgerDay(year: 2026, month: 10, day: value) }
    func state() throws -> LedgerState {
        LedgerState(targets: [TargetValue(currencyCode: "JPY", amountMinor: 31_000,
                                         effectiveMonth: try LedgerMonth(year: 2026, month: 10))])
    }
    func query(_ state: LedgerState, today: Int = 7) throws -> SafeLine {
        try LedgerQueries.safeLine(in: state, today: day(today), currencyCode: "JPY", calendar: calendar)
    }

    @Test("No target leaves both remaining amounts unset")
    func noTarget() throws {
        var value = LedgerState()
        value.rules = [RuleValue(amount: 650, currencyCode: "JPY", schedule: .weekly(weekday: 5), startDay: try day(1))]
        let result = try query(value)
        #expect(result.weekRemaining == nil && result.safeAmount == nil)
        #expect(result.scheduledTotal == 650 && result.scheduled.count == 1)
    }

    @Test("No rules leaves the existing weekly remaining unchanged")
    func noRules() throws {
        let result = try query(state())
        #expect(result.weekRemaining == 7_000 && result.safeAmount == 7_000)
        #expect(result.scheduled.isEmpty && result.scheduledTotal == 0)
    }

    @Test("Only future, active, target-counting expenses in this week are reserved",
          arguments: ["today", "later", "nextWeek", "paused", "ended", "income", "fixedOff", "fixedOn", "otherEnvelope", "otherCurrency", "processed", "pastPause"])
    func ruleSelection(_ scenario: String) throws {
        var value = try state()
        var rule = RuleValue(title: "Synthetic bill", amount: 650, currencyCode: "JPY",
                             schedule: .weekly(weekday: 5), startDay: try day(1))
        switch scenario {
        case "today": rule.schedule = .weekly(weekday: 4)
        case "nextWeek": rule.startDay = try day(12)
        case "paused": rule.isPaused = true
        case "ended": rule.endDay = try day(6)
        case "income": rule.kind = .income
        case "fixedOff": rule.isFixedCost = true
        case "fixedOn": rule.isFixedCost = true; value.settings.includeFixedCostsInTargets = true
        case "otherEnvelope": rule.envelopeID = UUID()
        case "otherCurrency": rule.currencyCode = "USD"
        case "processed": rule.lastProcessedDay = try day(8)
        case "pastPause": rule.pausedPeriods = [try LedgerPeriod(start: day(8), end: day(8))]
        default: break
        }
        value.rules = [rule]
        let before = value
        let result = try query(value)
        let included = ["later", "fixedOn"].contains(scenario)
        #expect(result.scheduled.count == (included ? 1 : 0))
        #expect(result.scheduledTotal == (included ? 650 : 0))
        #expect(result.safeAmount == (included ? 6_350 : 7_000))
        #expect(value == before)
        if included {
            #expect(result.scheduled.first?.day == (try day(8)))
            #expect(result.scheduled.first?.title == "Synthetic bill")
        }
    }

    @Test("Sunday boundary honors Sunday and Monday week starts", arguments: [1, 2])
    func weekBoundary(_ weekStart: Int) throws {
        var value = try state()
        value.settings.weekStart = weekStart
        value.rules = [RuleValue(amount: 650, currencyCode: "JPY", schedule: .weekly(weekday: 2), startDay: try day(1))]
        let result = try query(value, today: 11)
        #expect(result.scheduledTotal == (weekStart == 1 ? 650 : 0))
        #expect(result.safeAmount == (weekStart == 1 ? 6_350 : 7_000))
    }

    @Test("Posted spending and scheduled amounts can produce a negative safe amount")
    func negative() throws {
        var value = try state()
        value.entries = [EntryValue(kind: .expense, amount: 6_800, currencyCode: "JPY", day: try day(7))]
        value.rules = [RuleValue(amount: 650, currencyCode: "JPY", schedule: .weekly(weekday: 5), startDay: try day(1))]
        let result = try query(value)
        #expect(result.weekRemaining == 200 && result.safeAmount == -450)
    }

    @Test("Scheduled totals use checked arithmetic")
    func overflow() throws {
        var value = try state()
        value.rules = (0..<2).map { _ in RuleValue(amount: Int.max, currencyCode: "JPY", schedule: .weekly(weekday: 5), startDay: try! day(1)) }
        #expect(throws: CoreError.self) { try query(value) }
    }
}
