import SwiftUI
import SwiftData

struct PointCardsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var lm: LanguageManager
    @Query private var cards: [PointCard]
    @State private var showAdd = false
    @State private var editing: PointCard?
    @State private var error: String?
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if cards.isEmpty { Text(lm.text("points.empty")) }
                    ForEach(cards) { card in
                        Button { editing = card } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(card.name)
                                    Spacer()
                                    Text(lm.format("points.unit", card.points.formatted(.number.locale(lm.currentLanguage.locale))))
                                }
                                if !card.memberNumber.isEmpty { Text(card.memberNumber).font(.caption).foregroundStyle(.secondary) }
                                if let expiry = card.expiryDate {
                                    Text(expiry, format: .dateTime.year().month().day().locale(lm.currentLanguage.locale)).font(.caption)
                                }
                            }
                        }
                        .accessibilityIdentifier("points.row.\(card.name)")
                    }
                    .onDelete { indices in
                        indices.forEach { context.delete(cards[$0]) }
                        do { try context.save() }
                        catch { context.rollback(); self.error = error.localizedDescription }
                    }
                } footer: { Text(lm.text("points.manualNote")) }
            }
            .navigationTitle(lm.text("points.title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(lm.t(.close)) { dismiss() } }
                ToolbarItem(placement: .primaryAction) { Button(lm.t(.add)) { showAdd = true }.accessibilityIdentifier("points.add") }
            }
            .sheet(isPresented: $showAdd) { PointCardEditor(card: nil) }
            .sheet(item: $editing) { PointCardEditor(card: $0) }
            .alert(lm.t(.error), isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button(lm.text("ok"), role: .cancel) {}
            } message: { Text(error ?? "") }
        }
        .preferredColorScheme(.dark)
    }
}

private struct PointCardEditor: View {
    let card: PointCard?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var lm: LanguageManager
    @State private var name = ""
    @State private var number = ""
    @State private var points = 0
    @State private var hasExpiry = false
    @State private var expiry = Date()
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                TextField(lm.text("points.name"), text: $name).accessibilityIdentifier("points.name")
                TextField(lm.text("points.memberNumber"), text: $number).accessibilityIdentifier("points.number").textInputAutocapitalization(.never)
                TextField(lm.text("points.balance"), value: $points, format: .number.locale(lm.currentLanguage.locale)).keyboardType(.numberPad).accessibilityIdentifier("points.amount")
                Toggle(lm.text("points.hasExpiry"), isOn: $hasExpiry)
                if hasExpiry { DatePicker(lm.text("points.expiry"), selection: $expiry, displayedComponents: .date) }
            }
            .navigationTitle(lm.text("points.title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(lm.t(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(lm.t(.save)) {
                        let value = card ?? PointCard(name: name)
                        value.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        value.memberNumber = number; value.points = points; value.expiryDate = hasExpiry ? expiry : nil
                        if card == nil { context.insert(value) }
                        do { try context.save(); dismiss() }
                        catch { context.rollback(); self.error = error.localizedDescription }
                    }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || points < 0)
                }
            }
            .onAppear {
                if let card { name = card.name; number = card.memberNumber; points = card.points; hasExpiry = card.expiryDate != nil; expiry = card.expiryDate ?? Date() }
            }
            .alert(lm.t(.error), isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button(lm.text("ok"), role: .cancel) {}
            } message: { Text(error ?? "") }
        }
        .preferredColorScheme(.dark)
    }
}

struct FinancialServicesView: View {
    @EnvironmentObject private var lm: LanguageManager
    var body: some View {
        List {
            Section { Text(lm.text("connections.unavailable")) }
            Section(lm.text("connections.documentation")) {
                Link(ReceiptPaymentPolicy.displayName("sbiShinsei", language: lm.currentLanguage), destination: URL(string: "https://www.sbishinseibank.co.jp/")!)
                Link(ReceiptPaymentPolicy.displayName("docomoSMTB", language: lm.currentLanguage), destination: URL(string: "https://www.netbk.co.jp/contents/")!)
                Link("Moneytree LINK", destination: URL(string: "https://getmoneytree.com/jp/link/about")!)
            }
        }
        .navigationTitle(lm.text("connections.title"))
    }
}
