import Foundation
import SwiftData

@main
struct ValidateMigratedStore {
    @MainActor static func main() throws {
        let schema = Schema([Asset.self, Expense.self, RecurringItem.self, Category.self, PointCard.self])
        let configuration = ModelConfiguration(schema: schema, url: URL(fileURLWithPath: CommandLine.arguments[1]))
        let container = try ModelContainer(for: schema, configurations: configuration)
        let context = ModelContext(container)
        let wallet = try context.fetch(FetchDescriptor<Asset>()).first!
        let expense = try context.fetch(FetchDescriptor<Expense>()).first!
        precondition(wallet.name == "Legacy wallet" && wallet.balance == 4321)
        precondition(wallet.paymentMethod == nil && !wallet.isAutoCreated)
        precondition(expense.title == "Legacy expense" && expense.amount == 123 && expense.assetName == "Legacy wallet")
        precondition(expense.paymentMethod == nil && expense.balanceApplied && !expense.paymentNeedsReview)
        precondition(wallet.currencyCode == nil && wallet.effectiveCurrencyCode == "JPY")
        precondition(expense.currencyCode == nil && expense.effectiveCurrencyCode == "JPY")
        let rules = try context.fetch(FetchDescriptor<RecurringItem>())
        precondition(rules.count == 1 && rules[0].title == "Legacy monthly" && rules[0].amount == 250 && rules[0].dayOfMonth == 15 && rules[0].assetName == "Legacy wallet")
        precondition(rules.allSatisfy { $0.currencyCode == nil && $0.effectiveCurrencyCode == "JPY" })
        let pointCount = try context.fetchCount(FetchDescriptor<PointCard>())
        let category = try context.fetch(FetchDescriptor<Category>()).first
        precondition(pointCount == 0)
        precondition(category?.name == "Custom category")
        context.insert(PointCard(name: "New points", points: 10))
        try context.save()
        let newCount = try context.fetchCount(FetchDescriptor<PointCard>())
        precondition(newCount == 1)
        print("PASS: 11 persisted SwiftData migration checks (Mac store, not an iOS upgrade test).")
    }
}
