import Foundation
import SwiftData

/// Unshipped V1 uses defaulted properties and UUID references for optional future sync.
public enum WealthySchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)
    public static var models: [any PersistentModel.Type] { [Envelope.self, Category.self, LedgerEntry.self, ReceiptAttachment.self, RecurringRule.self, Target.self, NoSpendMark.self, Settings.self, PointCard.self] }

    @Model
    public final class Envelope {
        public var recordOrder: Int = 0
        public var id: UUID = UUID()
        public var kindRaw: String = "household"
        public var name: String = ""
        public var isArchived: Bool = false
        public var createdAt: Date = Date(timeIntervalSince1970: 0)

        public init(_ value: EnvelopeValue, order: Int = 0) {
            recordOrder = order
            id = value.id
            kindRaw = value.kind.rawValue
            name = value.name
            isArchived = value.isArchived
            createdAt = value.createdAt
        }
        public func value() throws -> EnvelopeValue {
            guard let kind = EnvelopeKind(rawValue: kindRaw) else { throw CoreError.invalidField("kind", id) }
            return EnvelopeValue(id: id, kind: kind, name: name, isArchived: isArchived, createdAt: createdAt)
        }
    }

    @Model
    public final class Category {
        public var recordOrder: Int = 0
        public var id: UUID = UUID()
        public var kindRaw: String = "expense"
        public var envelopeID: UUID = EnvelopeValue.householdID
        public var taxHintRaw: String = "nonfood"
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
            envelopeID = value.envelopeID
            taxHintRaw = value.taxHint.rawValue
            systemKey = value.systemKey
            customName = value.customName
            iconKey = value.iconKey
            colorKey = value.colorKey
            sortOrder = value.sortOrder
            isArchived = value.isArchived
        }
        public func value() throws -> CategoryValue {
            guard let kind = CategoryKind(rawValue: kindRaw) else { throw CoreError.invalidField("kind", id) }
            guard let taxHint = TaxHint(rawValue: taxHintRaw) else { throw CoreError.invalidField("taxHint", id) }
            return CategoryValue(id: id, kind: kind, envelopeID: envelopeID, taxHint: taxHint, systemKey: systemKey, customName: customName, iconKey: iconKey, colorKey: colorKey, sortOrder: sortOrder, isArchived: isArchived)
        }
    }

    @Model
    public final class LedgerEntry {
        public var recordOrder: Int = 0
        public var id: UUID = UUID()
        public var kindRaw: String = "expense"
        public var amount: Int = 0
        public var currencyCode: String = "JPY"
        public var day: LedgerDay = LedgerDay.epoch
        public var timestamp: Date = Date(timeIntervalSince1970: 0)
        public var envelopeID: UUID = EnvelopeValue.householdID
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
        public var taxRateRaw: String? = nil
        public var serviceModeRaw: String? = nil
        public var isFixedCost: Bool = false

        public init(_ value: EntryValue, order: Int = 0) {
            recordOrder = order
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
        public func value() throws -> EntryValue {
            guard let kind = EntryKind(rawValue: kindRaw) else { throw CoreError.invalidField("kind", id) }
            guard let source = EntrySource(rawValue: sourceRaw) else { throw CoreError.invalidField("source", id) }
            let flags = reviewFlagsRaw.compactMap(ReviewFlag.init(rawValue:))
            guard flags.count == reviewFlagsRaw.count else { throw CoreError.invalidField("reviewFlags", id) }
            let taxRate = taxRateRaw.flatMap(TaxRate.init(rawValue:))
            if taxRateRaw != nil && taxRate == nil { throw CoreError.invalidField("taxRate", id) }
            let serviceMode = serviceModeRaw.flatMap(ServiceMode.init(rawValue:))
            if serviceModeRaw != nil && serviceMode == nil { throw CoreError.invalidField("serviceMode", id) }
            return EntryValue(id: id, kind: kind, amount: amount, currencyCode: currencyCode, day: day, envelopeID: envelopeID, timestamp: timestamp, taxRate: taxRate, serviceMode: serviceMode, isFixedCost: isFixedCost, categoryID: categoryID, title: title, note: note, source: source, reviewFlags: Set(flags), receiptID: receiptID, recurringRuleID: recurringRuleID, occurrenceDay: occurrenceDay, createdAt: createdAt, updatedAt: updatedAt)
        }
    }

    @Model
    public final class ReceiptAttachment {
        public var recordOrder: Int = 0
        public var id: UUID = UUID()
        public var fileName: String = ""
        public var capturedAt: Date = Date(timeIntervalSince1970: 0)
        public var imageSHA256: String? = nil

        public init(_ value: ReceiptValue, order: Int = 0) {
            recordOrder = order
            id = value.id
            fileName = value.fileName
            capturedAt = value.capturedAt
            imageSHA256 = value.imageSHA256
        }
        public func value() throws -> ReceiptValue {
            return ReceiptValue(id: id, fileName: fileName, capturedAt: capturedAt, imageSHA256: imageSHA256)
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
        public var envelopeID: UUID = EnvelopeValue.householdID
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
        public var taxRateRaw: String? = nil
        public var serviceModeRaw: String? = nil
        public var isFixedCost: Bool = false

        public init(_ value: RuleValue, order: Int = 0) {
            recordOrder = order
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
        public func value() throws -> RuleValue {
            guard let kind = EntryKind(rawValue: kindRaw) else { throw CoreError.invalidField("kind", id) }
            let taxRate = taxRateRaw.flatMap(TaxRate.init(rawValue:))
            if taxRateRaw != nil && taxRate == nil { throw CoreError.invalidField("taxRate", id) }
            let serviceMode = serviceModeRaw.flatMap(ServiceMode.init(rawValue:))
            if serviceModeRaw != nil && serviceMode == nil { throw CoreError.invalidField("serviceMode", id) }
            return RuleValue(id: id, title: title, kind: kind, amount: amount, currencyCode: currencyCode, envelopeID: envelopeID, categoryID: categoryID, taxRate: taxRate, serviceMode: serviceMode, isFixedCost: isFixedCost, schedule: schedule, startDay: startDay, endDay: endDay, isPaused: isPaused, lastPostedDay: lastPostedDay, lastProcessedDay: lastProcessedDay, pauseStartedDay: pauseStartedDay, pausedPeriods: pausedPeriods, createdAt: createdAt)
        }
    }

    @Model
    public final class Target {
        public var recordOrder: Int = 0
        public var id: UUID = UUID()
        public var envelopeID: UUID = EnvelopeValue.householdID
        public var categoryID: UUID? = nil
        public var currencyCode: String = "JPY"
        public var amountMinor: Int = 0
        public var effectiveMonth: LedgerMonth = try! LedgerMonth(year: 1970, month: 1)

        public init(_ value: TargetValue, order: Int = 0) {
            recordOrder = order
            id = value.id
            envelopeID = value.envelopeID
            categoryID = value.categoryID
            currencyCode = value.currencyCode
            amountMinor = value.amountMinor
            effectiveMonth = value.effectiveMonth
        }
        public func value() throws -> TargetValue {
            return TargetValue(id: id, envelopeID: envelopeID, categoryID: categoryID, currencyCode: currencyCode, amountMinor: amountMinor, effectiveMonth: effectiveMonth)
        }
    }

    @Model
    public final class NoSpendMark {
        public var recordOrder: Int = 0
        public var id: UUID = UUID()
        public var envelopeID: UUID = EnvelopeValue.householdID
        public var day: LedgerDay = LedgerDay.epoch

        public init(_ value: NoSpendMarkValue, order: Int = 0) {
            recordOrder = order
            id = value.id
            envelopeID = value.envelopeID
            day = value.day
        }
        public func value() throws -> NoSpendMarkValue {
            return NoSpendMarkValue(id: id, envelopeID: envelopeID, day: day)
        }
    }

    @Model
    public final class Settings {
        public var recordOrder: Int = 0
        public var id: UUID = LedgerSettings.defaultID
        public var includeFixedCostsInTargets: Bool = false
        public var weekStart: Int = 2

        public init(_ value: LedgerSettings, order: Int = 0) {
            recordOrder = order
            id = value.id
            includeFixedCostsInTargets = value.includeFixedCostsInTargets
            weekStart = value.weekStart
        }
        public func value() throws -> LedgerSettings {
            return LedgerSettings(id: id, includeFixedCostsInTargets: includeFixedCostsInTargets, weekStart: weekStart)
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
