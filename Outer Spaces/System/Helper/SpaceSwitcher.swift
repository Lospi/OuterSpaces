import Foundation

enum SpaceSwitchError: Error, LocalizedError {
    case invalidSpaceID
    case switchFailed
    case accessibilityNotGranted

    var errorDescription: String? {
        switch self {
        case .invalidSpaceID:
            return "Invalid space ID — unable to convert to numeric identifier"
        case .switchFailed:
            return "Failed to switch space via CGS API"
        case .accessibilityNotGranted:
            return "Accessibility permission is required to switch spaces"
        }
    }
}

enum SpaceSwitcher {
    /// Switches a single space on its display via the CGS private API.
    static func switchToSpace(_ space: Space) throws {
        guard let numericID = Int(space.spaceID) else {
            Logger.shared.logError("Invalid spaceID: \(space.spaceID)")
            throw SpaceSwitchError.invalidSpaceID
        }

        let conn = _CGSDefaultConnection()
        let displayID = space.displayID as CFString

        Logger.shared.logInfo("Switching display \(space.displayID) to space \(numericID)")
        CGSManagedDisplaySetCurrentSpace(conn, displayID, numericID)
    }

    /// Applies a full preset — switches one space per display, handles Stage Manager.
    /// Returns `true` if an error occurred (matches existing convention in SettingsViewModel).
    @MainActor
    static func applyPreset(_ focus: Focus) -> Bool {
        let permissionHandler = PermissionHandler.shared
        permissionHandler.checkAccessibilityPermission()

        guard permissionHandler.hasAccessibilityPermission else {
            Logger.shared.logWarning("Accessibility permission not granted — cannot switch spaces")
            permissionHandler.handleSpaceSwitchError(
                SpaceSwitchError.accessibilityNotGranted.localizedDescription
            )
            return true
        }

        // Group by displayID — last space per display wins
        var spacesByDisplay: [String: Space] = [:]
        for space in focus.spaces {
            spacesByDisplay[space.displayID] = space
        }

        for (_, space) in spacesByDisplay {
            do {
                try switchToSpace(space)
            } catch {
                Logger.shared.logError("Failed to switch space: \(error.localizedDescription)")
                permissionHandler.handleSpaceSwitchError(error.localizedDescription)
                return true
            }
        }

        applyStageManager(enabled: focus.stageManager)
        return false
    }

    /// Sets the Stage Manager state via `defaults write` (no Automation permission needed).
    static func applyStageManager(enabled: Bool) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["write", "com.apple.WindowManager", "GloballyEnabled", "-bool", enabled ? "true" : "false"]

        do {
            try process.run()
            process.waitUntilExit()
            Logger.shared.logInfo("Stage Manager set to \(enabled)")
        } catch {
            Logger.shared.logError("Failed to set Stage Manager: \(error.localizedDescription)")
        }
    }
}
