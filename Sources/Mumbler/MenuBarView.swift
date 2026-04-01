import SwiftUI

struct MenuBarView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Status
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(appState.statusMessage)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Record / Stop button
            Button(action: { appState.toggleRecording() }) {
                HStack {
                    Image(systemName: appState.isRecording ? "stop.circle.fill" : "record.circle")
                        .foregroundColor(appState.isRecording ? .red : .primary)
                    Text(appState.isRecording ? "Stop Recording" : "Start Recording")
                    Spacer()
                    Text("\u{2325}Space")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            Divider()

            // Last transcript
            if !appState.lastTranscript.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last transcript:")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(appState.lastTranscript)
                        .font(.system(size: 11))
                        .lineLimit(3)
                        .truncationMode(.tail)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Button("Copy Last Transcript") {
                    appState.pasteService.copyToClipboard(appState.lastTranscript)
                    appState.statusMessage = "Copied!"
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)

                Divider()
            }

            // Settings
            Toggle("Auto-paste", isOn: $appState.autoPaste)
                .toggleStyle(.checkbox)
                .font(.system(size: 11))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)

            Toggle("Hold to record", isOn: $appState.holdToRecord)
                .toggleStyle(.checkbox)
                .font(.system(size: 11))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)

            Divider()

            // Permissions
            Button("Check Permissions...") {
                Task { await Permissions.requestAll() }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            Divider()

            // Quit
            Button("Quit Mumbler") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .keyboardShortcut("q", modifiers: .command)
        }
        .frame(width: 260)
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        if appState.isRecording { return .red }
        if appState.statusMessage.starts(with: "Error") { return .orange }
        if appState.statusMessage == "Pasted!" || appState.statusMessage == "Copied" { return .green }
        return .gray
    }
}
