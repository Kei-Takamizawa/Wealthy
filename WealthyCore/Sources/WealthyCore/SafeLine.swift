import Foundation

public struct SafeLine: Sendable, Equatable {
    public let weekRemaining: Int?
    public let scheduled: [UpcomingOccurrence]
    public let scheduledTotal: Int
    public let safeAmount: Int?
}

extension LedgerQueries {
    /// Reserves only future occurrences that would count toward this week's target.
    public static func safeLine(in state: LedgerState, today: LedgerDay,
                                envelopeID: UUID = EnvelopeValue.householdID, currencyCode: String,
                                calendar: Calendar = .current) throws -> SafeLine {
        let week = try LedgerPeriod.week(containing: today, weekStart: state.settings.weekStart, calendar: calendar)
        let status = try targetStatus(in: state, period: week, envelopeID: envelopeID, currencyCode: currencyCode, calendar: calendar)
        var civil = Calendar(identifier: .gregorian)
        civil.timeZone = calendar.timeZone
        let days = civil.dateComponents([.day], from: try today.date(calendar: civil), to: try week.end.date(calendar: civil)).day ?? 0
        let eligibleRules = Set(state.rules.filter {
            !$0.isFixedCost || state.settings.includeFixedCostsInTargets
        }.map(\.id))
        let scheduled = try upcoming(in: state, nextDays: days, today: today, calendar: calendar).filter {
            $0.kind == .expense && $0.envelopeID == envelopeID && $0.currencyCode == currencyCode && eligibleRules.contains($0.ruleID)
        }
        let total = try scheduled.reduce(0) { try checkedSum($0, $1.amount) }
        return SafeLine(weekRemaining: status.remaining, scheduled: scheduled, scheduledTotal: total,
                        safeAmount: try status.remaining.map { try checkedSum($0, -total) })
    }
}
