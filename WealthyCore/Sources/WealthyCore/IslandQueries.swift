import Foundation

public enum RewardOutcome: String, Sendable, Equatable { case unset, achieved, over, few }
public enum IslandDayState: String, Sendable, Equatable {
    case underAllowance, over, noSpend, today, future, unlogged
}
public struct IslandDay: Sendable, Equatable, Identifiable {
    public var id: LedgerDay { day }
    public var day: LedgerDay
    public var status: TargetStatus
    public var hasGrowth: Bool { status.loggedDays > 0 && (status.remaining ?? -1) > 0 }
    public var presentationState: IslandDayState {
        if status.period.start > referenceToday { return .future }
        if status.noSpendDays > 0 { return .noSpend }
        if status.isOver { return .over }
        if status.period.start == referenceToday { return .today }
        if hasGrowth { return .underAllowance }
        return .unlogged
    }
    public var referenceToday: LedgerDay
}
public struct IslandSummary: Sendable, Equatable {
    public var week: TargetStatus
    public var month: TargetStatus
    public var days: [IslandDay]
    public var festivals: Int
}
extension LedgerQueries {
    public static func fixedCostDefault(for category: CategoryValue) -> Bool { category.systemKey == "child.support" }

    public static func rewardOutcome(_ status: TargetStatus) -> RewardOutcome {
        guard status.isSet else { return .unset }
        if (status.remaining ?? 0) < 0 { return .over }
        return status.isRewardEligible ? .achieved : .few
    }
    /// A single detached snapshot feeds the Home and Info screens. No rewards are persisted.
    public static func islandSummary(in state: LedgerState, today: LedgerDay, envelopeID: UUID = EnvelopeValue.householdID,
                                     currencyCode: String, calendar: Calendar = .current) throws -> IslandSummary {
        let week = try weekTargetStatus(in: state, containing: today, envelopeID: envelopeID, currencyCode: currencyCode, calendar: calendar)
        let month = try monthTargetStatus(in: state, month: LedgerMonth(day: today), envelopeID: envelopeID, currencyCode: currencyCode, calendar: calendar)
        var days: [IslandDay] = []
        for offset in 0..<7 {
            let day = try week.period.start.adding(days: offset, calendar: calendar)
            let status = try targetStatus(in: state, period: LedgerPeriod(start: day, end: day), envelopeID: envelopeID, currencyCode: currencyCode, calendar: calendar)
            days.append(IslandDay(day: day, status: status, referenceToday: today))
        }
        var cursor = month.period.start, festivals = 0
        while cursor <= month.period.end {
            let period = try LedgerPeriod.week(containing: cursor, weekStart: state.settings.weekStart, calendar: calendar)
            // Assign a cross-month festival to the month in which the week ends.
            if period.end <= today && period.end <= month.period.end {
                let status = try targetStatus(in: state, period: period, envelopeID: envelopeID, currencyCode: currencyCode, calendar: calendar)
                if status.isRewardEligible { festivals += 1 }
            }
            cursor = try period.end.adding(days: 1, calendar: calendar)
        }
        return IslandSummary(week: week, month: month, days: days, festivals: min(4, festivals))
    }
    /// Counts growth from daily allowance queries, never merely from the number of logged days.
    public static func islandGrowthDays(in state: LedgerState, period: LedgerPeriod, envelopeID: UUID = EnvelopeValue.householdID,
                                        currencyCode: String, calendar: Calendar = .current) throws -> Int {
        var cursor = period.start, count = 0
        while cursor <= period.end {
            let status = try targetStatus(in: state, period: LedgerPeriod(start: cursor, end: cursor), envelopeID: envelopeID, currencyCode: currencyCode, calendar: calendar)
            if status.loggedDays > 0 && (status.remaining ?? -1) > 0 { count += 1 }
            cursor = try cursor.adding(days: 1, calendar: calendar)
        }
        return count
    }
    /// Counts reward-eligible completed weeks ending within a month, capped at the four visible areas.
    public static func earnedFestivalCount(in state: LedgerState, monthPeriod: LedgerPeriod,
                                           envelopeID: UUID = EnvelopeValue.householdID, currencyCode: String,
                                           calendar: Calendar = .current) throws -> Int {
        var cursor = try LedgerPeriod.week(containing: monthPeriod.start, weekStart: state.settings.weekStart, calendar: calendar).start
        var festivals = 0
        while cursor <= monthPeriod.end {
            let week = try LedgerPeriod.week(containing: cursor, weekStart: state.settings.weekStart, calendar: calendar)
            if week.end <= monthPeriod.end {
                let status = try targetStatus(in: state, period: week, envelopeID: envelopeID, currencyCode: currencyCode, calendar: calendar)
                if status.isRewardEligible { festivals += 1 }
            }
            cursor = try week.end.adding(days: 1, calendar: calendar)
        }
        return min(4, festivals)
    }
    public static func canAddEntry(on day: LedgerDay, today: LedgerDay, weekStart: Int = 2, calendar: Calendar = .current) throws -> Bool {
        let week = try LedgerPeriod.week(containing: day, weekStart: weekStart, calendar: calendar)
        let month = try LedgerPeriod.month(containing: day, calendar: calendar)
        let weekDeadline = try week.end.adding(days: 3, calendar: calendar)
        let monthDeadline = try month.end.adding(days: 3, calendar: calendar)
        return today <= weekDeadline && today <= monthDeadline
    }
    public static func recentlyEndedResults(in state: LedgerState, today: LedgerDay, envelopeID: UUID = EnvelopeValue.householdID,
                                           currencyCode: String, calendar: Calendar = .current) throws -> [TargetStatus] {
        let week = try LedgerPeriod.week(containing: today, weekStart: state.settings.weekStart, calendar: calendar)
        let month = try LedgerPeriod.month(containing: today, calendar: calendar)
        return try [(week.start, true), (month.start, false)].compactMap { start, isWeek in
            let end = try start.adding(days: -1, calendar: calendar)
            guard today <= (try end.adding(days: 3, calendar: calendar)) else { return nil }
            let period = isWeek ? try LedgerPeriod.week(containing: end, weekStart: state.settings.weekStart, calendar: calendar) : try LedgerPeriod.month(containing: end, calendar: calendar)
            return try targetStatus(in: state, period: period, envelopeID: envelopeID, currencyCode: currencyCode, calendar: calendar)
        }
    }
}
