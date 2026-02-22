import Foundation

class Logger {
    static let shared = Logger()

    private init() {}

    func logInfo(_ message: String) {
        log(level: "INFO", message: message)
    }

    func logError(_ message: String) {
        log(level: "ERROR", message: message)
    }

    func logWarning(_ message: String) {
        log(level: "WARNING", message: message)
    }

    private func log(level: String, message: String) {
        #if DEBUG
        print("[\(level)] \(Date()): \(message)")
        #endif
    }
}
