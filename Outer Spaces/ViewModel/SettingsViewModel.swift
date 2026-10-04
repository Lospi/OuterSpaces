import Foundation

@MainActor
class SettingsViewModel {
    static let shared = SettingsViewModel()
    private let switcher: SpaceSwitcher
    private let permissions: PermissionHandler

    init(switcher: SpaceSwitcher? = nil, permissions: PermissionHandler? = nil) {
        self.switcher = switcher ?? .shared
        self.permissions = permissions ?? .shared
    }

    func updateSpacesOnScreen(focus: Focus, onlyInactive: Bool = false,
                              isCurrent: @escaping @MainActor () -> Bool = { true }) async throws {
        do {
            try await switcher.applyPreset(focus, onlyInactive: onlyInactive, isCurrent: isCurrent)
            permissions.clearError()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            permissions.handleSpaceSwitchError(error)
            throw error
        }
    }

    func switchToSpace(_ space: Space, stageManager: Bool?) async throws {
        do {
            try await switcher.switchToSpace(space)
            if let stageManager { try SpaceSwitcher.applyStageManager(enabled: stageManager) }
            permissions.clearError()
        } catch {
            permissions.handleSpaceSwitchError(error)
            throw error
        }
    }
}
