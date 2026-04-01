import SwiftUI
import AppKit

// MARK: - SwiftUI View

struct MumblerPanelView: View {
    @ObservedObject var appState: AppState

    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 12) {
            // Big record/stop button
            Button(action: { appState.toggleRecording() }) {
                ZStack {
                    Circle()
                        .fill(appState.isRecording ? Color.red : Color.white.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(
                                    appState.isRecording ? Color.red.opacity(0.4) : Color.white.opacity(0.3),
                                    lineWidth: appState.isRecording ? 6 : 1.5
                                )
                                .scaleEffect(isPulsing && appState.isRecording ? 1.4 : 1.0)
                                .opacity(isPulsing && appState.isRecording ? 0 : 1)
                                .animation(
                                    appState.isRecording
                                        ? .easeOut(duration: 1.0).repeatForever(autoreverses: false)
                                        : .default,
                                    value: isPulsing
                                )
                        )

                    Image(systemName: appState.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .onChange(of: appState.isRecording) { _, recording in
                isPulsing = recording
            }

            // Status + transcript
            VStack(alignment: .leading, spacing: 3) {
                Text(appState.statusMessage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                if appState.isRecording && !appState.currentTranscript.isEmpty {
                    Text(appState.currentTranscript)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .transition(.opacity)
                } else if !appState.isRecording && !appState.lastTranscript.isEmpty
                            && appState.statusMessage != "Ready" {
                    Text(appState.lastTranscript)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .transition(.opacity)
                } else {
                    Text("tap to record")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.35))
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.leading, 10)
        .padding(.trailing, 14)
        .frame(width: Constants.indicatorWidth, height: Constants.indicatorHeight)
        .background(
            RoundedRectangle(cornerRadius: Constants.indicatorHeight / 2)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Constants.indicatorHeight / 2)
                .stroke(
                    appState.isRecording ? Color.red.opacity(0.5) : Color.white.opacity(0.12),
                    lineWidth: 1
                )
        )
        .animation(.easeInOut(duration: 0.2), value: appState.isRecording)
    }
}

// MARK: - NSPanel Wrapper

class MumblerPanel {
    private var panel: NSPanel?
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func show() {
        if panel == nil {
            createPanel()
        }
        panel?.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func createPanel() {
        let w = Constants.indicatorWidth
        let h = Constants.indicatorHeight

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: w, height: h),
            styleMask: [.nonactivatingPanel, .hudWindow, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        let hostingView = NSHostingView(rootView: MumblerPanelView(appState: appState))
        hostingView.frame = NSRect(x: 0, y: 0, width: w, height: h)

        panel.contentView = hostingView
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true

        // Position: top-right of the screen (near menu bar)
        if let screen = NSScreen.main {
            let sf = screen.visibleFrame
            let x = sf.maxX - w - 16
            let y = sf.maxY - h - 10
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.panel = panel
    }
}
