import Foundation

/// Domain failures contain identifiers and field keys for caller localization.
public enum CoreError: Error, Sendable, Equatable {
    case unsupportedCurrency(String)
    case invalidField(String, UUID?)
    case missingRecord(String, UUID)
    case duplicateID(UUID)
    case duplicateName(String)
    case currencyMismatch(UUID)
    case crossCurrencyTransfer(UUID, UUID)
    case sameWalletTransfer(UUID)
    case archivedWallet(UUID)
    case archivedCategory(UUID)
    case categoryKindMismatch(UUID)
    case walletHasHistory(UUID)
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

public enum WalletKind: String, Codable, Sendable, CaseIterable { case cash, bankAccount, creditCard, prepaid, other }
public enum CategoryKind: String, Codable, Sendable, CaseIterable { case expense, income }
public enum EntryKind: String, Codable, Sendable, CaseIterable { case expense, income, transfer, adjustment }
public enum AdjustmentDirection: String, Codable, Sendable { case increase, decrease }
public enum EntrySource: String, Codable, Sendable, CaseIterable { case manual, receipt, voice, recurring, openingBalance, reconciliation }
public enum ReviewFlag: String, Codable, Sendable, CaseIterable { case paymentMethodUncertain, dateFromCaptureTime, amountUncertain, multipleWalletMatches }
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

public struct WalletValue: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var kind: WalletKind
    public var currencyCode: String
    public var paymentMethodKey: String?
    public var colorKey: String
    public var iconKey: String
    public var sortOrder: Int
    public var isArchived: Bool
    public var createdAt: Date
    public var isProvisional: Bool
    public init(id: UUID = UUID(), name: String, currencyCode: String, kind: WalletKind = .cash,
                paymentMethodKey: String? = nil, colorKey: String = "default", iconKey: String = "wallet.pass",
                sortOrder: Int = 0, isArchived: Bool = false, createdAt: Date = Date(), isProvisional: Bool = false) {
        self.id = id; self.name = name; self.currencyCode = currencyCode; self.kind = kind
        self.paymentMethodKey = paymentMethodKey; self.colorKey = colorKey; self.iconKey = iconKey
        self.sortOrder = sortOrder; self.isArchived = isArchived; self.createdAt = createdAt; self.isProvisional = isProvisional
    }
}
public struct CategoryValue: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var kind: CategoryKind
    public var systemKey: String?
    public var customName: String?
    public var iconKey: String
    public var colorKey: String
    public var sortOrder: Int
    public var isArchived: Bool
    public init(id: UUID = UUID(), kind: CategoryKind, systemKey: String? = nil, customName: String? = nil,
                iconKey: String = "tag", colorKey: String = "default", sortOrder: Int = 0, isArchived: Bool = false) {
        self.id = id; self.kind = kind; self.systemKey = systemKey; self.customName = customName
        self.iconKey = iconKey; self.colorKey = colorKey; self.sortOrder = sortOrder; self.isArchived = isArchived
    }
}
public struct EntryValue: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var kind: EntryKind
    public var amount: Int
    public var direction: AdjustmentDirection?
    public var currencyCode: String
    public var day: LedgerDay
    public var timestamp: Date
    public var walletID: UUID
    public var counterpartWalletID: UUID?
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
    public init(id: UUID = UUID(), kind: EntryKind, amount: Int, currencyCode: String, day: LedgerDay, walletID: UUID,
                direction: AdjustmentDirection? = nil, timestamp: Date = Date(), counterpartWalletID: UUID? = nil,
                categoryID: UUID? = nil, title: String = "", note: String = "", source: EntrySource = .manual,
                reviewFlags: Set<ReviewFlag> = [], receiptID: UUID? = nil, recurringRuleID: UUID? = nil,
                occurrenceDay: LedgerDay? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id; self.kind = kind; self.amount = amount; self.currencyCode = currencyCode; self.day = day
        self.walletID = walletID; self.direction = direction; self.timestamp = timestamp; self.counterpartWalletID = counterpartWalletID
        self.categoryID = categoryID; self.title = title; self.note = note; self.source = source; self.reviewFlags = reviewFlags
        self.receiptID = receiptID; self.recurringRuleID = recurringRuleID; self.occurrenceDay = occurrenceDay
        self.createdAt = createdAt; self.updatedAt = updatedAt
    }
}
public struct ReceiptValue: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var fileName: String
    public var capturedAt: Date
    public init(id: UUID = UUID(), fileName: String, capturedAt: Date = Date()) {
        self.id = id; self.fileName = fileName; self.capturedAt = capturedAt
    }
}
public struct RuleValue: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var title: String
    public var kind: EntryKind
    public var amount: Int
    public var currencyCode: String
    public var walletID: UUID
    public var counterpartWalletID: UUID?
    public var categoryID: UUID?
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
                walletID: UUID, counterpartWalletID: UUID? = nil, categoryID: UUID? = nil, schedule: RecurringSchedule,
                startDay: LedgerDay, endDay: LedgerDay? = nil, isPaused: Bool = false, lastPostedDay: LedgerDay? = nil,
                lastProcessedDay: LedgerDay? = nil, pauseStartedDay: LedgerDay? = nil,
                pausedPeriods: [LedgerPeriod] = [], createdAt: Date = Date()) {
        self.id = id; self.title = title; self.kind = kind; self.amount = amount; self.currencyCode = currencyCode
        self.walletID = walletID; self.counterpartWalletID = counterpartWalletID; self.categoryID = categoryID
        self.schedule = schedule; self.startDay = startDay; self.endDay = endDay; self.isPaused = isPaused
        self.lastPostedDay = lastPostedDay; self.lastProcessedDay = lastProcessedDay
        self.pauseStartedDay = pauseStartedDay; self.pausedPeriods = pausedPeriods; self.createdAt = createdAt
    }
}
public struct BudgetValue: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var currencyCode: String
    public var categoryID: UUID?
    public var monthlyAmount: Int
    public init(id: UUID = UUID(), currencyCode: String, categoryID: UUID? = nil, monthlyAmount: Int) {
        self.id = id; self.currencyCode = currencyCode; self.categoryID = categoryID; self.monthlyAmount = monthlyAmount
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
    public var wallets: [WalletValue]
    public var categories: [CategoryValue]
    public var entries: [EntryValue]
    public var receipts: [ReceiptValue]
    public var rules: [RuleValue]
    public var budgets: [BudgetValue]
    public var pointCards: [PointCardValue]
    public init(wallets: [WalletValue] = [], categories: [CategoryValue] = [], entries: [EntryValue] = [],
                receipts: [ReceiptValue] = [], rules: [RuleValue] = [], budgets: [BudgetValue] = [], pointCards: [PointCardValue] = []) {
        self.wallets = wallets; self.categories = categories; self.entries = entries; self.receipts = receipts
        self.rules = rules; self.budgets = budgets; self.pointCards = pointCards
    }
}
