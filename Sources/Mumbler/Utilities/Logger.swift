import Foundation

enum Log {
    private static func timestamp() -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: Date())
    }

    static func info(_ message: String) {
        print("[\(timestamp())] \(message)")
    }

    static func error(_ message: String) {
        print("[\(timestamp())] ERROR: \(message)")
    }
}
