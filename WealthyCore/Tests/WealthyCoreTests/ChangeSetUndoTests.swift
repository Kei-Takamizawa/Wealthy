import Foundation
import SwiftData
import Testing
@testable import WealthyCore

@Suite("Bounded change-set undo")
@MainActor
struct ChangeSetUndoTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    var day: LedgerDay { try! LedgerDay(year: 2027, month: 1, day: 5) }
    var image: Data { Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==")! }
    func entry(_ envelope: EnvelopeValue) -> EntryValue {
        EntryValue(kind: .expense, amount: 100, currencyCode: "JPY", day: day,
                   envelopeID: envelope.id, timestamp: now, createdAt: now, updatedAt: now)
    }
    func core(envelope: EnvelopeValue, entries: [EntryValue] = []) throws -> LedgerCore {
        let store = try LedgerStore(inMemory: true, seed: false)
        try store.replace(LedgerState(envelopes: [envelope], entries: entries))
        return try LedgerCore(store: store)
    }
    @Test("P5 adding an entry retains only its own record and optional attachment")
    func retainedChangedRecords() throws {
        for attached in [false, true] {
            let envelope = EnvelopeValue(id: EnvelopeValue.householdID, name: "Cash")
            let core = try core(envelope: envelope, entries: [entry(envelope)])
            let before = core.state
            let receipt = attached ? ReceiptInput(metadata: ReceiptValue(fileName: "receipt.png", capturedAt: now), image: image) : nil
            try core.run(.addEntry(entry(envelope), receipt: receipt), now: now)
            #expect(core.latestUndoRecordCount == (attached ? 2 : 1))
            #expect(core.undoRetainedRecordCount == (attached ? 2 : 1))
            try core.undo(now: now)
            #expect(core.state == before && core.undoRetainedRecordCount == 0)
            try CoreValidation.validate(core.state)
        }
    }
    @Test("P5 twenty retained steps contain twenty additions regardless of ledger size")
    func boundedRecordHistory() throws {
        let envelope = EnvelopeValue(id: EnvelopeValue.householdID, name: "Cash")
        let core = try core(envelope: envelope, entries: (0..<1_000).map { _ in entry(envelope) })
        for _ in 0..<21 {
            try core.run(.addEntry(entry(envelope)), now: now)
            try CoreValidation.validate(core.state)
        }
        #expect(core.undoCount == 20 && core.undoRetainedRecordCount == 20)
        #expect(core.latestUndoRecordCount == 1)
        for _ in 0..<20 { try core.undo(now: now) }
        #expect(core.state.entries.count == 1_001 && core.undoRetainedRecordCount == 0)
    }
    @Test("P7 undo rejects an externally changed touched recordOrder")
    func touchedOrderConflict() throws {
        let envelope = EnvelopeValue(id: EnvelopeValue.householdID, name: "Cash")
        let core = try core(envelope: envelope)
        try core.run(.addEntry(entry(envelope)), now: now)
        let context = ModelContext(core.store.container)
        context.autosaveEnabled = false
        let record = try #require(context.fetch(FetchDescriptor<WealthySchemaV1.LedgerEntry>()).first)
        record.recordOrder = 100
        try context.save()
        try core.reload()
        let before = core.state, revision = core.revision
        #expect(throws: CoreError.undoConflict) { try core.undo(now: now) }
        #expect(core.state == before && core.revision == revision && core.undoCount == 1)
    }
    @Test("P7 restoring a deleted row keeps its old order and stable UUID ordering when orders tie")
    func tiedExternalOrder() throws {
        let envelope = EnvelopeValue(id: EnvelopeValue.householdID, name: "Cash")
        let first = entry(envelope), deleted = entry(envelope), external = entry(envelope)
        let core = try core(envelope: envelope, entries: [first, deleted])
        let previousOrder = core.store.orders.entries[deleted.id]
        try core.run(.deleteEntry(deleted.id), now: now)
        let context = ModelContext(core.store.container)
        context.autosaveEnabled = false
        let model = WealthySchemaV1.LedgerEntry(external, order: try #require(previousOrder))
        context.insert(model)
        try context.save()
        let identity = model.persistentModelID
        try core.reload()
        try core.undo(now: now)
        #expect(core.store.orders.entries[deleted.id] == previousOrder)
        #expect(core.state.entries.map(\.id) == [first.id] + [deleted.id, external.id].sorted { $0.uuidString < $1.uuidString })
        #expect(try core.store.read() == core.state)
        let readContext = ModelContext(core.store.container)
        let rows = try readContext.fetch(FetchDescriptor<WealthySchemaV1.LedgerEntry>())
        #expect(rows.first { $0.id == external.id }?.persistentModelID == identity)
        try CoreValidation.validate(core.state)
    }
    @Test("P7 undo checks persisted touched rows even before external changes are reloaded")
    func unseenExternalConflict() throws {
        let envelope = EnvelopeValue(id: EnvelopeValue.householdID, name: "Cash")
        let core = try core(envelope: envelope)
        try core.run(.addEntry(entry(envelope)), now: now)
        let context = ModelContext(core.store.container)
        context.autosaveEnabled = false
        let record = try #require(context.fetch(FetchDescriptor<WealthySchemaV1.LedgerEntry>()).first)
        record.amount = 999
        try context.save()
        let cached = core.state, revision = core.revision, persisted = try core.store.read()
        #expect(throws: CoreError.undoConflict) { try core.undo(now: now) }
        #expect(core.state == cached && core.revision == revision && core.undoCount == 1)
        #expect(try core.store.read() == persisted)
    }

}
