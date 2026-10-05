import Foundation

public struct TargetImpact: Codable, Sendable, Equatable {
    public var envelopeID: UUID
    public var categoryID: UUID?
    public var currencyCode: String
    public var period: LedgerPeriod
    public var beforeRemaining: Int?
    public var afterRemaining: Int?
}
/// Confirmation data contains values only, never live SwiftData models.
public struct CommandSummary: Codable, Sendable, Equatable {
    public var targets: [TargetImpact]
    public var taxPart: Int?
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
    var allIDs: [UUID] { envelopes.map(\.id) + categories.map(\.id) + entries.map(\.id) + receipts.map(\.id) + rules.map(\.id) + targets.map(\.id) + noSpendMarks.map(\.id) + pointCards.map(\.id) + [settings.id] }
}

/// Changed record identities also feed user-facing confirmation data.
enum StateChanges {
    static func ids<T: Identifiable & Equatable>(_ before: [T], _ after: [T]) -> Set<UUID> where T.ID == UUID {
        let a = Dictionary(uniqueKeysWithValues: before.map { ($0.id, $0) })
        let b = Dictionary(uniqueKeysWithValues: after.map { ($0.id, $0) })
        return Set(a.keys).union(b.keys).filter { a[$0] != b[$0] }
    }
    static func result(before: LedgerState, after: LedgerState, today: LedgerDay, calendar: Calendar) throws -> CommandResult {
        let entries = ids(before.entries, after.entries)
        var impacts: [TargetImpact] = []
        var keys = Set<String>()
        let relevant = (before.entries + after.entries).filter { entries.contains($0.id) && $0.kind == .expense }
        for entry in relevant {
            let periods = [try LedgerPeriod.week(containing: entry.day, weekStart: after.settings.weekStart, calendar: calendar), try LedgerPeriod.month(containing: entry.day, calendar: calendar)]
            let categories: [UUID?] = entry.categoryID.map { [nil, $0] } ?? [nil]
            for category in categories {
                for period in periods {
                    let key = "\(entry.envelopeID):\(category?.uuidString ?? "overall"):\(entry.currencyCode):\(period.start):\(period.end)"
                    guard keys.insert(key).inserted else { continue }
                    let hasTarget = (before.targets + after.targets).contains { $0.envelopeID == entry.envelopeID && $0.categoryID == category && $0.currencyCode == entry.currencyCode }
                    var oldRemaining: Int?, newRemaining: Int?
                    if hasTarget {
                        oldRemaining = try LedgerQueries.targetStatus(in: before, period: period, envelopeID: entry.envelopeID, categoryID: category, currencyCode: entry.currencyCode, calendar: calendar).remaining
                        newRemaining = try LedgerQueries.targetStatus(in: after, period: period, envelopeID: entry.envelopeID, categoryID: category, currencyCode: entry.currencyCode, calendar: calendar).remaining
                    }
                    impacts.append(TargetImpact(envelopeID: entry.envelopeID, categoryID: category, currencyCode: entry.currencyCode, period: period, beforeRemaining: oldRemaining, afterRemaining: newRemaining))
                }
            }
        }
        var affected = entries.union(ids(before.envelopes, after.envelopes)).union(ids(before.targets, after.targets))
        affected.formUnion(ids(before.categories, after.categories)); affected.formUnion(ids(before.receipts, after.receipts))
        affected.formUnion(ids(before.rules, after.rules)); affected.formUnion(ids(before.pointCards, after.pointCards))
        affected.formUnion(ids(before.noSpendMarks, after.noSpendMarks))
        if before.settings != after.settings { affected.insert(after.settings.id) }
        let entry = after.entries.first { entries.contains($0.id) }
        let tax = try entry.flatMap { value in try value.taxRate.map { try TaxMath.taxPart(inclusiveMinor: value.amount, rate: $0) } }
        return CommandResult(affectedIDs: affected.sorted { $0.uuidString < $1.uuidString }, summary: CommandSummary(targets: impacts, taxPart: tax))
    }
}
