import Foundation

public enum MissingField: String, Codable, Sendable { case amountMinor, currency, categoryID, envelopeID, day, serviceMode }
public struct EntryDraft: Codable, Sendable, Equatable {
    public var amountMinor: Int?
    public var currency: String?
    public var categoryID: UUID?
    public var envelopeID: UUID?
    public var day: LedgerDay?
    public var note: String?
    public var serviceMode: ServiceMode?
    public var proposedTaxRate: TaxRate?
    public var confidence: [String: Double]?
    public init(amountMinor: Int? = nil, currency: String? = nil, categoryID: UUID? = nil, envelopeID: UUID? = nil,
                day: LedgerDay? = nil, note: String? = nil, serviceMode: ServiceMode? = nil,
                proposedTaxRate: TaxRate? = nil, confidence: [String: Double]? = nil) {
        self.amountMinor = amountMinor; self.currency = currency; self.categoryID = categoryID; self.envelopeID = envelopeID
        self.day = day; self.note = note; self.serviceMode = serviceMode; self.proposedTaxRate = proposedTaxRate; self.confidence = confidence
    }
}
public struct ResolvedDraft: Sendable, Equatable {
    public var entry: EntryValue
    public var preview: CommandPreview
    public var taxRateDisagreement: Bool
}
public enum DraftResolution: Sendable, Equatable { case ready(ResolvedDraft), needsInput([MissingField]) }
@MainActor
public enum DraftResolver {
    /// Missing envelope defaults to household; missing day uses the caller's current civil day.
    /// Currency and amount are required rather than guessed from natural-language confidence.
    public static func resolve(_ draft: EntryDraft, core: LedgerCore, today: LedgerDay, now: Date = Date()) throws -> DraftResolution {
        var missing: [MissingField] = []
        if draft.amountMinor == nil || draft.amountMinor! <= 0 { missing.append(.amountMinor) }
        if draft.currency == nil || (try? CoreCurrency.normalizedCode(draft.currency!)) == nil { missing.append(.currency) }
        let envelope = draft.envelopeID ?? EnvelopeValue.householdID
        if !core.state.envelopes.contains(where: { $0.id == envelope && !$0.isArchived }) { missing.append(.envelopeID) }
        let category = draft.categoryID.flatMap { id in core.state.categories.first { $0.id == id && $0.envelopeID == envelope && !$0.isArchived && $0.kind == .expense } }
        if draft.categoryID != nil && category == nil { missing.append(.categoryID) }
        let day = draft.day ?? today
        if (try? day.validated()) == nil { missing.append(.day) }
        guard missing.isEmpty else { return .needsInput(missing) }
        let currency = try CoreCurrency.normalizedCode(draft.currency!)
        let tax = currency == "JPY" ? TaxClassifier.suggestedRate(taxHint: category?.taxHint ?? .nonfood, serviceMode: draft.serviceMode, day: day) : nil
        let disagreement = draft.proposedTaxRate != nil && draft.proposedTaxRate != tax
        let entry = EntryValue(kind: .expense, amount: draft.amountMinor!, currencyCode: currency, day: day,
                               envelopeID: envelope, timestamp: now, taxRate: tax, serviceMode: draft.serviceMode,
                               categoryID: category?.id, note: draft.note ?? "", source: .voice, createdAt: now, updatedAt: now)
        let preview = core.preview(.addEntry(entry), now: now)
        if !preview.isValid { return .needsInput([.amountMinor]) }
        return .ready(ResolvedDraft(entry: entry, preview: preview, taxRateDisagreement: disagreement))
    }
}
