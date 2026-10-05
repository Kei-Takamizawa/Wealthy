import Foundation
import SwiftData

/// Successful record writes, exposed internally for persistence regression tests.
struct PersistenceWrites: Equatable {
    var inserts = 0
    var updates = 0
    var deletes = 0
    var saves = 0
}

struct RecordOrders {
    var wallets: [UUID: Int] = [:]
    var categories: [UUID: Int] = [:]
    var entries: [UUID: Int] = [:]
    var receipts: [UUID: Int] = [:]
    var rules: [UUID: Int] = [:]
    var budgets: [UUID: Int] = [:]
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

extension WealthySchemaV1.Wallet: LedgerRecord {
    typealias Value = WalletValue
    func update(_ value: WalletValue) {
            id = value.id
            name = value.name
            kindRaw = value.kind.rawValue
            currencyCode = value.currencyCode
            paymentMethodKey = value.paymentMethodKey
            colorKey = value.colorKey
            iconKey = value.iconKey
            sortOrder = value.sortOrder
            isArchived = value.isArchived
            createdAt = value.createdAt
            isProvisional = value.isProvisional
    }
    static func fetch(_ id: UUID, in context: ModelContext) throws -> WealthySchemaV1.Wallet? {
        var descriptor = FetchDescriptor<WealthySchemaV1.Wallet>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

extension WealthySchemaV1.Category: LedgerRecord {
    typealias Value = CategoryValue
    func update(_ value: CategoryValue) {
            id = value.id
            kindRaw = value.kind.rawValue
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
            directionRaw = value.direction?.rawValue
            currencyCode = value.currencyCode
            day = value.day
            timestamp = value.timestamp
            walletID = value.walletID
            counterpartWalletID = value.counterpartWalletID
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
            walletID = value.walletID
            counterpartWalletID = value.counterpartWalletID
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
    }
    static func fetch(_ id: UUID, in context: ModelContext) throws -> WealthySchemaV1.RecurringRule? {
        var descriptor = FetchDescriptor<WealthySchemaV1.RecurringRule>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

extension WealthySchemaV1.Budget: LedgerRecord {
    typealias Value = BudgetValue
    func update(_ value: BudgetValue) {
            id = value.id
            currencyCode = value.currencyCode
            categoryID = value.categoryID
            monthlyAmount = value.monthlyAmount
    }
    static func fetch(_ id: UUID, in context: ModelContext) throws -> WealthySchemaV1.Budget? {
        var descriptor = FetchDescriptor<WealthySchemaV1.Budget>(predicate: #Predicate { $0.id == id })
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
