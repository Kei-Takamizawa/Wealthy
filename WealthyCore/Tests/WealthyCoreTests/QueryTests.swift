import Foundation
import Testing
@testable import WealthyCore

@Suite("Pure ledger queries")
struct QueryTests {
    let now = Date(timeIntervalSince1970: 1_791_158_400)
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
    func day(_ month: Int = 10, _ day: Int = 5, year: Int = 2026) throws -> LedgerDay {
        try LedgerDay(year: year, month: month, day: day)
    }
    var household: EnvelopeValue {
        EnvelopeValue(id: EnvelopeValue.householdID, name: "Household", createdAt: now)
    }
    func row(_ envelope: EnvelopeValue, kind: EntryKind = .expense, amount: Int = 100,
             currency: String = "JPY", day: LedgerDay, category: UUID? = nil,
             title: String = "", note: String = "", source: EntrySource = .manual,
             flags: Set<ReviewFlag> = [], timestamp: Date? = nil, fixed: Bool = false) -> EntryValue {
        EntryValue(kind: kind, amount: amount, currencyCode: currency, day: day, envelopeID: envelope.id,
            timestamp: timestamp ?? now, isFixedCost: fixed, categoryID: category,
            title: title, note: note, source: source, reviewFlags: flags, createdAt: now, updatedAt: now)
    }

    @Test("Q1 summaries include archived history, isolate envelopes and preserve overflow-safe totals")
    func summariesAndCurrencies() throws {
        var home = household; home.isArchived = true
        let child = EnvelopeValue(kind: .child, name: "Child")
        let entries = [row(home, kind: .income, amount: Int.max, day: try day(10, 1)),
            row(home, kind: .income, amount: Int.max, day: try day(10, 1)),
            row(home, amount: 100, day: try day(10, 2)),
            row(child, amount: 50, day: try day(10, 3)),
            row(child, kind: .income, amount: 20, day: try day(10, 4)),
            row(child, amount: 1, currency: "USD", day: try day())]
        let rule = RuleValue(amount: 1, currencyCode: "EUR", envelopeID: home.id,
            schedule: .monthly(day: 1), startDay: try day())
        let state = LedgerState(envelopes: [home, child], entries: entries, rules: [rule],
            targets: [TargetValue(envelopeID: home.id, currencyCode: "GBP", amountMinor: 10,
                                  effectiveMonth: try LedgerMonth(year: 2026, month: 10))])
        let month = try LedgerPeriod.month(containing: day(), calendar: calendar)
        let summary = LedgerQueries.periodSummary(in: state, period: month, currencyCode: "JPY")
        #expect(summary.income == Decimal(Int.max) * 2 && summary.expense == 100)
        #expect(summary.net == Decimal(Int.max) * 2 - 100)
        let childSummary = LedgerQueries.periodSummary(in: state, period: month, currencyCode: "JPY", envelopeID: child.id)
        #expect(childSummary.income == 20 && childSummary.expense == 50 && childSummary.net == -30)
        let firstDay = try LedgerPeriod(start: day(10, 1), end: day(10, 1))
        #expect(LedgerQueries.periodSummary(in: state, period: firstDay, currencyCode: "JPY").income == Decimal(Int.max) * 2)
        #expect(LedgerQueries.currenciesInUse(in: state) == ["EUR", "GBP", "JPY", "USD"])
    }

    @Test("Q1 summaries, every month day, category comparisons and envelope totals")
    func summaryBreakdownAndEnvelopeTotals() throws {
        let home = household
        let child = EnvelopeValue(kind: .child, name: "Child")
        let food = CategoryValue(kind: .expense, customName: "Food", isArchived: true)
        let salary = CategoryValue(kind: .income, customName: "Salary")
        let childFood = CategoryValue(kind: .expense, envelopeID: child.id, customName: "Child food")
        let entries = [row(home, amount: 200, day: try day(), category: food.id),
            row(home, amount: 100, day: try day()), row(home, amount: 80, day: try day(9, 5), category: food.id),
            row(home, amount: 30, day: try day(9, 5)),
            row(home, kind: .income, amount: 500, day: try day(), category: salary.id),
            row(child, amount: 900, day: try day(), category: childFood.id),
            row(child, kind: .income, amount: 500, day: try day())]
        let state = LedgerState(envelopes: [home, child], categories: [food, salary, childFood], entries: entries)
        let month = try LedgerPeriod.month(containing: day(), calendar: calendar)
        let previous = try LedgerPeriod.previousMonth(containing: day(), calendar: calendar)
        let summary = LedgerQueries.periodSummary(in: state, period: month, currencyCode: "JPY")
        #expect(summary.income == 500 && summary.expense == 300 && summary.net == 200)
        #expect(summary.incomeCount == 1 && summary.expenseCount == 2)
        let daily = try LedgerQueries.dailyTotals(in: state, monthContaining: day(), currencyCode: "JPY", calendar: calendar)
        #expect(daily.count == 31)
        #expect(daily[4].expense == 300 && daily[4].income == 500)
        #expect(daily[0].expense == 0 && daily[30].expense == 0)
        let buckets = LedgerQueries.categoryBreakdown(in: state, period: month, previousPeriod: previous, currencyCode: "JPY")
        #expect(buckets.map(\.categoryID) == [food.id, nil])
        #expect(buckets[0].amount == 200 && buckets[0].previousAmount == 80)
        #expect(buckets[1].amount == 100 && buckets[1].previousAmount == 30)
        let income = LedgerQueries.categoryBreakdown(in: state, period: month, previousPeriod: previous, currencyCode: "JPY", kind: .income)
        #expect(income.first?.categoryID == salary.id && income.first?.amount == 500)
        let childSummary = LedgerQueries.periodSummary(in: state, period: month, currencyCode: "JPY", envelopeID: child.id)
        #expect(childSummary.income == 500 && childSummary.expense == 900)
        let childDaily = try LedgerQueries.dailyTotals(in: state, monthContaining: day(), currencyCode: "JPY", calendar: calendar, envelopeID: child.id)
        #expect(childDaily[4].expense == 900 && childDaily[4].income == 500)
        let childBuckets = LedgerQueries.categoryBreakdown(in: state, period: month, previousPeriod: previous, currencyCode: "JPY", envelopeID: child.id)
        #expect(childBuckets.first?.categoryID == childFood.id && childBuckets.first?.amount == 900)
        let bothMonths = try LedgerPeriod(start: previous.start, end: month.end)
        #expect(LedgerQueries.periodSummary(in: state, period: bothMonths, currencyCode: "JPY").expense == 410)
        #expect(state.entries == entries)
    }

    @Test("B1 targets isolate envelope, currency and category spending and permit negative remaining")
    func independentTargets() throws {
        let home = household
        let child = EnvelopeValue(kind: .child, name: "Child")
        let food = CategoryValue(kind: .expense, customName: "Food")
        let effective = try LedgerMonth(year: 2026, month: 10)
        let overall = TargetValue(currencyCode: "JPY", amountMinor: 250, effectiveMonth: effective)
        let category = TargetValue(categoryID: food.id, currencyCode: "JPY", amountMinor: 500, effectiveMonth: effective)
        let state = LedgerState(envelopes: [home, child], categories: [food], entries: [
            row(home, amount: 200, day: try day(), category: food.id), row(home, amount: 100, day: try day()),
            row(home, amount: 999, currency: "USD", day: try day(), category: food.id),
            row(home, kind: .income, amount: 999, day: try day()),
            row(child, amount: 999, day: try day()),
            row(home, amount: 999, day: try day(), fixed: true),
            row(home, amount: 999, day: try day(9, 30))], targets: [category, overall,
                TargetValue(currencyCode: "USD", amountMinor: 1_000, effectiveMonth: effective),
                TargetValue(envelopeID: child.id, currencyCode: "JPY", amountMinor: 200, effectiveMonth: effective)])
        let overallStatus = try LedgerQueries.monthTargetStatus(in: state, month: effective, currencyCode: "JPY", calendar: calendar)
        let categoryStatus = try LedgerQueries.monthTargetStatus(in: state, month: effective, categoryID: food.id, currencyCode: "JPY", calendar: calendar)
        #expect(overallStatus.allowance == 250 && overallStatus.spent == 300 && overallStatus.remaining == -50)
        #expect(categoryStatus.allowance == 500 && categoryStatus.spent == 200 && categoryStatus.remaining == 300)
        let childStatus = try LedgerQueries.monthTargetStatus(in: state, month: effective, envelopeID: child.id, currencyCode: "JPY", calendar: calendar)
        #expect(childStatus.spent == 999 && childStatus.remaining == -799)
        let usd = try LedgerQueries.monthTargetStatus(in: state, month: effective, currencyCode: "USD", calendar: calendar)
        #expect(usd.spent == 999 && usd.remaining == 1)
        var included = state; included.settings.includeFixedCostsInTargets = true
        let withFixed = try LedgerQueries.monthTargetStatus(in: included, month: effective, currencyCode: "JPY", calendar: calendar)
        #expect(withFixed.spent == 1_299 && withFixed.remaining == -1_049)
    }

    @Test("B2 a stored last-day expense stays in its original month across time zones")
    func monthAcrossTimeZones() throws {
        var tokyo = calendar; tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        var losAngeles = calendar; losAngeles.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let date = try #require(tokyo.date(from: DateComponents(year: 2026, month: 10, day: 31, hour: 23, minute: 30)))
        let recordedDay = try LedgerDay(date: date, calendar: tokyo)
        let target = TargetValue(currencyCode: "JPY", amountMinor: 1_000, effectiveMonth: try LedgerMonth(year: 2026, month: 10))
        let state = LedgerState(envelopes: [household], entries: [row(household, amount: 100, day: recordedDay, timestamp: date)], targets: [target])
        let october = try LedgerMonth(year: 2026, month: 10)
        let old = try LedgerQueries.monthTargetStatus(in: state, month: october, currencyCode: "JPY", calendar: tokyo)
        let moved = try LedgerQueries.monthTargetStatus(in: state, month: october, currencyCode: "JPY", calendar: losAngeles)
        #expect(old == moved && moved.spent == 100)
        #expect(try LedgerQueries.monthTargetStatus(in: state, month: LedgerMonth(year: 2026, month: 11), currencyCode: "JPY", calendar: losAngeles).spent == 0)
        #expect(try LedgerQueries.dailyTotals(in: state, monthContaining: day(10, 31), currencyCode: "JPY", calendar: losAngeles)[30].expense == 100)
    }

    @Test("Entry filters combine day, envelope, category, kind, currency, review, text and limits")
    func filtersAndRecent() throws {
        let home = household
        let child = EnvelopeValue(kind: .child, name: "Child")
        let food = CategoryValue(kind: .expense, customName: "Food")
        let early = row(home, day: try day(), category: food.id, title: "ＣＡＦＥ", flags: [.amountUncertain], timestamp: now)
        let late = row(home, day: try day(), note: "Coffee", source: .receipt, timestamp: now.addingTimeInterval(1))
        var next = row(home, kind: .income, day: try day(10, 6), title: "Salary")
        next.createdAt = now.addingTimeInterval(2)
        let separate = row(child, day: try day(10, 4))
        let state = LedgerState(envelopes: [home, child], categories: [food], entries: [early, next, separate, late])
        #expect(LedgerQueries.entries(in: state).map(\.id) == [next.id, late.id, early.id, separate.id])
        let period = try LedgerPeriod(start: day(), end: day())
        let filter = LedgerEntryFilter(period: period, envelopeID: home.id, category: .category(food.id), kind: .expense,
            currencyCode: "JPY", needsReview: true, search: "cafe", limit: 20)
        #expect(LedgerQueries.entries(in: state, filter: filter).map(\.id) == [early.id])
        #expect(LedgerQueries.entries(in: state, filter: LedgerEntryFilter(search: "coffee")).map(\.id) == [late.id])
        #expect(LedgerQueries.entries(in: state, filter: LedgerEntryFilter(period: period, category: .uncategorized, needsReview: false)).map(\.id) == [late.id])
        #expect(LedgerQueries.entries(in: state, filter: LedgerEntryFilter(envelopeID: child.id)).map(\.id) == [separate.id])
        #expect(LedgerQueries.entries(in: state, filter: LedgerEntryFilter(limit: 2)).count == 2)
        #expect(LedgerQueries.entries(in: state, filter: LedgerEntryFilter(limit: -1)).isEmpty)
        #expect(LedgerQueries.entries(in: state, filter: LedgerEntryFilter(currencyCode: "USD")).isEmpty)
        #expect(LedgerQueries.mostRecentEntry(in: state)?.id == next.id)
        #expect(LedgerQueries.mostRecentEntry(in: state, source: .receipt)?.id == late.id)
        #expect(LedgerQueries.mostRecentEntry(in: state, source: .voice) == nil)
    }

    @Test("Q2 last recorded entry ignores civil day and breaks ties by timestamp then ID")
    func lastRecordedOrdering() throws {
        var laterDay = row(household, day: try day(10, 20), timestamp: now.addingTimeInterval(100))
        laterDay.id = UUID(uuidString: "10000000-0000-0000-0000-000000000003")!
        var recordedLater = row(household, day: try day(10, 1), timestamp: now)
        recordedLater.createdAt = now.addingTimeInterval(1)
        recordedLater.id = UUID(uuidString: "10000000-0000-0000-0000-000000000002")!
        var tied = recordedLater; tied.id = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!
        var state = LedgerState(envelopes: [household], entries: [laterDay, recordedLater])
        #expect(LedgerQueries.mostRecentEntry(in: state)?.id == recordedLater.id)
        state.entries.append(tied)
        #expect(LedgerQueries.mostRecentEntry(in: state)?.id == tied.id)
        recordedLater.timestamp = now.addingTimeInterval(1)
        state.entries[1] = recordedLater
        #expect(LedgerQueries.mostRecentEntry(in: state)?.id == recordedLater.id)
    }

    @Test("Upcoming occurrences exclude paused, expired and processed days and clip the end horizon")
    func upcomingRules() throws {
        let active = RuleValue(title: "Month end", amount: 100, currencyCode: "JPY", envelopeID: household.id,
            schedule: .monthly(day: 31), startDay: try day(1, 1), endDay: try day(10, 31))
        var paused = active; paused.id = UUID(); paused.isPaused = true
        var expired = active; expired.id = UUID(); expired.endDay = try day(9, 30)
        var processed = active; processed.id = UUID(); processed.lastProcessedDay = try day(10, 31)
        let state = LedgerState(envelopes: [household], rules: [active, paused, expired, processed])
        let upcoming = try LedgerQueries.upcoming(in: state, nextDays: 40, today: day(10, 5), calendar: calendar)
        let dueDay = try day(10, 31)
        #expect(upcoming.count == 1 && upcoming[0].ruleID == active.id && upcoming[0].day == dueDay)
        #expect(upcoming[0].envelopeID == household.id)
        #expect(try LedgerQueries.upcoming(in: state, nextDays: 0, today: day(), calendar: calendar).isEmpty)
        #expect(throws: CoreError.invalidField("nextDays", nil)) {
            try LedgerQueries.upcoming(in: state, nextDays: -1, today: day(), calendar: calendar)
        }
        #expect(state.rules == [active, paused, expired, processed])
    }

    @Test("Month boundaries handle leap years, previous January and invalid periods")
    func periodBoundaries() throws {
        #expect(try LedgerPeriod.month(containing: day(2, 1, year: 2028), calendar: calendar).end.day == 29)
        #expect(try LedgerPeriod.month(containing: day(2, 1, year: 2027), calendar: calendar).end.day == 28)
        #expect(try LedgerPeriod.previousMonth(containing: day(1, 1), calendar: calendar).end == day(12, 31, year: 2025))
        #expect(throws: CoreError.invalidField("period", nil)) { try LedgerPeriod(start: day(10, 6), end: day()) }
    }

    @Test("Performance: 10,000 entries across household categories, median of 20 runs")
    func tenThousandEntryPerformance() throws {
        let home = household
        let categories = (0..<5).map { CategoryValue(kind: .expense, customName: "Category \($0)") }
        let period = try LedgerPeriod.month(containing: day(), calendar: calendar)
        let previous = try LedgerPeriod.previousMonth(containing: day(), calendar: calendar)
        let entries = try (0..<10_000).map { index in
            row(home, amount: 100, day: try day(10, (index % 31) + 1), category: categories[index % 5].id)
        }
        let state = LedgerState(envelopes: [home], categories: categories, entries: entries,
            targets: [TargetValue(currencyCode: "JPY", amountMinor: 900_000, effectiveMonth: try LedgerMonth(year: 2026, month: 10))])
        #expect(LedgerQueries.periodSummary(in: state, period: period, currencyCode: "JPY").expense == 1_000_000)
        #expect(LedgerQueries.categoryBreakdown(in: state, period: period, previousPeriod: previous, currencyCode: "JPY").reduce(Decimal.zero) { $0 + $1.amount } == 1_000_000)
        #expect(try LedgerQueries.monthTargetStatus(in: state, month: LedgerMonth(year: 2026, month: 10), currencyCode: "JPY", calendar: calendar).remaining == -100_000)
        let clock = ContinuousClock()
        var targets: [Double] = [], summaries: [Double] = [], breakdowns: [Double] = []
        func milliseconds(_ duration: Duration) -> Double {
            let components = duration.components
            return Double(components.seconds) * 1_000 + Double(components.attoseconds) / 1_000_000_000_000_000
        }
        for _ in 0..<20 {
            var start = clock.now
            let status = try LedgerQueries.monthTargetStatus(in: state, month: LedgerMonth(year: 2026, month: 10), currencyCode: "JPY", calendar: calendar)
            targets.append(milliseconds(start.duration(to: clock.now)))
            #expect(status.spent == 1_000_000 && status.loggedDays == 31)
            start = clock.now
            let summary = LedgerQueries.periodSummary(in: state, period: period, currencyCode: "JPY")
            summaries.append(milliseconds(start.duration(to: clock.now)))
            #expect(summary.expenseCount == 10_000)
            start = clock.now
            let breakdown = LedgerQueries.categoryBreakdown(in: state, period: period, previousPeriod: previous, currencyCode: "JPY")
            breakdowns.append(milliseconds(start.duration(to: clock.now)))
            #expect(breakdown.count == 6)
        }
        func median(_ values: [Double]) -> Double { let values = values.sorted(); return (values[9] + values[10]) / 2 }
        print("WEALTHY_CORE_PERFORMANCE entries=10000 envelopes=1 runs=20 median_ms targets=\(median(targets)) summary=\(median(summaries)) breakdown=\(median(breakdowns))")
    }
}
