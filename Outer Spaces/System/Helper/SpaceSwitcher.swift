import Carbon
import Cocoa

// Preserve AppleScript codes so permission recovery never depends on translated error text.
enum SpaceSwitchError: Error, LocalizedError, Equatable {
    case invalidSpaceIndex
    case invalidTarget(String)
    case snapshotUnavailable
    case accessibilityNotGranted
    case automationNotGranted(Int)
    case scriptFailed(code: Int, message: String)
    case transitionFailed(String)
    case stageManagerFailed(Int)

    static func scriptError(code: Int, message: String) -> SpaceSwitchError {
        switch code {
        case -1743, -1744: return .automationNotGranted(code)
        case 1002: return .accessibilityNotGranted
        default: return .scriptFailed(code: code, message: message)
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidSpaceIndex: return String(localized: "Only Desktop shortcuts 1–19 are supported.")
        case .invalidTarget(let id): return String(localized: "A preset target is unavailable. Refresh Spaces and edit the preset.") + " (\(id))"
        case .snapshotUnavailable: return String(localized: "The current desktop layout could not be read.")
        case .accessibilityNotGranted: return String(localized: "Allow Outer Spaces in Privacy & Security → Accessibility.")
        case .automationNotGranted(let code): return String(localized: "Allow Outer Spaces to control System Events in Privacy & Security → Automation.") + " (\(code))"
        case .scriptFailed(let code, let message): return "\(message) (\(code))"
        case .transitionFailed(let id): return String(localized: "The desktop did not change. Check the Mission Control keyboard shortcuts.") + " (\(id))"
        case .stageManagerFailed(let code): return String(localized: "Stage Manager could not be updated.") + " (\(code))"
        }
    }
}

@MainActor
final class SpaceSwitcher {
    static let shared = SpaceSwitcher()
    private var operationRevision = 0
    private let snapshot: @MainActor () async throws -> ManagedDisplaySpacesSnapshot
    private let accessibility: @MainActor () -> Bool
    private let automation: @MainActor () -> Int
    private let execute: @MainActor (String) throws -> Void
    private let stageManager: @MainActor (Bool) throws -> Void
    private let wait: @MainActor () async throws -> Void

    init(snapshot: @escaping @MainActor () async throws -> ManagedDisplaySpacesSnapshot = { try SpacesViewModel.shared.refreshSnapshot() },
         accessibility: @escaping @MainActor () -> Bool = { AXIsProcessTrusted() },
         automation: @escaping @MainActor () -> Int = { PermissionHandler.automationStatus(prompt: false) },
         execute: @escaping @MainActor (String) throws -> Void = { try SpaceSwitcher.executeScript($0) },
         stageManager: @escaping @MainActor (Bool) throws -> Void = { try SpaceSwitcher.applyStageManager(enabled: $0) },
         wait: @escaping @MainActor () async throws -> Void = { try await Task.sleep(nanoseconds: 100_000_000) }) {
        self.snapshot = snapshot
        self.accessibility = accessibility
        self.automation = automation
        self.execute = execute
        self.stageManager = stageManager
        self.wait = wait
    }

    static func targets(for spaces: [Space], in snapshot: ManagedDisplaySpacesSnapshot) throws -> [(Space, Int)] {
        guard !spaces.isEmpty else { throw SpaceSwitchError.invalidTarget("empty preset") }
        var displays = Set<String>()
        return try spaces.map { saved in
            guard let index = snapshot.allSpaces.firstIndex(where: {
                $0.spaceID == saved.spaceID && $0.displayID == saved.displayID
            }), displays.insert(saved.displayID).inserted else {
                throw SpaceSwitchError.invalidTarget(saved.spaceID)
            }
            _ = try SpaceSwitchCommandFactory.command(forSpaceIndex: index)
            return (snapshot.allSpaces[index], index)
        }.sorted { $0.1 < $1.1 }
    }

    func applyPreset(_ focus: Focus, onlyInactive: Bool = false,
                     isCurrent: @escaping @MainActor () -> Bool = { true }) async throws {
        try await switchSpaces(focus.spaces, isCurrent: isCurrent)
        guard isCurrent(), !Task.isCancelled else { throw CancellationError() }
        if !onlyInactive { try stageManager(focus.stageManager) }
    }

    func switchToSpace(_ space: Space) async throws {
        try await switchSpaces([space], isCurrent: { true })
    }

    private func switchSpaces(_ spaces: [Space], isCurrent: @escaping @MainActor () -> Bool) async throws {
        operationRevision += 1
        let revision = operationRevision
        let callerIsCurrent = isCurrent
        let isCurrent = { self.operationRevision == revision && callerIsCurrent() }
        let initial = try await snapshot()
        let targets = try Self.targets(for: spaces, in: initial)
        guard isCurrent(), !Task.isCancelled else { throw CancellationError() }
        if targets.contains(where: { initial.activeSpaceIDsByDisplay[$0.0.displayID] != $0.0.spaceID }) {
            guard accessibility() else { throw SpaceSwitchError.accessibilityNotGranted }
            let status = automation()
            guard status == 0 else { throw SpaceSwitchError.automationNotGranted(status) }
        }
        for (target, _) in targets {
            // Re-resolve after each transition; a display or Space can disappear during an await.
            let current = try await snapshot()
            guard let (freshTarget, index) = try Self.targets(for: [target], in: current).first else {
                throw SpaceSwitchError.invalidTarget(target.spaceID)
            }
            guard isCurrent(), !Task.isCancelled else { throw CancellationError() }
            if current.activeSpaceIDsByDisplay[freshTarget.displayID] == freshTarget.spaceID { continue }
            try execute(SpaceSwitchCommandFactory.command(forSpaceIndex: index).appleScriptSource)
            var reachedTarget = false
            for _ in 0..<20 {
                try await wait()
                let updated = try await snapshot()
                guard isCurrent(), !Task.isCancelled else { throw CancellationError() }
                if updated.activeSpaceIDsByDisplay[freshTarget.displayID] == freshTarget.spaceID {
                    reachedTarget = true
                    break
                }
            }
            guard reachedTarget else { throw SpaceSwitchError.transitionFailed(freshTarget.spaceID) }
        }
    }

    static func executeScript(_ source: String) throws {
        guard let script = NSAppleScript(source: source) else {
            throw SpaceSwitchError.scriptFailed(code: -1, message: "Could not create AppleScript")
        }
        var error: NSDictionary?
        script.executeAndReturnError(&error)
        if let error {
            let code = (error[NSAppleScript.errorNumber] as? NSNumber)?.intValue ?? -1
            let message = error[NSAppleScript.errorMessage] as? String ?? "AppleScript failed"
            throw SpaceSwitchError.scriptError(code: code, message: message)
        }
    }

    static func applyStageManager(enabled: Bool) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["write", "com.apple.WindowManager", "GloballyEnabled", "-bool", enabled ? "true" : "false"]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw SpaceSwitchError.stageManagerFailed(Int(process.terminationStatus)) }
    }
}
