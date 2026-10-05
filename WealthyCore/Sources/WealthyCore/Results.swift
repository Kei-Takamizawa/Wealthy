import Foundation

public struct WalletImpact: Codable, Sendable, Equatable {
    public var walletID: UUID
    public var before: Decimal?
    public var after: Decimal?
}
public struct BudgetImpact: Codable, Sendable, Equatable {
    public var budgetID: UUID
    public var year: Int
    public var month: Int
    public var beforeRemaining: Decimal?
    public var afterRemaining: Decimal?
}
/// Confirmation data contains values only, never live SwiftData models.
public struct CommandSummary: Codable, Sendable, Equatable {
    public var wallets: [WalletImpact]
    public var budgets: [BudgetImpact]
}
public struct CommandResult: Codable, Sendable, Equatable {
    public var affectedIDs: [UUID]
    public var summary: CommandSummary
}
public struct CommandPreview: Sendable, Equatable {
    public var errors: [CoreError]
    public var summary: CommandSummary?
    public var isValid: Bool { errors.isEmpty }
}

extension LedgerState {
    var allIDs: [UUID] { wallets.map(\.id) + categories.map(\.id) + entries.map(\.id) + receipts.map(\.id) + rules.map(\.id) + budgets.map(\.id) + pointCards.map(\.id) }
}

/// Snapshot differences are also used to detect whether an undo still applies.
enum StateChanges {
    static func ids<T: Identifiable & Equatable>(_ before: [T], _ after: [T]) -> Set<UUID> where T.ID == UUID {
        let a = Dictionary(uniqueKeysWithValues: before.map { ($0.id, $0) })
        let b = Dictionary(uniqueKeysWithValues: after.map { ($0.id, $0) })
        return Set(a.keys).union(b.keys).filter { a[$0] != b[$0] }
    }
    static func result(before: LedgerState, after: LedgerState, today: LedgerDay, calendar: Calendar) throws -> CommandResult {
        let entries = ids(before.entries, after.entries)
        var wallets = ids(before.wallets, after.wallets)
        for e in before.entries + after.entries where entries.contains(e.id) {
            wallets.insert(e.walletID); if let id = e.counterpartWalletID { wallets.insert(id) }
        }
        let walletSummary = wallets.sorted { $0.uuidString < $1.uuidString }.map { id in
            WalletImpact(walletID: id, before: before.wallets.contains { $0.id == id } ? LedgerMath.balance(id, in: before) : nil,
                         after: after.wallets.contains { $0.id == id } ? LedgerMath.balance(id, in: after) : nil)
        }
        let budgetChanges = ids(before.budgets, after.budgets)
        let months = Set((before.entries + after.entries).filter { entries.contains($0.id) && $0.kind == .expense }.map { "\($0.day.year)-\($0.day.month)" })
        var budgetSummary: [BudgetImpact] = []
        for id in Set(before.budgets.map(\.id)).union(after.budgets.map(\.id)).sorted(by: { $0.uuidString < $1.uuidString }) {
            let old = before.budgets.first { $0.id == id }, new = after.budgets.first { $0.id == id }
            var periods = months
            if budgetChanges.contains(id) { periods.insert("\(today.year)-\(today.month)") }
            for month in periods.sorted() {
                let parts = month.split(separator: "-").compactMap { Int($0) }
                let year = parts[0], month = parts[1]
                let a = try old.map { try remaining($0, year: year, month: month, state: before, calendar: calendar) }
                let b = try new.map { try remaining($0, year: year, month: month, state: after, calendar: calendar) }
                if a != b { budgetSummary.append(BudgetImpact(budgetID: id, year: year, month: month, beforeRemaining: a, afterRemaining: b)) }
            }
        }
        var affected = wallets.union(entries).union(budgetChanges)
        affected.formUnion(ids(before.categories, after.categories)); affected.formUnion(ids(before.receipts, after.receipts))
        affected.formUnion(ids(before.rules, after.rules)); affected.formUnion(ids(before.pointCards, after.pointCards))
        return CommandResult(affectedIDs: affected.sorted { $0.uuidString < $1.uuidString }, summary: CommandSummary(wallets: walletSummary, budgets: budgetSummary))
    }
    static func remaining(_ b: BudgetValue, year: Int, month: Int, state: LedgerState, calendar: Calendar) throws -> Decimal {
        let period = try LedgerPeriod.month(containing: LedgerDay(year: year, month: month, day: 1), calendar: calendar)
        return Decimal(b.monthlyAmount) - LedgerQueries.budgetSpent(b, in: state, period: period)
    }
}
