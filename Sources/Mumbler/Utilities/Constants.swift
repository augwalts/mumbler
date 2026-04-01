import Foundation

enum Constants {
    static let appName = "Mumbler"
    static let bundleIdentifier = "com.augustine.mumbler"

    // UserDefaults keys
    static let holdToRecordKey = "holdToRecord"
    static let autoPasteKey = "autoPaste"

    // Clipboard restore delay after paste (seconds)
    static let clipboardRestoreDelay: TimeInterval = 0.5
    // Delay before simulating Cmd+V (seconds)
    static let pasteDelay: TimeInterval = 0.05

    // Recording indicator window size
    static let indicatorWidth: CGFloat = 280
    static let indicatorHeight: CGFloat = 60
}
