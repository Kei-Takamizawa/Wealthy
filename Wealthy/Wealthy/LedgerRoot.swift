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
            else if session.core == nil { ProgressView().task { session.open() } }
            else if !session.onboarded { OnboardingView() }
            else { mainContent }
        }
        .environment(\.dynamicTypeSize, LedgerSession.isUITest ? (ProcessInfo.processInfo.arguments.contains("--ax3") ? .accessibility3 : .large) : actualType)
        .preferredColorScheme(LedgerSession.isUITest ? (ProcessInfo.processInfo.arguments.contains("--dark") ? .dark : .light) : nil)
        .foregroundStyle(V4.ink(scheme)).tint(V4.primary(scheme))
        .background(V4.paper(scheme).ignoresSafeArea())
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
                case "voice": VoiceView(toInfo: {}, toIsland: {})
                case "info", "info-child": InfoView(toIsland: {}, showResult: { _ in })
                default: LedgerPager()
                }
            }
        } else { LedgerPager() }
        #else
        LedgerPager()
        #endif
    }

}
struct NoAIView: View {
    var reasonOverride: String? = nil
    @Environment(LedgerSession.self) private var session
    @Environment(\.openURL) private var openURL
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "sparkles").font(.system(size: 56)).accessibilityHidden(true)
                Text(session.t("noAI")).font(V4.heading(session.language)).multilineTextAlignment(.center)
                Plate { VStack(alignment: .leading, spacing: 16) { Text(session.t(reasonOverride ?? session.readiness)); Text(session.t("noAIDetail")) } }
                LanguagePicker()
                Button(session.t("checkAgain")) { session.refreshAvailability(); session.open() }.buttonStyle(PrimaryButton())
                Button(session.t("openSettings")) { if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) } }.frame(minHeight: 44)
            }.padding(24)
        }
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
        Picker(session.t("currency"), selection: $session.currency) { ForEach(["JPY", "USD", "EUR", "KRW"], id: \.self) { Text($0).tag($0) } }.frame(minHeight: 44)
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
        ScrollView {
            VStack(spacing: 24) {
                IslandScene(growth: 0, festivals: 0, dusk: false).frame(height: 180).accessibilityHidden(true)
                Text(session.t(titles[step])).font(V4.heading(session.language)).frame(maxWidth: .infinity, alignment: .leading)
                Text("\(step + 1) / 4").foregroundStyle(V4.ink2(scheme))
                Plate {
                    VStack(alignment: .leading, spacing: 20) {
                        if step == 0 { LanguagePicker() }
                        if step == 1 { CurrencyPicker() }
                        if step == 2 {
                            Text(session.t("monthlyTarget"))
                            TextField(session.t("amount"), text: $amount).keyboardType(.decimalPad).font(.system(.largeTitle, design: .rounded).monospacedDigit()).accessibilityIdentifier("onboardingAmount")
                            Text(session.t("notBalance")).font(.footnote)
                            Text(session.t("fixedOff"))
                        }
                        if step == 3 { Toggle(session.t("useChild"), isOn: $child).frame(minHeight: 52); Text(session.t("childExplanation")) }
                    }
                }
                HStack {
                    if step > 0 { Button(session.t("back")) { step -= 1 }.frame(minHeight: 44) }
                    Spacer()
                    Button(session.t(step == 3 ? "start" : "next")) {
                        if step == 3 { session.perform { try session.completeOnboarding(amount: amount, child: child) } }
                        else { step += 1 }
                    }.buttonStyle(PrimaryButton()).accessibilityIdentifier("onboardingNext")
                }
            }.padding(24)
        }.scrollDismissesKeyboard(.interactively)
    }
}
struct LedgerPager: View {
    @Environment(LedgerSession.self) private var session
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    private var reduce: Bool { systemReduce || (LedgerSession.isUITest && ProcessInfo.processInfo.arguments.contains("--reduce-motion")) }
    @Environment(\.colorScheme) private var scheme
    @Namespace private var pages
    @State private var page = 1
    @State private var result: TargetStatus?
    @State private var resultQueue: [TargetStatus] = []
    @State private var lastResults: [TargetStatus] = []
    func move(_ destination: Int) { withAnimation(reduce ? nil : .spring(duration: 0.4, bounce: 0)) { page = destination } }
    var body: some View {
        NavigationStack {
            TabView(selection: $page) {
                VoiceView(toInfo: { move(2) }, toIsland: { move(1) }).tag(0).accessibilityLabel(session.t("voice")).accessibilityRotorEntry(id: 0, in: pages)
                HomeView(toVoice: { move(0) }, toInfo: { move(2) }, showResult: { result = $0 }).tag(1).accessibilityLabel(session.t("home")).accessibilityRotorEntry(id: 1, in: pages)
                InfoView(toIsland: { move(1) }, showResult: { result = $0 }).tag(2).accessibilityLabel(session.t("info")).accessibilityRotorEntry(id: 2, in: pages)
            } .tabViewStyle(.page(indexDisplayMode: .never)).background(V4.paper(scheme))
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    HStack(spacing: 0) {
                        ForEach(0..<3) { index in
                            Button { move(index) } label: {
                                Circle().fill(page == index ? V4.ink(scheme) : .clear)
                                    .overlay(Circle().stroke(V4.ink2(scheme), lineWidth: 1.5))
                                    .frame(width: 8, height: 8).frame(width: 44, height: 44).contentShape(Rectangle())
                            }.accessibilityIdentifier("page-\(index)").accessibilityLabel(session.t(["voice", "home", "info"][index]))
                                .accessibilityAddTraits(page == index ? .isSelected : [])
                        }
                    }.frame(maxWidth: .infinity).background(V4.paper(scheme))
                }
                .accessibilityAction(named: Text(session.t("voice"))) { move(0) }
                .accessibilityAction(named: Text(session.t("home"))) { move(1) }
                .accessibilityAction(named: Text(session.t("info"))) { move(2) }
                .accessibilityAction(.escape) { move(1) }
                .accessibilityRotor(session.t("pages")) {
                    AccessibilityRotorEntry(Text(session.t("voice")), id: 0, in: pages) { move(0) }
                    AccessibilityRotorEntry(Text(session.t("home")), id: 1, in: pages) { move(1) }
                    AccessibilityRotorEntry(Text(session.t("info")), id: 2, in: pages) { move(2) }
                }
                .sheet(isPresented: Binding(get: { result != nil }, set: { if !$0 { result = nil } }), onDismiss: {
                    if !resultQueue.isEmpty { result = resultQueue.removeFirst() }
                }) { if let result { ResultView(status: result) } }
                .onChange(of: session.recentResults, initial: true) { _, results in
                    let changed = results.filter { $0.isSet && !lastResults.contains($0) }
                    lastResults = results
                    if !changed.isEmpty { resultQueue = changed; if result == nil { result = resultQueue.removeFirst() } }
                }
        }
    }
}
struct VoiceView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorScheme) private var scheme
    @Environment(LedgerSession.self) private var session
    let toInfo: () -> Void
    let toIsland: () -> Void
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                GlassEffectContainer {
                    let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout())
                    layout { Button(action: toIsland) { Pill(text: session.t("toIsland"), icon: "chevron.left") }; if !typeSize.isAccessibilitySize { Spacer() }; Button(action: toInfo) { Pill(text: session.t("info"), icon: "chevron.right") }.accessibilityIdentifier("voiceInfo") }
                }
                IslandScene(growth: session.summary?.days.filter(\.hasGrowth).count ?? 0, festivals: session.summary?.festivals ?? 0, dusk: false).frame(height: 280).blur(radius: 14).accessibilityHidden(true)
                Text(session.t("voice")).font(V4.heading(session.language))
                Plate { Text(session.t("voiceLater")).frame(maxWidth: .infinity).multilineTextAlignment(.center) }
                Label(session.t("microphoneUnavailable"), systemImage: "mic.slash").padding(24).modifier(V4Glass()).accessibilityIdentifier("voicePlaceholder")
            }.padding(16)
        }.background(V4.paper(scheme))
    }
}
