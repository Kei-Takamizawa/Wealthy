import Foundation
import SwiftData

/// V1 uses UUID references and property defaults, ready for optional future CloudKit sync.
public enum WealthySchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)
    public static var models: [any PersistentModel.Type] {
        [Wallet.self, Category.self, LedgerEntry.self, ReceiptAttachment.self, RecurringRule.self, Budget.self, PointCard.self]
    }

    @Model
    public final class Wallet {
        public var recordOrder: Int = 0
        public var id: UUID = UUID()
        public var name: String = ""
        public var kindRaw: String = "cash"
        public var currencyCode: String = "JPY"
        public var paymentMethodKey: String? = nil
        public var colorKey: String = "default"
        public var iconKey: String = "wallet.pass"
        public var sortOrder: Int = 0
        public var isArchived: Bool = false
        public var createdAt: Date = Date(timeIntervalSince1970: 0)
        public var isProvisional: Bool = false

        public init(_ value: WalletValue, order: Int = 0) {
            recordOrder = order
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

        public func value() throws -> WalletValue {
            guard let kind = WalletKind(rawValue: kindRaw) else { throw CoreError.invalidField("kind", id) }
            return WalletValue(id: id, name: name, currencyCode: currencyCode, kind: kind, paymentMethodKey: paymentMethodKey, colorKey: colorKey, iconKey: iconKey, sortOrder: sortOrder, isArchived: isArchived, createdAt: createdAt, isProvisional: isProvisional)
        }
    }

    @Model
    public final class Category {
        public var recordOrder: Int = 0
        public var id: UUID = UUID()
        public var kindRaw: String = "expense"
        public var systemKey: String? = nil
        public var customName: String? = nil
        public var iconKey: String = "tag"
        public var colorKey: String = "default"
        public var sortOrder: Int = 0
        public var isArchived: Bool = false

        public init(_ value: CategoryValue, order: Int = 0) {
            recordOrder = order
            id = value.id
            kindRaw = value.kind.rawValue
            systemKey = value.systemKey
            customName = value.customName
            iconKey = value.iconKey
            colorKey = value.colorKey
            sortOrder = value.sortOrder
            isArchived = value.isArchived
        }

        public func value() throws -> CategoryValue {
            guard let kind = CategoryKind(rawValue: kindRaw) else { throw CoreError.invalidField("kind", id) }
            return CategoryValue(id: id, kind: kind, systemKey: systemKey, customName: customName, iconKey: iconKey, colorKey: colorKey, sortOrder: sortOrder, isArchived: isArchived)
        }
    }

    @Model
    public final class LedgerEntry {
        public var recordOrder: Int = 0
        public var id: UUID = UUID()
        public var kindRaw: String = "expense"
        public var amount: Int = 0
        public var directionRaw: String? = nil
        public var currencyCode: String = "JPY"
        public var day: LedgerDay = LedgerDay.epoch
        public var timestamp: Date = Date(timeIntervalSince1970: 0)
        public var walletID: UUID = UUID()
        public var counterpartWalletID: UUID? = nil
        public var categoryID: UUID? = nil
        public var title: String = ""
        public var note: String = ""
        public var sourceRaw: String = "manual"
        public var reviewFlagsRaw: [String] = []
        public var receiptID: UUID? = nil
        public var recurringRuleID: UUID? = nil
        public var occurrenceDay: LedgerDay? = nil
        public var createdAt: Date = Date(timeIntervalSince1970: 0)
        public var updatedAt: Date = Date(timeIntervalSince1970: 0)

        public init(_ value: EntryValue, order: Int = 0) {
            recordOrder = order
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

        public func value() throws -> EntryValue {
            guard let kind = EntryKind(rawValue: kindRaw) else { throw CoreError.invalidField("kind", id) }
            let direction = directionRaw.flatMap(AdjustmentDirection.init(rawValue:))
            if directionRaw != nil && direction == nil { throw CoreError.invalidField("direction", id) }
            guard let source = EntrySource(rawValue: sourceRaw) else { throw CoreError.invalidField("source", id) }
            let flags = reviewFlagsRaw.compactMap(ReviewFlag.init(rawValue:))
            guard flags.count == reviewFlagsRaw.count else { throw CoreError.invalidField("reviewFlags", id) }
            return EntryValue(id: id, kind: kind, amount: amount, currencyCode: currencyCode, day: day, walletID: walletID, direction: direction, timestamp: timestamp, counterpartWalletID: counterpartWalletID, categoryID: categoryID, title: title, note: note, source: source, reviewFlags: Set(flags), receiptID: receiptID, recurringRuleID: recurringRuleID, occurrenceDay: occurrenceDay, createdAt: createdAt, updatedAt: updatedAt)
        }
    }

    @Model
    public final class ReceiptAttachment {
        public var recordOrder: Int = 0
        public var id: UUID = UUID()
        public var fileName: String = ""
        public var capturedAt: Date = Date(timeIntervalSince1970: 0)

        public init(_ value: ReceiptValue, order: Int = 0) {
            recordOrder = order
            id = value.id
            fileName = value.fileName
            capturedAt = value.capturedAt
        }

        public func value() throws -> ReceiptValue {
            return ReceiptValue(id: id, fileName: fileName, capturedAt: capturedAt)
        }
    }

    @Model
    public final class RecurringRule {
        public var recordOrder: Int = 0
        public var id: UUID = UUID()
        public var title: String = ""
        public var kindRaw: String = "expense"
        public var amount: Int = 0
        public var currencyCode: String = "JPY"
        public var walletID: UUID = UUID()
        public var counterpartWalletID: UUID? = nil
        public var categoryID: UUID? = nil
        public var schedule: RecurringSchedule = RecurringSchedule.monthly(day: 1)
        public var startDay: LedgerDay = LedgerDay.epoch
        public var endDay: LedgerDay? = nil
        public var isPaused: Bool = false
        public var lastPostedDay: LedgerDay? = nil
        public var lastProcessedDay: LedgerDay? = nil
        public var pauseStartedDay: LedgerDay? = nil
        public var pausedPeriods: [LedgerPeriod] = []
        public var createdAt: Date = Date(timeIntervalSince1970: 0)

        public init(_ value: RuleValue, order: Int = 0) {
            recordOrder = order
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

        public func value() throws -> RuleValue {
            guard let kind = EntryKind(rawValue: kindRaw) else { throw CoreError.invalidField("kind", id) }
            return RuleValue(id: id, title: title, kind: kind, amount: amount, currencyCode: currencyCode, walletID: walletID, counterpartWalletID: counterpartWalletID, categoryID: categoryID, schedule: schedule, startDay: startDay, endDay: endDay, isPaused: isPaused, lastPostedDay: lastPostedDay, lastProcessedDay: lastProcessedDay, pauseStartedDay: pauseStartedDay, pausedPeriods: pausedPeriods, createdAt: createdAt)
        }
    }

    @Model
    public final class Budget {
        public var recordOrder: Int = 0
        public var id: UUID = UUID()
        public var currencyCode: String = "JPY"
        public var categoryID: UUID? = nil
        public var monthlyAmount: Int = 0

        public init(_ value: BudgetValue, order: Int = 0) {
            recordOrder = order
            id = value.id
            currencyCode = value.currencyCode
            categoryID = value.categoryID
            monthlyAmount = value.monthlyAmount
        }

        public func value() throws -> BudgetValue {
            return BudgetValue(id: id, currencyCode: currencyCode, categoryID: categoryID, monthlyAmount: monthlyAmount)
        }
    }

    @Model
    public final class PointCard {
        public var recordOrder: Int = 0
        public var id: UUID = UUID()
        public var name: String = ""
        public var memberNumber: String = ""
        public var points: Int = 0
        public var expiryDay: LedgerDay? = nil
        public var colorKey: String = "default"
        public var sortOrder: Int = 0

        public init(_ value: PointCardValue, order: Int = 0) {
            recordOrder = order
            id = value.id
            name = value.name
            memberNumber = value.memberNumber
            points = value.points
            expiryDay = value.expiryDay
            colorKey = value.colorKey
            sortOrder = value.sortOrder
        }

        public func value() throws -> PointCardValue {
            return PointCardValue(id: id, name: name, memberNumber: memberNumber, points: points, expiryDay: expiryDay, colorKey: colorKey, sortOrder: sortOrder)
        }
    }
}

public enum WealthyMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] { [WealthySchemaV1.self] }
    public static var stages: [MigrationStage] { [] }
}
