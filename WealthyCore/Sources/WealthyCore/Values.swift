import Foundation

/// Domain failures contain identifiers and field keys for caller localization.
public enum CoreError: Error, Sendable, Equatable {
    case unsupportedCurrency(String)
    case invalidField(String, UUID?)
    case missingRecord(String, UUID)
    case duplicateID(UUID)
    case duplicateName(String)
    case currencyMismatch(UUID)
    case archivedEnvelope(UUID)
    case envelopeHasHistory(UUID)
    case archivedCategory(UUID)
    case categoryKindMismatch(UUID)
    case undoConflict
    case saveFailed
    case fileFailure(String)
    case legacyBackupNotSupported
    case malformedBackup
    case unsupportedBackupVersion(Int)
    case invalidBackupFormat(String)
    case unsafeFilename(String)
    case invalidImage(String)
    case danglingReference(String, UUID)
    case historyNotEmpty
}

public enum EnvelopeKind: String, Codable, Sendable, CaseIterable { case household, child }
public enum TaxRate: String, Codable, Sendable, CaseIterable { case standard, reduced, exempt }
public enum TaxHint: String, Codable, Sendable, CaseIterable { case food, nonfood, exempt }
public enum ServiceMode: String, Codable, Sendable, CaseIterable { case dineIn, takeout, delivery, none }
public enum CategoryKind: String, Codable, Sendable, CaseIterable { case expense, income }
public enum EntryKind: String, Codable, Sendable, CaseIterable { case expense, income }
public enum EntrySource: String, Codable, Sendable, CaseIterable { case manual, receipt, voice, recurring }
public enum ReviewFlag: String, Codable, Sendable, CaseIterable { case dateFromCaptureTime, amountUncertain }
public enum RecurringSchedule: Codable, Sendable, Equatable {
    case monthly(day: Int)
    /// Weekdays follow Foundation Calendar: Sunday is 1, Saturday is 7.
    case weekly(weekday: Int)
    case yearly(month: Int, day: Int)
}

/// A Gregorian civil date whose identity does not depend on a time zone.
public struct LedgerDay: Codable, Sendable, Equatable, Hashable, Comparable {
    public let year: Int
    public let month: Int
    public let day: Int
    public static let epoch = try! LedgerDay(year: 1970, month: 1, day: 1)

    public init(year: Int, month: Int, day: Int) throws {
        self.year = year; self.month = month; self.day = day
        try validated()
    }
    public init(date: Date, calendar: Calendar) throws {
        let components = Self.gregorian(calendar).dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else {
            throw CoreError.invalidField("day", nil)
        }
        try self.init(year: year, month: month, day: day)
    }
    public func validated() throws {
        guard (1...9999).contains(year), (1...12).contains(month), (1...31).contains(day) else {
            throw CoreError.invalidField("day", nil)
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = DateComponents(year: year, month: month, day: day, hour: 12)
        guard let date = calendar.date(from: components),
              calendar.component(.year, from: date) == year,
              calendar.component(.month, from: date) == month,
              calendar.component(.day, from: date) == day else {
            throw CoreError.invalidField("day", nil)
        }
    }
    /// Returns noon in the injected calendar to avoid midnight DST transitions.
    public func date(calendar: Calendar) throws -> Date {
        try validated()
        guard let date = Self.gregorian(calendar).date(from: DateComponents(year: year, month: month, day: day, hour: 12)) else {
            throw CoreError.invalidField("day", nil)
        }
        return date
    }
    public func adding(days: Int, calendar: Calendar) throws -> LedgerDay {
        guard let date = Self.gregorian(calendar).date(byAdding: .day, value: days, to: try date(calendar: calendar)) else {
            throw CoreError.invalidField("day", nil)
        }
        return try LedgerDay(date: date, calendar: calendar)
    }
    private static func gregorian(_ calendar: Calendar) -> Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = calendar.timeZone
        result.locale = calendar.locale
        return result
    }
    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        if lhs.month != rhs.month { return lhs.month < rhs.month }
        return lhs.day < rhs.day
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(year: container.decode(Int.self, forKey: .year),
                      month: container.decode(Int.self, forKey: .month), day: container.decode(Int.self, forKey: .day))
    }
    private enum CodingKeys: String, CodingKey { case year, month, day }
}

public struct EnvelopeValue: Codable, Sendable, Equatable, Identifiable {
    public static let householdID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    public var id: UUID
    public var kind: EnvelopeKind
    public var name: String
    public var isArchived: Bool
    public var createdAt: Date
    public init(id: UUID = UUID(), kind: EnvelopeKind = .household, name: String,
                isArchived: Bool = false, createdAt: Date = Date()) {
        self.id = id; self.kind = kind; self.name = name; self.isArchived = isArchived; self.createdAt = createdAt
    }
}

public struct LedgerMonth: Codable, Sendable, Equatable, Hashable, Comparable {
    public let year: Int
    public let month: Int
    public init(year: Int, month: Int) throws {
        self.year = year; self.month = month; try validated()
    }
    public init(day: LedgerDay) { year = day.year; month = day.month }
    public func validated() throws {
        guard (1...9999).contains(year), (1...12).contains(month) else { throw CoreError.invalidField("month", nil) }
    }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.year == rhs.year ? lhs.month < rhs.month : lhs.year < rhs.year }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(year: container.decode(Int.self, forKey: .year), month: container.decode(Int.self, forKey: .month))
    }
    private enum CodingKeys: String, CodingKey { case year, month }
}

public struct LedgerSettings: Codable, Sendable, Equatable, Identifiable {
    public static let defaultID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    public var id: UUID
    public var includeFixedCostsInTargets: Bool
    /// Foundation weekday numbering: Monday is 2.
    public var weekStart: Int
    public init(id: UUID = Self.defaultID, includeFixedCostsInTargets: Bool = false, weekStart: Int = 2) {
        self.id = id; self.includeFixedCostsInTargets = includeFixedCostsInTargets; self.weekStart = weekStart
    }
}
public struct CategoryValue: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var kind: CategoryKind
    public var envelopeID: UUID
    public var taxHint: TaxHint
    public var systemKey: String?
    public var customName: String?
    public var iconKey: String
    public var colorKey: String
    public var sortOrder: Int
    public var isArchived: Bool
    public init(id: UUID = UUID(), kind: CategoryKind, envelopeID: UUID = EnvelopeValue.householdID, taxHint: TaxHint = .nonfood, systemKey: String? = nil, customName: String? = nil,
                iconKey: String = "tag", colorKey: String = "default", sortOrder: Int = 0, isArchived: Bool = false) {
        self.id = id; self.kind = kind; self.envelopeID = envelopeID; self.taxHint = taxHint; self.systemKey = systemKey; self.customName = customName
        self.iconKey = iconKey; self.colorKey = colorKey; self.sortOrder = sortOrder; self.isArchived = isArchived
    }
}
public struct EntryValue: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var kind: EntryKind
    public var amount: Int
    public var taxRate: TaxRate?
    public var serviceMode: ServiceMode?
    public var isFixedCost: Bool
    public var currencyCode: String
    public var day: LedgerDay
    public var timestamp: Date
    public var envelopeID: UUID
    public var categoryID: UUID?
    public var title: String
    public var note: String
    public var source: EntrySource
    public var reviewFlags: Set<ReviewFlag>
    public var receiptID: UUID?
    public var recurringRuleID: UUID?
    public var occurrenceDay: LedgerDay?
    public var createdAt: Date
    public var updatedAt: Date
    public var needsReview: Bool { !reviewFlags.isEmpty }
    public init(id: UUID = UUID(), kind: EntryKind, amount: Int, currencyCode: String, day: LedgerDay, envelopeID: UUID = EnvelopeValue.householdID,
                timestamp: Date = Date(), taxRate: TaxRate? = nil, serviceMode: ServiceMode? = nil, isFixedCost: Bool = false,
                categoryID: UUID? = nil, title: String = "", note: String = "", source: EntrySource = .manual,
                reviewFlags: Set<ReviewFlag> = [], receiptID: UUID? = nil, recurringRuleID: UUID? = nil,
                occurrenceDay: LedgerDay? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id; self.kind = kind; self.amount = amount; self.currencyCode = currencyCode; self.day = day
        self.envelopeID = envelopeID; self.timestamp = timestamp; self.taxRate = taxRate; self.serviceMode = serviceMode; self.isFixedCost = isFixedCost
        self.categoryID = categoryID; self.title = title; self.note = note; self.source = source; self.reviewFlags = reviewFlags
        self.receiptID = receiptID; self.recurringRuleID = recurringRuleID; self.occurrenceDay = occurrenceDay
        self.createdAt = createdAt; self.updatedAt = updatedAt
    }
}
public struct ReceiptValue: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var fileName: String
    public var capturedAt: Date
    /// Lowercase SHA-256 of saved image bytes; nil means an older archive has no known hash.
    public var imageSHA256: String?
    public init(id: UUID = UUID(), fileName: String, capturedAt: Date = Date(), imageSHA256: String? = nil) {
        self.id = id; self.fileName = fileName; self.capturedAt = capturedAt; self.imageSHA256 = imageSHA256
    }
}
public struct RuleValue: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var title: String
    public var kind: EntryKind
    public var amount: Int
    public var currencyCode: String
    public var envelopeID: UUID
    public var categoryID: UUID?
    public var taxRate: TaxRate?
    public var serviceMode: ServiceMode?
    public var isFixedCost: Bool
    public var schedule: RecurringSchedule
    public var startDay: LedgerDay
    public var endDay: LedgerDay?
    public var isPaused: Bool
    public var lastPostedDay: LedgerDay?
    /// Cursor for skipped or invalid occurrences, independent of successful posting.
    public var lastProcessedDay: LedgerDay?
    /// The beginning of the current pause, used to retain catch-up before that pause.
    public var pauseStartedDay: LedgerDay?
    /// Completed inclusive pause intervals whose occurrences must remain skipped.
    public var pausedPeriods: [LedgerPeriod]
    public var createdAt: Date
    public init(id: UUID = UUID(), title: String = "", kind: EntryKind = .expense, amount: Int, currencyCode: String,
                envelopeID: UUID = EnvelopeValue.householdID, categoryID: UUID? = nil, taxRate: TaxRate? = nil, serviceMode: ServiceMode? = nil, isFixedCost: Bool = false, schedule: RecurringSchedule,
                startDay: LedgerDay, endDay: LedgerDay? = nil, isPaused: Bool = false, lastPostedDay: LedgerDay? = nil,
                lastProcessedDay: LedgerDay? = nil, pauseStartedDay: LedgerDay? = nil,
                pausedPeriods: [LedgerPeriod] = [], createdAt: Date = Date()) {
        self.id = id; self.title = title; self.kind = kind; self.amount = amount; self.currencyCode = currencyCode
        self.envelopeID = envelopeID; self.categoryID = categoryID; self.taxRate = taxRate; self.serviceMode = serviceMode; self.isFixedCost = isFixedCost
        self.schedule = schedule; self.startDay = startDay; self.endDay = endDay; self.isPaused = isPaused
        self.lastPostedDay = lastPostedDay; self.lastProcessedDay = lastProcessedDay
        self.pauseStartedDay = pauseStartedDay; self.pausedPeriods = pausedPeriods; self.createdAt = createdAt
    }
}
public struct TargetValue: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var envelopeID: UUID
    public var currencyCode: String
    public var categoryID: UUID?
    public var amountMinor: Int
    public var effectiveMonth: LedgerMonth
    public init(id: UUID = UUID(), envelopeID: UUID = EnvelopeValue.householdID, categoryID: UUID? = nil,
                currencyCode: String, amountMinor: Int, effectiveMonth: LedgerMonth) {
        self.id = id; self.envelopeID = envelopeID; self.currencyCode = currencyCode; self.categoryID = categoryID
        self.amountMinor = amountMinor; self.effectiveMonth = effectiveMonth
    }
}
public struct NoSpendMarkValue: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var envelopeID: UUID
    public var day: LedgerDay
    public init(id: UUID = UUID(), envelopeID: UUID = EnvelopeValue.householdID, day: LedgerDay) {
        self.id = id; self.envelopeID = envelopeID; self.day = day
    }
}
public struct PointCardValue: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var memberNumber: String
    public var points: Int
    public var expiryDay: LedgerDay?
    public var colorKey: String
    public var sortOrder: Int
    public init(id: UUID = UUID(), name: String, memberNumber: String = "", points: Int = 0,
                expiryDay: LedgerDay? = nil, colorKey: String = "default", sortOrder: Int = 0) {
        self.id = id; self.name = name; self.memberNumber = memberNumber; self.points = points
        self.expiryDay = expiryDay; self.colorKey = colorKey; self.sortOrder = sortOrder
    }
}
/// Detached, transferable records are the boundary between persistence and callers.
public struct LedgerState: Codable, Sendable, Equatable {
    public var envelopes: [EnvelopeValue]
    public var categories: [CategoryValue]
    public var entries: [EntryValue]
    public var receipts: [ReceiptValue]
    public var rules: [RuleValue]
    public var targets: [TargetValue]
    public var noSpendMarks: [NoSpendMarkValue]
    public var settings: LedgerSettings
    public var pointCards: [PointCardValue]
    public init(envelopes: [EnvelopeValue] = [EnvelopeValue(id: EnvelopeValue.householdID, name: "Household", createdAt: Date(timeIntervalSince1970: 0))], categories: [CategoryValue] = [], entries: [EntryValue] = [],
                receipts: [ReceiptValue] = [], rules: [RuleValue] = [], targets: [TargetValue] = [],
                noSpendMarks: [NoSpendMarkValue] = [], settings: LedgerSettings = LedgerSettings(), pointCards: [PointCardValue] = []) {
        self.envelopes = envelopes; self.categories = categories; self.entries = entries; self.receipts = receipts
        self.rules = rules; self.targets = targets; self.noSpendMarks = noSpendMarks; self.settings = settings; self.pointCards = pointCards
    }
}

/// Reference category tables use stable localization keys rather than display translations.
public enum CategoryPresets {
    private static let householdData: [(CategoryKind, String, TaxHint)] = [
        (.expense, "catFood", .food), (.expense, "catTransport", .nonfood),
        (.expense, "catDaily", .nonfood), (.expense, "catHobby", .nonfood),
        (.expense, "catClothing", .nonfood), (.expense, "catOthers", .nonfood),
        (.expense, "categoryFixedCosts", .nonfood), (.income, "incomeSalary", .exempt),
        (.income, "incomeBonus", .exempt), (.income, "incomeOther", .exempt)
    ]
    private static let childData: [(String, TaxHint)] = [
        ("child.food", .food), ("child.education", .nonfood), ("child.clothing", .nonfood),
        ("child.medical", .nonfood), ("child.activities", .nonfood),
        ("child.support", .exempt), ("child.other", .nonfood)
    ]
    public static func household(envelopeID: UUID = EnvelopeValue.householdID) -> [CategoryValue] {
        householdData.enumerated().map { index, item in
            CategoryValue(kind: item.0, envelopeID: envelopeID, taxHint: item.2, systemKey: item.1, sortOrder: index)
        }
    }
    public static func child(envelopeID: UUID) -> [CategoryValue] {
        childData.enumerated().map { index, item in
            CategoryValue(kind: .expense, envelopeID: envelopeID, taxHint: item.1, systemKey: item.0, sortOrder: index)
        }
    }
}
