import SwiftUI

@main struct WealthyApp: App {
    @State private var session = LedgerSession()
    @Environment(\.scenePhase) private var phase
    var body: some Scene {
        WindowGroup {
            LedgerRoot().environment(session).environment(\.locale, session.locale)
                .onChange(of: phase) { _, phase in
                    if phase == .active { session.refreshAvailability(); if session.core != nil { session.reload() } }
                }
        }
    }
}
