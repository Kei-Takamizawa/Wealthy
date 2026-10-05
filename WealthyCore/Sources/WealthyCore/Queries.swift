import Foundation

/// An inclusive range of stored Gregorian civil days, independent of entry timestamps.
public struct LedgerPeriod: Codable, Sendable, Equatable {
    public let start: LedgerDay
    public let end: LedgerDay
    public init(start: LedgerDay, end: LedgerDay) throws {
        guard start <= end else { throw CoreError.invalidField("period", nil) }
        self.start = start; self.end = end
    }
    public func contains(_ day: LedgerDay) -> Bool { start <= day && day <= end }
    /// All budget and monthly query boundaries come from this function.
    public static func month(containing day: LedgerDay, calendar: Calendar = .current) throws -> LedgerPeriod {
        var civilCalendar = Calendar(identifier: .gregorian)
        civilCalendar.timeZone = calendar.timeZone
        let start = try LedgerDay(year: day.year, month: day.month, day: 1)
        guard let range = civilCalendar.range(of: .day, in: .month, for: try start.date(calendar: civilCalendar)) else {
            throw CoreError.invalidField("month", nil)
        }
        return try LedgerPeriod(start: start, end: LedgerDay(year: day.year, month: day.month, day: range.count))
    }
    public static func previousMonth(containing day: LedgerDay, calendar: Calendar = .current) throws -> LedgerPeriod {
        let current = try month(containing: day, calendar: calendar)
        var civilCalendar = Calendar(identifier: .gregorian)
        civilCalendar.timeZone = calendar.timeZone
        return try self.month(containing: current.start.adding(days: -1, calendar: civilCalendar), calendar: civilCalendar)
    }
}

public enum CategoryFilter: Codable, Sendable, Equatable {
    case all, uncategorized, category(UUID)
}

/// All filters are combined; wallet matches either side of a transfer.
public struct LedgerEntryFilter: Codable, Sendable, Equatable {
    public var period: LedgerPeriod?
    public var walletID: UUID?
    public var category: CategoryFilter
    public var kind: EntryKind?
    public var currencyCode: String?
    public var needsReview: Bool?
    public var search: String?
    public var limit: Int?
    public init(period: LedgerPeriod? = nil, walletID: UUID? = nil, category: CategoryFilter = .all,
                kind: EntryKind? = nil, currencyCode: String? = nil, needsReview: Bool? = nil,
                search: String? = nil, limit: Int? = nil) {
        self.period = period; self.walletID = walletID; self.category = category; self.kind = kind
        self.currencyCode = currencyCode; self.needsReview = needsReview; self.search = search; self.limit = limit
    }
}

public struct WalletBalance: Codable, Sendable, Equatable {
    public var walletID: UUID
    public var currencyCode: String
    public var balance: Decimal
}
public struct PeriodSummary: Codable, Sendable, Equatable {
    public var currencyCode: String
    public var income: Decimal
    public var expense: Decimal
    public var net: Decimal { income - expense }
    public var incomeCount: Int
    public var expenseCount: Int
}
public struct DailyTotal: Codable, Sendable, Equatable {
    public var day: LedgerDay
    public var income: Decimal
    public var expense: Decimal
}
public struct CategoryBreakdown: Codable, Sendable, Equatable {
    public var categoryID: UUID?
    public var amount: Decimal
    public var previousAmount: Decimal
}
public struct WalletPeriodTotals: Codable, Sendable, Equatable {
    public var walletID: UUID
    public var currencyCode: String
    public var income: Decimal
    public var expense: Decimal
}
public struct BudgetStatus: Codable, Sendable, Equatable {
    public var budgetID: UUID
    public var categoryID: UUID?
    public var currencyCode: String
    public var period: LedgerPeriod
    public var budget: Decimal
    public var spent: Decimal
    public var remaining: Decimal { budget - spent }
    /// Spending divided by budget, with 1 representing exactly the budget amount.
    public var ratio: Decimal { spent / budget }
}
public struct UpcomingOccurrence: Codable, Sendable, Equatable {
    public var ruleID: UUID
    public var day: LedgerDay
    public var kind: EntryKind
    public var amount: Int
    public var currencyCode: String
    public var walletID: UUID
    public var counterpartWalletID: UUID?
    public var categoryID: UUID?
    public var title: String
}

/// Pure read functions work on detached snapshots, including archived history.
public enum LedgerQueries {
    public static func walletBalances(in state: LedgerState, through day: LedgerDay? = nil) -> [WalletBalance] {
        var balances = Dictionary(uniqueKeysWithValues: state.wallets.map { ($0.id, Decimal.zero) })
        for entry in state.entries where day == nil || entry.day <= day! {
            let amount = Decimal(entry.amount)
            switch entry.kind {
            case .expense: balances[entry.walletID, default: .zero] -= amount
            case .income: balances[entry.walletID, default: .zero] += amount
            case .adjustment: balances[entry.walletID, default: .zero] += entry.direction == .increase ? amount : -amount
            case .transfer:
                balances[entry.walletID, default: .zero] -= amount
                if let id = entry.counterpartWalletID { balances[id, default: .zero] += amount }
            }
        }
        return state.wallets.map { WalletBalance(walletID: $0.id, currencyCode: $0.currencyCode, balance: balances[$0.id] ?? .zero) }
    }
    public static func totalBalances(in state: LedgerState, through day: LedgerDay? = nil) -> [String: Decimal] {
        walletBalances(in: state, through: day).reduce(into: [:]) { $0[$1.currencyCode, default: .zero] += $1.balance }
    }
    public static func entries(in state: LedgerState, filter: LedgerEntryFilter = LedgerEntryFilter()) -> [EntryValue] {
        let search = filter.search.map(CoreValidation.normalizedName) ?? ""
        let matches = state.entries.filter { entry in
            if let period = filter.period, !period.contains(entry.day) { return false }
            if let id = filter.walletID, entry.walletID != id && entry.counterpartWalletID != id { return false }
            switch filter.category {
            case .all: break
            case .uncategorized: if entry.categoryID != nil { return false }
            case let .category(id): if entry.categoryID != id { return false }
            }
            if let kind = filter.kind, entry.kind != kind { return false }
            if let currency = filter.currencyCode, entry.currencyCode != currency { return false }
            if let review = filter.needsReview, entry.needsReview != review { return false }
            if !search.isEmpty && !CoreValidation.normalizedName(entry.title).contains(search)
                && !CoreValidation.normalizedName(entry.note).contains(search) { return false }
            return true
        }.sorted(by: ordered)
        return filter.limit.map { Array(matches.prefix(max(0, $0))) } ?? matches
    }
    public static func periodSummary(in state: LedgerState, period: LedgerPeriod, currencyCode: String) -> PeriodSummary {
        var result = PeriodSummary(currencyCode: currencyCode, income: .zero, expense: .zero, incomeCount: 0, expenseCount: 0)
        for entry in state.entries where entry.currencyCode == currencyCode && period.contains(entry.day) {
            if entry.kind == .income { result.income += Decimal(entry.amount); result.incomeCount += 1 }
            if entry.kind == .expense { result.expense += Decimal(entry.amount); result.expenseCount += 1 }
        }
        return result
    }
    /// Includes zero-spending days and groups by stored day, never by timestamp.
    public static func dailyTotals(in state: LedgerState, monthContaining day: LedgerDay, currencyCode: String,
                                   calendar: Calendar = .current) throws -> [DailyTotal] {
        let period = try LedgerPeriod.month(containing: day, calendar: calendar)
        var totals: [LedgerDay: DailyTotal] = [:]
        for entry in state.entries where entry.currencyCode == currencyCode && period.contains(entry.day) {
            var total = totals[entry.day] ?? DailyTotal(day: entry.day, income: .zero, expense: .zero)
            if entry.kind == .income { total.income += Decimal(entry.amount) }
            if entry.kind == .expense { total.expense += Decimal(entry.amount) }
            totals[entry.day] = total
        }
        return try (1...period.end.day).map {
            let day = try LedgerDay(year: period.start.year, month: period.start.month, day: $0)
            return totals[day] ?? DailyTotal(day: day, income: .zero, expense: .zero)
        }
    }
    /// Returns current and previous-period buckets, including an uncategorized bucket.
    public static func categoryBreakdown(in state: LedgerState, period: LedgerPeriod, previousPeriod: LedgerPeriod,
                                         currencyCode: String, kind: CategoryKind = .expense) -> [CategoryBreakdown] {
        var totals: [UUID?: Decimal] = [nil: .zero], previous: [UUID?: Decimal] = [nil: .zero]
        for entry in state.entries where entry.currencyCode == currencyCode && entry.kind.rawValue == kind.rawValue {
            if period.contains(entry.day) { totals[entry.categoryID, default: .zero] += Decimal(entry.amount) }
            if previousPeriod.contains(entry.day) { previous[entry.categoryID, default: .zero] += Decimal(entry.amount) }
        }
        return Set(totals.keys).union(previous.keys).map {
            CategoryBreakdown(categoryID: $0, amount: totals[$0] ?? .zero, previousAmount: previous[$0] ?? .zero)
        }.sorted {
            if $0.amount != $1.amount { return $0.amount > $1.amount }
            return ($0.categoryID?.uuidString ?? "") < ($1.categoryID?.uuidString ?? "")
        }
    }
    public static func walletTotals(in state: LedgerState, period: LedgerPeriod? = nil) -> [WalletPeriodTotals] {
        var income: [UUID: Decimal] = [:], expense: [UUID: Decimal] = [:]
        for entry in state.entries where period == nil || period!.contains(entry.day) {
            if entry.kind == .income { income[entry.walletID, default: .zero] += Decimal(entry.amount) }
            if entry.kind == .expense { expense[entry.walletID, default: .zero] += Decimal(entry.amount) }
        }
        return state.wallets.map { WalletPeriodTotals(walletID: $0.id, currencyCode: $0.currencyCode,
            income: income[$0.id] ?? .zero, expense: expense[$0.id] ?? .zero) }
    }
    /// Shared spending rule for previews and budget status. Category budgets are independent.
    public static func budgetSpent(_ budget: BudgetValue, in state: LedgerState, period: LedgerPeriod) -> Decimal {
        state.entries.reduce(Decimal.zero) { total, entry in
            guard entry.kind == .expense, entry.currencyCode == budget.currencyCode, period.contains(entry.day),
                  budget.categoryID == nil || entry.categoryID == budget.categoryID else { return total }
            return total + Decimal(entry.amount)
        }
    }
    public static func budgetStatuses(in state: LedgerState, monthContaining day: LedgerDay, currencyCode: String,
                                      calendar: Calendar = .current) throws -> [BudgetStatus] {
        let period = try LedgerPeriod.month(containing: day, calendar: calendar)
        return state.budgets.filter { $0.currencyCode == currencyCode }.map {
            BudgetStatus(budgetID: $0.id, categoryID: $0.categoryID, currencyCode: $0.currencyCode,
                         period: period, budget: Decimal($0.monthlyAmount), spent: budgetSpent($0, in: state, period: period))
        }.sorted {
            if $0.categoryID == nil { return $1.categoryID != nil }
            if $1.categoryID == nil { return false }
            return $0.budgetID.uuidString < $1.budgetID.uuidString
        }
    }
    /// Predicts unprocessed occurrences in the next N civil days, starting tomorrow.
    public static func upcoming(in state: LedgerState, nextDays: Int, today: LedgerDay,
                                calendar: Calendar = .current) throws -> [UpcomingOccurrence] {
        guard nextDays >= 0 else { throw CoreError.invalidField("nextDays", nil) }
        guard nextDays > 0 else { return [] }
        var civilCalendar = Calendar(identifier: .gregorian)
        civilCalendar.timeZone = calendar.timeZone
        let first = try today.adding(days: 1, calendar: civilCalendar)
        let last = try today.adding(days: nextDays, calendar: civilCalendar)
        var result: [UpcomingOccurrence] = []
        for rule in state.rules where !rule.isPaused {
            var from = max(first, rule.startDay)
            if let cursor = [rule.lastPostedDay, rule.lastProcessedDay].compactMap({ $0 }).max(), cursor >= from {
                from = try cursor.adding(days: 1, calendar: civilCalendar)
            }
            let through = min(last, rule.endDay ?? last)
            guard from <= through else { continue }
            for day in try RecurringEngine.occurrences(rule: rule, from: from, through: through, calendar: calendar) {
                if rule.pausedPeriods.contains(where: { $0.contains(day) }) { continue }
                result.append(UpcomingOccurrence(ruleID: rule.id, day: day, kind: rule.kind, amount: rule.amount,
                    currencyCode: rule.currencyCode, walletID: rule.walletID, counterpartWalletID: rule.counterpartWalletID,
                    categoryID: rule.categoryID, title: rule.title))
            }
        }
        return result.sorted { $0.day == $1.day ? $0.ruleID.uuidString < $1.ruleID.uuidString : $0.day < $1.day }
    }
    public static func mostRecentEntry(in state: LedgerState, source: EntrySource? = nil) -> EntryValue? {
        state.entries.filter { source == nil || $0.source == source! }.max { ordered($1, $0) }
    }
    public static func currenciesInUse(in state: LedgerState) -> [String] {
        Set(state.wallets.map(\.currencyCode) + state.entries.map(\.currencyCode)
            + state.rules.map(\.currencyCode) + state.budgets.map(\.currencyCode)).sorted()
    }
    private static func ordered(_ lhs: EntryValue, _ rhs: EntryValue) -> Bool {
        if lhs.day != rhs.day { return lhs.day > rhs.day }
        if lhs.timestamp != rhs.timestamp { return lhs.timestamp > rhs.timestamp }
        return lhs.id.uuidString < rhs.id.uuidString
    }
}
