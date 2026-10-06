import Foundation
import Observation
import WealthyCore
import FoundationModels

@Observable @MainActor final class LedgerSession {
    static var isUITest: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("--cycle2a-test")
        #else
        false
        #endif
    }
    private(set) var core: LedgerCore?
    var error: String?
    var language: String { didSet { if !Self.isUITest { UserDefaults.standard.set(language, forKey: "v4.language") } } }
    var currency: String { didSet { if !Self.isUITest { UserDefaults.standard.set(currency, forKey: "v4.currency") } } }
    var onboarded: Bool { didSet { if !Self.isUITest { UserDefaults.standard.set(onboarded, forKey: "v4.onboarded") } } }
    var readiness = "notReady"
    private(set) var available = false
    var summary: IslandSummary?
    var recentResults: [TargetStatus] = []
    var envelopeID = EnvelopeValue.householdID
    var today: LedgerDay {
        #if DEBUG
        if Self.isUITest && ProcessInfo.processInfo.arguments.contains("--cycle2a-seed") { return try! LedgerDay(year: 2026, month: 10, day: 11) }
        #endif
        return try! LedgerDay(date: Date(), calendar: .current)
    }
    var locale: Locale { Locale(identifier: ["en":"en_US", "ja":"ja_JP", "es":"es_ES", "ko":"ko_KR"][language] ?? "en_US") }
    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--cycle2a-clear-created-preferences") {
            // Clear only the new keys created by this cycle's early test run; never legacy keys.
            for key in ["v4.language", "v4.currency", "v4.onboarded"] { UserDefaults.standard.removeObject(forKey: key) }
        }
        #endif
        language = UserDefaults.standard.string(forKey: "v4.language") ?? "en"
        currency = UserDefaults.standard.string(forKey: "v4.currency") ?? "JPY"
        onboarded = UserDefaults.standard.bool(forKey: "v4.onboarded")
        refreshAvailability()
    }
    func refreshAvailability() {
        switch SystemLanguageModel.default.availability {
        case .available: available = true; readiness = "available"
        case .unavailable(let reason):
            available = false
            switch reason {
            case .deviceNotEligible: readiness = "ineligible"
            case .appleIntelligenceNotEnabled: readiness = "notEnabled"
            case .modelNotReady: readiness = "notReady"
            @unknown default: readiness = "unavailable"
            }
        }
    }
    func open() {
        guard available, core == nil else { return }
        do {
            #if DEBUG
            let isolated = Self.isUITest
            #else
            let isolated = false
            #endif
            #if DEBUG
            let performance = isolated && ProcessInfo.processInfo.arguments.contains("--cycle2a-performance")
            let directory = performance ? FileManager.default.temporaryDirectory.appendingPathComponent("Cycle2aPerformance", isDirectory: true) : nil
            core = try LedgerCore(store: LedgerStore(inMemory: isolated && !performance, directory: directory))
            if performance { try preparePerformanceStore() }
            #else
            core = try LedgerCore(store: LedgerStore(inMemory: isolated))
            #endif
            #if DEBUG
            if isolated && ProcessInfo.processInfo.arguments.contains("--cycle2a-seed") { try seedUITest() }
            #endif
            refresh()
        }
        catch { self.error = t("storeError") }
    }
    func t(_ key: String) -> String {
        let bundle = Bundle.main.path(forResource: language, ofType: "lproj").flatMap(Bundle.init(path:)) ?? .main
        return bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }
    func money(_ amount: Int, code: String? = nil) -> String {
        (try? CoreCurrency.formatForDisplay(amount, currencyCode: code ?? currency, locale: locale)) ?? "—"
    }
    func reload() {
        do { try core?.reload(); refresh() } catch { self.error = t("queryError") }
    }
    func input(_ amount: Int) -> String { (try? CoreCurrency.inputText(amount, currencyCode: currency, locale: locale)) ?? "" }
    func parse(_ text: String) throws -> Int {
        guard let value = try CoreCurrency.parseMinorUnits(text, currencyCode: currency, locale: locale) else { throw CoreError.invalidField("amount", nil) }
        return value
    }
    func run(_ command: LedgerCommand) throws {
        guard let core else { throw CoreError.saveFailed }
        try core.run(command, now: Date()); refresh()
    }
    func perform(_ action: () throws -> Void) { do { try action() } catch { self.error = t("invalidInput") } }
    func refresh() {
        guard let core else { return }
        do {
            summary = try LedgerQueries.islandSummary(in: core.state, today: today, envelopeID: envelopeID, currencyCode: currency)
            recentResults = try LedgerQueries.recentlyEndedResults(in: core.state, today: today, envelopeID: envelopeID, currencyCode: currency)
        } catch { self.error = t("queryError") }
    }
    func categoryName(_ category: CategoryValue) -> String { category.customName ?? t(category.systemKey ?? "catOthers") }
    func child() -> EnvelopeValue? { core?.state.envelopes.first { $0.kind == .child && !$0.isArchived } }
    func createChild() throws {
        if let existing = core?.state.envelopes.first(where: { $0.kind == .child }) {
            try run(.archiveEnvelope(existing.id, archived: false)); return
        }
        let child = EnvelopeValue(kind: .child, name: "Child")
        try run(.createEnvelope(child))
    }
    func completeOnboarding(amount: String, child: Bool) throws {
        let value = try parse(amount)
        try run(.setTarget(TargetValue(currencyCode: currency, amountMinor: value, effectiveMonth: LedgerMonth(day: today))))
        if child { try createChild() }
        onboarded = true
    }
    #if DEBUG
    private func preparePerformanceStore() throws {
        guard let core else { return }
        if core.state.entries.count != 50000 {
            var state = core.state
            state.entries = (0..<50000).map { _ in EntryValue(kind: .expense, amount: 1, currencyCode: "JPY", day: today) }
            state.targets = [TargetValue(currencyCode: "JPY", amountMinor: 310000, effectiveMonth: LedgerMonth(day: today))]
            let archive = LedgerBackupArchive(exportDate: Date(), appVersion: "Cycle2aTest", coreVersion: "2", state: state)
            try LedgerBackup.restore(JSONEncoder().encode(archive), into: core)
        }
        onboarded = true
    }
    private func seedUITest() throws {
        let args = ProcessInfo.processInfo.arguments
        let first = try LedgerDay(year: 2026, month: 10, day: 1)
        if !args.contains("--unset") { try run(.setTarget(TargetValue(currencyCode: "JPY", amountMinor: 310000, effectiveMonth: LedgerMonth(day: first)))) }
        let week = try LedgerPeriod.week(containing: today)
        let logged = args.contains("--few") ? 2 : 6
        for offset in 0..<logged { try run(.markNoSpend(week.start.adding(days: offset, calendar: .current))) }
        if let food = core?.state.categories.first(where: { $0.systemKey == "catFood" }) {
            try run(.addEntry(EntryValue(kind: .expense, amount: args.contains("--over") ? 80000 : 2400, currencyCode: "JPY", day: week.start, taxRate: .standard, serviceMode: .dineIn, categoryID: food.id, title: "Test lunch")))
            try run(.addEntry(EntryValue(kind: .expense, amount: 500, currencyCode: "JPY", day: week.start, title: "Test unknown rate")))
        }
        try createChild()
        if let child = child() {
            try run(.setTarget(TargetValue(envelopeID: child.id, currencyCode: "JPY", amountMinor: 80000, effectiveMonth: LedgerMonth(day: first))))
            try run(.addEntry(EntryValue(kind: .expense, amount: 3600, currencyCode: "JPY", day: week.start, envelopeID: child.id, taxRate: .reduced, title: "Test child expense")))
        }
        if args.contains("--child-info"), let child = child() { envelopeID = child.id }
        onboarded = true
    }
    #endif

}
