import HotKey
import Carbon

class HotkeyService {
    private var hotKey: HotKey?

    var onToggle: (() -> Void)?
    var onKeyUp: (() -> Void)?

    func register() {
        // Option+Space as the global hotkey
        hotKey = HotKey(key: .space, modifiers: [.option])

        hotKey?.keyDownHandler = { [weak self] in
            self?.onToggle?()
        }

        hotKey?.keyUpHandler = { [weak self] in
            self?.onKeyUp?()
        }
    }

    func unregister() {
        hotKey = nil
    }
}
