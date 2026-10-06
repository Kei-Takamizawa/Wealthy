import SwiftUI
import WealthyCore

struct EntryEditor: View {
    @Environment(LedgerSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    let entry: EntryValue?
    @State private var amount = ""
    @State private var date = Date()
    @State private var kind = EntryKind.expense
    @State private var envelope = EnvelopeValue.householdID
    @State private var category: UUID?
    @State private var service = ServiceMode.none
    @State private var tax = "unknown"
    @State private var note = ""
    @State private var fixed = false
    @State private var review = false
    @State private var loaded = false
    var categories: [CategoryValue] { session.core?.state.categories.filter { $0.envelopeID == envelope && $0.kind.rawValue == kind.rawValue && (!$0.isArchived || $0.id == category) } ?? [] }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(session.t(entry == nil ? "addEntry" : "editEntry")).font(V4.heading(session.language))
                Picker(session.t("kind"), selection: Binding(get: { kind }, set: { kind = $0; category = nil })) { ForEach(EntryKind.allCases, id: \.self) { Text(session.t($0.rawValue)).tag($0) } }.pickerStyle(.segmented).frame(minHeight: 44)
                Plate { VStack(alignment: .leading, spacing: 16) {
                    Text(session.t("amount"))
                    MoneyInputField(text: $amount, label: session.t("amount"), identifier: "entryAmount",
                                    font: .system(.largeTitle, design: .rounded),
                                    foreground: kind == .expense ? V4.expense(scheme) : V4.ok(scheme))
                    VStack(alignment: .leading, spacing: 8) { Text(session.t("date")); DatePicker("", selection: $date, displayedComponents: .date).labelsHidden().frame(minHeight: 52).accessibilityLabel(session.t("date")).accessibilityIdentifier("entryDate") }
                    Picker(session.t("category"), selection: Binding(get: { category }, set: { category = $0; suggestTax(); if let selected = categories.first(where: { $0.id == category }), LedgerQueries.fixedCostDefault(for: selected) { fixed = true } })) { Text(session.t("none")).tag(nil as UUID?); ForEach(categories) { Text(session.categoryName($0)).tag(Optional($0.id)) } }.frame(minHeight: 52).accessibilityIdentifier("entryCategory")
                    Text(session.t("note"))
                    TextField("", text: $note, axis: .vertical).accessibilityLabel(session.t("note")).lineLimit(3...6).frame(minHeight: 52).accessibilityIdentifier("entryNote")
                } }
                Picker(session.t("envelope"), selection: Binding(get: { envelope }, set: { envelope = $0; category = nil })) { Text(session.t("household")).tag(EnvelopeValue.householdID); if let child = session.child() { Text(session.t("child")).tag(child.id) } }.pickerStyle(.segmented).frame(minHeight: 44)
                if kind == .expense {
                    Plate { VStack(alignment: .leading, spacing: 16) {
                        Picker(session.t("service"), selection: Binding(get: { service }, set: { service = $0; suggestTax() })) { ForEach(ServiceMode.allCases, id: \.self) { Text(session.t($0.rawValue)).tag($0) } }.frame(minHeight: 52).accessibilityIdentifier("entryService")
                        Picker(session.t("taxRate"), selection: $tax) { ForEach(["standard", "reduced", "exempt", "unknown"], id: \.self) { Text(session.t($0)).tag($0) } }.frame(minHeight: 52).accessibilityIdentifier("entryTaxRate")
                        if (entry?.currencyCode ?? session.currency) == "JPY", let value = try? CoreCurrency.parseMinorUnits(amount, currencyCode: "JPY", locale: session.locale), let rate = TaxRate(rawValue: tax), let part = try? TaxMath.taxPart(inclusiveMinor: value, rate: rate) {
                            LabeledContent(session.t("taxPart"), value: session.money(part, code: "JPY"))
                        }
                    } }
                }
                Plate { VStack(alignment: .leading, spacing: 12) { Toggle(session.t("fixedCost"), isOn: $fixed).frame(minHeight: 52); Toggle(session.t("needsReview"), isOn: $review).frame(minHeight: 52) } }
                Button(session.t("save")) { session.perform { try save() } }.buttonStyle(PrimaryButton()).accessibilityIdentifier("saveEntry")
                if let entry { Button(role: .destructive) { session.perform { try session.run(.deleteEntry(entry.id)); dismiss() } } label: { Text(session.t("deleteEntry")) }.frame(minHeight: 52) }
            }.padding(16)
        }.background(V4.paper(scheme)).scrollDismissesKeyboard(.interactively)
            .task { load() }
    }
    func load() {
        guard !loaded else { return }; loaded = true
        envelope = entry?.envelopeID ?? EnvelopeValue.householdID
        guard let entry else { return }
        amount = (try? CoreCurrency.inputText(entry.amount, currencyCode: entry.currencyCode, locale: session.locale)) ?? ""
        date = (try? entry.day.date(calendar: .current)) ?? Date(); kind = entry.kind
        category = entry.categoryID; service = entry.serviceMode ?? .none; tax = entry.taxRate?.rawValue ?? "unknown"
        note = entry.note; fixed = entry.isFixedCost; review = entry.needsReview
    }
    func suggestTax() {
        guard let category = categories.first(where: { $0.id == category }), let day = try? LedgerDay(date: date, calendar: .current) else { return }
        tax = TaxClassifier.suggestedRate(taxHint: category.taxHint, serviceMode: service, day: day)?.rawValue ?? "unknown"
    }
    func save() throws {
        let code = entry?.currencyCode ?? session.currency
        guard let value = try CoreCurrency.parseMinorUnits(amount, currencyCode: code, locale: session.locale) else { throw CoreError.invalidField("amount", nil) }
        let day = try LedgerDay(date: date, calendar: .current)
        if entry == nil {
            guard try LedgerQueries.canAddEntry(on: day, today: session.today, weekStart: session.core?.state.settings.weekStart ?? 2) else { throw CoreError.invalidField("lateEntry", nil) }
        }
        var result = entry ?? EntryValue(kind: kind, amount: value, currencyCode: code, day: day)
        result.kind = kind; result.amount = value; result.day = day; result.envelopeID = envelope; result.categoryID = category
        result.title = categories.first(where: { $0.id == category }).map(session.categoryName) ?? ""
        result.note = note; result.serviceMode = service; result.taxRate = TaxRate(rawValue: tax); result.isFixedCost = fixed
        result.reviewFlags = review ? (entry?.reviewFlags.isEmpty == false ? entry!.reviewFlags : [.amountUncertain]) : []
        result.updatedAt = Date()
        try session.run(entry == nil ? .addEntry(result) : .updateEntry(result)); dismiss()
    }
}
