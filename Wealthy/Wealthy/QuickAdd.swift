import SwiftUI
import WealthyCore

struct QuickAddSheet: View {
    @Environment(LedgerSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorScheme) private var scheme
    @State private var amount = ""
    @State private var details = false
    @State private var error: String?
    #if DEBUG
    @State private var keyboardTop: CGFloat?
    #endif
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Group {
                if details { EntryEditor(entry: nil, initialAmount: amount, initialDay: session.today) }
                else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(session.t("amount")).font(.headline)
                                #if DEBUG
                                .accessibilityIdentifier("quickAmountLabel")
                                .accessibilityValue(keyboardTop.map { String(Double($0)) } ?? "")
                                #endif
                            MoneyInputField(text: $amount, label: session.t("amount"), identifier: "quickAmount",
                                            font: .system(.largeTitle, design: .rounded), focus: $focused)
                            if let error { Text(error).accessibilityIdentifier("quickError") }
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 12) {
                                ForEach(session.quickCategories) { category in
                                    Button { save(categoryID: category.id) } label: {
                                        Text(session.categoryName(category)).frame(maxWidth: .infinity, minHeight: 44)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }.buttonStyle(.bordered)
                                        .accessibilityIdentifier("quickCategory-" + (category.systemKey ?? category.id.uuidString))
                                }
                            }
                            Button(session.t("moreDetails")) { focused = false; details = true }
                                .frame(minHeight: 44).accessibilityIdentifier("quickDetails")
                        }.padding(16)
                    }
                    .safeAreaInset(edge: .bottom) {
                        Button(session.t("save")) { save(categoryID: nil) }
                            .foregroundStyle(scheme == .dark ? Color.black : Color.white)
                            .buttonStyle(.borderedProminent).frame(maxWidth: .infinity, minHeight: 44)
                            .accessibilityIdentifier("quickSave").padding(16).background(.bar)
                    }
                    .task {
                        // Focus after the sheet transition so UIKit can present its keyboard.
                        try? await Task.sleep(for: .milliseconds(350))
                        guard !Task.isCancelled else { return }
                        focused = true
                    }
                }
            }
            .navigationTitle(session.t(details ? "addEntry" : "quickAdd"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if details { ToolbarItem(placement: .cancellationAction) { Button(session.t("cancel")) { dismiss() } } }
            }
        }
        .tint(V4.primary(scheme))
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        #if DEBUG
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            guard LedgerSession.isUITest, let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            keyboardTop = frame.minY
        }
        #endif
    }

    private func save(categoryID: UUID?) {
        do {
            _ = try session.recordExpense(amount: session.parse(amount), categoryID: categoryID)
            dismiss()
            UIAccessibility.post(notification: .announcement, argument: session.t("entryRecorded"))
        } catch { self.error = session.message(error) }
    }
}

extension LedgerSession {
    var expenseCategories: [CategoryValue] {
        (core?.state.categories ?? []).filter {
            $0.envelopeID == EnvelopeValue.householdID && $0.kind == .expense && !$0.isArchived
        }.sorted { $0.sortOrder == $1.sortOrder ? $0.id.uuidString < $1.id.uuidString : $0.sortOrder < $1.sortOrder }
    }

    var quickCategories: [CategoryValue] {
        guard let core, let first = try? today.adding(days: -29, calendar: .current),
              let period = try? LedgerPeriod(start: first, end: today) else { return [] }
        let entries = LedgerQueries.entries(in: core.state, filter: LedgerEntryFilter(period: period, envelopeID: EnvelopeValue.householdID, kind: .expense))
        let counts = Dictionary(grouping: entries.compactMap(\.categoryID), by: { $0 }).mapValues(\.count)
        let categories = expenseCategories
        var selected = Array(categories.filter { counts[$0.id] != nil }.sorted {
            let left = counts[$0.id, default: 0], right = counts[$1.id, default: 0]
            return left == right ? ($0.sortOrder == $1.sortOrder ? $0.id.uuidString < $1.id.uuidString : $0.sortOrder < $1.sortOrder) : left > right
        }.prefix(4))
        for key in ["catFood", "catDaily", "catOthers"] where selected.count < 4 {
            if let category = categories.first(where: { $0.systemKey == key }), !selected.contains(where: { $0.id == category.id }) { selected.append(category) }
        }
        return selected
    }

    /// The common, undoable command path for Quick add and RecordExpenseIntent.
    @discardableResult
    func recordExpense(amount: Int, categoryID: UUID?) throws -> EntryValue {
        guard let core else { throw CoreError.saveFailed }
        guard try LedgerQueries.canAddEntry(on: today, today: today, weekStart: core.state.settings.weekStart) else { throw CoreError.invalidField("lateEntry", nil) }
        let category = categoryID.flatMap { id in expenseCategories.first { $0.id == id } }
        if let categoryID, category == nil { throw CoreError.archivedCategory(categoryID) }
        let entry = EntryValue(kind: .expense, amount: amount, currencyCode: currency, day: today,
                               categoryID: categoryID, title: category.map(categoryName) ?? "")
        catchUp()
        try run(.addEntry(entry))
        return entry
    }

    func entryCategoryName(_ entry: EntryValue) -> String {
        entry.categoryID.flatMap { id in core?.state.categories.first { $0.id == id }.map(categoryName) } ?? t("uncategorized")
    }

    var safeLineText: String {
        guard let safeLine, let amount = safeLine.safeAmount, !safeLine.scheduled.isEmpty else { return "" }
        return "\(t("safeToSpend")), \(money(amount))\(amount < 0 ? ", " + t("over") : ""), \(String(format: t("afterScheduled"), safeLine.scheduled.count, money(safeLine.scheduledTotal)))"
    }
}
