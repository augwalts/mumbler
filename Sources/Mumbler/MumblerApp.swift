import SwiftUI

@main
struct MumblerApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MumblerWindowView(appState: appState)
        } label: {
            Image(systemName: appState.isRecording ? "mic.fill" : "mic")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(appState.isRecording ? .red : .primary)
        }
        .menuBarExtraStyle(.window)
    }
}
