import AppKit
import CoreGraphics

class PasteService {
    private var savedClipboard: String?
    private var isPasting = false

    func pasteText(_ text: String) {
        guard !isPasting else {
            Log.info("Paste skipped — previous paste still in-flight")
            return
        }
        isPasting = true

        let pasteboard = NSPasteboard.general

        // Save current clipboard
        savedClipboard = pasteboard.string(forType: .string)

        // Set transcript to clipboard
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        Log.info("Clipboard set with transcript (\(text.count) chars)")

        // Small delay to ensure pasteboard write commits, then simulate Cmd+V
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.pasteDelay) { [weak self] in
            self?.simulateCmdV()

            // Restore previous clipboard after paste completes
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.clipboardRestoreDelay) { [weak self] in
                if let previous = self?.savedClipboard {
                    pasteboard.clearContents()
                    pasteboard.setString(previous, forType: .string)
                    Log.info("Clipboard restored")
                }
                self?.savedClipboard = nil
                self?.isPasting = false
            }
        }
    }

    /// Copy text to clipboard without auto-pasting
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func simulateCmdV() {
        guard Permissions.accessibilityGranted else {
            Log.error("Cmd+V failed — Accessibility permission not granted")
            return
        }

        let source = CGEventSource(stateID: .hidSystemState)

        // Virtual key code 0x09 = 'v'
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            Log.error("Cmd+V failed — could not create CGEvent")
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        Log.info("Cmd+V simulated")
    }
}
