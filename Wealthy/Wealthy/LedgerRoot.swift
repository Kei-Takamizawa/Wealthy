import SwiftUI
import WealthyCore

struct LedgerRoot: View {
    @Environment(LedgerSession.self) private var session
    @Environment(\.colorScheme) private var scheme
    @State private var presented: LedgerPresentation?
    @State private var presentingRecurring = false
    @State private var resultQueue: [TargetStatus] = []
    @State private var lastResults: [TargetStatus] = []
    var body: some View {
        @Bindable var session = session
        Group {
            if !session.available { NoAIView() }
            else if session.core == nil { ProgressView(session.t("loading")).accessibilityIdentifier("ledgerLoading").accessibilityAddTraits(.updatesFrequently).task { if UIAccessibility.isVoiceOverRunning { UIAccessibility.post(notification: .announcement, argument: session.t("loading")) }; await session.openAfterPresentation() } }
            else if !session.onboarded { OnboardingView() }
            else { mainContent }
        }
        .preferredColorScheme(LedgerSession.isUITest ? (ProcessInfo.processInfo.arguments.contains("--dark") ? .dark : .light) : nil)
        .tint(V4.primary(scheme))
        .task(id: session.core != nil) { if session.core != nil { await session.catchUpAfterPresentation() } }
        .sheet(item: $presented, onDismiss: {
            if presentingRecurring { session.dismissRecurringNotice() }
            presentingRecurring = false
            presentNext()
        }) { presentation in
            if let result = presentation.result {
                ResultView(status: result).presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
            } else { NavigationStack { RecurringNoticeView() }.tint(V4.primary(scheme)) }
        }
        .onChange(of: session.showRecurringNotice) { _, showing in
            if showing { presentNext() }
            else if presentingRecurring { presented = nil }
        }
        .onChange(of: session.recentResults, initial: true) { _, results in
            let changed = results.filter { $0.isSet && !lastResults.contains($0) }
            lastResults = results
            if !changed.isEmpty { resultQueue = changed; presentNext() }
        }

        .alert(session.t("error"), isPresented: Binding(get: { session.error != nil }, set: { if !$0 { session.error = nil } })) {
            Button(session.t("ok")) { session.error = nil }
        } message: { Text(session.error ?? "") }
    }
    private func presentNext() {
        guard presented == nil else { return }
        if !resultQueue.isEmpty { presented = LedgerPresentation(result: resultQueue.removeFirst()) }
        else if session.showRecurringNotice { presentingRecurring = true; presented = LedgerPresentation(result: nil) }
    }
    @ViewBuilder private var mainContent: some View {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if LedgerSession.isUITest, let position = args.firstIndex(of: "--screen"), args.count > position + 1 {
            NavigationStack {
                switch args[position + 1] {
                case "fixed-costs": FixedCostsView(envelopeID: session.envelopeID)
                case "rule-form": RuleEditor(rule: nil, envelopeID: session.envelopeID)
                case "calendar": CalendarView(envelopeID: session.envelopeID)
                case "analysis": AnalysisView(envelopeID: session.envelopeID)
                case "day-detail": DayDetailView(day: try! LedgerDay(year: 2026, month: 10, day: 8), envelopeID: session.envelopeID)
                case "catch-up": Color.clear
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
                default: LedgerTabs(isPresenting: presented != nil, showResult: { presented = LedgerPresentation(result: $0) })
                }
            }
        } else { LedgerTabs(isPresenting: presented != nil, showResult: { presented = LedgerPresentation(result: $0) }) }
        #else
        LedgerTabs(isPresenting: presented != nil, showResult: { presented = LedgerPresentation(result: $0) })
        #endif
    }

}
private struct LedgerPresentation: Identifiable {
    let id = UUID()
    let result: TargetStatus?
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
    @FocusState private var amountFocused: Bool
    private let titles = ["onboardLanguage", "onboardCurrency", "onboardTarget", "onboardChild"]
    var body: some View {
        Form {
            Section {
                if step != 2 || !amountFocused {
                    IslandScene(growth: 0, festivals: 0, dusk: false).frame(height: 180).accessibilityHidden(true)
                        .transition(.opacity)
                }
                Text(session.t(titles[step])).font(.title2.weight(.semibold)).frame(maxWidth: .infinity, alignment: .leading)
                Text("\(step + 1) / 4")
            }
            Section {
                if step == 0 { LanguagePicker() }
                if step == 1 { CurrencyPicker() }
                if step == 2 {
                    Text(session.t("monthlyTarget"))
                    MoneyInputField(text: $amount, label: session.t("amount"), identifier: "onboardingAmount", font: .system(.largeTitle, design: .rounded).monospacedDigit(), focus: $amountFocused)
                    Text(session.t("notBalance")).font(.footnote)
                    Text(session.t("fixedOff"))
                }
                if step == 3 { Toggle(session.t("useChild"), isOn: $child); Text(session.t("childExplanation")) }
            }
        }.animation(.default, value: amountFocused).scrollDismissesKeyboard(.interactively).safeAreaInset(edge: .bottom) {
                HStack {
                    if step > 0 { Button(session.t("back")) { step -= 1 }.frame(minHeight: 44) }
                    Spacer()
                    Button(session.t(step == 3 ? "start" : "next")) {
                        if step == 3 { session.perform { try session.completeOnboarding(amount: amount, child: child) } }
                        else { step += 1 }
                    }.buttonStyle(.borderedProminent).accessibilityIdentifier("onboardingNext")
                }
                .padding()
                .background(.bar)
        }.navigationTitle(session.t(titles[step]))
    }
}
struct LedgerTabs: View {
    @Environment(LedgerSession.self) private var session
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    private var reduce: Bool { systemReduce || (LedgerSession.isUITest && ProcessInfo.processInfo.arguments.contains("--reduce-motion")) }
    @Environment(\.colorScheme) private var scheme
    @State private var page = 1
    let isPresenting: Bool
    let showResult: (TargetStatus) -> Void
    private func move(_ destination: Int) {
        guard (0...2).contains(destination) else { return }
        withAnimation(reduce ? nil : .easeInOut(duration: 0.2)) { page = destination }
    }
    private func rootSwipe(_ index: Int) -> RootTabSwipeModifier {
        RootTabSwipeModifier(enabled: page == index && !isPresenting && session.error == nil) { direction in move(page + direction) }
    }
    var body: some View {
        TabView(selection: $page) {
            NavigationStack { VoiceView().modifier(rootSwipe(0)) }
                .tabItem { Label(session.t("voice"), systemImage: "mic") }.tag(0)
            NavigationStack { HomeView(showResult: showResult).modifier(rootSwipe(1)) }
                .tabItem { Label(session.t("home"), systemImage: "house") }.tag(1)
            NavigationStack { InfoView(showResult: showResult).modifier(rootSwipe(2)) }
                .tabItem { Label(session.t("info"), systemImage: "info.circle") }.tag(2)
        }
        .accessibilityIdentifier("mainTabs")
        .toolbarBackground(.visible, for: .tabBar)

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

private struct RootTabSwipeModifier: ViewModifier {
    let enabled: Bool
    let move: (Int) -> Void
    @State private var visible = false
    func body(content: Content) -> some View {
        content.gesture(RootTabSwipe(enabled: enabled && visible, move: move))
            .onAppear { visible = true }
            .onDisappear { visible = false }
    }
}

/// Installed on the three root pages, never on their NavigationStacks or destinations.
private struct RootTabSwipe: UIGestureRecognizerRepresentable {
    let enabled: Bool
    let move: (Int) -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator(converter: converter) }
    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.maximumNumberOfTouches = 1
        pan.cancelsTouchesInView = false
        pan.delegate = context.coordinator
        return pan
    }
    func updateUIGestureRecognizer(_ pan: UIPanGestureRecognizer, context: Context) {
        pan.isEnabled = enabled && !UIAccessibility.isVoiceOverRunning
    }
    func handleUIGestureRecognizerAction(_ pan: UIPanGestureRecognizer, context: Context) {
        guard pan.state == .ended, enabled, !UIAccessibility.isVoiceOverRunning,
              context.coordinator.canNavigate(in: context.coordinator.window) else { return }
        guard let delta = context.converter.translation(in: .global) else { return }
        guard abs(delta.x) >= 80, abs(delta.x) > abs(delta.y) * 2 else { return }
        move(delta.x < 0 ? 1 : -1)
    }
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var window: UIWindow?
        let converter: CoordinateSpaceConverter
        init(converter: CoordinateSpaceConverter) { self.converter = converter }
        func canNavigate(in window: UIWindow?) -> Bool {
            guard let window, !UIAccessibility.isVoiceOverRunning else { return false }
            func hasFocus(_ view: UIView) -> Bool {
                view.isFirstResponder || view.subviews.contains(where: hasFocus)
            }
            func hasPresentation(_ controller: UIViewController) -> Bool {
                controller.presentedViewController != nil || controller.children.contains(where: hasPresentation)
            }
            return !hasFocus(window) && !(window.rootViewController.map(hasPresentation) ?? true)
        }
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            window = touch.view?.window
            guard canNavigate(in: window) else { return false }
            var view = touch.view
            while let current = view {
                // Include SwiftUI controls exposed through accessibility, as well as UIKit controls.
                if current is UIControl || current is UITextView || current is UITextField ||
                    current.accessibilityTraits.contains(.button) || current.accessibilityTraits.contains(.adjustable) {
                    return false
                }
                view = current.superview
            }
            return true
        }
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard gestureRecognizer is UIPanGestureRecognizer,
                  canNavigate(in: window) else { return false }
            guard let velocity = converter.velocity(in: .global) else { return false }
            return abs(velocity.x) > abs(velocity.y) * 2
        }
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }
    }
}
