import Foundation

extension CoreValidation {
    /// Full validation remains the load/restore boundary; mutations validate changed and dependent entries.
    static func validateChanges(before: LedgerState, after: LedgerState) throws {
        var ids = Set<UUID>()
        for id in after.allIDs {
            guard ids.insert(id).inserted else { throw CoreError.duplicateID(id) }
        }
        var metadata = after
        metadata.entries = []
        let changedReceipts = StateChanges.ids(before.receipts, after.receipts)
        metadata.receipts = after.receipts.filter { changedReceipts.contains($0.id) }
        try validate(metadata)
        let changedEntries = StateChanges.ids(before.entries, after.entries)
        let envelopeReferences = Set(before.envelopes.filter { old in
            !after.envelopes.contains { $0.id == old.id }
        }.map(\.id))
        let categoryReferences = Set(before.categories.filter { old in
            !after.categories.contains { $0.id == old.id && $0.kind == old.kind && $0.envelopeID == old.envelopeID }
        }.map(\.id))
        let removedReceipts = Set(before.receipts.map(\.id)).subtracting(after.receipts.map(\.id))
        let removedRules = Set(before.rules.map(\.id)).subtracting(after.rules.map(\.id))
        var occurrences = Set<String>()
        for entry in after.entries {
            if changedEntries.contains(entry.id) || envelopeReferences.contains(entry.envelopeID)
                || entry.categoryID.map(categoryReferences.contains) == true
                || entry.receiptID.map(removedReceipts.contains) == true
                || entry.recurringRuleID.map(removedRules.contains) == true {
                try validateEntry(entry, in: after, active: false)
                try entry.occurrenceDay?.validated()
            }
            if let rule = entry.recurringRuleID, let day = entry.occurrenceDay {
                guard entry.source == .recurring else { throw CoreError.invalidField("source", entry.id) }
                let key = "\(rule)-\(day.year)-\(day.month)-\(day.day)"
                guard occurrences.insert(key).inserted else { throw CoreError.invalidField("duplicateOccurrence", entry.id) }
            }
        }
    }
}
