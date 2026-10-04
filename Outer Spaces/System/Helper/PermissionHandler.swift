import Carbon
import Cocoa
import SwiftUI

@MainActor
class PermissionHandler: ObservableObject {
    @Published var hasAccessibilityPermission = false
    @Published var showingPermissionAlert = false
    @Published private(set) var lastError: String?
    @Published private(set) var switchError: SpaceSwitchError?
    static let shared = PermissionHandler()

    init() { checkAccessibilityPermission() }

    func checkAccessibilityPermission() { hasAccessibilityPermission = AXIsProcessTrusted() }

    static func automationStatus(prompt: Bool) -> Int {
        let target = NSAppleEventDescriptor(bundleIdentifier: "com.apple.systemevents")
        return Int(AEDeterminePermissionToAutomateTarget(target.aeDesc, typeWildCard, typeWildCard, prompt))
    }

    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): kCFBooleanTrue] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    func openAccessibilitySettings() {
        openSettings("Privacy_Accessibility")
        requestAccessibilityPermission()
    }

    func openAutomationSettings() {
        _ = Self.automationStatus(prompt: true)
        openSettings("Privacy_Automation")
    }

    private func openSettings(_ pane: String) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)") else { return }
        NSWorkspace.shared.open(url)
    }

    func handleSpaceSwitchError(_ error: Error) {
        let typed = error as? SpaceSwitchError ?? .scriptFailed(code: -1, message: error.localizedDescription)
        switchError = typed
        lastError = typed.localizedDescription
        showingPermissionAlert = true
        Logger.shared.logError("Space switch failed: \(typed)")
        checkAccessibilityPermission()
    }

    func clearError() {
        switchError = nil
        lastError = nil
        showingPermissionAlert = false
    }
}

struct AccessibilityPermissionModifier: ViewModifier {
    @ObservedObject private var handler = PermissionHandler.shared

    func body(content: Content) -> some View {
        content.alert("Space Switching Error", isPresented: $handler.showingPermissionAlert) {
            switch handler.switchError {
            case .accessibilityNotGranted:
                Button("Open Accessibility Settings", action: handler.openAccessibilitySettings)
            case .automationNotGranted:
                Button("Allow Automation", action: handler.openAutomationSettings)
            case .transitionFailed, .invalidSpaceIndex:
                Button("Open Keyboard Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.keyboard?Shortcuts") {
                        NSWorkspace.shared.open(url)
                    }
                }
            default: EmptyView()
            }
            Button("OK", role: .cancel) {}
        } message: { Text(handler.lastError ?? "") }
    }
}

extension View {
    func withAccessibilityPermissionHandling() -> some View { modifier(AccessibilityPermissionModifier()) }
}
