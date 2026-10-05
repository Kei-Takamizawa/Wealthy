import Foundation

public struct TaxRule: Codable, Sendable, Equatable {
    public var effectiveFrom: LedgerDay
    public var standardRate: Int
    public var reducedRate: Int
    public init(effectiveFrom: LedgerDay, standardRate: Int, reducedRate: Int) {
        self.effectiveFrom = effectiveFrom; self.standardRate = standardRate; self.reducedRate = reducedRate
    }
    public func percentage(_ rate: TaxRate) -> Int {
        switch rate { case .standard: standardRate; case .reduced: reducedRate; case .exempt: 0 }
    }
}
public struct TaxRuleBook: Codable, Sendable, Equatable {
    public var rules: [TaxRule]
    public init(rules: [TaxRule] = Self.referenceRules) { self.rules = rules }
    public static let referenceRules = [TaxRule(effectiveFrom: try! LedgerDay(year: 2019, month: 10, day: 1), standardRate: 10, reducedRate: 8)]
    public func rule(on day: LedgerDay) -> TaxRule? {
        rules.filter { $0.effectiveFrom <= day }.max { $0.effectiveFrom < $1.effectiveFrom }
    }
}
public enum TaxMath {
    /// Per-entry floor is an approximation; Japanese invoices round once per invoice and rate.
    /// Quotient/remainder arithmetic avoids multiplying the entire amount by the rate.
    public static func taxPart(inclusiveMinor amount: Int, rate: Int) throws -> Int {
        guard amount >= 0, (0...100).contains(rate) else { throw CoreError.invalidField("taxAmountOrRate", nil) }
        let divisor = 100 + rate
        return (amount / divisor) * rate + ((amount % divisor) * rate) / divisor
    }
    public static func taxPart(inclusiveMinor amount: Int, rate: TaxRate) throws -> Int {
        let rule = TaxRuleBook.referenceRules[0]
        return try taxPart(inclusiveMinor: amount, rate: rule.percentage(rate))
    }
}
public enum TaxClassifier {
    public static func suggestedRate(taxHint: TaxHint, serviceMode: ServiceMode?, day: LedgerDay,
                                     ruleBook: TaxRuleBook = TaxRuleBook()) -> TaxRate? {
        guard ruleBook.rule(on: day) != nil else { return nil }
        if taxHint == .exempt { return .exempt }
        if taxHint == .food && (serviceMode == .takeout || serviceMode == .delivery) { return .reduced }
        return .standard
    }
}
public struct TaxRateTotal: Sendable, Equatable {
    public var rate: TaxRate
    public var taxPaid: Int
    public var taxableBase: Int
}
public struct TaxSummary: Sendable, Equatable {
    public var totalTaxPaid: Int
    public var perRate: [TaxRateTotal]
    public var unknownTaxEntryCount: Int
}
public struct TakeoutSavingEstimate: Sendable, Equatable {
    /// Difference between standard/reduced tax parts of the same inclusive recorded amount.
    public var estimatedTaxSaving: Int
    public var entryCount: Int
}
extension LedgerQueries {
    public static func taxSummary(in state: LedgerState, period: LedgerPeriod, envelopeID: UUID = EnvelopeValue.householdID,
                                  currencyCode: String = "JPY", ruleBook: TaxRuleBook = TaxRuleBook()) throws -> TaxSummary {
        var totals: [TaxRate: (Int, Int)] = [:], unknown = 0
        for e in state.entries where e.envelopeID == envelopeID && e.currencyCode == currencyCode && e.kind == .expense && period.contains(e.day) {
            guard currencyCode == "JPY", let rate = e.taxRate, let rule = ruleBook.rule(on: e.day) else { unknown += 1; continue }
            let tax = try TaxMath.taxPart(inclusiveMinor: e.amount, rate: rule.percentage(rate))
            let old = totals[rate] ?? (0, 0)
            totals[rate] = (try checkedSum(old.0, tax), try checkedSum(old.1, e.amount - tax))
        }
        let rows = TaxRate.allCases.map { TaxRateTotal(rate: $0, taxPaid: totals[$0]?.0 ?? 0, taxableBase: totals[$0]?.1 ?? 0) }
        return TaxSummary(totalTaxPaid: try rows.reduce(0) { try checkedSum($0, $1.taxPaid) }, perRate: rows, unknownTaxEntryCount: unknown)
    }
    public static func takeoutSavingEstimate(in state: LedgerState, month: LedgerMonth,
                                            envelopeID: UUID = EnvelopeValue.householdID, ruleBook: TaxRuleBook = TaxRuleBook()) throws -> TakeoutSavingEstimate {
        var total = 0, count = 0
        let hints = Dictionary(uniqueKeysWithValues: state.categories.map { ($0.id, $0.taxHint) })
        for e in state.entries where e.envelopeID == envelopeID && e.currencyCode == "JPY" && e.kind == .expense && e.day.year == month.year && e.day.month == month.month && e.serviceMode == .dineIn {
            guard let category = e.categoryID, hints[category] == .food, let rule = ruleBook.rule(on: e.day), e.taxRate != nil else { continue }
            let difference = try TaxMath.taxPart(inclusiveMinor: e.amount, rate: rule.standardRate) - TaxMath.taxPart(inclusiveMinor: e.amount, rate: rule.reducedRate)
            total = try checkedSum(total, difference); count += 1
        }
        return TakeoutSavingEstimate(estimatedTaxSaving: total, entryCount: count)
    }
}
func checkedSum(_ a: Int, _ b: Int) throws -> Int {
    let (value, overflow) = a.addingReportingOverflow(b)
    guard !overflow else { throw CoreError.invalidField("aggregateOverflow", nil) }; return value
}
