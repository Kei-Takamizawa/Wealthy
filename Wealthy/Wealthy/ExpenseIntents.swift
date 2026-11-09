import AppIntents
import Foundation
import WealthyCore

nonisolated struct ExpenseCategoryEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "category" }
    static var defaultQuery: ExpenseCategoryQuery { ExpenseCategoryQuery() }
    let id: UUID
    let name: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: LocalizedStringResource(stringLiteral: name)) }
}

nonisolated struct ExpenseCategoryQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [ExpenseCategoryEntity] {
        try await suggestedEntities().filter { identifiers.contains($0.id) }
    }
    @MainActor
    func suggestedEntities() async throws -> [ExpenseCategoryEntity] {
        let session = LedgerSession.shared
        session.open()
        guard session.core != nil else { throw ExpenseIntentError(message: session.t("storeError")) }
        return session.expenseCategories.map { ExpenseCategoryEntity(id: $0.id, name: session.categoryName($0)) }
    }
}

nonisolated struct ExpenseIntentError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

struct RecordExpenseIntent: AppIntent {
    nonisolated static var title: LocalizedStringResource { "recordExpense" }
    nonisolated static var description: IntentDescription { IntentDescription("recordExpenseDescription") }
    nonisolated static var openAppWhenRun: Bool { false }
    @Parameter(title: "amount", description: "intentAmountDescription") var amount: String
    @Parameter(title: "category") var category: ExpenseCategoryEntity?
    nonisolated static var parameterSummary: some ParameterSummary { Summary("Record expense \(\.$amount)") { \.$category } }

    nonisolated init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let session = LedgerSession.shared
        session.open()
        do {
            // A text parameter preserves exact currency input; this SDK has no Decimal IntentValue.
            let minor = try session.parse(amount)
            let entry = try session.recordExpense(amount: minor, categoryID: category?.id)
            var text = String(format: session.t("recordedExpense"), session.money(entry.amount), session.entryCategoryName(entry))
            if let remaining = session.householdSummary?.week.remaining { text += " " + String(format: session.t("intentWeekRemaining"), session.money(remaining)) }
            return .result(value: text, dialog: IntentDialog(stringLiteral: text))
        } catch { throw ExpenseIntentError(message: session.message(error)) }
    }
}

nonisolated struct OpenQuickAddIntent: AppIntent {
    nonisolated static var title: LocalizedStringResource { "quickAdd" }
    nonisolated static var description: IntentDescription { IntentDescription("quickAddDescription") }
    nonisolated static var openAppWhenRun: Bool { true }
    @MainActor
    func perform() async throws -> some IntentResult {
        let session = LedgerSession.shared
        if session.onboarded { session.selectedTab = 1; session.showQuickAdd = true }
        return .result()
    }
}

nonisolated struct WealthyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: RecordExpenseIntent(), phrases: ["Record an expense in \(.applicationName)"], shortTitle: "recordExpense", systemImageName: "plus.circle")
        AppShortcut(intent: OpenQuickAddIntent(), phrases: ["Quick add in \(.applicationName)"], shortTitle: "quickAdd", systemImageName: "square.and.pencil")
    }
}
