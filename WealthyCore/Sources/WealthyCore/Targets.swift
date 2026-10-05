import Foundation

extension LedgerPeriod {
    public static func week(containing day: LedgerDay, weekStart: Int = 2, calendar: Calendar = .current) throws -> LedgerPeriod {
        guard (1...7).contains(weekStart) else { throw CoreError.invalidField("weekStart", nil) }
        var civil = Calendar(identifier: .gregorian); civil.timeZone = calendar.timeZone
        let weekday = civil.component(.weekday, from: try day.date(calendar: civil))
        let start = try day.adding(days: -((weekday - weekStart + 7) % 7), calendar: civil)
        return try LedgerPeriod(start: start, end: start.adding(days: 6, calendar: civil))
    }
}
public struct TargetStatus: Codable, Sendable, Equatable {
    public var envelopeID: UUID
    public var categoryID: UUID?
    public var currencyCode: String
    public var period: LedgerPeriod
    public var allowance: Int?
    public var spent: Int
    public var remaining: Int?
    public var loggedDays: Int
    public var noSpendDays: Int
    public var isRewardEligible: Bool
    public var isSet: Bool { allowance != nil }
}
extension LedgerQueries {
    public static func effectiveTarget(in state: LedgerState, month: LedgerMonth, envelopeID: UUID = EnvelopeValue.householdID,
                                       categoryID: UUID? = nil, currencyCode: String) -> TargetValue? {
        state.targets.filter { $0.envelopeID == envelopeID && $0.categoryID == categoryID && $0.currencyCode == currencyCode && $0.effectiveMonth <= month }
            .max { $0.effectiveMonth < $1.effectiveMonth }
    }
    public static func dailyAllowance(in state: LedgerState, day: LedgerDay, envelopeID: UUID = EnvelopeValue.householdID,
                                      categoryID: UUID? = nil, currencyCode: String, calendar: Calendar = .current) throws -> Int? {
        let month = try LedgerMonth(year: day.year, month: day.month)
        guard let target = effectiveTarget(in: state, month: month, envelopeID: envelopeID, categoryID: categoryID, currencyCode: currencyCode) else { return nil }
        let days = try LedgerPeriod.month(containing: day, calendar: calendar).end.day
        return target.amountMinor / days + (day.day <= target.amountMinor % days ? 1 : 0)
    }
    public static func targetStatus(in state: LedgerState, period: LedgerPeriod, envelopeID: UUID = EnvelopeValue.householdID,
                                    categoryID: UUID? = nil, currencyCode: String, calendar: Calendar = .current) throws -> TargetStatus {
        var allowance = 0, configured = true, day = period.start, dayCount = 0
        while day <= period.end {
            if let amount = try dailyAllowance(in: state, day: day, envelopeID: envelopeID, categoryID: categoryID, currencyCode: currencyCode, calendar: calendar) {
                allowance = try checkedSum(allowance, amount)
            } else { configured = false }
            dayCount += 1
            if day == period.end { break }; day = try day.adding(days: 1, calendar: calendar)
        }
        var spent = 0, logged = Set<LedgerDay>(), expenseDays = Set<LedgerDay>()
        for entry in state.entries where entry.envelopeID == envelopeID && period.contains(entry.day) {
            // Logging belongs to the envelope and is independent of currency/category and target exclusions.
            logged.insert(entry.day)
            if entry.kind == .expense { expenseDays.insert(entry.day) }
            if entry.kind == .expense && entry.currencyCode == currencyCode && (categoryID == nil || entry.categoryID == categoryID)
                && (state.settings.includeFixedCostsInTargets || !entry.isFixedCost) { spent = try checkedSum(spent, entry.amount) }
        }
        let marked = Set(state.noSpendMarks.filter { $0.envelopeID == envelopeID && period.contains($0.day) }.map(\.day))
        logged.formUnion(marked)
        let remaining = configured ? try checkedSum(allowance, -spent) : nil
        let minimum = dayCount == 7 ? 5 : (dayCount * 80 + 99) / 100
        return TargetStatus(envelopeID: envelopeID, categoryID: categoryID, currencyCode: currencyCode, period: period,
                            allowance: configured ? allowance : nil, spent: spent, remaining: remaining,
                            loggedDays: logged.count, noSpendDays: marked.subtracting(expenseDays).count,
                            isRewardEligible: configured && spent <= allowance && logged.count >= minimum)
    }
    public static func monthTargetStatus(in state: LedgerState, month: LedgerMonth, envelopeID: UUID = EnvelopeValue.householdID,
                                         categoryID: UUID? = nil, currencyCode: String, calendar: Calendar = .current) throws -> TargetStatus {
        try targetStatus(in: state, period: LedgerPeriod.month(containing: LedgerDay(year: month.year, month: month.month, day: 1), calendar: calendar), envelopeID: envelopeID, categoryID: categoryID, currencyCode: currencyCode, calendar: calendar)
    }
    public static func weekTargetStatus(in state: LedgerState, containing day: LedgerDay, envelopeID: UUID = EnvelopeValue.householdID,
                                        categoryID: UUID? = nil, currencyCode: String, calendar: Calendar = .current) throws -> TargetStatus {
        try targetStatus(in: state, period: LedgerPeriod.week(containing: day, weekStart: state.settings.weekStart, calendar: calendar), envelopeID: envelopeID, categoryID: categoryID, currencyCode: currencyCode, calendar: calendar)
    }
}
