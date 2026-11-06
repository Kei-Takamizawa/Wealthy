import SwiftUI
import WealthyCore

struct FixedCostsView: View {
    @Environment(LedgerSession.self) private var session
    let envelopeID: UUID
    @State private var actionRule: RuleValue?
    @State private var deleting = false
    @State private var error: String?
    var body: some View {
        List {
            if let core = session.core {
                let rules = core.state.rules.filter { $0.envelopeID == envelopeID }
                if rules.isEmpty { Text(session.t("emptyRules")) }
                ForEach(rules) { rule in
                    HStack(alignment: .top, spacing: 12) {
                        NavigationLink { RuleEditor(rule: rule, envelopeID: envelopeID) } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(rule.title.isEmpty ? session.t("fixedCosts") : rule.title).font(.headline)
                                Text(session.money(rule.amount, code: rule.currencyCode)).monospacedDigit()
                                Text(session.scheduleText(rule.schedule))
                                if rule.isPaused { Label(session.t("paused"), systemImage: "pause.circle") }
                                if let next = nextOccurrence(rule) { Text(session.t("nextOccurrence") + ": " + session.dayText(next)) }
                                else { Text(session.t("noUpcoming")) }
                            }.padding(.vertical, 4)
                        }.accessibilityIdentifier("rule-" + rule.title)
                        Menu {
                            Button(session.t(rule.isPaused ? "resumeRule" : "pauseRule")) { deleting = false; actionRule = rule }
                            Button(session.t("deleteRule"), role: .destructive) { deleting = true; actionRule = rule }
                        } label: { Image(systemName: "ellipsis.circle").frame(width: 44, height: 44) }
                            .accessibilityLabel(session.t("ruleActions") + ": " + rule.title)
                            .accessibilityIdentifier("ruleActions-" + rule.title)
                    }
                }
            }
            if let error { Text(error).accessibilityIdentifier("rulesError") }
        }
        .navigationTitle(session.t("fixedCosts")).navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { RuleEditor(rule: nil, envelopeID: envelopeID) } label: { Label(session.t("addRule"), systemImage: "plus") }
                    .accessibilityIdentifier("addRule")
            }
        }
        .confirmationDialog(session.t(deleting ? "deleteRule" : actionRule?.isPaused == true ? "confirmResume" : "confirmPause"), isPresented: Binding(get: { actionRule != nil }, set: { if !$0 { actionRule = nil } }), titleVisibility: .visible) {
            if let rule = actionRule {
                Button(session.t(deleting ? "delete" : rule.isPaused ? "confirmResume" : "confirmPause"), role: deleting ? .destructive : nil) {
                    do { try session.run(deleting ? .deleteRule(rule.id) : .pauseRule(rule.id, paused: !rule.isPaused)); error = nil }
                    catch { self.error = session.message(error) }
                    actionRule = nil
                }
                Button(session.t("cancel"), role: .cancel) { actionRule = nil }
            }
        } message: { Text(session.t(deleting ? "deleteRuleDetail" : "pauseRuleDetail")) }
    }
    private func nextOccurrence(_ rule: RuleValue) -> LedgerDay? {
        guard let core = session.core else { return nil }
        do {
            var state = core.state
            state.rules = [rule]
            let from = rule.startDay > session.today ? try rule.startDay.adding(days: -1, calendar: .current) : session.today
            return try LedgerQueries.upcoming(in: state, nextDays: 366, today: from).first?.day
        } catch { return nil }
    }
}

struct RuleEditor: View {
    @Environment(LedgerSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    let rule: RuleValue?
    let envelopeID: UUID
    @State private var title = ""
    @State private var amount = ""
    @State private var kind = EntryKind.expense
    @State private var envelope = EnvelopeValue.householdID
    @State private var category: UUID?
    @State private var schedule = "monthly"
    @State private var day = "25"
    @State private var weekday = 2
    @State private var month = 4
    @State private var start = Date()
    @State private var hasEnd = false
    @State private var end = Date()
    @State private var fixed = true
    @State private var tax = "unknown"
    @State private var service = ServiceMode.none
    @State private var error: String?
    @State private var loaded = false
    private var categories: [CategoryValue] {
        session.core?.state.categories.filter { $0.envelopeID == envelope && $0.kind.rawValue == kind.rawValue && (!$0.isArchived || $0.id == category) } ?? []
    }
    var body: some View {
        Form {
            if let error { Section { Text(error).accessibilityIdentifier("ruleError") } }
            Section {
                Button(session.t("save")) { save() }.accessibilityIdentifier("saveRule")
            }
            Section {
                TextField(session.t("ruleTitle"), text: $title).accessibilityIdentifier("ruleTitle")
                Picker(session.t("kind"), selection: Binding(get: { kind }, set: { kind = $0; category = nil })) {
                    Text(session.t("expense")).tag(EntryKind.expense)
                    Text(session.t("income")).tag(EntryKind.income)
                }
                LabeledContent(session.t("amount")) {
                    MoneyInputField(text: $amount, label: session.t("amount"), identifier: "ruleAmount", font: .body, currencyCode: rule?.currencyCode)
                }
                Picker(session.t("envelope"), selection: Binding(get: { envelope }, set: { envelope = $0; category = nil })) {
                    Text(session.t("household")).tag(EnvelopeValue.householdID)
                    if let child = session.child() { Text(session.t("child")).tag(child.id) }
                }.accessibilityIdentifier("ruleEnvelope")
                Picker(selection: $category) {
                    Text(session.t("none")).tag(nil as UUID?)
                    ForEach(categories) { Text(session.categoryName($0)).tag(Optional($0.id)) }
                } label: {
                    Text(session.t("category")).lineLimit(nil).fixedSize(horizontal: false, vertical: true)
                }.accessibilityIdentifier("ruleCategory")
            }
            Section {
                Picker(session.t("schedule"), selection: $schedule) {
                    Text(session.t("monthly")).tag("monthly")
                    Text(session.t("weekly")).tag("weekly")
                    Text(session.t("yearly")).tag("yearly")
                }
                if schedule == "weekly" {
                    Picker(session.t("weekday"), selection: $weekday) {
                        ForEach(1...7, id: \.self) { Text(session.locale.calendar.weekdaySymbols[$0 - 1]).tag($0) }
                    }
                } else {
                    if schedule == "yearly" {
                        Picker(session.t("scheduleMonth"), selection: $month) {
                            ForEach(1...12, id: \.self) { Text(session.locale.calendar.monthSymbols[$0 - 1]).tag($0) }
                        }
                    }
                    LabeledContent {
                        TextField("", text: $day).font(.body).keyboardType(.numberPad)
                            .accessibilityLabel(session.t("scheduleDay")).accessibilityIdentifier("ruleDay")
                            .frame(width: 100).frame(minHeight: 44)
                    } label: {
                        Text(session.t("scheduleDay")).lineLimit(nil).fixedSize(horizontal: false, vertical: true)
                    }
                }
                DatePicker(session.t("startDay"), selection: $start, displayedComponents: .date)
                Toggle(session.t("hasEndDay"), isOn: $hasEnd)
                if hasEnd { DatePicker(session.t("endDay"), selection: $end, displayedComponents: .date) }
            }
            Section {
                Toggle(session.t("fixedCost"), isOn: $fixed)
                if kind == .expense {
                    Picker(session.t("service"), selection: $service) { ForEach(ServiceMode.allCases, id: \.self) { Text(session.t($0.rawValue)).tag($0) } }
                    Picker(session.t("taxRate"), selection: $tax) { ForEach(["standard", "reduced", "exempt", "unknown"], id: \.self) { Text(session.t($0)).tag($0) } }
                }
            }
        }
        .navigationTitle(session.t(rule == nil ? "addRule" : "editRule")).navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .task { load() }
    }
    private func load() {
        guard !loaded else { return }; loaded = true
        envelope = rule?.envelopeID ?? envelopeID
        start = (try? (rule?.startDay ?? session.today).date(calendar: .current)) ?? Date()
        end = (try? (rule?.endDay ?? session.today).date(calendar: .current)) ?? start
        guard let rule else { return }
        title = rule.title; amount = session.input(rule.amount, code: rule.currencyCode); kind = rule.kind
        category = rule.categoryID; fixed = rule.isFixedCost; tax = rule.taxRate?.rawValue ?? "unknown"; service = rule.serviceMode ?? .none
        hasEnd = rule.endDay != nil
        switch rule.schedule {
        case let .monthly(n): schedule = "monthly"; day = String(n)
        case let .weekly(n): schedule = "weekly"; weekday = n
        case let .yearly(m, n): schedule = "yearly"; month = m; day = String(n)
        }
    }
    private func save() {
        do {
            let code = rule?.currencyCode ?? session.currency
            let value = try session.parse(amount, code: code)
            let startDay = try LedgerDay(date: start, calendar: .current)
            let scheduleDay = Int(day) ?? 0
            let recurrence: RecurringSchedule = schedule == "weekly" ? .weekly(weekday: weekday) : schedule == "yearly" ? .yearly(month: month, day: scheduleDay) : .monthly(day: scheduleDay)
            // Read fresh metadata: catch-up may have advanced cursors while this form was open.
            var result: RuleValue
            if let rule {
                guard let current = session.core?.state.rules.first(where: { $0.id == rule.id }) else { throw CoreError.missingRecord("rule", rule.id) }
                result = current
            } else { result = RuleValue(amount: value, currencyCode: code, schedule: recurrence, startDay: startDay) }
            result.title = title; result.kind = kind; result.amount = value; result.envelopeID = envelope; result.categoryID = category
            result.schedule = recurrence; result.startDay = startDay; result.endDay = hasEnd ? try LedgerDay(date: end, calendar: .current) : nil
            result.isFixedCost = fixed; result.taxRate = TaxRate(rawValue: tax); result.serviceMode = service
            try session.run(rule == nil ? .createRule(result) : .updateRule(result)); dismiss()
        } catch { self.error = session.message(error) }
    }
}

struct RecurringNoticeView: View {
    @Environment(LedgerSession.self) private var session
    var body: some View {
        List {
            Section {
                if !session.recurringEntries.isEmpty {
                    Text(String(format: session.t("catchUpNotice"), session.recurringEntries.count)).accessibilityIdentifier("catchUpNotice")
                    NavigationLink { PostedRecurringView() } label: { Text(session.t("viewRecorded")) }.accessibilityIdentifier("viewCatchUp")
                }
                ForEach(Array(session.recurringFailures.enumerated()), id: \.offset) { _, failure in Text(failure) }
                Button(session.t("done")) { session.dismissRecurringNotice() }.accessibilityIdentifier("dismissCatchUp")
            }
        }.navigationTitle(session.t("recordedFixedCosts")).navigationBarTitleDisplayMode(.inline)
    }
}
struct PostedRecurringView: View {
    @Environment(LedgerSession.self) private var session
    var body: some View {
        List(session.recurringEntries) { entry in
            NavigationLink { DayDetailView(day: entry.day, envelopeID: entry.envelopeID) } label: { LedgerEntryRow(entry: entry) }
                .accessibilityIdentifier("postedEntry-" + entry.day.formatted)
        }.navigationTitle(session.t("recordedFixedCosts")).navigationBarTitleDisplayMode(.inline)
    }
}
