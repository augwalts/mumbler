import SwiftUI

struct MumblerWindowView: View {
    @ObservedObject var appState: AppState
    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: 0) {
            // Big record button
            Button(action: { appState.toggleRecording() }) {
                ZStack {
                    Circle()
                        .fill(appState.isRecording ? Color.red : Color.primary.opacity(0.08))
                        .frame(width: 72, height: 72)

                    // Pulse ring when recording
                    if appState.isRecording {
                        Circle()
                            .stroke(Color.red.opacity(0.3), lineWidth: 3)
                            .frame(width: 72, height: 72)
                            .scaleEffect(isPulsing ? 1.5 : 1.0)
                            .opacity(isPulsing ? 0 : 0.8)
                            .animation(
                                .easeOut(duration: 1.0).repeatForever(autoreverses: false),
                                value: isPulsing
                            )
                    }

                    Image(systemName: appState.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(appState.isRecording ? .white : .primary)
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 20)
            .onChange(of: appState.isRecording) { _, recording in
                isPulsing = recording
            }
            .onAppear {
                isPulsing = appState.isRecording
            }

            // Status text
            Text(appState.statusMessage)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(statusColor)
                .padding(.top, 10)

            // Live transcript preview
            if appState.isRecording && !appState.currentTranscript.isEmpty {
                Text(appState.currentTranscript)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .transition(.opacity)
            }

            Divider()
                .padding(.top, 16)
                .padding(.bottom, 0)

            // Last transcript
            if !appState.lastTranscript.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Last transcript")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Copy") {
                            appState.pasteService.copyToClipboard(appState.lastTranscript)
                            appState.statusMessage = "Copied!"
                        }
                        .font(.system(size: 10))
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    }
                    Text(appState.lastTranscript)
                        .font(.system(size: 11))
                        .lineLimit(3)
                        .truncationMode(.tail)
                        .textSelection(.enabled)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

                Divider()
            }

            // Settings + Quit
            VStack(spacing: 0) {
                Toggle("Auto-paste after recording", isOn: $appState.autoPaste)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 11))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)

                Divider()

                Button("Check Permissions...") {
                    Task { _ = await Permissions.requestAll() }
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)

                Divider()

                Button("Quit Mumbler") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 240)
        .animation(.easeInOut(duration: 0.2), value: appState.isRecording)
        .animation(.easeInOut(duration: 0.15), value: appState.currentTranscript.isEmpty)
    }

    private var statusColor: Color {
        switch appState.statusMessage {
        case "Recording...": return .red
        case "Pasted!", "Copied": return .green
        case let s where s.starts(with: "Error"): return .orange
        default: return .secondary
        }
    }
}
