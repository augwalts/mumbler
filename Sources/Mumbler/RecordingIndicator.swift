import SwiftUI
import AppKit

// MARK: - SwiftUI View

struct RecordingIndicatorView: View {
    @ObservedObject var appState: AppState

    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 10) {
            // Pulsing red dot
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
                .opacity(isPulsing ? 0.4 : 1.0)
                .animation(
                    .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                    value: isPulsing
                )
                .onAppear { isPulsing = true }

            VStack(alignment: .leading, spacing: 2) {
                Text("Recording...")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)

                if !appState.currentTranscript.isEmpty {
                    Text(appState.currentTranscript)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(width: Constants.indicatorWidth)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - NSPanel Wrapper

class RecordingIndicatorPanel {
    private var panel: NSPanel?
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func showIndicator() {
        if panel == nil {
            createPanel()
        }
        panel?.orderFrontRegardless()
    }

    func hideIndicator() {
        panel?.orderOut(nil)
    }

    private func createPanel() {
        let hostingView = NSHostingView(rootView: RecordingIndicatorView(appState: appState))
        hostingView.frame = NSRect(
            x: 0, y: 0,
            width: Constants.indicatorWidth,
            height: Constants.indicatorHeight
        )

        let panel = NSPanel(
            contentRect: NSRect(
                x: 0, y: 0,
                width: Constants.indicatorWidth,
                height: Constants.indicatorHeight
            ),
            styleMask: [.nonactivatingPanel, .hudWindow, .utilityWindow],
            backing: .buffered,
            defer: false
        )

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

        // Position: top-center of the screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - Constants.indicatorWidth / 2
            let y = screenFrame.maxY - Constants.indicatorHeight - 10
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.panel = panel
    }
}
