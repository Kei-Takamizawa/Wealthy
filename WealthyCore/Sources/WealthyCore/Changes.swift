import Foundation

/// A history item retains only values touched by one operation and their persisted order.
struct RecordChange<Value: Identifiable & Equatable> where Value.ID == UUID {
    var id: UUID
    var before: Value?
    var after: Value?
    var beforeOrder: Int?
    var afterOrder: Int?
}

struct LedgerChanges {
    var wallets: [RecordChange<WalletValue>] = []
    var categories: [RecordChange<CategoryValue>] = []
    var entries: [RecordChange<EntryValue>] = []
    var receipts: [RecordChange<ReceiptValue>] = []
    var rules: [RecordChange<RuleValue>] = []
    var budgets: [RecordChange<BudgetValue>] = []
    var pointCards: [RecordChange<PointCardValue>] = []

    var isEmpty: Bool { wallets.isEmpty && categories.isEmpty && entries.isEmpty && receipts.isEmpty && rules.isEmpty && budgets.isEmpty && pointCards.isEmpty }
    var recordCount: Int { wallets.count + categories.count + entries.count + receipts.count + rules.count + budgets.count + pointCards.count }

    static func records<Value: Identifiable & Equatable>(_ before: [Value], _ after: [Value],
        orders: [UUID: Int], restoring: [RecordChange<Value>]) -> [RecordChange<Value>] where Value.ID == UUID {
        let old = Dictionary(uniqueKeysWithValues: before.map { ($0.id, $0) })
        let new = Dictionary(uniqueKeysWithValues: after.map { ($0.id, $0) })
        let restoredOrders = Dictionary(uniqueKeysWithValues: restoring.compactMap { change in
            change.beforeOrder.map { (change.id, $0) }
        })
        var nextOrder = (orders.values.max() ?? -1) + 1
        var changes: [RecordChange<Value>] = []
        for item in before where new[item.id] == nil {
            changes.append(RecordChange(id: item.id, before: item, after: nil, beforeOrder: orders[item.id], afterOrder: nil))
        }
        for item in after where old[item.id] != item {
            let order: Int
            if let existing = orders[item.id] { order = existing }
            else if let restored = restoredOrders[item.id] { order = restored }
            else { order = nextOrder; nextOrder += 1 }
            changes.append(RecordChange(id: item.id, before: old[item.id], after: item,
                beforeOrder: orders[item.id], afterOrder: order))
        }
        return changes
    }

    init(before: LedgerState, after: LedgerState, orders: RecordOrders, restoring: LedgerChanges? = nil) {
        wallets = Self.records(before.wallets, after.wallets, orders: orders.wallets, restoring: restoring?.wallets ?? [])
        categories = Self.records(before.categories, after.categories, orders: orders.categories, restoring: restoring?.categories ?? [])
        entries = Self.records(before.entries, after.entries, orders: orders.entries, restoring: restoring?.entries ?? [])
        receipts = Self.records(before.receipts, after.receipts, orders: orders.receipts, restoring: restoring?.receipts ?? [])
        rules = Self.records(before.rules, after.rules, orders: orders.rules, restoring: restoring?.rules ?? [])
        budgets = Self.records(before.budgets, after.budgets, orders: orders.budgets, restoring: restoring?.budgets ?? [])
        pointCards = Self.records(before.pointCards, after.pointCards, orders: orders.pointCards, restoring: restoring?.pointCards ?? [])
    }

    static func inverse<Value: Identifiable & Equatable>(_ changes: [RecordChange<Value>],
        current: [Value], orders: [UUID: Int]) throws -> [Value] where Value.ID == UUID {
        let values = Dictionary(uniqueKeysWithValues: current.map { ($0.id, $0) })
        for change in changes {
            guard values[change.id] == change.after, orders[change.id] == change.afterOrder else {
                throw CoreError.undoConflict
            }
        }
        let ids = Set(changes.map(\.id))
        var restored = current.filter { !ids.contains($0.id) }
        var previousOrders = orders
        for change in changes {
            if let value = change.before { restored.append(value); previousOrders[change.id] = change.beforeOrder }
            else { previousOrders.removeValue(forKey: change.id) }
        }
        return restored.sorted {
            let first = previousOrders[$0.id] ?? Int.max, second = previousOrders[$1.id] ?? Int.max
            return first == second ? $0.id.uuidString < $1.id.uuidString : first < second
        }
    }

    func inverse(current: LedgerState, orders: RecordOrders) throws -> LedgerState {
        try LedgerState(
            wallets: Self.inverse(wallets, current: current.wallets, orders: orders.wallets),
            categories: Self.inverse(categories, current: current.categories, orders: orders.categories),
            entries: Self.inverse(entries, current: current.entries, orders: orders.entries),
            receipts: Self.inverse(receipts, current: current.receipts, orders: orders.receipts),
            rules: Self.inverse(rules, current: current.rules, orders: orders.rules),
            budgets: Self.inverse(budgets, current: current.budgets, orders: orders.budgets),
            pointCards: Self.inverse(pointCards, current: current.pointCards, orders: orders.pointCards)
        )
    }
}
