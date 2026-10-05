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
    func row(_ wallet: WalletValue, kind: EntryKind = .expense, amount: Int = 100, day: LedgerDay,
             category: UUID? = nil, target: UUID? = nil, direction: AdjustmentDirection? = nil,
             title: String = "", note: String = "", source: EntrySource = .manual,
             flags: Set<ReviewFlag> = [], timestamp: Date? = nil) -> EntryValue {
        EntryValue(kind: kind, amount: amount, currencyCode: wallet.currencyCode, day: day, walletID: wallet.id,
            direction: direction, timestamp: timestamp ?? now, counterpartWalletID: target, categoryID: category,
            title: title, note: note, source: source, reviewFlags: flags, createdAt: now, updatedAt: now)
    }

    @Test("Q1 balances include archived history, transfers, as-of days and overflow-safe totals")
    func balancesAndCurrencies() throws {
        let a = WalletValue(name: "Cash", currencyCode: "JPY", isArchived: true)
        let b = WalletValue(name: "Bank", currencyCode: "JPY")
        let usd = WalletValue(name: "USD", currencyCode: "USD")
        let eur = WalletValue(name: "EUR", currencyCode: "EUR")
        let entries = [row(a, kind: .income, amount: Int.max, day: try day(10, 1)),
            row(a, kind: .income, amount: Int.max, day: try day(10, 1)),
            row(a, kind: .transfer, amount: 100, day: try day(10, 2), target: b.id),
            row(b, kind: .expense, amount: 50, day: try day(10, 3)),
            row(b, kind: .adjustment, amount: 20, day: try day(10, 4), direction: .decrease)]
        let rule = RuleValue(amount: 1, currencyCode: "EUR", walletID: eur.id, schedule: .monthly(day: 1), startDay: try day())
        let state = LedgerState(wallets: [a, b, usd, eur], entries: entries, rules: [rule],
            budgets: [BudgetValue(currencyCode: "GBP", monthlyAmount: 10)])
        let balance = LedgerQueries.walletBalances(in: state)
        #expect(balance.first { $0.walletID == a.id }?.balance == Decimal(Int.max) * 2 - 100)
        #expect(balance.first { $0.walletID == b.id }?.balance == 30)
        #expect(LedgerQueries.totalBalances(in: state)["JPY"] == Decimal(Int.max) * 2 - 70)
        #expect(LedgerQueries.totalBalances(in: state, through: try day(10, 1))["JPY"] == Decimal(Int.max) * 2)
        #expect(LedgerQueries.currenciesInUse(in: state) == ["EUR", "GBP", "JPY", "USD"])
    }

    @Test("Q1 summaries, every month day, current/previous category amounts and wallet totals")
    func summaryBreakdownAndWalletTotals() throws {
        let wallet = WalletValue(name: "Cash", currencyCode: "JPY")
        let other = WalletValue(name: "Bank", currencyCode: "JPY")
        let food = CategoryValue(kind: .expense, customName: "Food", isArchived: true)
        let salary = CategoryValue(kind: .income, customName: "Salary")
        let entries = [row(wallet, amount: 200, day: try day(), category: food.id),
            row(wallet, amount: 100, day: try day()), row(wallet, amount: 80, day: try day(9, 5), category: food.id),
            row(wallet, amount: 30, day: try day(9, 5)),
            row(wallet, kind: .income, amount: 500, day: try day(), category: salary.id),
            row(wallet, kind: .transfer, amount: 900, day: try day(), target: other.id),
            row(wallet, kind: .adjustment, amount: 500, day: try day(), direction: .increase)]
        let state = LedgerState(wallets: [wallet, other], categories: [food, salary], entries: entries)
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
        let totals = LedgerQueries.walletTotals(in: state, period: month)
        #expect(totals[0].income == 500 && totals[0].expense == 300)
        #expect(totals[1].income == 0 && totals[1].expense == 0)
        #expect(LedgerQueries.walletTotals(in: state)[0].expense == 410)
        #expect(state.entries == entries)
    }

    @Test("B1 budget spending excludes non-expense rows and other currencies, permits overspending")
    func independentBudgets() throws {
        let jpy = WalletValue(name: "JPY", currencyCode: "JPY")
        let usd = WalletValue(name: "USD", currencyCode: "USD")
        let bank = WalletValue(name: "Bank", currencyCode: "JPY")
        let food = CategoryValue(kind: .expense, customName: "Food")
        let overall = BudgetValue(currencyCode: "JPY", monthlyAmount: 250)
        let category = BudgetValue(currencyCode: "JPY", categoryID: food.id, monthlyAmount: 500)
        let state = LedgerState(wallets: [jpy, usd, bank], categories: [food], entries: [
            row(jpy, amount: 200, day: try day(), category: food.id), row(jpy, amount: 100, day: try day()),
            row(usd, amount: 999, day: try day(), category: food.id),
            row(jpy, kind: .income, amount: 999, day: try day()),
            row(jpy, kind: .transfer, amount: 999, day: try day(), target: bank.id),
            row(jpy, kind: .adjustment, amount: 999, day: try day(), direction: .increase),
            row(jpy, amount: 999, day: try day(9, 30))], budgets: [category, overall, BudgetValue(currencyCode: "USD", monthlyAmount: 1_000)])
        let statuses = try LedgerQueries.budgetStatuses(in: state, monthContaining: day(), currencyCode: "JPY", calendar: calendar)
        #expect(statuses.count == 2 && statuses[0].budgetID == overall.id)
        #expect(statuses[0].spent == 300 && statuses[0].remaining == -50 && statuses[0].ratio == Decimal(string: "1.2"))
        #expect(statuses[1].spent == 200 && statuses[1].remaining == 300 && statuses[1].ratio == Decimal(string: "0.4"))
    }

    @Test("B2 a stored last-day expense stays in its original month across time zones")
    func monthAcrossTimeZones() throws {
        var tokyo = calendar; tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        var losAngeles = calendar; losAngeles.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let date = try #require(tokyo.date(from: DateComponents(year: 2026, month: 10, day: 31, hour: 23, minute: 30)))
        let recordedDay = try LedgerDay(date: date, calendar: tokyo)
        let wallet = WalletValue(name: "Cash", currencyCode: "JPY")
        let budget = BudgetValue(currencyCode: "JPY", monthlyAmount: 1_000)
        let state = LedgerState(wallets: [wallet], entries: [row(wallet, amount: 100, day: recordedDay, timestamp: date)], budgets: [budget])
        let old = try LedgerQueries.budgetStatuses(in: state, monthContaining: day(10, 31), currencyCode: "JPY", calendar: tokyo)
        let moved = try LedgerQueries.budgetStatuses(in: state, monthContaining: day(10, 31), currencyCode: "JPY", calendar: losAngeles)
        #expect(old == moved && moved[0].spent == 100)
        #expect(try LedgerQueries.budgetStatuses(in: state, monthContaining: day(11, 1), currencyCode: "JPY", calendar: losAngeles)[0].spent == 0)
        #expect(try LedgerQueries.dailyTotals(in: state, monthContaining: day(10, 31), currencyCode: "JPY", calendar: losAngeles)[30].expense == 100)
    }

    @Test("Entry filters combine day, wallet, category, kind, currency, review, text and limits")
    func filtersAndRecent() throws {
        let wallet = WalletValue(name: "Cash", currencyCode: "JPY")
        let target = WalletValue(name: "Bank", currencyCode: "JPY")
        let food = CategoryValue(kind: .expense, customName: "Food")
        let early = row(wallet, day: try day(), category: food.id, title: "ＣＡＦＥ", flags: [.amountUncertain], timestamp: now)
        let late = row(wallet, day: try day(), note: "Coffee", source: .receipt, timestamp: now.addingTimeInterval(1))
        var next = row(wallet, kind: .income, day: try day(10, 6), title: "Salary")
        next.createdAt = now.addingTimeInterval(2)
        let transfer = row(wallet, kind: .transfer, day: try day(10, 4), target: target.id)
        let state = LedgerState(wallets: [wallet, target], categories: [food], entries: [early, next, transfer, late])
        #expect(LedgerQueries.entries(in: state).map(\.id) == [next.id, late.id, early.id, transfer.id])
        let period = try LedgerPeriod(start: day(), end: day())
        let filter = LedgerEntryFilter(period: period, walletID: wallet.id, category: .category(food.id), kind: .expense,
            currencyCode: "JPY", needsReview: true, search: "cafe", limit: 20)
        #expect(LedgerQueries.entries(in: state, filter: filter).map(\.id) == [early.id])
        #expect(LedgerQueries.entries(in: state, filter: LedgerEntryFilter(search: "coffee")).map(\.id) == [late.id])
        #expect(LedgerQueries.entries(in: state, filter: LedgerEntryFilter(period: period, category: .uncategorized, needsReview: false)).map(\.id) == [late.id])
        #expect(LedgerQueries.entries(in: state, filter: LedgerEntryFilter(walletID: target.id)).map(\.id) == [transfer.id])
        #expect(LedgerQueries.entries(in: state, filter: LedgerEntryFilter(limit: 2)).count == 2)
        #expect(LedgerQueries.entries(in: state, filter: LedgerEntryFilter(limit: -1)).isEmpty)
        #expect(LedgerQueries.entries(in: state, filter: LedgerEntryFilter(currencyCode: "USD")).isEmpty)
        #expect(LedgerQueries.mostRecentEntry(in: state)?.id == next.id)
        #expect(LedgerQueries.mostRecentEntry(in: state, source: .receipt)?.id == late.id)
        #expect(LedgerQueries.mostRecentEntry(in: state, source: .voice) == nil)
    }

    @Test("Upcoming occurrences exclude paused, expired and processed days and clip the end horizon")
    func upcomingRules() throws {
        let wallet = WalletValue(name: "Cash", currencyCode: "JPY")
        let active = RuleValue(title: "Month end", amount: 100, currencyCode: "JPY", walletID: wallet.id,
            schedule: .monthly(day: 31), startDay: try day(1, 1), endDay: try day(10, 31))
        var paused = active; paused.id = UUID(); paused.isPaused = true
        var expired = active; expired.id = UUID(); expired.endDay = try day(9, 30)
        var processed = active; processed.id = UUID(); processed.lastProcessedDay = try day(10, 31)
        let state = LedgerState(wallets: [wallet], rules: [active, paused, expired, processed])
        let upcoming = try LedgerQueries.upcoming(in: state, nextDays: 40, today: day(10, 5), calendar: calendar)
        let dueDay = try day(10, 31)
        #expect(upcoming.count == 1 && upcoming[0].ruleID == active.id && upcoming[0].day == dueDay)
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

    @Test("Performance: 10,000 entries across 10 wallets, median of 20 runs")
    func tenThousandEntryPerformance() throws {
        let wallets = (0..<10).map { WalletValue(name: "Wallet \($0)", currencyCode: "JPY") }
        let categories = (0..<5).map { CategoryValue(kind: .expense, customName: "Category \($0)") }
        let period = try LedgerPeriod.month(containing: day(), calendar: calendar)
        let previous = try LedgerPeriod.previousMonth(containing: day(), calendar: calendar)
        let entries = try (0..<10_000).map { index in
            row(wallets[index % 10], amount: 100, day: try day(10, (index % 31) + 1), category: categories[index % 5].id)
        }
        let state = LedgerState(wallets: wallets, categories: categories, entries: entries)
        #expect(LedgerQueries.totalBalances(in: state)["JPY"] == -1_000_000)
        #expect(LedgerQueries.periodSummary(in: state, period: period, currencyCode: "JPY").expense == 1_000_000)
        #expect(LedgerQueries.categoryBreakdown(in: state, period: period, previousPeriod: previous, currencyCode: "JPY").reduce(Decimal.zero) { $0 + $1.amount } == 1_000_000)
        let clock = ContinuousClock()
        var balances: [Double] = [], summaries: [Double] = [], breakdowns: [Double] = []
        func milliseconds(_ duration: Duration) -> Double {
            let components = duration.components
            return Double(components.seconds) * 1_000 + Double(components.attoseconds) / 1_000_000_000_000_000
        }
        for _ in 0..<20 {
            var start = clock.now
            let balance = LedgerQueries.walletBalances(in: state)
            balances.append(milliseconds(start.duration(to: clock.now)))
            #expect(balance.count == 10)
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
        print("WEALTHY_CORE_PERFORMANCE entries=10000 wallets=10 runs=20 median_ms balances=\(median(balances)) summary=\(median(summaries)) breakdown=\(median(breakdowns))")
    }
}
