import SwiftUI

@main
struct MumblerApp: App {
    @NSApplicationDelegateAdaptor(MumblerAppDelegate.self) var delegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(appState: appState)
                .onAppear {
                    // Ensure setup runs (idempotent)
                    if !appState.isSetUp {
                        appState.setup()
                    }
                }
        } label: {
            Image(systemName: appState.isRecording ? "mic.fill" : "mic")
        }
        .menuBarExtraStyle(.window)
    }
}

class MumblerAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // App is agent-only (no dock icon) — handled by Info.plist LSUIElement
    }
}
