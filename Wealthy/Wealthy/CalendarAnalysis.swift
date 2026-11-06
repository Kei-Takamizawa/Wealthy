import SwiftUI
import WealthyCore

struct CalendarView: View {
    @Environment(LedgerSession.self) private var session
    @Environment(\.dynamicTypeSize) private var typeSize
    let envelopeID: UUID
    @State private var month = Date()
    @State private var loaded = false
    @State private var error: String?
    private var days: [DailyTotal] {
        guard let core = session.core else { return [] }
        return (try? LedgerQueries.dailyTotals(in: core.state, monthContaining: LedgerDay(date: month, calendar: .current), currencyCode: session.currency, envelopeID: envelopeID)) ?? []
    }
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = session.locale
        calendar.firstWeekday = session.core?.state.settings.weekStart ?? 2
        return calendar
    }
    private var leadingDays: Int {
        guard let day = days.first?.day, let date = try? day.date(calendar: calendar) else { return 0 }
        return (calendar.component(.weekday, from: date) - calendar.firstWeekday + 7) % 7
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                MonthControl(date: $month)
                if typeSize.isAccessibilitySize {
                    LazyVStack(alignment: .leading, spacing: 12) { ForEach(days, id: \.day) { day in cell(day) } }
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 12) {
                        ForEach(0..<7, id: \.self) { offset in
                            Text(calendar.shortWeekdaySymbols[(calendar.firstWeekday - 1 + offset) % 7]).font(.caption).fixedSize(horizontal: false, vertical: true)
                        }
                        ForEach(0..<leadingDays, id: \.self) { _ in Color.clear.frame(height: 1).accessibilityHidden(true) }
                        ForEach(days, id: \.day) { day in cell(day) }
                    }
                }
                if let error { Text(error).foregroundStyle(.primary) }
            }.padding(16)
        }
        .navigationTitle(session.t("calendar"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard !loaded else { return }; loaded = true
            do { month = try session.today.date(calendar: calendar) } catch { self.error = session.message(error) }
        }
    }
    private func cell(_ total: DailyTotal) -> some View {
        let marked = session.isNoSpend(total.day, envelopeID: envelopeID)
        let today = total.day == session.today
        return NavigationLink { DayDetailView(day: total.day, envelopeID: envelopeID) } label: {
            VStack(alignment: typeSize.isAccessibilitySize ? .leading : .center, spacing: 4) {
                Text(typeSize.isAccessibilitySize ? session.dayText(total.day) : String(total.day.day)).font(.body.weight(today ? .bold : .regular))
                Text(typeSize.isAccessibilitySize ? session.totalMoney(total.expense) : session.compactMoney(total.expense)).font(typeSize.isAccessibilitySize ? .body : .footnote).monospacedDigit()
                if marked { Image(systemName: "checkmark.circle").accessibilityHidden(true) }
                if today { Text(session.t("today")).font(.caption2) }
            }
            .frame(maxWidth: .infinity, minHeight: 64, alignment: typeSize.isAccessibilitySize ? .leading : .center)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(session.dayText(total.day)), \(session.t("spent")) \(session.totalMoney(total.expense)), \(session.t(marked ? "noSpendMarked" : "noSpendUnmarked"))\(today ? ", " + session.t("today") : "")")
        .accessibilityIdentifier("calendar-" + total.day.formatted)
        }
        .buttonStyle(.plain)
    }
}

struct DayDetailView: View {
    @Environment(LedgerSession.self) private var session
    let day: LedgerDay
    let envelopeID: UUID
    @State private var error: String?
    var body: some View {
        List {
            if let core = session.core, let period = try? LedgerPeriod(start: day, end: day) {
                let total = LedgerQueries.periodSummary(in: core.state, period: period, currencyCode: session.currency, envelopeID: envelopeID)
                Section(session.t("dayTotals")) {
                    LabeledContent(session.t("expense"), value: session.totalMoney(total.expense))
                    LabeledContent(session.t("income"), value: session.totalMoney(total.income))
                    Toggle(session.t("noSpendMarked"), isOn: Binding(get: { session.isNoSpend(day, envelopeID: envelopeID) }, set: { marked in
                        do { try session.run(marked ? .markNoSpend(day, envelopeID: envelopeID) : .unmarkNoSpend(day, envelopeID: envelopeID)); error = nil }
                        catch { self.error = session.message(error) }
                    })).accessibilityIdentifier("dayNoSpend")
                    if let error { Text(error).accessibilityIdentifier("dayError") }
                }
                Section(session.t("recentEntries")) {
                    let entries = LedgerQueries.entries(in: core.state, filter: LedgerEntryFilter(period: period, envelopeID: envelopeID, currencyCode: session.currency))
                    if entries.isEmpty { Text(session.t("emptyDay")) }
                    ForEach(entries) { entry in
                        NavigationLink { EntryEditor(entry: entry) } label: { LedgerEntryRow(entry: entry) }
                            .accessibilityIdentifier("dayEntry-" + entry.title)
                    }
                }
            }
        }.navigationTitle(session.dayText(day)).navigationBarTitleDisplayMode(.inline)
    }
}

struct LedgerEntryRow: View {
    @Environment(LedgerSession.self) private var session
    let entry: EntryValue
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.title.isEmpty ? session.t(entry.kind.rawValue) : entry.title)
            Text(session.dayText(entry.day))
            Text(session.money(entry.amount, code: entry.currencyCode)).monospacedDigit()
        }.accessibilityElement(children: .combine)
    }
}

struct AnalysisView: View {
    @Environment(LedgerSession.self) private var session
    let envelopeID: UUID
    @State private var month = Date()
    @State private var loaded = false
    var body: some View {
        List {
            Section { MonthControl(date: $month) }
            if let core = session.core, let day = try? LedgerDay(date: month, calendar: .current),
               let period = try? LedgerPeriod.month(containing: day), let previous = try? LedgerPeriod.previousMonth(containing: day) {
                let total = LedgerQueries.periodSummary(in: core.state, period: period, currencyCode: session.currency, envelopeID: envelopeID)
                let prior = LedgerQueries.periodSummary(in: core.state, period: previous, currencyCode: session.currency, envelopeID: envelopeID)
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(session.t("thisMonth") + ": " + session.totalMoney(total.expense))
                        Text(session.t("previousMonthTotal") + ": " + session.totalMoney(prior.expense))
                    }.accessibilityElement(children: .combine).accessibilityIdentifier("analysisTotals")
                }
                if total.expenseCount == 0 {
                    Text(session.t("emptyAnalysis")).accessibilityIdentifier("emptyAnalysis")
                } else {
                    Section {
                        let rows = LedgerQueries.categoryBreakdown(in: core.state, period: period, previousPeriod: previous, currencyCode: session.currency, envelopeID: envelopeID)
                        ForEach(rows, id: \.categoryID) { row in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(row.categoryID.flatMap { id in core.state.categories.first { $0.id == id }.map(session.categoryName) } ?? session.t("none")).font(.headline)
                                Text(session.t("thisMonth") + ": " + session.totalMoney(row.amount))
                                Text(session.t("previousMonthTotal") + ": " + session.totalMoney(row.previousAmount))
                            }.accessibilityElement(children: .combine).accessibilityIdentifier("analysis-" + (row.categoryID?.uuidString ?? "none"))
                        }
                    } header: { Text(session.t("category")).font(.body).foregroundStyle(Color.primary) }
                }
            }
        }
        .navigationTitle(session.t("analysis")).navigationBarTitleDisplayMode(.inline)
        .task { if !loaded { loaded = true; month = (try? session.today.date(calendar: .current)) ?? Date() } }
    }
}
