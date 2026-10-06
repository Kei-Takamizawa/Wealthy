import SwiftUI
import WealthyCore

struct GoalsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(LedgerSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    let envelopeID: UUID
    @State private var amounts: [String: String] = [:]
    @State private var includeFixed = false
    @State private var weekStart = 2
    @State private var monthDate = Date()
    var month: LedgerMonth { LedgerMonth(day: try! LedgerDay(date: monthDate, calendar: .current)) }
    var categories: [CategoryValue] { session.core?.state.categories.filter { $0.envelopeID == envelopeID && $0.kind == .expense && !$0.isArchived } ?? [] }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(session.t("goals")).font(V4.heading(session.language))
                MonthControl(date: $monthDate)
                Plate { VStack(alignment: .leading, spacing: 12) { Text(session.t("monthlyTarget")); amountField("overall"); Text(session.t("notBalance")).font(.footnote) } }
                Plate { VStack(alignment: .leading, spacing: 16) { ForEach(categories) { category in Text(session.categoryName(category)); amountField(category.id.uuidString) } } }
                Plate { VStack(spacing: 12) { Toggle(session.t("includeFixed"), isOn: $includeFixed).frame(minHeight: 52); Picker(session.t("weekStart"), selection: $weekStart) { ForEach(1...7, id: \.self) { Text(session.locale.calendar.weekdaySymbols[$0 - 1]).tag($0) } }.frame(minHeight: 52) } }
                Text(session.t("targetVersionDetail")).font(.footnote)
                Button(session.t("save")) { session.perform { try save() } }.buttonStyle(PrimaryButton()).accessibilityIdentifier("saveGoals")
            }.padding(16)
        }.background(V4.paper(scheme)).task { load() }.onChange(of: monthDate) { load() }
    }
    func amountField(_ key: String) -> some View { TextField("", text: Binding(get: { amounts[key] ?? "" }, set: { amounts[key] = $0 }), prompt: Text(session.t("targetUnset")).foregroundStyle(V4.ink2(scheme))).accessibilityLabel(key == "overall" ? session.t("monthlyTarget") : categories.first(where: { $0.id.uuidString == key }).map(session.categoryName) ?? session.t("category")).keyboardType(.decimalPad).font(.system(.title2, design: .rounded).monospacedDigit()).frame(minHeight: 52).accessibilityIdentifier(key == "overall" ? "overallTarget" : "categoryTarget-\(key)") }
    func load() {
        guard let core = session.core else { return }
        includeFixed = core.state.settings.includeFixedCostsInTargets; weekStart = core.state.settings.weekStart
        amounts = [:]
        for key in ["overall"] + categories.map({ $0.id.uuidString }) {
            amounts[key] = ""
            if let target = LedgerQueries.effectiveTarget(in: core.state, month: month, envelopeID: envelopeID, categoryID: UUID(uuidString: key), currencyCode: session.currency) { amounts[key] = session.input(target.amountMinor) }
        }
    }
    func save() throws {
        // Parse every field before issuing commands so an invalid field cannot partially save a form.
        let parsed = try amounts.map { key, value -> (String, Int?) in (key, value.trimmingCharacters(in: .whitespaces).isEmpty ? nil : try session.parse(value)) }
        var commands: [LedgerCommand] = []
        for (key, value) in parsed {
            let category = UUID(uuidString: key)
            if let value { commands.append(.setTarget(TargetValue(envelopeID: envelopeID, categoryID: category, currencyCode: session.currency, amountMinor: value, effectiveMonth: month))) }
            else if let target = session.core?.state.targets.first(where: { $0.envelopeID == envelopeID && $0.categoryID == category && $0.currencyCode == session.currency && $0.effectiveMonth == month }) { commands.append(.removeTarget(target.id)) }
        }
        commands.append(.updateSettings(LedgerSettings(includeFixedCostsInTargets: includeFixed, weekStart: weekStart)))
        for command in commands {
            guard let preview = session.core?.preview(command, now: Date()) else { throw CoreError.saveFailed }
            if let error = preview.errors.first { throw error }
        }
        for command in commands { try session.run(command) }
        dismiss()
    }
}
struct TaxView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(LedgerSession.self) private var session
    @State private var monthDate = Date()
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(session.t("tax")).font(V4.heading(session.language))
                MonthControl(date: $monthDate)
                if session.currency != "JPY" { Plate { Text(session.t("taxJPYOnly")) } }
                else if let core = session.core, let day = try? LedgerDay(date: monthDate, calendar: .current), let period = try? LedgerPeriod.month(containing: day), let tax = try? LedgerQueries.taxSummary(in: core.state, period: period, envelopeID: session.envelopeID) {
                    Plate { VStack(alignment: .leading, spacing: 12) { Text(session.t("taxTotal")); Text(session.money(tax.totalTaxPaid)).font(.system(.largeTitle, design: .rounded).monospacedDigit()); Text(session.t("taxDetail")).font(.footnote) } }
                    Plate { VStack(spacing: 16) { ForEach(tax.perRate, id: \.rate) { row in Row { VStack(alignment: .leading) { LabeledContent(session.t(row.rate.rawValue), value: session.money(row.taxPaid)); LabeledContent(session.t("taxableBase"), value: session.money(row.taxableBase)) } } } } }
                    Plate { VStack(alignment: .leading, spacing: 16) {
                        Text(String(format: session.t("unknownTaxCount"), tax.unknownTaxEntryCount))
                        ForEach(LedgerQueries.entries(in: core.state, filter: LedgerEntryFilter(period: period, envelopeID: session.envelopeID, kind: .expense, currencyCode: "JPY")).filter { $0.taxRate == nil }) { entry in NavigationLink { EntryEditor(entry: entry) } label: { Text(entry.title.isEmpty ? entry.day.formatted : entry.title).frame(minHeight: 52) } }
                    } }
                    if let estimate = try? LedgerQueries.takeoutSavingEstimate(in: core.state, month: LedgerMonth(day: day), envelopeID: session.envelopeID) {
                        Plate { VStack(alignment: .leading, spacing: 12) { Label(session.t("estimate"), systemImage: "sparkles"); LabeledContent(session.t("takeoutSaving"), value: session.money(estimate.estimatedTaxSaving)); Text(session.t("estimateDetail")).font(.footnote) } }
                    }
                }
            }.padding(16)
        }.background(V4.paper(scheme)).accessibilityIdentifier("taxScreen")
    }
}
struct ChildSetupView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(LedgerSession.self) private var session
    @State private var enabled = false
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 20) {
            Text(session.t("childSetup")).font(V4.heading(session.language))
            IslandScene(growth: 0, festivals: 0, dusk: false).frame(height: 150).accessibilityHidden(true)
            Plate { VStack(alignment: .leading) { Toggle(session.t("useChild"), isOn: $enabled).frame(minHeight: 52); Text(session.t("childExplanation")) } }
            if let child = session.child() {
                ChildCategoryRows(envelopeID: child.id, showsSpending: false)
                NavigationLink { GoalsView(envelopeID: child.id) } label: { Label(session.t("goals"), systemImage: "target").frame(minHeight: 52) }
            }
        }.padding(16) }.background(V4.paper(scheme)).task { enabled = session.child() != nil }.onChange(of: enabled) { _, value in session.perform {
            if value && session.child() == nil { try session.createChild() }
            else if !value, let child = session.child() { try session.run(.archiveEnvelope(child.id, archived: true)); session.envelopeID = EnvelopeValue.householdID; session.refresh() }
        } }
    }
}
struct ChildDetailView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(LedgerSession.self) private var session
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 20) {
            Text(session.t("childDetail")).font(V4.heading(session.language))
            if let child = session.child(), let core = session.core {
                if let s = try? LedgerQueries.islandSummary(in: core.state, today: session.today, envelopeID: child.id, currencyCode: session.currency) { IslandScene(growth: s.days.filter(\.hasGrowth).count, festivals: s.festivals, dusk: s.month.isOver).frame(height: 180).accessibilityHidden(true); AllowancePlate(title: "monthlyAllowance", status: s.month) }
                NavigationLink { GoalsView(envelopeID: child.id) } label: { Label(session.t("goals"), systemImage: "target").frame(minHeight: 52) }
                ChildCategoryRows(envelopeID: child.id, showsSpending: true)
                Text(session.t("childExplanation"))
            }
        }.padding(16) }.background(V4.paper(scheme))
    }
}
struct ChildCategoryRows: View {
    @Environment(LedgerSession.self) private var session
    let envelopeID: UUID
    let showsSpending: Bool
    var body: some View {
        if let core = session.core {
            Plate { VStack(alignment: .leading, spacing: 12) {
                Text(session.t("category")).font(V4.heading(session.language, size: 22))
                ForEach(core.state.categories.filter { $0.envelopeID == envelopeID && $0.kind == .expense && !$0.isArchived }) { category in
                    let status = try? LedgerQueries.monthTargetStatus(in: core.state, month: LedgerMonth(day: session.today), envelopeID: envelopeID, categoryID: category.id, currencyCode: session.currency)
                    NavigationLink { GoalsView(envelopeID: envelopeID) } label: {
                        Row { VStack(alignment: .leading, spacing: 6) {
                            Text(session.categoryName(category)).foregroundStyle(.primary)
                            if showsSpending, let status { Text(session.money(status.spent)).font(.system(.title3, design: .rounded).monospacedDigit()) }
                            Text(status?.allowance.map { session.money($0) } ?? session.t("targetUnset")).font(.footnote)
                        } }
                    }
                    Divider()
                }
                Text(session.t("notBalance")).font(.footnote)
            } }
        }
    }
}
struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(LedgerSession.self) private var session
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 20) {
            Text(session.t("settings")).font(V4.heading(session.language))
            Plate { VStack { LanguagePicker(); CurrencyPicker() } }
            NavigationLink { LicenseView() } label: { Label(session.t("licenses"), systemImage: "doc.text").frame(minHeight: 52) }
            Plate { VStack(alignment: .leading) { Text(session.t("about")); Text("Wealthy").font(.title2); Text(session.t("aboutDetail")) } }
        }.padding(16) }.background(V4.paper(scheme)).onChange(of: session.currency) { session.refresh() }
    }
}
struct LicenseView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(LedgerSession.self) private var session
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 24) { Text(session.t("licenses")).font(V4.heading(session.language)); ForEach(["KleeOne", "PoorStory", "PatrickHand"], id: \.self) { name in Text(name).font(.title2); Text(Bundle.main.url(forResource: name + "-OFL", withExtension: "txt").flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? session.t("licenseError")).font(.body).textSelection(.enabled) } }.padding(16) }.background(V4.paper(scheme)) }
}
