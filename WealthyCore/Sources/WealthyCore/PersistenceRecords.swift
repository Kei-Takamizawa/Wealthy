import Foundation
import SwiftData

struct PersistenceWrites: Equatable {
    var inserts = 0
    var updates = 0
    var deletes = 0
    var saves = 0
}

struct RecordOrders {
    var envelopes: [UUID: Int] = [:]
    var categories: [UUID: Int] = [:]
    var entries: [UUID: Int] = [:]
    var receipts: [UUID: Int] = [:]
    var rules: [UUID: Int] = [:]
    var targets: [UUID: Int] = [:]
    var noSpendMarks: [UUID: Int] = [:]
    var settings: [UUID: Int] = [:]
    var pointCards: [UUID: Int] = [:]
}

protocol LedgerRecord: PersistentModel {
    associatedtype Value: Identifiable & Equatable where Value.ID == UUID
    var recordOrder: Int { get set }
    init(_ value: Value, order: Int)
    func update(_ value: Value)
    func value() throws -> Value
    static func fetch(_ id: UUID, in context: ModelContext) throws -> Self?
}

extension WealthySchemaV1.Envelope: LedgerRecord {
    typealias Value = EnvelopeValue
    func update(_ value: EnvelopeValue) {
            id = value.id
            kindRaw = value.kind.rawValue
            name = value.name
            isArchived = value.isArchived
            createdAt = value.createdAt
    }
    static func fetch(_ id: UUID, in context: ModelContext) throws -> WealthySchemaV1.Envelope? {
        var descriptor = FetchDescriptor<WealthySchemaV1.Envelope>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

extension WealthySchemaV1.Category: LedgerRecord {
    typealias Value = CategoryValue
    func update(_ value: CategoryValue) {
            id = value.id
            kindRaw = value.kind.rawValue
            envelopeID = value.envelopeID
            taxHintRaw = value.taxHint.rawValue
            systemKey = value.systemKey
            customName = value.customName
            iconKey = value.iconKey
            colorKey = value.colorKey
            sortOrder = value.sortOrder
            isArchived = value.isArchived
    }
    static func fetch(_ id: UUID, in context: ModelContext) throws -> WealthySchemaV1.Category? {
        var descriptor = FetchDescriptor<WealthySchemaV1.Category>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

extension WealthySchemaV1.LedgerEntry: LedgerRecord {
    typealias Value = EntryValue
    func update(_ value: EntryValue) {
            id = value.id
            kindRaw = value.kind.rawValue
            amount = value.amount
            currencyCode = value.currencyCode
            day = value.day
            timestamp = value.timestamp
            envelopeID = value.envelopeID
            categoryID = value.categoryID
            title = value.title
            note = value.note
            sourceRaw = value.source.rawValue
            reviewFlagsRaw = value.reviewFlags.map(\.rawValue).sorted()
            receiptID = value.receiptID
            recurringRuleID = value.recurringRuleID
            occurrenceDay = value.occurrenceDay
            createdAt = value.createdAt
            updatedAt = value.updatedAt
            taxRateRaw = value.taxRate?.rawValue
            serviceModeRaw = value.serviceMode?.rawValue
            isFixedCost = value.isFixedCost
    }
    static func fetch(_ id: UUID, in context: ModelContext) throws -> WealthySchemaV1.LedgerEntry? {
        var descriptor = FetchDescriptor<WealthySchemaV1.LedgerEntry>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

extension WealthySchemaV1.ReceiptAttachment: LedgerRecord {
    typealias Value = ReceiptValue
    func update(_ value: ReceiptValue) {
            id = value.id
            fileName = value.fileName
            capturedAt = value.capturedAt
            imageSHA256 = value.imageSHA256
    }
    static func fetch(_ id: UUID, in context: ModelContext) throws -> WealthySchemaV1.ReceiptAttachment? {
        var descriptor = FetchDescriptor<WealthySchemaV1.ReceiptAttachment>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

extension WealthySchemaV1.RecurringRule: LedgerRecord {
    typealias Value = RuleValue
    func update(_ value: RuleValue) {
            id = value.id
            title = value.title
            kindRaw = value.kind.rawValue
            amount = value.amount
            currencyCode = value.currencyCode
            envelopeID = value.envelopeID
            categoryID = value.categoryID
            schedule = value.schedule
            startDay = value.startDay
            endDay = value.endDay
            isPaused = value.isPaused
            lastPostedDay = value.lastPostedDay
            lastProcessedDay = value.lastProcessedDay
            pauseStartedDay = value.pauseStartedDay
            pausedPeriods = value.pausedPeriods
            createdAt = value.createdAt
            taxRateRaw = value.taxRate?.rawValue
            serviceModeRaw = value.serviceMode?.rawValue
            isFixedCost = value.isFixedCost
    }
    static func fetch(_ id: UUID, in context: ModelContext) throws -> WealthySchemaV1.RecurringRule? {
        var descriptor = FetchDescriptor<WealthySchemaV1.RecurringRule>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

extension WealthySchemaV1.Target: LedgerRecord {
    typealias Value = TargetValue
    func update(_ value: TargetValue) {
            id = value.id
            envelopeID = value.envelopeID
            categoryID = value.categoryID
            currencyCode = value.currencyCode
            amountMinor = value.amountMinor
            effectiveMonth = value.effectiveMonth
    }
    static func fetch(_ id: UUID, in context: ModelContext) throws -> WealthySchemaV1.Target? {
        var descriptor = FetchDescriptor<WealthySchemaV1.Target>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

extension WealthySchemaV1.NoSpendMark: LedgerRecord {
    typealias Value = NoSpendMarkValue
    func update(_ value: NoSpendMarkValue) {
            id = value.id
            envelopeID = value.envelopeID
            day = value.day
    }
    static func fetch(_ id: UUID, in context: ModelContext) throws -> WealthySchemaV1.NoSpendMark? {
        var descriptor = FetchDescriptor<WealthySchemaV1.NoSpendMark>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

extension WealthySchemaV1.Settings: LedgerRecord {
    typealias Value = LedgerSettings
    func update(_ value: LedgerSettings) {
            id = value.id
            includeFixedCostsInTargets = value.includeFixedCostsInTargets
            weekStart = value.weekStart
    }
    static func fetch(_ id: UUID, in context: ModelContext) throws -> WealthySchemaV1.Settings? {
        var descriptor = FetchDescriptor<WealthySchemaV1.Settings>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

extension WealthySchemaV1.PointCard: LedgerRecord {
    typealias Value = PointCardValue
    func update(_ value: PointCardValue) {
            id = value.id
            name = value.name
            memberNumber = value.memberNumber
            points = value.points
            expiryDay = value.expiryDay
            colorKey = value.colorKey
            sortOrder = value.sortOrder
    }
    static func fetch(_ id: UUID, in context: ModelContext) throws -> WealthySchemaV1.PointCard? {
        var descriptor = FetchDescriptor<WealthySchemaV1.PointCard>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
