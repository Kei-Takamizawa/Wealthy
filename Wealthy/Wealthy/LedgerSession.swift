import Foundation
import Observation
import WealthyCore
import FoundationModels
import os
import MetricKit
import AppIntents

@Observable @MainActor final class LedgerSession {
    /// UI and main-target App Intents retain the same Core and store for this process.
    static let shared = LedgerSession()
    static var isUITest: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("--cycle2a-test")
        #elseif WEALTHY_LAUNCH_MEASUREMENT
        measurementEntryCount != nil
        #else
        false
        #endif
    }
    #if WEALTHY_LAUNCH_MEASUREMENT
    /// Opt-in Release measurement build only. Never opens the owner's normal store.
    private static var measurementEntryCount: Int? {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains("--cycle2a-performance"), let index = args.firstIndex(of: "--entry-count"),
              args.count > index + 1, let count = Int(args[index + 1]), [1000, 10000, 50000].contains(count) else { return nil }
        return count
    }
    private let measurementStart = ProcessInfo.processInfo.systemUptime
    private var measurementSamples: [String: Double] = [:]
    #endif
    private var firstFrameInterval: OSSignpostIntervalState?
    private var interactiveInterval: OSSignpostIntervalState?
    private var renderInterval: OSSignpostIntervalState?
    private(set) var isOpening = false
    private let loadLog = OSSignposter(subsystem: "com.harrison.Wealthy", category: "LedgerLaunch")
    private static var testDiskID: String? {
        #if DEBUG || WEALTHY_LAUNCH_MEASUREMENT
        let args = ProcessInfo.processInfo.arguments
        if isUITest, let i = args.firstIndex(of: "--disk-test"), args.count > i + 1 { return args[i + 1] }
        #endif
        return nil
    }
    private static var preferences: UserDefaults {
        #if DEBUG || WEALTHY_LAUNCH_MEASUREMENT
        if isUITest && ProcessInfo.processInfo.arguments.contains("--reset-test-preferences") {
            return UserDefaults(suiteName: "Cycle2aUITestPreferences")!
        }
        #endif
        if let id = testDiskID { return UserDefaults(suiteName: "Cycle2aOnboarding-" + id)! }
        return .standard
    }
    private static var persistsPreferences: Bool { !isUITest || testDiskID != nil }
    private(set) var core: LedgerCore?
    var recurringEntries: [EntryValue] = []
    var recurringFailures: [String] = []
    var showRecurringNotice = false
    var error: String?
    var language: String { didSet { if Self.persistsPreferences { Self.preferences.set(language, forKey: "v4.language") } } }
    var currency: String { didSet { if Self.persistsPreferences { Self.preferences.set(currency, forKey: "v4.currency") } } }
    var onboarded: Bool { didSet { if Self.persistsPreferences { Self.preferences.set(onboarded, forKey: "v4.onboarded") } } }
    var readiness = "notReady"
    private(set) var available = false
    var selectedTab = 1
    var showQuickAdd = false
    var safeLine: SafeLine?
    #if DEBUG
    var intentTestDialog: String?
    #endif
    var summary: IslandSummary?
    var householdSummary: IslandSummary?
    var recentResults: [TargetStatus] = []
    var envelopeID = EnvelopeValue.householdID
    var today: LedgerDay {
        #if DEBUG || WEALTHY_LAUNCH_MEASUREMENT
        if Self.isUITest && ProcessInfo.processInfo.arguments.contains("--cycle2b2-seed") { return try! LedgerDay(year: 2026, month: 10, day: 7) }
        if Self.isUITest && ProcessInfo.processInfo.arguments.contains("--cycle2a-performance") { return try! LedgerDay(year: 2026, month: 10, day: 15) }
        if Self.isUITest && (ProcessInfo.processInfo.arguments.contains("--cycle2a-seed") || ProcessInfo.processInfo.arguments.contains("--cycle2b-seed")) { return try! LedgerDay(year: 2026, month: 10, day: ProcessInfo.processInfo.arguments.contains("--cycle2b-results") ? 2 : ProcessInfo.processInfo.arguments.contains(where: { $0.hasPrefix("--month-") }) ? 31 : 11) }
        #endif
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if Self.isUITest, let index = arguments.firstIndex(of: "--today"), index + 1 < arguments.count {
            let value = arguments[index + 1]
            let parts = value.split(separator: "-", omittingEmptySubsequences: false)
            if parts.map(\.count) == [4, 2, 2],
               let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]),
               let today = try? LedgerDay(year: year, month: month, day: day) { return today }
        }
        #endif
        return try! LedgerDay(date: Date(), calendar: .current)
    }
    var locale: Locale { Locale(identifier: ["en":"en_US", "ja":"ja_JP", "es":"es_ES", "ko":"ko_KR"][language] ?? "en_US") }
    private init() {
        firstFrameInterval = loadLog.beginInterval("FirstFrame")
        language = Self.preferences.string(forKey: "v4.language") ?? "en"
        currency = Self.preferences.string(forKey: "v4.currency") ?? "JPY"
        onboarded = Self.preferences.bool(forKey: "v4.onboarded")
        #if DEBUG || WEALTHY_LAUNCH_MEASUREMENT
        if Self.isUITest && ProcessInfo.processInfo.arguments.contains("--measure-home-launch") {
            do { try MXMetricManager.extendLaunchMeasurement(forTaskID: MXLaunchTaskID("ledger-home-ready")) }
            catch { self.error = t("queryError"); print("EXTENDED_LAUNCH_TRACKING_FAILED: \(error)") }
        }
        #endif
        interactiveInterval = loadLog.beginInterval("HomeInteractive")
        refreshAvailability()
    }
    func refreshAvailability() {
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        if let forced = environment["WEALTHY_TEST_AI_AVAILABLE"], ["0", "1"].contains(forced) {
            available = forced == "1"
            readiness = available ? "available" : "ineligible"
            return
        }
        if environment["WEALTHY_CYCLE2A_TEST_AI_AVAILABLE"] == "1" {
            available = true; readiness = "available"
            return
        }
        #endif
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
        if let firstFrameInterval {
            loadLog.endInterval("FirstFrame", firstFrameInterval)
            self.firstFrameInterval = nil
            #if WEALTHY_LAUNCH_MEASUREMENT
            measurementSamples["FirstFrame"] = ProcessInfo.processInfo.systemUptime - measurementStart
            #endif
        }
        guard !Task.isCancelled else { return }
        open()
    }
    func homePresented() async {
        #if WEALTHY_LAUNCH_MEASUREMENT
        guard measurementSamples["HomeInteractive"] == nil else { return }
        #endif
        await DisplayFrameWaiter.wait()
        if let renderInterval { loadLog.endInterval("HomeRender", renderInterval); self.renderInterval = nil }
        if let interactiveInterval { loadLog.endInterval("HomeInteractive", interactiveInterval); self.interactiveInterval = nil }
        #if WEALTHY_LAUNCH_MEASUREMENT
        if let count = Self.measurementEntryCount {
            let now = ProcessInfo.processInfo.systemUptime
            measurementSamples["HomeInteractive"] = now - measurementStart
            if let start = measurementSamples.removeValue(forKey: "HomeRenderStart") { measurementSamples["HomeRender"] = now - start }
            measurementSamples["EntryCount"] = Double(count)
            measurementSamples["LaunchUptime"] = measurementStart
            do {
                let data = try JSONEncoder().encode(measurementSamples)
                try data.write(to: FileManager.default.temporaryDirectory.appendingPathComponent("Cycle2aLaunchMeasurement.json"), options: .atomic)
            } catch { print("LAUNCH_MEASUREMENT_WRITE_FAILED: \(error)") }
        }
        #endif
        #if DEBUG || WEALTHY_LAUNCH_MEASUREMENT
        if Self.isUITest && ProcessInfo.processInfo.arguments.contains("--measure-home-launch") {
            do { try MXMetricManager.finishExtendedLaunchMeasurement(forTaskID: MXLaunchTaskID("ledger-home-ready")) }
            catch { self.error = t("queryError"); print("EXTENDED_LAUNCH_FINISH_FAILED: \(error)") }
        }
        #endif
    }
    func open() {
        guard core == nil else { return }
        let interval = loadLog.beginInterval("LedgerOpen")
        defer { loadLog.endInterval("LedgerOpen", interval) }
        do {
            #if DEBUG || WEALTHY_LAUNCH_MEASUREMENT
            let isolated = Self.isUITest
            #else
            let isolated = false
            #endif
            #if DEBUG || WEALTHY_LAUNCH_MEASUREMENT
            let performance = isolated && ProcessInfo.processInfo.arguments.contains("--cycle2a-performance")
            let directory: URL?
            if let id = Self.testDiskID { directory = FileManager.default.temporaryDirectory.appendingPathComponent("Cycle2aOnboarding-" + id, isDirectory: true) }
            else if performance {
                let args = ProcessInfo.processInfo.arguments
                let size = args.firstIndex(of: "--entry-count").flatMap { $0 + 1 < args.count ? Int(args[$0 + 1]) : nil } ?? 50000
                directory = FileManager.default.temporaryDirectory.appendingPathComponent("Cycle2aPerformance-\(size)", isDirectory: true)
            } else { directory = nil }
            let storeInterval = loadLog.beginInterval("StoreOpen")
            #if WEALTHY_LAUNCH_MEASUREMENT
            let storeStart = ProcessInfo.processInfo.systemUptime
            #endif
            let store = try LedgerStore(inMemory: isolated && !performance && Self.testDiskID == nil, directory: directory)
            loadLog.endInterval("StoreOpen", storeInterval)
            #if WEALTHY_LAUNCH_MEASUREMENT
            measurementSamples["StoreOpen"] = ProcessInfo.processInfo.systemUptime - storeStart
            let snapshotStart = ProcessInfo.processInfo.systemUptime
            #endif
            let snapshotInterval = loadLog.beginInterval("Snapshot")
            core = try LedgerCore(store: store)
            loadLog.endInterval("Snapshot", snapshotInterval)
            #if WEALTHY_LAUNCH_MEASUREMENT
            measurementSamples["Snapshot"] = ProcessInfo.processInfo.systemUptime - snapshotStart
            #endif
            if performance { try preparePerformanceStore() }
            #else
            core = try LedgerCore(store: LedgerStore(inMemory: isolated))
            #endif
            #if DEBUG || WEALTHY_LAUNCH_MEASUREMENT
            if isolated && ProcessInfo.processInfo.arguments.contains("--cycle2a-seed") { try seedUITest() }
            if isolated && ProcessInfo.processInfo.arguments.contains("--cycle2b-seed") { try seedCycle2b() }
            if isolated && ProcessInfo.processInfo.arguments.contains("--cycle2b2-seed") { try seedQuickEntry() }
            #endif
            refresh()
            renderInterval = loadLog.beginInterval("HomeRender")
            #if WEALTHY_LAUNCH_MEASUREMENT
            measurementSamples["HomeRenderStart"] = ProcessInfo.processInfo.systemUptime
            #endif
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
    func input(_ amount: Int, code: String? = nil) -> String { (try? CoreCurrency.inputText(amount, currencyCode: code ?? currency, locale: locale)) ?? "" }
    func parse(_ text: String, code: String? = nil) throws -> Int {
        let currency = code ?? currency
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
    func formattedInput(_ text: String, code: String? = nil) -> String {
        guard let amount = try? parse(text, code: code) else { return text }
        return money(amount, code: code)
    }
    var commandDate: Date {
        #if DEBUG
        if Self.isUITest && (ProcessInfo.processInfo.arguments.contains("--cycle2a-seed") || ProcessInfo.processInfo.arguments.contains("--cycle2b-seed") || ProcessInfo.processInfo.arguments.contains("--cycle2b2-seed")) {
            return (try? today.date(calendar: .current)) ?? Date()
        }
        #endif
        return Date()
    }
    func run(_ command: LedgerCommand) throws {
        guard let core else { throw CoreError.saveFailed }
        try core.run(command, now: commandDate); refresh()
    }
    func perform(_ action: () throws -> Void) { do { try action() } catch { self.error = t("invalidInput") } }
    func refresh() {
        guard let core else { return }
        #if WEALTHY_LAUNCH_MEASUREMENT
        let queryStart = ProcessInfo.processInfo.systemUptime
        defer { measurementSamples["QuerySnapshot"] = ProcessInfo.processInfo.systemUptime - queryStart }
        #endif
        let interval = loadLog.beginInterval("QuerySnapshot")
        defer { loadLog.endInterval("QuerySnapshot", interval) }
        do {
            householdSummary = try LedgerQueries.islandSummary(in: core.state, today: today, envelopeID: EnvelopeValue.householdID, currencyCode: currency)
            safeLine = try LedgerQueries.safeLine(in: core.state, today: today, currencyCode: currency)
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
    #if DEBUG || WEALTHY_LAUNCH_MEASUREMENT
    private func seedQuickEntry() throws {
        onboarded = true
        if ProcessInfo.processInfo.arguments.contains("--quick-no-target") { return }
        guard core?.state.targets.isEmpty == true else { return }
        try run(.setTarget(TargetValue(currencyCode: "JPY", amountMinor: 310000, effectiveMonth: LedgerMonth(day: today))))
        if ProcessInfo.processInfo.arguments.contains("--quick-due-rule") {
            try run(.createRule(RuleValue(title: "Synthetic due today", amount: 1000, currencyCode: "JPY",
                                         schedule: .monthly(day: 7), startDay: today)))
        }
        if ProcessInfo.processInfo.arguments.contains("--quick-ranking"), let core {
            for (key, count, daysAgo) in [("catHobby", 3, 1), ("catTransport", 2, 29), ("catDaily", 2, 0), ("catClothing", 8, 30)] {
                guard let category = core.state.categories.first(where: { $0.systemKey == key }) else { continue }
                for _ in 0..<count {
                    try run(.addEntry(EntryValue(kind: .expense, amount: 1, currencyCode: "JPY", day: today.adding(days: -daysAgo, calendar: .current), categoryID: category.id)))
                }
            }
        }
        if ProcessInfo.processInfo.arguments.contains("--quick-safe-rule") {
            try run(.updateSettings(LedgerSettings(includeFixedCostsInTargets: true)))
            try run(.createRule(RuleValue(title: "Synthetic Thursday", amount: 2000, currencyCode: "JPY", isFixedCost: true,
                                         schedule: .weekly(weekday: 5), startDay: today.adding(days: 1, calendar: .current))))
        }
    }
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

    #if DEBUG
    func runIntentTestHook() async {
        let args = ProcessInfo.processInfo.arguments
        if Self.isUITest, args.contains("--run-intent-open-quick-add") { _ = try? await OpenQuickAddIntent().perform() }
        guard Self.isUITest, intentTestDialog == nil, let index = args.firstIndex(of: "--run-intent-record-expense"),
              index + 1 < args.count else { return }
        let categoryKey = index + 2 < args.count && !args[index + 2].hasPrefix("-") ? args[index + 2] : nil
        let key = "c2b2.intent." + (Self.testDiskID ?? "memory") + "." + args[index + 1] + "." + (categoryKey ?? "none")
        if Self.testDiskID != nil, let dialog = Self.preferences.string(forKey: key) { intentTestDialog = dialog; return }
        do {
            let intent = RecordExpenseIntent()
            intent.amount = args[index + 1]
            if let categoryKey {
                guard let category = expenseCategories.first(where: { $0.systemKey == categoryKey }) else { throw CoreError.invalidField("categoryID", nil) }
                intent.category = ExpenseCategoryEntity(id: category.id, name: categoryName(category))
            }
            let result = try await intent.perform()
            intentTestDialog = result.value
            if Self.testDiskID != nil { Self.preferences.set(intentTestDialog, forKey: key) }
        } catch { intentTestDialog = message(error) }
    }
    #endif

}
