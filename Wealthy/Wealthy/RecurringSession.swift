import Foundation
import WealthyCore

extension LedgerSession {
    func totalMoney(_ amount: Decimal) -> String {
        // Core formats Decimal totals directly, preserving totals beyond Int range.
        if amount >= Decimal(Int.min), amount <= Decimal(Int.max) {
            return money(NSDecimalNumber(decimal: amount).intValue)
        }
        return (try? CoreCurrency.format(amount, currencyCode: currency, locale: locale)) ?? "—"
    }
    func compactMoney(_ amount: Decimal) -> String {
        guard let scale = try? CoreCurrency.minorUnits(for: currency) else { return "—" }
        let divisor = NSDecimalNumber(mantissa: 1, exponent: Int16(scale), isNegative: false)
        let majorUnits = NSDecimalNumber(decimal: amount).dividing(by: divisor).decimalValue
        return majorUnits.formatted(.currency(code: currency).locale(locale).precision(.significantDigits(1...3)).notation(.compactName))
    }
    func dayText(_ day: LedgerDay) -> String {
        (try? day.date(calendar: .current))?.formatted(.dateTime.year().month(.wide).day().locale(locale)) ?? day.formatted
    }
    func isNoSpend(_ day: LedgerDay, envelopeID: UUID) -> Bool {
        core?.state.noSpendMarks.contains { $0.day == day && $0.envelopeID == envelopeID } ?? false
    }
    func scheduleText(_ schedule: RecurringSchedule) -> String {
        switch schedule {
        case let .monthly(day): return String(format: t("scheduleMonthly"), day)
        case let .weekly(weekday):
            var calendar = Calendar(identifier: .gregorian); calendar.locale = locale
            return String(format: t("scheduleWeekly"), calendar.weekdaySymbols[weekday - 1])
        case let .yearly(month, day):
            let date = try? LedgerDay(year: 2028, month: month, day: day).date(calendar: .current)
            return String(format: t("scheduleYearly"), date?.formatted(.dateTime.month(.wide).day().locale(locale)) ?? "—")
        }
    }
    func message(_ error: Error) -> String {
        guard let error = error as? CoreError else { return t("saveError") }
        switch error {
        case let .invalidField(field, _):
            switch field {
            case "amount", "amountMinor": return t("positiveAmountError")
            case "endDay": return t("endDayError")
            case "yearlyDay", "scheduleDay", "weekday", "day": return t("scheduleDayError")
            case "taxRate": return t("taxRateError")
            case "categoryEnvelope", "categoryID": return t("ruleCategoryError")
            case "archivedEnvelope": return t("ruleEnvelopeError")
            default: return t("invalidInput")
            }
        case .categoryKindMismatch, .archivedCategory: return t("ruleCategoryError")
        case .archivedEnvelope, .danglingReference, .missingRecord: return t("ruleReferenceError")
        case .unsupportedCurrency, .currencyMismatch: return t("ruleCurrencyError")
        case .saveFailed, .fileFailure: return t("saveError")
        default: return t("invalidInput")
        }
    }
    /// Runs after presentation, outside the first-frame boundary and Core undo history.
    func catchUpAfterPresentation() async {
        await Task.yield()
        await DisplayFrameWaiter.wait()
        guard !Task.isCancelled, let core else { return }
        do {
            let result = try core.postRecurring(through: today, now: commandDate)
            if !result.posted.isEmpty { recurringEntries.append(contentsOf: result.posted) }
            recurringFailures.append(contentsOf: result.failures.map { failure in
                let name = core.state.rules.first { $0.id == failure.ruleID }?.title ?? t("fixedCosts")
                return "\(name) (\(dayText(failure.day))): \(message(failure.error))"
            })
            if !result.posted.isEmpty || !result.failures.isEmpty { showRecurringNotice = true }
            if !result.posted.isEmpty { refresh() }
        } catch {
            recurringFailures.append(message(error)); showRecurringNotice = true
        }
    }
    func dismissRecurringNotice() {
        showRecurringNotice = false; recurringEntries = []; recurringFailures = []
    }

    #if DEBUG || WEALTHY_LAUNCH_MEASUREMENT
    func seedCycle2b() throws {
        guard let core else { return }
        onboarded = true
        // A disk fixture is seeded once; process relaunch must exercise real Core cursors.
        guard core.state.rules.isEmpty else { return }
        let future = try LedgerDay(year: 2026, month: 10, day: 12)
        let food = core.state.categories.first { $0.systemKey == "catFood" }?.id
        let transport = core.state.categories.first { $0.systemKey == "catTransport" }?.id
        if ProcessInfo.processInfo.arguments.contains("--cycle2b-failure"), let food {
            try run(.createRule(RuleValue(title: "Synthetic unavailable category", amount: 1000, currencyCode: "JPY", categoryID: food, schedule: .monthly(day: 1), startDay: LedgerDay(year: 2026, month: 10, day: 1))))
            try run(.archiveCategory(food, archived: true))
            return
        }
        if ProcessInfo.processInfo.arguments.contains("--cycle2b-catchup") {
            if ProcessInfo.processInfo.arguments.contains("--cycle2b-results") {
                var state = core.state
                state.targets = [TargetValue(currencyCode: "JPY", amountMinor: 310000, effectiveMonth: try LedgerMonth(year: 2026, month: 9))]
                let archive = LedgerBackupArchive(exportDate: commandDate, appVersion: "Cycle2bTest", coreVersion: "2", state: state)
                try LedgerBackup.restore(JSONEncoder().encode(archive), into: core)
            }
            try run(.createRule(RuleValue(title: "Synthetic catch-up", amount: 1000, currencyCode: "JPY", isFixedCost: true, schedule: .monthly(day: 1), startDay: LedgerDay(year: 2026, month: 8, day: 1))))
            return
        }
        if ProcessInfo.processInfo.arguments.contains("--cycle2b-usd") {
            try run(.createRule(RuleValue(title: "Synthetic dollar rule", amount: 1299, currencyCode: "USD", schedule: .monthly(day: 25), startDay: future)))
        }
        try run(.createRule(RuleValue(title: "Synthetic monthly", amount: 68000, currencyCode: "JPY", isFixedCost: true, schedule: .monthly(day: 25), startDay: future)))
        try run(.createRule(RuleValue(title: "Synthetic weekly", amount: 2000, currencyCode: "JPY", isFixedCost: true, schedule: .weekly(weekday: 2), startDay: future)))
        try run(.createRule(RuleValue(title: "Synthetic yearly", amount: 24000, currencyCode: "JPY", isFixedCost: true, schedule: .yearly(month: 4, day: 1), startDay: future)))
        let day = try LedgerDay(year: 2026, month: 10, day: 8)
        try run(.addEntry(EntryValue(kind: .expense, amount: 800, currencyCode: "JPY", day: day, categoryID: food, title: "Synthetic lunch")))
        try run(.addEntry(EntryValue(kind: .expense, amount: 330, currencyCode: "JPY", day: day, categoryID: transport, title: "Synthetic train")))
        let prior = try LedgerDay(year: 2026, month: 9, day: 8)
        try run(.addEntry(EntryValue(kind: .expense, amount: 600, currencyCode: "JPY", day: prior, categoryID: food, title: "Synthetic prior lunch")))
        try run(.addEntry(EntryValue(kind: .expense, amount: 200, currencyCode: "JPY", day: prior, categoryID: transport, title: "Synthetic prior train")))
        try run(.markNoSpend(day))
        try createChild()
        if let child = child() {
            try run(.createRule(RuleValue(title: "Synthetic child rule", amount: 5000, currencyCode: "JPY", envelopeID: child.id, categoryID: core.state.categories.first { $0.envelopeID == child.id && $0.systemKey == "child.food" }?.id, schedule: .monthly(day: 15), startDay: future)))
        }
        if ProcessInfo.processInfo.arguments.contains("--child-info"), let child = child() { envelopeID = child.id }
    }
    #endif
}
