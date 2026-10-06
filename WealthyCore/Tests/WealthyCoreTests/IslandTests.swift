import Foundation
import Testing
@testable import WealthyCore

struct IslandTests {
    var calendar: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(secondsFromGMT: 0)!; return c }
    func day(_ y: Int, _ m: Int, _ d: Int) throws -> LedgerDay { try LedgerDay(year: y, month: m, day: d) }
    @Test func childSupportDefaultIsFixedAndExempt() throws {
        let childID = UUID()
        let categories = CategoryPresets.child(envelopeID: childID)
        let support = try #require(categories.first { $0.systemKey == "child.support" })
        #expect(LedgerQueries.fixedCostDefault(for: support))
        let date = try day(2026,10,5)
        #expect(TaxClassifier.suggestedRate(taxHint: support.taxHint, serviceMode: ServiceMode.none, day: date) == .exempt)
        #expect(categories.filter { $0.id != support.id }.allSatisfy { !LedgerQueries.fixedCostDefault(for: $0) })
    }
    @Test func seventyPercentBoundaries() throws {
        for (year, month, count, minimum) in [(2027,2,28,20),(2028,2,29,21),(2027,4,30,21),(2027,1,31,22)] {
            let first = try day(year,month,1)
            var state = LedgerState(targets: [TargetValue(currencyCode:"JPY",amountMinor:count*100,effectiveMonth:LedgerMonth(day:first))])
            state.noSpendMarks = try (1..<minimum).map { NoSpendMarkValue(day: try day(year,month,$0)) }
            #expect(try LedgerQueries.rewardOutcome(LedgerQueries.monthTargetStatus(in:state,month:LedgerMonth(day:first),currencyCode:"JPY",calendar:calendar)) == .few)
            state.noSpendMarks.append(NoSpendMarkValue(day:try day(year,month,minimum)))
            #expect(try LedgerQueries.monthTargetStatus(in:state,month:LedgerMonth(day:first),currencyCode:"JPY",calendar:calendar).isRewardEligible)
        }
    }
    @Test func lateEntryBoundariesAndRecomputedResult() throws {
        let monday = try day(2026,10,5), end = try day(2026,10,11)
        #expect(try LedgerQueries.canAddEntry(on:monday,today:day(2026,10,14),calendar:calendar))
        #expect(try !LedgerQueries.canAddEntry(on:monday,today:day(2026,10,15),calendar:calendar))
        #expect(try !LedgerQueries.canAddEntry(on:day(2026,9,30),today:day(2026,10,4),calendar:calendar))
        var state = LedgerState(targets:[TargetValue(currencyCode:"JPY",amountMinor:3100,effectiveMonth:LedgerMonth(day:monday))])
        state.noSpendMarks = try (0..<4).map {NoSpendMarkValue(day:try monday.adding(days:$0,calendar:calendar))}
        #expect(try LedgerQueries.recentlyEndedResults(in:state,today:day(2026,10,12),currencyCode:"JPY",calendar:calendar).first?.isRewardEligible == false)
        state.noSpendMarks.append(NoSpendMarkValue(day:end))
        #expect(try LedgerQueries.recentlyEndedResults(in:state,today:day(2026,10,12),currencyCode:"JPY",calendar:calendar).first?.isRewardEligible == true)
        let summary = try LedgerQueries.islandSummary(in:state,today:end,currencyCode:"JPY",calendar:calendar)
        #expect(summary.days.count == 7 && summary.festivals == 1)
        #expect(summary.days.last?.hasGrowth == true)
        state.entries.append(EntryValue(kind:.expense,amount:701,currencyCode:"JPY",day:end))
        #expect(try LedgerQueries.rewardOutcome(LedgerQueries.weekTargetStatus(in:state,containing:end,currencyCode:"JPY",calendar:calendar)) == .over)
    }
    @Test func coincidentWeekAndMonthStartsKeepDistinctResults() throws {
        let today = try day(2027,11,1)
        let results = try LedgerQueries.recentlyEndedResults(in:LedgerState(),today:today,currencyCode:"JPY",calendar:calendar)
        #expect(results.count == 2)
        #expect(results[0].period.start == (try day(2027,10,25)))
        #expect(results[1].period.start == (try day(2027,10,1)))
    }

    @Test func dailyGrowthRequiresStrictlyUnderAllowance() throws {
        let today = try day(2026,10,5)
        var state = LedgerState(targets: [TargetValue(currencyCode:"JPY",amountMinor:3100,effectiveMonth:LedgerMonth(day:today))])
        state.entries = [EntryValue(kind:.expense,amount:100,currencyCode:"JPY",day:today)]
        #expect(try LedgerQueries.islandSummary(in:state,today:today,currencyCode:"JPY",calendar:calendar).days.first?.hasGrowth == false)
        #expect(try LedgerQueries.islandSummary(in:state,today:today,currencyCode:"JPY",calendar:calendar).days.first?.status.isOver == false)
        state.entries[0].amount = 99
        #expect(try LedgerQueries.islandSummary(in:state,today:today,currencyCode:"JPY",calendar:calendar).days.first?.hasGrowth == true)
    }

    @Test func displayGroupingAndExactIntegerBounds() throws {
        for (locale, expected) in [("en_US","¥1,234"),("ja_JP","¥1,234"),("es_ES","1.234 ¥"),("ko_KR","JP¥1,234")] {
            #expect(try CoreCurrency.formatForDisplay(1234,currencyCode:"JPY",locale:Locale(identifier:locale)) == expected)
        }
        #expect(try CoreCurrency.formatForDisplay(Int.max,currencyCode:"JPY",locale:Locale(identifier:"en_US")) == "¥9,223,372,036,854,775,807")
        #expect(try CoreCurrency.formatForDisplay(Int.min,currencyCode:"JPY",locale:Locale(identifier:"en_US")) == "-¥9,223,372,036,854,775,808")
        #expect(try CoreCurrency.formatForDisplay(1234,currencyCode:"USD",locale:Locale(identifier:"en_US")) == "$12.34")
    }

    @Test func resultGrowthUsesDailyAmountsInsteadOfLoggedCount() throws {
        let first = try day(2026,10,5), second = try day(2026,10,6), third = try day(2026,10,7)
        var state = LedgerState(entries: [EntryValue(kind: .expense, amount: 100, currencyCode: "JPY", day: first), EntryValue(kind: .expense, amount: 99, currencyCode: "JPY", day: second)], targets: [TargetValue(currencyCode: "JPY", amountMinor: 3100, effectiveMonth: LedgerMonth(day: first))], noSpendMarks: [NoSpendMarkValue(day: third)])
        let period = try LedgerPeriod(start: first, end: third)
        #expect(try LedgerQueries.islandGrowthDays(in: state, period: period, currencyCode: "JPY", calendar: calendar) == 2)
        state.entries[1].amount = 101
        #expect(try LedgerQueries.islandGrowthDays(in: state, period: period, currencyCode: "JPY", calendar: calendar) == 1)
    }

    @Test func largeIslandSnapshotUsesAuthoritativeTotals() throws {
        let today = try day(2026,10,5)
        let state = LedgerState(entries:(0..<50000).map { _ in EntryValue(kind:.expense,amount:1,currencyCode:"JPY",day:today) },targets:[TargetValue(currencyCode:"JPY",amountMinor:310000,effectiveMonth:LedgerMonth(day:today))])
        let start = ContinuousClock.now
        let summary = try LedgerQueries.islandSummary(in:state,today:today,currencyCode:"JPY",calendar:calendar)
        print("ISLAND_QUERY_50000_DURATION \(start.duration(to:.now))")
        #expect(summary.week.spent == 50000 && summary.week.remaining == 20000)
        #expect(summary.month.spent == 50000 && summary.month.remaining == 260000)
        #expect(summary.week.loggedDays == 1 && summary.festivals == 0)
        #expect(summary.days.first?.hasGrowth == false)
        #expect(summary.week.isOver == false)
    }

}
