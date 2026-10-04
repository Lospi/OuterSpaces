import AppKit
import Combine
import Foundation

/// Connects system events to the independently testable return controller for the app's lifetime.
@MainActor
final class FocusReturnCoordinator: ObservableObject {
    static let shared = FocusReturnCoordinator()
    let controller: FocusReturnController
    private var subscriptions = Set<AnyCancellable>()
    private var timer: Timer?
    private var timerTask: Task<Void, Never>?

    private init() {
        let status = FocusStatusViewModel.shared
        let spaces = SpacesViewModel.shared
        let presets = FocusViewModel.shared
        controller = FocusReturnController(
            readSnapshot: { try spaces.refreshSnapshot() },
            readSession: { await status.refreshCurrentFilter(); return status.filterState },
            apply: { focus, isCurrent in
                try await SettingsViewModel.shared.updateSpacesOnScreen(focus: focus, onlyInactive: true, isCurrent: isCurrent)
            },
            report: { PermissionHandler.shared.handleSpaceSwitchError($0) }
        )
        guard !Constants.isRunningTests else { return }
        status.$filterState.combineLatest(presets.$availableFocusPresets, spaces.$snapshot)
            .sink { [weak self] session, presets, snapshot in
                self?.controller.update(session: session, presets: presets, snapshot: snapshot)
            }
            .store(in: &subscriptions)
        let workspace = NSWorkspace.shared.notificationCenter
        workspace.publisher(for: NSWorkspace.willSleepNotification).sink { [weak self] _ in
            Task { @MainActor in self?.controller.prepareForSleep() }
        }.store(in: &subscriptions)
        workspace.publisher(for: NSWorkspace.didWakeNotification).sink { [weak self] _ in
            Task { @MainActor in await self?.controller.reloadAfterWake() }
        }.store(in: &subscriptions)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.timerTask == nil else { return }
                self.timerTask = Task { [weak self] in
                    await self?.controller.tick()
                    self?.timerTask = nil
                }
            }
        }
        Task { await controller.reloadAfterWake() }
    }

    deinit { timer?.invalidate(); timerTask?.cancel() }
}
