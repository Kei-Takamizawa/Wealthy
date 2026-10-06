import SwiftUI
import WealthyCore

struct AllowanceSummary: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(LedgerSession.self) private var session
    @Environment(\.colorScheme) private var scheme
    let title: String
    let status: TargetStatus
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text(session.t(title)).font(.headline)
                Text(status.remaining.map { session.money($0) } ?? session.t("targetUnset")).font(.system(.largeTitle, design: .rounded).weight(.bold).monospacedDigit()).lineLimit(1).minimumScaleFactor(0.25)
                Text(session.t("notBalance")).font(.callout)
                if status.isSet { ProgressView(value: status.displayFill, total: 1).tint(status.isOver ? V4.over(scheme) : V4.ok(scheme)).accessibilityHidden(true) }
                if let allowance = status.allowance {
                    LabeledContent(session.t("allowance"), value: session.money(allowance))
                }
                if typeSize.isAccessibilitySize { VStack(alignment: .leading, spacing: 4) { Text(session.t("spent")); Text(session.money(status.spent)).monospacedDigit() } }
                else { LabeledContent(session.t("spent"), value: session.money(status.spent)) }
                Text(String(format: session.t("loggedDays"), status.loggedDays)).font(.footnote)
                HStack(spacing: 8) {
                    Image(systemName: status.isOver ? "moon.fill" : "sun.max.fill").foregroundStyle(status.isOver ? V4.over(scheme) : V4.ok(scheme))
                    Text(session.t(status.isOver ? "over" : status.isSet ? "within" : "unset"))
                }
            }
        }.accessibilityElement(children: .combine)
    }
}
struct HomeView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(LedgerSession.self) private var session
    let showResult: (TargetStatus) -> Void
    var body: some View {
        Form {
            Section {
                if let summary = session.householdSummary {
                    IslandScene(growth: summary.days.filter(\.hasGrowth).count, festivals: summary.festivals, dusk: summary.week.isOver)
                        .frame(height: 180)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(String(format: session.t("islandLabel"), summary.festivals, summary.days.filter(\.hasGrowth).count))
                    weeklyCard(summary.week, summary: summary)
                    monthCard(summary.month)
                    Menu {
                        Button(session.t("weekResultTitle")) { showResult(summary.week) }
                        Button(session.t("monthResultTitle")) { showResult(summary.month) }
                    } label: {
                        Label(session.t("result"), systemImage: "calendar")
                    }
                }
            }
            Section(session.t("thisWeek")) {
                if let summary = session.householdSummary { HStack(spacing: 4) { dayStates(summary) } }
            }
            Section {
                if session.core?.state.entries.isEmpty == true {
                    LabeledContent(session.t("emptyDay"), value: session.t("emptyDetail"))
                }
                NavigationLink { EntryEditor(entry: nil) } label: { Label(session.t("addEntry"), systemImage: "plus") }
                    .buttonStyle(.borderedProminent).accessibilityIdentifier("addEntry")
                Button { session.perform { try session.run(.markNoSpend(session.today, envelopeID: EnvelopeValue.householdID)) } } label: {
                    Label(session.t("noSpend"), systemImage: "checkmark.circle").frame(maxWidth: .infinity, minHeight: 44)
                }.buttonStyle(.bordered).accessibilityIdentifier("noSpend")
                HStack {
                    NavigationLink { GoalsView(envelopeID: EnvelopeValue.householdID) } label: { Label(session.t("goals"), systemImage: "target") }.buttonStyle(.bordered)
                    NavigationLink { SettingsView() } label: { Label(session.t("settings"), systemImage: "gear") }.buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle(session.t("home"))
        .navigationBarTitleDisplayMode(.large)
        .accessibilityIdentifier("homePage")
        .task { await session.homePresented() }
    }
    private func weeklyCard(_ status: TargetStatus, summary: IslandSummary) -> some View {
        Section {
            LabeledContent(session.t("leftThisWeek"), value: status.remaining.map { session.money($0) } ?? session.t("targetUnset"))
            Text(session.t("notBalance"))
            if status.isSet { ProgressView(value: status.displayFill, total: 1).tint(status.isOver ? V4.over(scheme) : V4.ok(scheme)) }
            if status.isSet, let allowance = status.allowance {
                LabeledContent(session.t("allowance"), value: session.money(allowance))
                LabeledContent(session.t("spent"), value: session.money(status.spent))
            }
            HStack(spacing: 8) {
                Image(systemName: status.isOver ? "moon.fill" : status.isSet ? "checkmark.circle.fill" : "circle.dotted")
                    .foregroundStyle(status.isOver ? V4.over(scheme) : status.isSet ? V4.ok(scheme) : .secondary)
                Text(session.t(status.isOver ? "over" : status.isSet ? "within" : "unset"))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.t("leftThisWeek")), \(status.remaining.map { session.money($0) } ?? session.t("targetUnset")), \(session.t("notBalance")), \(session.t("allowance")) \(status.allowance.map { session.money($0) } ?? session.t("targetUnset")), \(session.t("spent")) \(session.money(status.spent))")
    }
    private func monthCard(_ status: TargetStatus) -> some View {
        Section {
            LabeledContent(session.t("spent"), value: session.money(status.spent))
            LabeledContent(session.t("leftThisMonth"), value: status.remaining.map { session.money($0) } ?? session.t("targetUnset"))
            Label(session.t("notBalance"), systemImage: "info.circle")
        }
    }
    @ViewBuilder private func dayStates(_ summary: IslandSummary) -> some View {
        ForEach(summary.days) { day in
            VStack(spacing: 6) {
                let state = day.presentationState
                let icon = switch state {
                    case .underAllowance: "checkmark.circle.fill"
                    case .over: "moon.fill"
                    case .noSpend: "sparkles"
                    case .today: "plus.circle"
                    case .future: "minus"
                    case .unlogged: "circle.dotted"
                }
                Image(systemName: icon).font(.title3).foregroundStyle(state == .over ? V4.over(scheme) : state == .future || state == .unlogged ? .secondary : V4.ok(scheme)).frame(height: 32)
                Text((try? day.day.date(calendar: .current))?.formatted(.dateTime.weekday(.narrow).locale(session.locale)) ?? "\(day.day.day)")
                    .font(.footnote.weight(.semibold))
            }.frame(maxWidth: .infinity).accessibilityElement(children: .ignore)
                .accessibilityLabel("\(day.day.formatted), \(session.t(day.presentationState == .noSpend ? "noSpendMarked" : day.presentationState.rawValue))")
        }
    }
}
struct InfoView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorScheme) private var scheme
    @Environment(LedgerSession.self) private var session
    let showResult: (TargetStatus) -> Void
    var body: some View {
        @Bindable var session = session
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                IslandScene(growth: session.summary?.days.filter(\.hasGrowth).count ?? 0, festivals: session.summary?.festivals ?? 0, dusk: false).frame(height: 100).accessibilityHidden(true)
                Picker(session.t("envelope"), selection: $session.envelopeID) {
                    Text(session.t("household")).tag(EnvelopeValue.householdID)
                    if let child = session.child() { Text(session.t("child")).tag(child.id) }
                }.pickerStyle(.segmented).frame(minHeight: 44)
                if let s = session.summary { AllowanceSummary(title: "leftThisWeek", status: s.week); AllowanceSummary(title: "leftThisMonth", status: s.month) }
                NavigationLink { GoalsView(envelopeID: session.envelopeID) } label: { Label(session.t("goals"), systemImage: "target").frame(minHeight: 52) }
                categoryTargets
                NavigationLink { TaxView() } label: { Label(session.t("tax"), systemImage: "percent").frame(minHeight: 52) }
                if session.envelopeID != EnvelopeValue.householdID { NavigationLink { ChildDetailView() } label: { Label(session.t("childDetail"), systemImage: "leaf").frame(minHeight: 52) } }
                NavigationLink { ChildSetupView() } label: { Label(session.t("childSetup"), systemImage: "person.2").frame(minHeight: 52) }
                Section(session.t("recentEntries")) {
                if let core = session.core {
                    ForEach(LedgerQueries.entries(in: core.state, filter: LedgerEntryFilter(envelopeID: session.envelopeID, limit: 30))) { entry in
                        NavigationLink { EntryEditor(entry: entry) } label: {
                            GroupBox { VStack(alignment: .leading, spacing: 8) { Text(entry.title.isEmpty ? session.t(entry.kind.rawValue) : entry.title); Text(entry.day.formatted).font(.footnote); Text(session.money(entry.amount, code: entry.currencyCode)).font(.system(.title3, design: .rounded).monospacedDigit()); if entry.needsReview { Label(session.t("needsReview"), systemImage: "exclamationmark.triangle") } } }
                        }
                    }
                }
                }
            }.padding(16).padding(.bottom, 32)
        }.navigationTitle(session.t("info")).navigationBarTitleDisplayMode(.large).onChange(of: session.envelopeID) { session.refresh() }.accessibilityIdentifier("infoPage")
    }
    @ViewBuilder private var categoryTargets: some View {
        if let core = session.core, let period = session.summary?.month.period {
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: typeSize.isAccessibilitySize ? 1 : 3), spacing: 16) {
                        ForEach(core.state.categories.filter { $0.envelopeID == session.envelopeID && $0.kind == .expense && !$0.isArchived }) { category in
                            if let status = try? LedgerQueries.targetStatus(in: core.state, period: period, envelopeID: session.envelopeID, categoryID: category.id, currencyCode: session.currency) {
                                VStack(spacing: 8) {
                                    ZStack(alignment: .bottom) {
                                        RoundedRectangle(cornerRadius: 8).stroke(.secondary, lineWidth: 1.5)
                                        RoundedRectangle(cornerRadius: 7).fill(status.isOver ? V4.over(scheme) : V4.ok(scheme)).frame(height: 52 * status.displayFill)
                                    }.frame(width: 32, height: 52).accessibilityHidden(true)
                                    Text(session.categoryName(category)).font(.headline).multilineTextAlignment(.center)
                                    Text(session.money(status.spent)).font(.system(.callout, design: .rounded).weight(.bold).monospacedDigit())
                                    Text(status.allowance.map { session.money($0) } ?? session.t("targetUnset")).font(.footnote)
                                    Label(session.t(status.isSet ? status.isOver ? "over" : "within" : "unset"), systemImage: status.isOver ? "moon.fill" : "sun.max.fill").font(.footnote)
                                }.frame(maxWidth: .infinity).padding(.vertical, 12).accessibilityElement(children: .combine)
                            }
                        }
                    }
                Text(session.t("notBalance")).font(.callout)
                }
            }
        }
    }

}
extension LedgerDay { var formatted: String { String(format: "%04d-%02d-%02d", year, month, day) } }
struct ResultView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(LedgerSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    let status: TargetStatus
    private var isMonth: Bool { loggedRequirement.map { $0.total > 7 } ?? false }
    private var outcome: RewardOutcome { LedgerQueries.rewardOutcome(status) }
    private var resultGrowth: Int {
        guard let core = session.core else { return 0 }
        return (try? LedgerQueries.islandGrowthDays(in: core.state, period: status.period, envelopeID: status.envelopeID, currencyCode: status.currencyCode)) ?? 0
    }
    private var monthAreas: Int {
        guard isMonth, let core = session.core else { return 0 }
        return (try? LedgerQueries.earnedFestivalCount(in: core.state, monthPeriod: status.period, envelopeID: status.envelopeID, currencyCode: status.currencyCode)) ?? 0
    }
    private var loggedRequirement: LoggedDayRequirement? {
        return try? LedgerQueries.loggedDayRequirement(in: status.period)
    }
    var body: some View {
        ScrollView { VStack(spacing: 24) {
            Text(session.t(isMonth ? "monthResultTitle" : "weekResultTitle")).font(.headline)
            if isMonth {
                Text(session.t(monthHeadlineKey)).font(.title2.weight(.semibold)).multilineTextAlignment(.center).foregroundStyle(.primary)
            }
            Label(session.t(isMonth ? monthStickerKey : outcome.rawValue), systemImage: outcome == .achieved ? (isMonth ? "leaf.fill" : "sparkles") : "moon.fill")
                .font(.headline).foregroundStyle(.primary)
            if isMonth, let loggedRequirement {
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(String(format: session.t("monthRequirement"), status.loggedDays, loggedRequirement.total, loggedRequirement.required))
                            .foregroundStyle(.primary)
                        Text(String(format: session.t("monthAreaReward"), monthAreas)).font(.headline).foregroundStyle(.primary)
                        if outcome == .achieved {
                        Label(session.t("monthDecorationReward"), systemImage: "sparkles").foregroundStyle(.primary)
                        }
                        Text("\(status.period.start.formatted) – \(status.period.end.formatted)").font(.footnote)
                        Text(session.t("lateDetail")).font(.footnote).foregroundStyle(.primary).accessibilityIdentifier("resultLateDetail")
                    }
                }
            } else {
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(status.period.start.formatted) – \(status.period.end.formatted)").font(.footnote)
                        Text(session.t("lateDetail")).foregroundStyle(.primary).accessibilityIdentifier("resultLateDetail")
                    }
                }
            }
            IslandScene(growth: resultGrowth, festivals: isMonth ? monthAreas : status.isRewardEligible ? 1 : 0, dusk: status.isOver).frame(height: 180).accessibilityHidden(true)
            AllowanceSummary(title: "remainingAllowance", status: status)
            Button(session.t("done")) { dismiss() }.buttonStyle(.borderedProminent)
        }.padding(24) }.scrollEdgeEffectHidden(for: .bottom).accessibilityIdentifier("resultSheet")
    }
    private var monthHeadlineKey: String {
        switch outcome {
        case .achieved: "monthAchieved"
        case .over: "monthOver"
        case .few: "monthFewDays"
        case .unset: "monthUnset"
        }
    }
    private var monthStickerKey: String {
        switch outcome {
        case .achieved: "monthAchieved"
        case .over: "over"
        case .few: "few"
        case .unset: "unset"
        }
    }
}
