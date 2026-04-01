import SwiftUI

@main
struct MumblerApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(appState: appState)
        } label: {
            Image(systemName: appState.isRecording ? "mic.fill" : "mic")
        }
        .menuBarExtraStyle(.window)
    }
}
