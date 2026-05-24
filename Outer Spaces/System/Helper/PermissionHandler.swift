import Cocoa
import SwiftUI

@MainActor
class PermissionHandler: ObservableObject {
    @Published var hasAccessibilityPermission = false
    @Published var showingPermissionAlert = false
    @Published var lastError: String?

    static let shared = PermissionHandler()

    private var permissionPollTimer: Timer?

    private init() {
        checkAccessibilityPermission()
    }

    func checkAccessibilityPermission() {
        var accessEnabled = AXIsProcessTrusted()

        // Fallback: AXIsProcessTrusted() can return false on some macOS versions
        // even when access is granted (stale TCC entry). Verify with a real AX call.
        if !accessEnabled {
            accessEnabled = verifyAccessibilityByAttempt()
        }

        hasAccessibilityPermission = accessEnabled
        if accessEnabled {
            stopPolling()
        } else {
            startPollingIfNeeded()
        }
    }

    /// Attempts an actual AX operation to verify accessibility permission.
    private func verifyAccessibilityByAttempt() -> Bool {
        let systemWide = AXUIElementCreateSystemWide()
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedApplicationAttribute as CFString,
            &value
        )
        // .apiDisabled means accessibility is definitely not granted
        return result != .apiDisabled
    }

    private func startPollingIfNeeded() {
        guard permissionPollTimer == nil else { return }
        permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkAccessibilityPermission()
            }
        }
    }

    private func stopPolling() {
        permissionPollTimer?.invalidate()
        permissionPollTimer = nil
    }

    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): kCFBooleanTrue] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
            self.requestAccessibilityPermission()
        } else {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security")!)
            self.requestAccessibilityPermission()
        }
    }

    func handleSpaceSwitchError(_ message: String) {
        self.lastError = message
        self.showingPermissionAlert = true
        Logger.shared.logError("Space switch error: \(message)")
    }
}

struct AccessibilityPermissionModifier: ViewModifier {
    @ObservedObject private var permissionHandler = PermissionHandler.shared

    func body(content: Content) -> some View {
        content
            .alert("Accessibility Permission Required", isPresented: self.$permissionHandler.showingPermissionAlert) {
                Button("Open Settings", action: self.permissionHandler.openAccessibilitySettings)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("""
                Outer Spaces needs accessibility permissions to switch spaces.

                Please go to System Settings → Privacy & Security → Accessibility and enable Outer Spaces.

                Error: \(self.permissionHandler.lastError ?? "")
                """)
            }
    }
}

extension View {
    func withAccessibilityPermissionHandling() -> some View {
        modifier(AccessibilityPermissionModifier())
    }
}
