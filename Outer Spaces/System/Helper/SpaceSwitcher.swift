import Foundation

enum SpaceSwitchError: Error, LocalizedError {
    case invalidSpaceIndex
    case switchFailed(String)
    case accessibilityNotGranted

    var errorDescription: String? {
        switch self {
        case .invalidSpaceIndex:
            return "Invalid space index — no key code mapped for this index"
        case .switchFailed(let detail):
            return "Failed to switch space: \(detail)"
        case .accessibilityNotGranted:
            return "Accessibility permission is required to switch spaces"
        }
    }
}

enum SpaceSwitcher {
    // Maps (spaceIndex + 1) % 10 → macOS key code for that digit key
    private static let keycodeDictionary: [Int: Int] = [
        0: 29, 1: 18, 2: 19, 3: 20, 4: 21,
        5: 23, 6: 22, 7: 26, 8: 28, 9: 25
    ]

    /// Switches a space using Control+N keyboard simulation via System Events.
    /// This goes through the standard macOS Mission Control transition, giving proper animations.
    /// Spaces 0–8 use Control+1…9; spaces 9–18 use Control+Option+1…9.
    static func switchToSpace(_ space: Space) throws {
        let index = space.spaceIndex
        guard let keycode = keycodeDictionary[(index + 1) % 10] else {
            Logger.shared.logError("No key code for spaceIndex \(index)")
            throw SpaceSwitchError.invalidSpaceIndex
        }

        let useOptionKey = index >= 9
        let script = makeSpaceSwitchScript(keycode: keycode, useOptionKey: useOptionKey)

        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else {
            throw SpaceSwitchError.switchFailed("Failed to create AppleScript")
        }
        appleScript.executeAndReturnError(&error)

        if let errorDict = error,
           let message = errorDict["NSAppleScriptErrorMessage"] as? String
        {
            Logger.shared.logError("AppleScript error switching to space \(index): \(message)")
            throw SpaceSwitchError.switchFailed(message)
        }

        Logger.shared.logInfo("Switched to spaceIndex \(index) on display \(space.displayID)")
    }

    private static func makeSpaceSwitchScript(keycode: Int, useOptionKey: Bool) -> String {
        if useOptionKey {
            return """
            tell application "System Events"
                key code \(keycode) using {control down, option down}
            end tell
            """
        } else {
            return """
            tell application "System Events"
                key code \(keycode) using {control down}
            end tell
            """
        }
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

    /// Sets the Stage Manager state via `defaults write`.
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
