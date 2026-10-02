import Foundation
import SwiftData

@main
struct CreateLegacyStore {
    @MainActor static func main() throws {
        let schema = Schema([Asset.self, Expense.self, RecurringItem.self, Category.self])
        let configuration = ModelConfiguration(schema: schema, url: URL(fileURLWithPath: CommandLine.arguments[1]))
        let container = try ModelContainer(for: schema, configurations: configuration)
        let context = ModelContext(container)
        context.insert(Asset(name: "Legacy wallet", balance: 4321))
        context.insert(Expense(title: "Legacy expense", amount: 123, date: Date(timeIntervalSince1970: 1700000000), assetName: "Legacy wallet"))
        context.insert(RecurringItem(title: "Legacy monthly", amount: 250, dayOfMonth: 15, isIncome: false, assetName: "Legacy wallet"))
        context.insert(Category(name: "Custom category", icon: "tag", colorHex: "FFFFFF"))
        try context.save()
    }
}
