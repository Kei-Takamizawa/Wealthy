import SwiftUI
import WealthyCore

struct LedgerRoot: View {
    @Environment(LedgerSession.self) private var session
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var actualType
    var body: some View {
        @Bindable var session = session
        Group {
            if !session.available { NoAIView() }
            else if session.core == nil { ProgressView(session.t("loading")).accessibilityIdentifier("ledgerLoading").accessibilityAddTraits(.updatesFrequently).task { if UIAccessibility.isVoiceOverRunning { UIAccessibility.post(notification: .announcement, argument: session.t("loading")) }; await session.openAfterPresentation() } }
            else if !session.onboarded { OnboardingView() }
            else { mainContent }
        }
        .environment(\.dynamicTypeSize, LedgerSession.isUITest ? (ProcessInfo.processInfo.arguments.contains("--ax3") ? .accessibility3 : .large) : actualType)
        .preferredColorScheme(LedgerSession.isUITest ? (ProcessInfo.processInfo.arguments.contains("--dark") ? .dark : .light) : nil)
        .tint(V4.primary(scheme))
        .alert(session.t("error"), isPresented: Binding(get: { session.error != nil }, set: { if !$0 { session.error = nil } })) {
            Button(session.t("ok")) { session.error = nil }
        } message: { Text(session.error ?? "") }
    }
    @ViewBuilder private var mainContent: some View {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if LedgerSession.isUITest, let position = args.firstIndex(of: "--screen"), args.count > position + 1 {
            NavigationStack {
                switch args[position + 1] {
                case "goals": GoalsView(envelopeID: session.envelopeID)
                case "edit": EntryEditor(entry: session.core?.state.entries.first)
                case "tax": TaxView()
                case "child-setup": ChildSetupView()
                case "child-detail": ChildDetailView()
                case "settings": SettingsView()
                case "result": if let status = session.summary?.week { ResultView(status: status) }
                case "month-result": if let status = session.summary?.month { ResultView(status: status) }
                case "no-ai": NoAIView(reasonOverride: "ineligible")
                case "voice": VoiceView()
                case "info", "info-child": InfoView(showResult: { _ in })
                default: LedgerTabs()
                }
            }
        } else { LedgerTabs() }
        #else
        LedgerTabs()
        #endif
    }

}
struct NoAIView: View {
    var reasonOverride: String? = nil
    @Environment(LedgerSession.self) private var session
    @Environment(\.openURL) private var openURL
    var body: some View {
        Form {
            Section {
                Image(systemName: "sparkles").font(.largeTitle).accessibilityHidden(true)
                Text(session.t("noAI")).font(.headline)
                Text(session.t(reasonOverride ?? session.readiness))
                Text(session.t("noAIDetail"))
            }
            Section(session.t("language")) { LanguagePicker() }
            Section {
                Button(session.t("checkAgain")) { session.refreshAvailability(); session.open() }
                Button(session.t("openSettings")) { if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) } }
            }
        }
        .navigationTitle(session.t("noAI"))
    }
}
struct LanguagePicker: View {
    @Environment(LedgerSession.self) private var session
    var body: some View {
        @Bindable var session = session
        Picker(session.t("language"), selection: $session.language) {
            Text("English").tag("en"); Text("日本語").tag("ja"); Text("Español").tag("es"); Text("한국어").tag("ko")
        }.pickerStyle(.menu).frame(minHeight: 44).accessibilityIdentifier("language")
    }
}
struct CurrencyPicker: View {
    @Environment(LedgerSession.self) private var session
    var body: some View {
        @Bindable var session = session
        Picker(session.t("currency"), selection: $session.currency) { ForEach(["JPY", "USD", "EUR", "KRW"], id: \.self) { Text($0).tag($0) } }.frame(minHeight: 44).accessibilityIdentifier("currency")
    }
}
struct OnboardingView: View {
    @Environment(LedgerSession.self) private var session
    @Environment(\.colorScheme) private var scheme
    @State private var step = 0
    @State private var amount = ""
    @State private var child = false
    private let titles = ["onboardLanguage", "onboardCurrency", "onboardTarget", "onboardChild"]
    var body: some View {
        Form {
            Section {
                IslandScene(growth: 0, festivals: 0, dusk: false).frame(height: 180).accessibilityHidden(true)
                Text(session.t(titles[step])).font(.title2.weight(.semibold)).frame(maxWidth: .infinity, alignment: .leading)
                Text("\(step + 1) / 4")
            }
            Section {
                if step == 0 { LanguagePicker() }
                if step == 1 { CurrencyPicker() }
                if step == 2 {
                    Text(session.t("monthlyTarget"))
                    MoneyInputField(text: $amount, label: session.t("amount"), identifier: "onboardingAmount", font: .system(.largeTitle, design: .rounded).monospacedDigit())
                    Text(session.t("notBalance")).font(.footnote)
                    Text(session.t("fixedOff"))
                }
                if step == 3 { Toggle(session.t("useChild"), isOn: $child); Text(session.t("childExplanation")) }
            }
            Section {
                HStack {
                    if step > 0 { Button(session.t("back")) { step -= 1 }.frame(minHeight: 44) }
                    Spacer()
                    Button(session.t(step == 3 ? "start" : "next")) {
                        if step == 3 { session.perform { try session.completeOnboarding(amount: amount, child: child) } }
                        else { step += 1 }
                    }.buttonStyle(.borderedProminent).accessibilityIdentifier("onboardingNext")
                }
            }
        }.scrollDismissesKeyboard(.interactively).navigationTitle(session.t(titles[step]))
    }
}
struct LedgerTabs: View {
    @Environment(LedgerSession.self) private var session
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    private var reduce: Bool { systemReduce || (LedgerSession.isUITest && ProcessInfo.processInfo.arguments.contains("--reduce-motion")) }
    @Environment(\.colorScheme) private var scheme
    @State private var page = 1
    @State private var result: TargetStatus?
    @State private var resultQueue: [TargetStatus] = []
    @State private var lastResults: [TargetStatus] = []
    private func move(_ destination: Int) {
        guard (0...2).contains(destination) else { return }
        withAnimation(reduce ? nil : .easeInOut(duration: 0.2)) { page = destination }
    }
    private func swipeGesture(for index: Int) -> some Gesture {
        DragGesture(minimumDistance: 80)
            .onEnded { value in
                guard !UIAccessibility.isVoiceOverRunning,
                      abs(value.translation.width) > abs(value.translation.height) * 1.6,
                      abs(value.translation.width) > 100 else { return }
                move(index + (value.translation.width < 0 ? 1 : -1))
            }
    }
    var body: some View {
        NavigationStack {
            TabView(selection: $page) {
                VoiceView().tabItem { Label(session.t("voice"), systemImage: "mic") }.tag(0)
                    .simultaneousGesture(swipeGesture(for: 0))
                HomeView(showResult: { result = $0 }).tabItem { Label(session.t("home"), systemImage: "house") }.tag(1)
                    .simultaneousGesture(swipeGesture(for: 1))
                InfoView(showResult: { result = $0 }).tabItem { Label(session.t("info"), systemImage: "info.circle") }.tag(2)
                    .simultaneousGesture(swipeGesture(for: 2))
            }
            .accessibilityIdentifier("mainTabs")
            .navigationTitle(session.t(["voice", "home", "info"][page]))
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: Binding(get: { result != nil }, set: { if !$0 { result = nil } }), onDismiss: {
                if !resultQueue.isEmpty { result = resultQueue.removeFirst() }
            }) { if let result { ResultView(status: result).presentationDetents([.medium, .large]).presentationDragIndicator(.visible) } }
            .onChange(of: session.recentResults, initial: true) { _, results in
                let changed = results.filter { $0.isSet && !lastResults.contains($0) }
                lastResults = results
                if !changed.isEmpty { resultQueue = changed; if result == nil { result = resultQueue.removeFirst() } }
            }
        }
    }
}
struct VoiceView: View {
    @Environment(LedgerSession.self) private var session
    var body: some View {
        Form {
            Section {
                IslandScene(growth: session.householdSummary?.days.filter(\.hasGrowth).count ?? 0, festivals: session.householdSummary?.festivals ?? 0, dusk: false)
                    .frame(height: 220).accessibilityHidden(true)
                Text(session.t("voiceLater")).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationTitle(session.t("voice"))
        .accessibilityIdentifier("voiceScreen")
    }
}
