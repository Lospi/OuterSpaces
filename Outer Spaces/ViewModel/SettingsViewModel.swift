import Foundation

@MainActor
class SettingsViewModel {
    var selectedFocusPresetId: UUID?
    var errorMessage: String?

    static let shared = SettingsViewModel()

    func updateSpacesOnScreen(focus: Focus) async throws -> Bool {
        return applyPresetToScreen(focus: focus)
    }

    func updateSpacesOnScreen(focus: Focus) -> Bool {
        return applyPresetToScreen(focus: focus)
    }

    private func applyPresetToScreen(focus: Focus) -> Bool {
        Logger.shared.logInfo("Updating spaces on screen for focus: \(focus.name)")
        let didError = SpaceSwitcher.applyPreset(focus)
        if didError {
            errorMessage = PermissionHandler.shared.lastError
        }
        return didError
    }
}
