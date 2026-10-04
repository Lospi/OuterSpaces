import AppIntents
import Intents
import SwiftUI
import UserNotifications

enum FocusActivity: Equatable {
    case active, inactive, unknown
    static func resolve(authorized: Bool, focused: Bool?) -> Self {
        guard authorized, let focused else { return .unknown }
        return focused ? .active : .inactive
    }
}

enum FocusFilterState: Equatable {
    case unknown, unconfigured, preset(UUID)
    var presetID: UUID? {
        if case .preset(let id) = self { return id }
        return nil
    }
}

@MainActor
class FocusStatusViewModel: ObservableObject {
    static let shared = FocusStatusViewModel(startsAutomatically: !Constants.isRunningTests)
    @Published private(set) var activity: FocusActivity = .unknown
    @Published private(set) var filterState: FocusFilterState = .unknown
    @Published private(set) var defaultPresetID: UUID?
    @Published var focusAuthorizationStatus: INFocusStatusAuthorizationStatus = .notDetermined
    var activePresetID: UUID? { filterState.presetID }
    var isFocusActive: Bool { activePresetID != nil || activity == .active }
    private(set) var filterRevision = 0
    private var refreshID: UUID?
    private var lastDefaultAttempt: UUID?
    private var focusTimer: Timer?
    private var focusPollInFlight = false
    private var lastMappedApplicationID: UUID?
    private let defaults: UserDefaults
    private let status: @MainActor () -> (INFocusStatusAuthorizationStatus, Bool?)
    private let currentFilter: @MainActor () async throws -> UUID?
    private let presets: @MainActor () -> [Focus]
    private let apply: @MainActor (Focus, @escaping @MainActor () -> Bool) async throws -> Void

    init(defaults: UserDefaults = .standard, startsAutomatically: Bool = true,
         status: @escaping @MainActor () -> (INFocusStatusAuthorizationStatus, Bool?) = {
             let center = INFocusStatusCenter.default
             return (center.authorizationStatus, center.focusStatus.isFocused)
         },
         currentFilter: @escaping @MainActor () async throws -> UUID? = {
             try await SpacesFocusFilter.current.spaceFilterPreset?.id
         },
         presets: @escaping @MainActor () -> [Focus] = { FocusViewModel.shared.availableFocusPresets },
         apply: @escaping @MainActor (Focus, @escaping @MainActor () -> Bool) async throws -> Void = { focus, isCurrent in
             try await SettingsViewModel.shared.updateSpacesOnScreen(focus: focus, isCurrent: isCurrent)
         }) {
        self.defaults = defaults
        self.status = status
        self.currentFilter = currentFilter
        self.presets = presets
        self.apply = apply
        defaultPresetID = defaults.string(forKey: Constants.StorageKeys.defaultPresetID).flatMap(UUID.init(uuidString:))
        if startsAutomatically {
            startFocusTimer()
            Task { await pollFocus() }
        }
    }

    deinit { focusTimer?.invalidate() }

    @discardableResult
    func refreshCurrentFilter() async -> Bool {
        let request = UUID()
        refreshID = request
        let revision = filterRevision
        do {
            let id = try await currentFilter()
            guard refreshID == request, filterRevision == revision else { return false }
            setFilterState(id.map(FocusFilterState.preset) ?? .unconfigured)
            if id == nil { lastMappedApplicationID = nil }
            await refreshActivity()
            return true
        } catch {
            guard refreshID == request, filterRevision == revision else { return false }
            setFilterState(.unknown)
            Logger.shared.logError("Could not read current Focus filter: \(error)")
            return false
        }
    }

    func receiveFilter(presetID: UUID?) async throws {
        // Every callback invalidates in-flight configuration reads, even duplicate callbacks.
        filterRevision += 1
        refreshID = nil
        setFilterState(presetID.map(FocusFilterState.preset) ?? .unconfigured)
        lastMappedApplicationID = presetID
        guard let presetID else { await refreshActivity(); return }
        try await applyMappedPreset(presetID)
    }

    private func applyMappedPreset(_ presetID: UUID) async throws {
        guard let focus = presets().first(where: { $0.id == presetID }) else {
            let error = SpaceSwitchError.invalidTarget(presetID.uuidString)
            PermissionHandler.shared.handleSpaceSwitchError(error)
            throw error
        }
        let revision = filterRevision
        try await apply(focus, { [weak self] in
            self?.filterRevision == revision && self?.activePresetID == presetID
        })
    }

    /// Reconcile with the supported current-filter API when a system callback is missed.
    /// A failed switch is attempted once per observed mapping, never on every poll.
    func pollFocus() async {
        guard !focusPollInFlight else { return }
        focusPollInFlight = true
        defer { focusPollInFlight = false }
        guard await refreshCurrentFilter(), let presetID = activePresetID,
              lastMappedApplicationID != presetID else { return }
        lastMappedApplicationID = presetID
        do {
            try await applyMappedPreset(presetID)
        } catch is CancellationError {
            Logger.shared.logInfo("Recovered Focus application cancelled after Focus changed")
        } catch {
            Logger.shared.logError("Recovered Focus application failed: \(error)")
        }
    }

    private func setFilterState(_ state: FocusFilterState) {
        if filterState != state {
            filterRevision += 1
            lastDefaultAttempt = nil
            filterState = state
        }
    }

    func refreshActivity() async {
        let (authorization, focused) = status()
        focusAuthorizationStatus = authorization
        let next = FocusActivity.resolve(authorized: authorization == .authorized, focused: focused)
        if activity != next {
            activity = next
            if next != .inactive { lastDefaultAttempt = nil }
        }
        await applyDefaultPresetIfNeeded()
    }

    func setDefaultPreset(id: UUID?) {
        defaultPresetID = id
        defaults.set(id?.uuidString, forKey: Constants.StorageKeys.defaultPresetID)
        lastDefaultAttempt = nil
        Task { await applyDefaultPresetIfNeeded() }
    }

    private func applyDefaultPresetIfNeeded() async {
        guard activity == .inactive, filterState == .unconfigured,
              let id = defaultPresetID, lastDefaultAttempt != id,
              let preset = presets().first(where: { $0.id == id }) else { return }
        lastDefaultAttempt = id
        let revision = filterRevision
        do {
            try await apply(preset, { [weak self] in
                guard let self else { return false }
                return self.filterRevision == revision && self.activity == .inactive
                    && self.filterState == .unconfigured && self.defaultPresetID == id
            })
        } catch is CancellationError {
            Logger.shared.logInfo("Default preset cancelled after Focus changed")
        } catch { Logger.shared.logError("Default preset failed: \(error)") }
    }

    func requestFocusAuthorization() {
        INFocusStatusCenter.default.requestAuthorization { [weak self] _ in
            Task { @MainActor in await self?.refreshActivity() }
        }
    }

    func startFocusTimer() {
        stopFocusTimer()
        focusTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.pollFocus() }
        }
    }

    func stopFocusTimer() { focusTimer?.invalidate(); focusTimer = nil }
}

extension FocusStatusViewModel {
    /// Request authorization for both focus status and notifications
    func requestAuthorizations() {
        requestFocusAuthorization()
        requestNotificationAuthorization()
    }

    /// Request authorization for user notifications
    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            Task { @MainActor in
                if !granted {
                    if let error = error {
                        Logger.shared.logError("Notification authorization error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    /// Sends a notification when a preset is applied
    func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.shared.logError("Error sending notification: \(error.localizedDescription)")
            }
        }
    }

}
