import Foundation
import Observation
import WealthyCore
import FoundationModels
import os
import MetricKit

@Observable @MainActor final class LedgerSession {
    static var isUITest: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("--cycle2a-test")
        #else
        false
        #endif
    }
    private var interactiveInterval: OSSignpostIntervalState?
    private var renderInterval: OSSignpostIntervalState?
    private(set) var isOpening = false
    private let loadLog = OSSignposter(subsystem: "com.harrison.Wealthy", category: "LedgerLaunch")
    private static var testDiskID: String? {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if isUITest, let i = args.firstIndex(of: "--disk-test"), args.count > i + 1 { return args[i + 1] }
        #endif
        return nil
    }
    private static var preferences: UserDefaults {
        #if DEBUG
        if isUITest && ProcessInfo.processInfo.arguments.contains("--reset-test-preferences") {
            return UserDefaults(suiteName: "Cycle2aUITestPreferences")!
        }
        #endif
        if let id = testDiskID { return UserDefaults(suiteName: "Cycle2aOnboarding-" + id)! }
        return .standard
    }
    private static var persistsPreferences: Bool { !isUITest || testDiskID != nil }
    private(set) var core: LedgerCore?
    var error: String?
    var language: String { didSet { if Self.persistsPreferences { Self.preferences.set(language, forKey: "v4.language") } } }
    var currency: String { didSet { if Self.persistsPreferences { Self.preferences.set(currency, forKey: "v4.currency") } } }
    var onboarded: Bool { didSet { if Self.persistsPreferences { Self.preferences.set(onboarded, forKey: "v4.onboarded") } } }
    var readiness = "notReady"
    private(set) var available = false
    var summary: IslandSummary?
    var householdSummary: IslandSummary?
    var recentResults: [TargetStatus] = []
    var envelopeID = EnvelopeValue.householdID
    var today: LedgerDay {
        #if DEBUG
        if Self.isUITest && ProcessInfo.processInfo.arguments.contains("--cycle2a-performance") { return try! LedgerDay(year: 2026, month: 10, day: 15) }
        if Self.isUITest && ProcessInfo.processInfo.arguments.contains("--cycle2a-seed") { return try! LedgerDay(year: 2026, month: 10, day: ProcessInfo.processInfo.arguments.contains(where: { $0.hasPrefix("--month-") }) ? 31 : 11) }
        #endif
        return try! LedgerDay(date: Date(), calendar: .current)
    }
    var locale: Locale { Locale(identifier: ["en":"en_US", "ja":"ja_JP", "es":"es_ES", "ko":"ko_KR"][language] ?? "en_US") }
    init() {
        language = Self.preferences.string(forKey: "v4.language") ?? "en"
        currency = Self.preferences.string(forKey: "v4.currency") ?? "JPY"
        onboarded = Self.preferences.bool(forKey: "v4.onboarded")
        #if DEBUG
        if Self.isUITest && ProcessInfo.processInfo.arguments.contains("--measure-home-launch") {
            do { try MXMetricManager.extendLaunchMeasurement(forTaskID: MXLaunchTaskID("ledger-home-ready")) }
            catch { self.error = t("queryError"); print("EXTENDED_LAUNCH_TRACKING_FAILED: \(error)") }
        }
        #endif
        interactiveInterval = loadLog.beginInterval("HomeInteractive")
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
    /// Defer synchronous Core work until the loading view has been presented.
    func openAfterPresentation() async {
        guard !isOpening, core == nil else { return }
        isOpening = true
        defer { isOpening = false }
        await Task.yield()
        await DisplayFrameWaiter.wait()
        guard !Task.isCancelled else { return }
        open()
    }
    func homePresented() async {
        await DisplayFrameWaiter.wait()
        if let renderInterval { loadLog.endInterval("HomeRender", renderInterval); self.renderInterval = nil }
        if let interactiveInterval { loadLog.endInterval("HomeInteractive", interactiveInterval); self.interactiveInterval = nil }
        #if DEBUG
        if Self.isUITest && ProcessInfo.processInfo.arguments.contains("--measure-home-launch") {
            do { try MXMetricManager.finishExtendedLaunchMeasurement(forTaskID: MXLaunchTaskID("ledger-home-ready")) }
            catch { self.error = t("queryError"); print("EXTENDED_LAUNCH_FINISH_FAILED: \(error)") }
        }
        #endif
    }
    func open() {
        guard available, core == nil else { return }
        let interval = loadLog.beginInterval("LedgerOpen")
        defer { loadLog.endInterval("LedgerOpen", interval) }
        do {
            #if DEBUG
            let isolated = Self.isUITest
            #else
            let isolated = false
            #endif
            #if DEBUG
            let performance = isolated && ProcessInfo.processInfo.arguments.contains("--cycle2a-performance")
            let directory: URL?
            if let id = Self.testDiskID { directory = FileManager.default.temporaryDirectory.appendingPathComponent("Cycle2aOnboarding-" + id, isDirectory: true) }
            else if performance {
                let args = ProcessInfo.processInfo.arguments
                let size = args.firstIndex(of: "--entry-count").flatMap { $0 + 1 < args.count ? Int(args[$0 + 1]) : nil } ?? 50000
                directory = FileManager.default.temporaryDirectory.appendingPathComponent("Cycle2aPerformance-\(size)", isDirectory: true)
            } else { directory = nil }
            let storeInterval = loadLog.beginInterval("StoreOpen")
            let store = try LedgerStore(inMemory: isolated && !performance && Self.testDiskID == nil, directory: directory)
            loadLog.endInterval("StoreOpen", storeInterval)
            let snapshotInterval = loadLog.beginInterval("Snapshot")
            core = try LedgerCore(store: store)
            loadLog.endInterval("Snapshot", snapshotInterval)
            if performance { try preparePerformanceStore() }
            #else
            core = try LedgerCore(store: LedgerStore(inMemory: isolated))
            #endif
            #if DEBUG
            if isolated && ProcessInfo.processInfo.arguments.contains("--cycle2a-seed") { try seedUITest() }
            #endif
            refresh()
            renderInterval = loadLog.beginInterval("HomeRender")
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
        var numeric = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let formatter = NumberFormatter(); formatter.locale = locale; formatter.numberStyle = .currency; formatter.currencyCode = currency
        let symbols = currency == "JPY" ? ["JP¥", "¥", currency] : [formatter.currencySymbol ?? currency, currency]
        for symbol in symbols {
            if numeric.hasPrefix(symbol) { numeric.removeFirst(symbol.count) }
            if numeric.hasSuffix(symbol) { numeric.removeLast(symbol.count) }
            numeric = numeric.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let value = try CoreCurrency.parseMinorUnits(numeric, currencyCode: currency, locale: locale) else { throw CoreError.invalidField("amount", nil) }
        return value
    }
    func formattedInput(_ text: String) -> String {
        guard let amount = try? parse(text) else { return text }
        return money(amount)
    }
    func run(_ command: LedgerCommand) throws {
        guard let core else { throw CoreError.saveFailed }
        try core.run(command, now: Date()); refresh()
    }
    func perform(_ action: () throws -> Void) { do { try action() } catch { self.error = t("invalidInput") } }
    func refresh() {
        guard let core else { return }
        let interval = loadLog.beginInterval("QuerySnapshot")
        defer { loadLog.endInterval("QuerySnapshot", interval) }
        do {
            householdSummary = try LedgerQueries.islandSummary(in: core.state, today: today, envelopeID: EnvelopeValue.householdID, currencyCode: currency)
            summary = envelopeID == EnvelopeValue.householdID ? householdSummary : try LedgerQueries.islandSummary(in: core.state, today: today, envelopeID: envelopeID, currencyCode: currency)
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
        let args = ProcessInfo.processInfo.arguments
        let count = args.firstIndex(of: "--entry-count").flatMap { $0 + 1 < args.count ? Int(args[$0 + 1]) : nil } ?? 50000
        if core.state.entries.count != count {
            var state = core.state
            state.entries = (0..<count).map { _ in EntryValue(kind: .expense, amount: 1, currencyCode: "JPY", day: today) }
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
        if args.contains("--month-achieved") || args.contains("--month-over") || args.contains("--month-few") {
            let logged = args.contains("--month-few") ? 10 : 25
            for offset in 0..<logged { try run(.markNoSpend(first.adding(days: offset, calendar: .current))) }
            if args.contains("--month-over") { try run(.addEntry(EntryValue(kind: .expense, amount: 400000, currencyCode: "JPY", day: first, title: "Test month expense"))) }
        }
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
