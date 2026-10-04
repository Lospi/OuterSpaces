import AppKit
import Combine
import Intents
import Testing
@testable import Outer_Spaces

@MainActor
struct FocusSwitchingTests {
    private func snapshot(active: String = "1") -> ManagedDisplaySpacesSnapshot {
        let spaces = [Space(displayID: "main", spaceID: "1", spaceIndex: 0),
                      Space(displayID: "main", spaceID: "2", spaceIndex: 1)]
        return ManagedDisplaySpacesSnapshot(desktopSpaces: [], allSpaces: spaces,
                                           activeSpaceID: active, activeSpaceIDsByDisplay: ["main": active])
    }

    @Test("Script errors retain permission category and numeric code", arguments: [-1743, -1744, 1002, -1712])
    func scriptErrors(code: Int) {
        let error = SpaceSwitchError.scriptError(code: code, message: "failure")
        switch code {
        case -1743, -1744: #expect(error == .automationNotGranted(code))
        case 1002: #expect(error == .accessibilityNotGranted)
        default: #expect(error == .scriptFailed(code: code, message: "failure"))
        }
    }

    @Test("Switch failures propagate to the caller and clear after recovery", .bug("https://github.com/Lospi/OuterSpaces/issues/8"))
    func errorsPropagate() async throws {
        var current = snapshot()
        var permitted = false
        let target = current.allSpaces[1]
        let switcher = SpaceSwitcher(snapshot: { current }, accessibility: { permitted }, automation: { 0 },
                                     execute: { _ in current.activeSpaceIDsByDisplay["main"] = "2" },
                                     stageManager: { _ in }, wait: {})
        let handler = PermissionHandler()
        let settings = SettingsViewModel(switcher: switcher, permissions: handler)
        let preset = Focus(name: "Work", spaces: [target], stageManager: false)
        await #expect(throws: SpaceSwitchError.accessibilityNotGranted) {
            try await settings.updateSpacesOnScreen(focus: preset)
        }
        #expect(handler.showingPermissionAlert)
        permitted = true
        try await settings.updateSpacesOnScreen(focus: preset)
        #expect(handler.lastError == nil)
        #expect(handler.showingPermissionAlert == false)
    }

    @Test("Automation denial prevents sending a key")
    func automationDenied() async {
        let current = snapshot()
        var events = 0
        let switcher = SpaceSwitcher(snapshot: { current }, accessibility: { true }, automation: { -1743 },
                                     execute: { _ in events += 1 }, stageManager: { _ in }, wait: {})
        await #expect(throws: SpaceSwitchError.automationNotGranted(-1743)) {
            try await switcher.switchToSpace(current.allSpaces[1])
        }
        #expect(events == 0)
    }

    @Test("A delivered shortcut without a transition is a failure")
    func transitionMustComplete() async {
        let current = snapshot()
        let switcher = SpaceSwitcher(snapshot: { current }, accessibility: { true }, automation: { 0 },
                                     execute: { _ in }, stageManager: { _ in }, wait: {})
        await #expect(throws: SpaceSwitchError.transitionFailed("2")) {
            try await switcher.switchToSpace(current.allSpaces[1])
        }
    }

    @Test("Targets use current global order and reject missing saved targets")
    func freshTargets() throws {
        var current = snapshot()
        let external = Space(displayID: "external", displayIndex: 2, spaceID: "3", spaceIndex: 0)
        current.allSpaces.append(external)
        let resolved = try SpaceSwitcher.targets(for: [external], in: current)
        #expect(resolved.first?.1 == 2)
        var removed = external
        removed.spaceID = "missing"
        #expect(throws: SpaceSwitchError.invalidTarget("missing")) {
            try SpaceSwitcher.targets(for: [removed], in: current)
        }
    }

    @Test("Unknown status never applies the default; inactivity applies it once")
    func defaultTransitions() async throws {
        let suite = "FocusSwitchingTests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preset = Focus(name: "Default", spaces: snapshot().allSpaces, stageManager: false)
        defaults.set(preset.id.uuidString, forKey: Constants.StorageKeys.defaultPresetID)
        var status: (INFocusStatusAuthorizationStatus, Bool?) = (.authorized, nil)
        var applications = 0
        let model = FocusStatusViewModel(defaults: defaults, startsAutomatically: false,
                                        status: { status }, currentFilter: { nil }, presets: { [preset] },
                                        apply: { _, _ in applications += 1 })
        await model.refreshCurrentFilter()
        for _ in 0..<3 { await model.refreshActivity() }
        #expect(model.activity == .unknown)
        #expect(applications == 0)
        status = (.denied, false)
        await model.refreshActivity()
        #expect(applications == 0)
        status = (.authorized, false)
        await model.refreshActivity()
        await model.refreshActivity()
        #expect(applications == 1)
        status = (.authorized, true)
        await model.refreshActivity()
        status = (.authorized, false)
        await model.refreshActivity()
        #expect(applications == 2)
    }

    @Test("Mapped Focus takes precedence and intent failures are not swallowed")
    func mappedFocusPrecedence() async throws {
        let suite = "FocusSwitchingTests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preset = Focus(name: "Work", spaces: snapshot().allSpaces, stageManager: false)
        defaults.set(preset.id.uuidString, forKey: Constants.StorageKeys.defaultPresetID)
        let model = FocusStatusViewModel(defaults: defaults, startsAutomatically: false,
                                        status: { (.authorized, false) }, currentFilter: { preset.id }, presets: { [preset] },
                                        apply: { _, _ in throw SpaceSwitchError.accessibilityNotGranted })
        await model.refreshCurrentFilter()
        #expect(model.activePresetID == preset.id)
        await #expect(throws: SpaceSwitchError.accessibilityNotGranted) {
            try await model.receiveFilter(presetID: preset.id)
        }
    }

    @Test("Late configuration reads cannot overwrite a newer filter callback")
    func staleConfiguration() async throws {
        let suite = "FocusSwitchingTests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preset = Focus(name: "Work", spaces: snapshot().allSpaces, stageManager: false)
        var continuation: CheckedContinuation<UUID?, Never>?
        let model = FocusStatusViewModel(defaults: defaults, startsAutomatically: false,
                                        status: { (.authorized, true) },
                                        currentFilter: { await withCheckedContinuation { continuation = $0 } },
                                        presets: { [preset] }, apply: { _, _ in })
        let refresh = Task { await model.refreshCurrentFilter() }
        while continuation == nil { await Task.yield() }
        try await model.receiveFilter(presetID: preset.id)
        continuation?.resume(returning: nil)
        await refresh.value
        #expect(model.activePresetID == preset.id)
    }

    @Test("Active-only snapshots update the view model without replacing UI identity")
    func activeSnapshots() throws {
        let suite = "FocusSwitchingTests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var active = 1
        let observer = SpaceObserver(notificationCenter: NotificationCenter(), fetch: {
            [["Display Identifier": "main", "Current Space": ["ManagedSpaceID": active],
              "Spaces": [["ManagedSpaceID": 1, "type": 0], ["ManagedSpaceID": 2, "type": 0]]]] as [NSDictionary]
        })
        let model = SpacesViewModel(observer: observer, defaults: defaults)
        let initial = try model.refreshSnapshot()
        active = 2
        let next = try model.refreshSnapshot()
        #expect(next.activeSpaceIDsByDisplay["main"] == "2")
        #expect(model.allSpaces[1].isActive)
        #expect(model.allSpaces[0].id == initial.allSpaces[0].id)
    }

    @Test("The observer receives workspace-center notifications")
    func workspaceNotifications() async throws {
        let observer = SpaceObserver(debounce: .zero, fetch: {
            [["Display Identifier": "main", "Current Space": ["ManagedSpaceID": 1],
              "Spaces": [["ManagedSpaceID": 1, "type": 0]]]] as [NSDictionary]
        })
        let values = observer.$snapshot.compactMap { $0 }.values
        let result = Task { () -> String? in
            for await value in values { return value.activeSpaceID }
            return nil
        }
        // Run-loop debounce is an integration boundary; only this test uses real scheduling.
        NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
        let timeout = Task {
            try await Task.sleep(nanoseconds: 2_000_000_000)
            result.cancel()
        }
        let active = await result.value
        timeout.cancel()
        #expect(active == "1")
    }
}
