import SwiftUI
import WealthyCore

struct AllowancePlate: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(LedgerSession.self) private var session
    @Environment(\.colorScheme) private var scheme
    let title: String
    let status: TargetStatus
    var body: some View {
        Plate {
            VStack(alignment: .leading, spacing: 12) {
                Text(session.t(title)).font(V4.heading(session.language, size: 22))
                Text(status.remaining.map { session.money($0) } ?? session.t("targetUnset")).font(.system(.largeTitle, design: .rounded).weight(.bold).monospacedDigit()).lineLimit(1).minimumScaleFactor(0.25)
                Text(session.t("notBalance")).font(.footnote).foregroundStyle(V4.ink2(scheme))
                if status.isSet { ProgressView(value: status.displayFill, total: 1).tint(status.isOver ? V4.over(scheme) : V4.ok(scheme)).accessibilityHidden(true) }
                if typeSize.isAccessibilitySize { VStack(alignment: .leading, spacing: 4) { Text(session.t("spent")); Text(session.money(status.spent)).monospacedDigit() } }
                else { LabeledContent(session.t("spent"), value: session.money(status.spent)) }
                Text(String(format: session.t("loggedDays"), status.loggedDays)).font(.footnote)
                Label(session.t(status.isOver ? "over" : status.isSet ? "within" : "unset"), systemImage: status.isOver ? "moon.fill" : "sun.max.fill").foregroundStyle(status.isOver ? V4.over(scheme) : V4.ok(scheme))
            }
        }.accessibilityElement(children: .combine)
    }
}
struct HomeView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorScheme) private var scheme
    @Environment(LedgerSession.self) private var session
    let toVoice: () -> Void
    let toInfo: () -> Void
    let showResult: (TargetStatus) -> Void
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                GlassEffectContainer {
                    let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout())
                    layout { Text(session.t("thisWeek")).foregroundStyle(V4.ink(scheme)).padding(12).modifier(V4Glass()); if !typeSize.isAccessibilitySize { Spacer() }; Button(action: toInfo) { Pill(text: session.t("info"), icon: "chevron.right") }.accessibilityIdentifier("homeInfo") }
                }
                if let s = session.householdSummary {
                    IslandScene(growth: s.days.filter(\.hasGrowth).count, festivals: s.festivals, dusk: s.week.isOver).frame(height: 180).accessibilityHidden(true)
                        .accessibilityElement(children: .ignore).accessibilityLabel(String(format: session.t("islandLabel"), s.festivals, s.days.filter(\.hasGrowth).count))
                    weeklyCard(s.week, summary: s)
                    monthCard(s.month)
                    HStack { Button { showResult(s.week) } label: { Text(session.t("weekResult")).frame(minHeight: 44) }; Spacer(); Button { showResult(s.month) } label: { Text(session.t("monthResult")).frame(minHeight: 44) } }
                }
                if session.core?.state.entries.isEmpty == true { Plate { VStack(alignment: .leading, spacing: 12) { Text(session.t("emptyDay")).font(V4.heading(session.language, size: 24)); Text(session.t("emptyDetail")) } } }
                NavigationLink { EntryEditor(entry: nil) } label: { Label(session.t("addEntry"), systemImage: "plus") }.buttonStyle(PrimaryButton()).accessibilityIdentifier("addEntry")
                Button { session.perform { try session.run(.markNoSpend(session.today, envelopeID: EnvelopeValue.householdID)) } } label: { Text(session.t("noSpend")).frame(maxWidth: .infinity, minHeight: 52).contentShape(Rectangle()) }.accessibilityIdentifier("noSpend")
                GlassEffectContainer { ViewThatFits(in: .horizontal) { HStack { homeControls }; VStack(alignment: .leading) { homeControls } } }
                }.padding(16).padding(.bottom, 32)
            }
            .frame(maxHeight: .infinity)
            .background(V4.paper(scheme)).accessibilityIdentifier("homePage").task { await session.homePresented() }
            homeBottomBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(V4.paper(scheme))
    }
    private var homeBottomBar: some View {
        GlassEffectContainer {
            HStack {
                Button(action: toInfo) {
                    Label(session.t("info"), systemImage: "info.circle")
                        .font(.footnote.weight(.semibold)).padding(12).frame(minHeight: 44)
                        .foregroundStyle(V4.ink(scheme))
                        .background(V4.color(0xFFF8EA, 0x25221E, scheme), in: .capsule)
                        .overlay(Capsule().stroke(V4.line(scheme), lineWidth: 0.7))
                }.accessibilityIdentifier("homeInfoBottom")
                Spacer()
                Button(action: toVoice) { Image(systemName: "mic.fill").font(.title2).frame(width: 56, height: 52).modifier(V4Glass()).accessibilityLabel(session.t("voice")) }
                    .accessibilityIdentifier("homeMicrophone")
                Spacer()
                Color.clear.frame(width: 56, height: 44).accessibilityHidden(true)
            }.padding(.horizontal, 16).padding(.vertical, 6)
        }
        .frame(maxWidth: .infinity)
        .background(V4.paper(scheme))
    }
    private func weeklyCard(_ status: TargetStatus, summary: IslandSummary) -> some View {
        Plate {
            VStack(alignment: .leading, spacing: 10) {
                Text(session.t("weeklyAllowance")).font(V4.heading(session.language, size: 22))
                Text(status.isSet ? session.money(status.remaining ?? 0) : session.t("targetUnset"))
                    .font(.system(.largeTitle, design: .rounded).weight(.bold).monospacedDigit()).lineLimit(1).minimumScaleFactor(0.35)
                    .accessibilityIdentifier("homeWeeklyRemaining")
                Text(session.t("notBalance")).font(.footnote).padding(.horizontal, 10).padding(.vertical, 6).background(V4.sunken(scheme), in: .capsule)
                if status.isSet { ProgressView(value: status.displayFill, total: 1).tint(status.isOver ? V4.over(scheme) : V4.ok(scheme)).accessibilityHidden(true) }
                if status.isSet, let allowance = status.allowance {
                    Text(String(format: session.t("allowanceSpentPercent"), session.money(allowance), session.money(status.spent), status.spentPercentage ?? 0))
                        .font(.footnote).foregroundStyle(V4.ink2(scheme))
                }
                Label(session.t(status.isOver ? "over" : status.isSet ? "within" : "unset"),
                      systemImage: status.isOver ? "moon.fill" : status.isSet ? "checkmark.circle.fill" : "circle.dotted")
                    .foregroundStyle(status.isOver ? V4.over(scheme) : status.isSet ? V4.ok(scheme) : V4.ink2(scheme))
                HStack(spacing: 4) { dayStickers(summary) }
            }
        }.accessibilityElement(children: .combine)
    }
    private func monthCard(_ status: TargetStatus) -> some View {
        Plate {
            VStack(alignment: .leading, spacing: 10) {
                Text(session.t("monthlyAllowance")).font(V4.heading(session.language, size: 21)).foregroundStyle(V4.ink(scheme))
                if status.isSet {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.t("spent")).font(.footnote).foregroundStyle(V4.ink2(scheme))
                            Text(session.money(status.spent)).font(.system(.title2, design: .rounded).monospacedDigit()).foregroundStyle(V4.ink(scheme))
                        }
                        Spacer(minLength: 8)
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(session.t("remainingAllowance")).font(.footnote).foregroundStyle(V4.ink2(scheme))
                            Text(session.money(status.remaining ?? 0)).font(.system(.title2, design: .rounded).monospacedDigit()).foregroundStyle(V4.ink(scheme))
                        }
                    }
                    Label(session.t(status.isOver ? "over" : "within"), systemImage: status.isOver ? "moon.fill" : "checkmark.circle.fill")
                        .foregroundStyle(status.isOver ? V4.over(scheme) : V4.ok(scheme))
                } else { Text(session.t("targetUnset")).foregroundStyle(V4.ink2(scheme)) }
                Text(session.t("notBalance")).font(.footnote).foregroundStyle(V4.ink2(scheme))
            }
        }.accessibilityElement(children: .combine)
    }
    @ViewBuilder private var homeControls: some View {
        NavigationLink { GoalsView(envelopeID: EnvelopeValue.householdID) } label: { Pill(text: session.t("goals"), icon: "target") }
        Button(action: toVoice) { Pill(text: session.t("voice"), icon: "mic") }.accessibilityIdentifier("homeVoice")
        NavigationLink { SettingsView() } label: { Pill(text: session.t("settings"), icon: "gear") }
    }
    @ViewBuilder private func dayStickers(_ s: IslandSummary) -> some View {
        ForEach(s.days) { day in
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
                Image(systemName: icon).font(.system(size: 24)).foregroundStyle(state == .over ? V4.over(scheme) : state == .future || state == .unlogged ? V4.ink2(scheme) : V4.ok(scheme)).frame(height: 32)
                Text((try? day.day.date(calendar: .current))?.formatted(.dateTime.weekday(.narrow).locale(session.locale)) ?? "\(day.day.day)").font(.footnote.weight(.semibold)).foregroundStyle(V4.ink(scheme))
            }.frame(maxWidth: .infinity).accessibilityElement(children: .ignore)
                .accessibilityLabel("\(day.day.formatted), \(session.t(day.presentationState == .noSpend ? "noSpendMarked" : day.presentationState.rawValue))")
        }
    }
}
struct InfoView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorScheme) private var scheme
    @Environment(LedgerSession.self) private var session
    let toIsland: () -> Void
    let showResult: (TargetStatus) -> Void
    var body: some View {
        @Bindable var session = session
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Button(action: toIsland) { Pill(text: session.t("toIsland"), icon: "chevron.left") }.accessibilityIdentifier("infoIsland")
                Text(session.t("info")).font(V4.heading(session.language))
                IslandScene(growth: session.summary?.days.filter(\.hasGrowth).count ?? 0, festivals: session.summary?.festivals ?? 0, dusk: false).frame(height: 100).accessibilityHidden(true)
                Picker(session.t("envelope"), selection: $session.envelopeID) {
                    Text(session.t("household")).tag(EnvelopeValue.householdID)
                    if let child = session.child() { Text(session.t("child")).tag(child.id) }
                }.pickerStyle(.segmented).frame(minHeight: 44)
                if let s = session.summary { AllowancePlate(title: "weeklyAllowance", status: s.week); AllowancePlate(title: "monthlyAllowance", status: s.month) }
                NavigationLink { GoalsView(envelopeID: session.envelopeID) } label: { Label(session.t("goals"), systemImage: "target").frame(minHeight: 52) }
                categoryTargets
                NavigationLink { TaxView() } label: { Label(session.t("tax"), systemImage: "percent").frame(minHeight: 52) }
                if session.envelopeID != EnvelopeValue.householdID { NavigationLink { ChildDetailView() } label: { Label(session.t("childDetail"), systemImage: "leaf").frame(minHeight: 52) } }
                NavigationLink { ChildSetupView() } label: { Label(session.t("childSetup"), systemImage: "person.2").frame(minHeight: 52) }
                Text(session.t("recentEntries")).font(V4.heading(session.language, size: 24))
                if let core = session.core {
                    ForEach(LedgerQueries.entries(in: core.state, filter: LedgerEntryFilter(envelopeID: session.envelopeID, limit: 30))) { entry in
                        NavigationLink { EntryEditor(entry: entry) } label: {
                            Plate { Row { VStack(alignment: .leading, spacing: 8) { Text(entry.title.isEmpty ? session.t(entry.kind.rawValue) : entry.title); Text(entry.day.formatted).font(.footnote); Text(session.money(entry.amount, code: entry.currencyCode)).font(.system(.title3, design: .rounded).monospacedDigit()); if entry.needsReview { Label(session.t("needsReview"), systemImage: "exclamationmark.triangle") } } } }
                        }
                    }
                }
            }.padding(16).padding(.bottom, 32)
        }.background(V4.paper(scheme)).onChange(of: session.envelopeID) { session.refresh() }.accessibilityIdentifier("infoPage")
    }
    @ViewBuilder private var categoryTargets: some View {
        if let core = session.core, let period = session.summary?.month.period {
            Plate {
                VStack(alignment: .leading, spacing: 16) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: typeSize.isAccessibilitySize ? 1 : 3), spacing: 16) {
                        ForEach(core.state.categories.filter { $0.envelopeID == session.envelopeID && $0.kind == .expense && !$0.isArchived }) { category in
                            if let status = try? LedgerQueries.targetStatus(in: core.state, period: period, envelopeID: session.envelopeID, categoryID: category.id, currencyCode: session.currency) {
                                VStack(spacing: 8) {
                                    ZStack(alignment: .bottom) {
                                        RoundedRectangle(cornerRadius: 8).stroke(V4.line(scheme), lineWidth: 1.5)
                                        RoundedRectangle(cornerRadius: 7).fill(status.isOver ? V4.over(scheme) : V4.ok(scheme)).frame(height: 52 * status.displayFill)
                                    }.frame(width: 32, height: 52).overlay(alignment: .top) { Capsule().fill(V4.line(scheme)).frame(width: 22, height: 3).offset(y: -3) }.accessibilityHidden(true)
                                    Text(session.categoryName(category)).font(V4.heading(session.language, size: 17)).multilineTextAlignment(.center)
                                    Text(session.money(status.spent)).font(.system(.callout, design: .rounded).weight(.bold).monospacedDigit())
                                    Text(status.allowance.map { session.money($0) } ?? session.t("targetUnset")).font(.footnote)
                                    Label(session.t(status.isSet ? status.isOver ? "over" : "within" : "unset"), systemImage: status.isOver ? "moon.fill" : "sun.max.fill").font(.footnote)
                                }.frame(maxWidth: .infinity).padding(.vertical, 12).background(V4.sunken(scheme), in: .rect(cornerRadius: 16)).accessibilityElement(children: .combine)
                            }
                        }
                    }
                    Text(session.t("notBalance")).font(.footnote)
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
            Text(session.t(isMonth ? "monthResultTitle" : "weekResultTitle")).font(V4.heading(session.language))
            if isMonth {
                Text(session.t(monthHeadlineKey)).font(V4.heading(session.language, size: 26)).multilineTextAlignment(.center).foregroundStyle(V4.ink(scheme))
            }
            Sticker(icon: outcome == .achieved ? (isMonth ? "leaf.fill" : "sparkles") : "moon.fill", label: session.t(isMonth ? monthStickerKey : outcome.rawValue))
            if isMonth, let loggedRequirement {
                Plate {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(String(format: session.t("monthRequirement"), status.loggedDays, loggedRequirement.total, loggedRequirement.required))
                            .foregroundStyle(V4.ink(scheme))
                        Text(String(format: session.t("monthAreaReward"), monthAreas)).font(.headline).foregroundStyle(V4.ink(scheme))
                        if outcome == .achieved {
                            Label(session.t("monthDecorationReward"), systemImage: "sparkles").foregroundStyle(V4.ink2(scheme))
                        }
                        Text("\(status.period.start.formatted) – \(status.period.end.formatted)").font(.footnote).foregroundStyle(V4.ink2(scheme))
                        Text(session.t("lateDetail")).font(.footnote).foregroundStyle(V4.ink2(scheme)).accessibilityIdentifier("resultLateDetail")
                    }
                }
            } else {
                Plate {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(status.period.start.formatted) – \(status.period.end.formatted)").font(.footnote).foregroundStyle(V4.ink2(scheme))
                        Text(session.t("lateDetail")).foregroundStyle(V4.ink2(scheme)).accessibilityIdentifier("resultLateDetail")
                    }
                }
            }
            IslandScene(growth: resultGrowth, festivals: isMonth ? monthAreas : status.isRewardEligible ? 1 : 0, dusk: status.isOver).frame(height: 180).accessibilityHidden(true)
            AllowancePlate(title: "remainingAllowance", status: status)
            Button(session.t("done")) { dismiss() }.buttonStyle(PrimaryButton())
        }.padding(24) }.scrollEdgeEffectHidden(for: .bottom).background(V4.paper(scheme)).presentationCornerRadius(36).accessibilityIdentifier("resultSheet")
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
