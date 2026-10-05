import Foundation

public struct RecurringFailure: Sendable, Equatable {
    public var ruleID: UUID
    public var day: LedgerDay
    public var error: CoreError
}
public struct RecurringResult: Sendable, Equatable {
    public var posted: [EntryValue]
    public var failures: [RecurringFailure]
}

/// Generates civil-day occurrences without relying on wall-clock time.
public enum RecurringEngine {
    public static func occurrences(rule: RuleValue, from start: LedgerDay, through end: LedgerDay, calendar: Calendar) throws -> [LedgerDay] {
        try CoreValidation.validateSchedule(rule)
        let cutoff = min(end, rule.endDay ?? end)
        guard !rule.isPaused, start <= cutoff else { return [] }
        let first = max(start, rule.startDay)
        guard first <= cutoff else { return [] }
        var days: [LedgerDay] = [], day = first
        var civil = Calendar(identifier: .gregorian)
        civil.timeZone = calendar.timeZone
        while day <= cutoff {
            let date = try day.date(calendar: civil)
            let count = civil.range(of: .day, in: .month, for: date)!.count
            let matches: Bool
            switch rule.schedule {
            case let .monthly(n): matches = day.day == min(n, count)
            case let .weekly(weekday): matches = civil.component(.weekday, from: date) == weekday
            case let .yearly(month, n): matches = day.month == month && day.day == min(n, count)
            }
            if matches { days.append(day) }
            if day == cutoff { break }
            day = try day.adding(days: 1, calendar: civil)
        }
        return days
    }
}

extension CoreValidation {
    static func validateSchedule(_ rule: RuleValue) throws {
        try rule.startDay.validated(); try rule.endDay?.validated(); try rule.lastPostedDay?.validated(); try rule.lastProcessedDay?.validated()
        try rule.pauseStartedDay?.validated()
        if !rule.isPaused && rule.pauseStartedDay != nil { throw CoreError.invalidField("pauseStartedDay", rule.id) }
        for period in rule.pausedPeriods {
            try period.start.validated(); try period.end.validated()
            guard period.start <= period.end else { throw CoreError.invalidField("pausedPeriods", rule.id) }
        }
        if let end = rule.endDay, end < rule.startDay { throw CoreError.invalidField("endDay", rule.id) }
        switch rule.schedule {
        case let .monthly(day): guard (1...31).contains(day) else { throw CoreError.invalidField("scheduleDay", rule.id) }
        case let .weekly(day): guard (1...7).contains(day) else { throw CoreError.invalidField("weekday", rule.id) }
        case let .yearly(month, day):
            guard (try? LedgerDay(year: 2028, month: month, day: day)) != nil else { throw CoreError.invalidField("yearlyDay", rule.id) }
        }
    }
    static func validateRule(_ rule: RuleValue, in state: LedgerState, active: Bool) throws {
        try validateSchedule(rule)
        let e = EntryValue(id: rule.id, kind: rule.kind, amount: rule.amount, currencyCode: rule.currencyCode,
                           day: rule.startDay, envelopeID: rule.envelopeID, taxRate: rule.taxRate, serviceMode: rule.serviceMode, isFixedCost: rule.isFixedCost, categoryID: rule.categoryID)
        try validateEntry(e, in: state, active: active)
    }
    static func validatePlanning(_ state: LedgerState) throws {
        for rule in state.rules { try validateRule(rule, in: state, active: false) }
        var targetKeys = Set<String>()
        for target in state.targets {
            guard try CoreCurrency.normalizedCode(target.currencyCode) == target.currencyCode else { throw CoreError.invalidField("currencyCode", target.id) }
            guard target.amountMinor >= 0 else { throw CoreError.invalidField("amountMinor", target.id) }
            guard state.envelopes.contains(where: { $0.id == target.envelopeID }) else { throw CoreError.danglingReference("envelopeID", target.envelopeID) }
            try target.effectiveMonth.validated()
            if let id = target.categoryID {
                guard let category = state.categories.first(where: { $0.id == id }) else { throw CoreError.danglingReference("categoryID", id) }
                guard category.kind == .expense, category.envelopeID == target.envelopeID else { throw CoreError.categoryKindMismatch(id) }
            }
            let key = "\(target.envelopeID):\(target.currencyCode):\(target.categoryID?.uuidString ?? "overall"):\(target.effectiveMonth.year)-\(target.effectiveMonth.month)"
            guard targetKeys.insert(key).inserted else { throw CoreError.invalidField("duplicateTarget", target.id) }
        }
        var markKeys = Set<String>()
        for mark in state.noSpendMarks {
            try mark.day.validated()
            guard state.envelopes.contains(where: { $0.id == mark.envelopeID }) else { throw CoreError.danglingReference("envelopeID", mark.envelopeID) }
            guard markKeys.insert("\(mark.envelopeID):\(mark.day)").inserted else { throw CoreError.invalidField("duplicateNoSpendMark", mark.id) }
        }
        for card in state.pointCards {
            guard card.points >= 0 else { throw CoreError.invalidField("points", card.id) }
            guard !normalizedName(card.name).isEmpty else { throw CoreError.invalidField("name", card.id) }
            try card.expiryDay?.validated()
        }
        var occurrenceKeys = Set<String>()
        for e in state.entries {
            try e.occurrenceDay?.validated()
            if let id = e.recurringRuleID, let day = e.occurrenceDay {
                guard e.source == .recurring else { throw CoreError.invalidField("source", e.id) }
                let key = "\(id)-\(day.year)-\(day.month)-\(day.day)"
                guard occurrenceKeys.insert(key).inserted else { throw CoreError.invalidField("duplicateOccurrence", e.id) }
            }
        }
    }
}

extension LedgerCore {
    func applyPlanning(_ command: LedgerCommand, to state: inout LedgerState, now: Date) throws {
        switch command {
        case let .createRule(rule):
            guard rule.lastPostedDay == nil, rule.lastProcessedDay == nil else { throw CoreError.invalidField("recurringCursor", rule.id) }
            var rule = rule
            guard rule.pausedPeriods.isEmpty, rule.pauseStartedDay == nil else { throw CoreError.invalidField("pauseMetadata", rule.id) }
            if rule.isPaused { rule.pauseStartedDay = rule.startDay }
            try CoreValidation.validateRule(rule, in: state, active: true); state.rules.append(rule)
        case let .updateRule(rule):
            let i = try index(rule.id, in: state.rules.map(\.id), type: "rule")
            guard rule.lastPostedDay == state.rules[i].lastPostedDay, rule.lastProcessedDay == state.rules[i].lastProcessedDay,
                  rule.isPaused == state.rules[i].isPaused, rule.pauseStartedDay == state.rules[i].pauseStartedDay,
                  rule.pausedPeriods == state.rules[i].pausedPeriods, rule.createdAt == state.rules[i].createdAt else { throw CoreError.invalidField("ruleMetadata", rule.id) }
            try CoreValidation.validateRule(rule, in: state, active: true); state.rules[i] = rule
        case let .pauseRule(id, paused):
            let i = try index(id, in: state.rules.map(\.id), type: "rule")
            let day = try LedgerDay(date: now, calendar: calendar)
            if !state.rules[i].isPaused && paused { state.rules[i].pauseStartedDay = day }
            if state.rules[i].isPaused && !paused {
                let start = state.rules[i].pauseStartedDay ?? state.rules[i].startDay
                guard start <= day else { throw CoreError.invalidField("resumeDay", id) }
                state.rules[i].pausedPeriods.append(try LedgerPeriod(start: start, end: day))
                state.rules[i].pauseStartedDay = nil
            }
            state.rules[i].isPaused = paused
        case let .deleteRule(id):
            let i = try index(id, in: state.rules.map(\.id), type: "rule"); state.rules.remove(at: i)
        case let .setTarget(value):
            var value = value
            value.currencyCode = try CoreCurrency.normalizedCode(value.currencyCode)
            let current = try LedgerDay(date: now, calendar: calendar)
            guard value.effectiveMonth.year == current.year, value.effectiveMonth.month == current.month else { throw CoreError.invalidField("effectiveMonth", value.id) }
            if let id = value.categoryID, state.categories.first(where: { $0.id == id })?.isArchived == true { throw CoreError.archivedCategory(id) }
            if let i = state.targets.firstIndex(where: { $0.envelopeID == value.envelopeID && $0.currencyCode == value.currencyCode && $0.categoryID == value.categoryID && $0.effectiveMonth == value.effectiveMonth }) {
                value.id = state.targets[i].id; state.targets[i] = value
            } else { state.targets.append(value) }
        case let .removeTarget(id):
            let i = try index(id, in: state.targets.map(\.id), type: "target")
            let current = try LedgerDay(date: now, calendar: calendar)
            guard state.targets[i].effectiveMonth.year == current.year, state.targets[i].effectiveMonth.month == current.month else { throw CoreError.invalidField("effectiveMonth", id) }
            state.targets.remove(at: i)
        case let .markNoSpend(day, envelopeID):
            try day.validated()
            guard let envelope = state.envelopes.first(where: { $0.id == envelopeID }) else { throw CoreError.danglingReference("envelopeID", envelopeID) }
            guard !envelope.isArchived else { throw CoreError.invalidField("archivedEnvelope", envelopeID) }
            if !state.noSpendMarks.contains(where: { $0.envelopeID == envelopeID && $0.day == day }) { state.noSpendMarks.append(NoSpendMarkValue(envelopeID: envelopeID, day: day)) }
        case let .unmarkNoSpend(day, envelopeID):
            try day.validated()
            guard state.envelopes.contains(where: { $0.id == envelopeID }) else { throw CoreError.danglingReference("envelopeID", envelopeID) }
            state.noSpendMarks.removeAll { $0.envelopeID == envelopeID && $0.day == day }
        case let .updateSettings(settings):
            guard settings.id == state.settings.id else { throw CoreError.invalidField("settingsID", settings.id) }
            state.settings = settings
        case let .createPointCard(card): state.pointCards.append(card)
        case let .updatePointCard(card):
            let i = try index(card.id, in: state.pointCards.map(\.id), type: "pointCard"); state.pointCards[i] = card
        case let .deletePointCard(id):
            let i = try index(id, in: state.pointCards.map(\.id), type: "pointCard"); state.pointCards.remove(at: i)
        default: throw CoreError.invalidField("command", nil)
        }
    }

    /// Consumes successful and failed occurrences in one save; this is outside undo history.
    public func postRecurring(through today: LedgerDay, now: Date) throws -> RecurringResult {
        try today.validated()
        let before = self.state
        var state = before, posted: [EntryValue] = [], failures: [RecurringFailure] = []
        for index in state.rules.indices {
            let rule = state.rules[index]
            guard !rule.isPaused else { continue }
            let cutoff = min(today, rule.endDay ?? today)
            let cursors = [rule.lastPostedDay, rule.lastProcessedDay].compactMap { $0 }
            let start: LedgerDay
            if let cursor = cursors.max() {
                guard cursor < cutoff else { continue }
                start = max(rule.startDay, try cursor.adding(days: 1, calendar: calendar))
            } else { start = rule.startDay }
            for day in try RecurringEngine.occurrences(rule: rule, from: start, through: cutoff, calendar: calendar) {
                if rule.pausedPeriods.contains(where: { $0.contains(day) }) {
                    state.rules[index].lastProcessedDay = day
                    continue
                }
                if state.entries.contains(where: { $0.recurringRuleID == rule.id && $0.occurrenceDay == day }) {
                    state.rules[index].lastPostedDay = max(state.rules[index].lastPostedDay ?? day, day)
                    state.rules[index].lastProcessedDay = day
                    continue
                }
                let e = EntryValue(kind: rule.kind, amount: rule.amount, currencyCode: rule.currencyCode, day: day,
                    envelopeID: rule.envelopeID, timestamp: try day.date(calendar: calendar),
                    taxRate: rule.currencyCode == "JPY" && TaxRuleBook().rule(on: day) != nil ? rule.taxRate : nil, serviceMode: rule.serviceMode, isFixedCost: rule.isFixedCost,
                    categoryID: rule.categoryID, title: rule.title, source: .recurring, recurringRuleID: rule.id,
                    occurrenceDay: day, createdAt: now, updatedAt: now)
                do {
                    try CoreValidation.validateEntry(e, in: state, active: true)
                    state.entries.append(e); posted.append(e); state.rules[index].lastPostedDay = day
                } catch { failures.append(RecurringFailure(ruleID: rule.id, day: day, error: error as? CoreError ?? .saveFailed)) }
                state.rules[index].lastProcessedDay = day
            }
        }
        if state != before { try commit(state) }
        return RecurringResult(posted: posted, failures: failures)
    }
}
