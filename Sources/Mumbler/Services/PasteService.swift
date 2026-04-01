import AppKit
import CoreGraphics

class PasteService {
    private var savedClipboard: String?

    func pasteText(_ text: String) {
        let pasteboard = NSPasteboard.general

        // Save current clipboard
        savedClipboard = pasteboard.string(forType: .string)

        // Set transcript to clipboard
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Small delay to ensure pasteboard write commits, then simulate Cmd+V
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.pasteDelay) { [weak self] in
            self?.simulateCmdV()

            // Restore previous clipboard after paste completes
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.clipboardRestoreDelay) { [weak self] in
                if let previous = self?.savedClipboard {
                    pasteboard.clearContents()
                    pasteboard.setString(previous, forType: .string)
                }
                self?.savedClipboard = nil
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
        let source = CGEventSource(stateID: .hidSystemState)

        // Virtual key code 0x09 = 'v'
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
