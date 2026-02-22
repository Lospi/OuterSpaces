import AppKit
import LaunchAtLogin
import SFSafeSymbols
import Sparkle
import SwiftUI
import UniformTypeIdentifiers // For UTType
import UserNotifications // For UNUserNotificationCenter

enum SettingsTab: String, CaseIterable {
    case general
    case advanced
    case about

    var title: String {
        switch self {
        case .general: return "General"
        case .advanced: return "Advanced"
        case .about: return "About"
        }
    }

    var symbol: SFSymbol {
        switch self {
        case .general: return .gearshape
        case .advanced: return .wrenchAndScrewdriver
        case .about: return .infoCircle
        }
    }
}

struct SettingsView: View {
    @ObservedObject var spacesViewModel: SpacesViewModel
    @ObservedObject private var permissionHandler = PermissionHandler.shared
    @ObservedObject var focusViewModel: FocusViewModel
    @ObservedObject var focusStatusViewModel: FocusStatusViewModel
    @Environment(\.openWindow) var openWindow
    @State private var isDisplayingShortcutsPanel = false
    @State private var showResetConfirmation = false
    @State private var activeTab: SettingsTab = .general

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    TabButton(title: tab.title, systemSymbol: tab.symbol, isActive: activeTab == tab) {
                        activeTab = tab
                    }
                }
            }
            .padding(.horizontal)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch activeTab {
                    case .general:
                        GeneralSettingsView(
                            permissionHandler: permissionHandler,
                            focusStatusViewModel: focusStatusViewModel,
                            isDisplayingShortcutsPanel: $isDisplayingShortcutsPanel
                        )
                    case .advanced:
                        AdvancedSettingsView(
                            showResetConfirmation: $showResetConfirmation,
                            spacesViewModel: spacesViewModel,
                            focusViewModel: focusViewModel,
                            focusStatusViewModel: focusStatusViewModel
                        )
                    case .about:
                        AboutSettingsView()
                    }
                }
                .padding()
                .animation(.easeInOut, value: activeTab)
            }
        }
        .frame(width: 600, height: 500)
        .sheet(isPresented: $isDisplayingShortcutsPanel) {
            ShortcutsPanel(isPresented: $isDisplayingShortcutsPanel)
                .frame(width: 500, height: 400)
        }
        .alert("Reset Outer Spaces?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetAllSettings()
            }
        } message: {
            Text("This will reset all your spaces, focus presets, and settings to default values. This action cannot be undone.")
        }
    }
    
    private func resetAllSettings() {
        // Reset UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        Repository.suiteUserDefaults.removePersistentDomain(forName: Constants.StorageKeys.suiteName)

        // Refresh spaces
        Task {
            await spacesViewModel.updateSystemSpaces()
        }
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let systemSymbol: SFSymbol
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemSymbol: systemSymbol)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.system(size: 11))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isActive ? Color.accentColor.opacity(0.1) : Color.clear)
            .foregroundStyle(isActive ? Color.accentColor : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - General Settings View

struct GeneralSettingsView: View {
    @ObservedObject var permissionHandler: PermissionHandler
    @ObservedObject var focusStatusViewModel: FocusStatusViewModel
    @Binding var isDisplayingShortcutsPanel: Bool

    var body: some View {
        SettingsSection(title: "Startup") {
            LaunchAtLogin.Toggle {
                Text("Launch at Login")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toggleStyle(SwitchToggleStyle())
        }

        SettingsSection(title: "Permissions") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Accessibility")
                            .font(.subheadline.weight(.medium))

                        Text("Required for switching between spaces")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack {
                        Circle()
                            .fill(permissionHandler.hasAccessibilityPermission ? Color.green : Color.red)
                            .frame(width: 8, height: 8)

                        Text(permissionHandler.hasAccessibilityPermission ? "Enabled" : "Disabled")
                            .font(.caption)
                            .foregroundStyle(permissionHandler.hasAccessibilityPermission ? .green : .red)
                    }

                    Button(permissionHandler.hasAccessibilityPermission ? "View in Settings" : "Enable") {
                        permissionHandler.openAccessibilitySettings()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Divider()

                PermissionsSettingsView(focusStatusViewModel: focusStatusViewModel)
            }
        }
        
        SettingsSection(title: "System Integration") {
            Button("Configure macOS Keyboard Shortcuts") {
                isDisplayingShortcutsPanel = true
            }
            
            Button("Open macOS Keyboard Settings") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.keyboard?Shortcuts")!)
            }
            
            Button("Open macOS Focus Settings") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Focus")!)
            }
        }
        
        SettingsSection(title: "Updates") {
            UpdateView()
                .frame(height: 30)
        }
    }
}

// MARK: - Advanced Settings View

struct AdvancedSettingsView: View {
    @Binding var showResetConfirmation: Bool
    @ObservedObject var spacesViewModel: SpacesViewModel
    @ObservedObject var focusViewModel: FocusViewModel
    @ObservedObject var focusStatusViewModel: FocusStatusViewModel
    @State private var debugMode = false
    @State private var validationResult: (success: Bool, message: String)? = nil
        
    var body: some View {
        SettingsSection(title: "Behavior") {
            Button("Validate Space Organization") {
                validateSpaces()
            }
            .buttonStyle(.bordered)
                
            // Show validation result if available
            if let result = validationResult {
                HStack {
                    Image(systemSymbol: result.success ? .checkmarkCircleFill : .exclamationmarkTriangleFill)
                        .foregroundStyle(result.success ? .green : .orange)
                        
                    Text(result.message)
                        .foregroundStyle(result.success ? .green : .orange)
                        
                    Spacer()
                        
                    if !result.success {
                        Button("Fix Issues") {
                            fixSpaceOrganization()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(8)
                .background(Color(nsColor: result.success ? .controlBackgroundColor : NSColor.systemYellow.withAlphaComponent(0.2)))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.top, 4)
            }
        }
            
        // Add the Default Preset section
        DefaultPresetSettingsView(focusStatusViewModel: focusStatusViewModel, focusViewModel: focusViewModel)
            
        SettingsSection(title: "Focus Status") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Focus Mode Integration")
                    .font(.headline)
                    
                Text("Outer Spaces integrates with macOS Focus modes. You can control spaces based on your current Focus status.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                Button("Open Focus Settings") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Focus")!)
                }
                .buttonStyle(.bordered)
            }
        }
            
        SettingsSection(title: "Debugging") {
            Toggle("Debug Mode", isOn: $debugMode)
                .toggleStyle(SwitchToggleStyle())
                
            if debugMode {
                Button("Export Diagnostics") {
                    exportDiagnostics()
                }
                .buttonStyle(.bordered)
            }
        }
            
        SettingsSection(title: "Reset") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Reset all settings, spaces, and focus presets to default values.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                Button("Reset All Settings") {
                    showResetConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .foregroundStyle(.white)
                .tint(.red)
            }
        }
    }
    
    private func validateSpaces() {
        let issues = spacesViewModel.validateSpaceOrganization()
        
        if issues.isEmpty {
            // Set success result
            validationResult = (true, "All spaces are correctly organized.")
            
            // Also show alert
            showNotification(title: "Space Validation", message: "All spaces are correctly organized.")
        } else {
            // Set error result
            validationResult = (false, "Found \(issues.count) issues with space organization.")
            
            // Also show alert
            showNotification(title: "Space Validation Issues", message: "Found \(issues.count) issues with space organization.")
            
            // Log issues
            for issue in issues {
                Logger.shared.logWarning("Space validation issue: \(issue)")
            }
        }
    }
    
    private func fixSpaceOrganization() {
        // Use our improved space organization to fix the issues
        Task {
            await spacesViewModel.updateSystemSpaces()
        }
        
        // Clear validation result until validation is run again
        validationResult = nil
        
        // Show confirmation
        showNotification(title: "Space Organization", message: "Space organization has been refreshed. Please validate again.")
    }
    
    // Helper method to show notifications in a compatible way
    private func showNotification(title: String, message: String) {
        // On macOS, use an alert instead of system notifications since those require special permissions
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        
        if let window = NSApplication.shared.windows.first {
            alert.beginSheetModal(for: window) { _ in }
        } else {
            alert.runModal()
        }
    }
    
    private func exportDiagnostics() {
        // Create diagnostics data
        var diagnosticsText = "Outer Spaces Diagnostics\n"
        diagnosticsText += "=====================\n"
        diagnosticsText += "App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")\n"
        diagnosticsText += "macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)\n\n"
        
        // Add space information
        diagnosticsText += "SPACES INFORMATION\n"
        diagnosticsText += "-----------------\n"
        diagnosticsText += "Total displays: \(spacesViewModel.desktopSpaces.count)\n"
        diagnosticsText += "Total spaces: \(spacesViewModel.allSpaces.count)\n\n"
        
        for (i, display) in spacesViewModel.desktopSpaces.enumerated() {
            diagnosticsText += "DISPLAY \(i+1) (\(display.displayID))\n"
            diagnosticsText += "  Spaces count: \(display.desktopSpaces.count)\n"
            
            for (j, space) in display.desktopSpaces.enumerated() {
                diagnosticsText += "  SPACE \(j+1):\n"
                diagnosticsText += "    ID: \(space.spaceID)\n"
                diagnosticsText += "    Display ID: \(space.displayID)\n"
                diagnosticsText += "    Display Index: \(space.displayIndex)\n"
                diagnosticsText += "    Space Index: \(space.spaceIndex)\n"
                diagnosticsText += "    Custom Name: \(space.customName ?? "None")\n"
                diagnosticsText += "    Active: \(space.isActive)\n\n"
            }
        }
        
        // Save to file and let user save it
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.showsTagField = false
        savePanel.nameFieldStringValue = "OuterSpaces-Diagnostics.txt"
        
        savePanel.allowedContentTypes = [UTType.plainText]
        
        if let window = NSApplication.shared.windows.first {
            savePanel.beginSheetModal(for: window) { response in
                if response == .OK, let url = savePanel.url {
                    do {
                        try diagnosticsText.write(to: url, atomically: true, encoding: .utf8)
                    } catch {
                        Logger.shared.logError("Failed to save diagnostics: \(error)")
                    }
                }
            }
        }
    }
}

// MARK: - About Settings View

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 20) {
                if let appIcon = NSImage(named: "AppIcon") {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 100, height: 100)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Outer Spaces")
                        .font(.title)
                    
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                        .foregroundStyle(.secondary)
                    
                    Text("Developed by Lospi")
                    
                    Text("Contact: admin@lospi.dev")
                        .foregroundStyle(.secondary)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("About Outer Spaces")
                    .font(.headline)
                
                Text("Outer Spaces helps you organize your Mac's desktop spaces with Focus modes, allowing for automatic workspace transitions based on your current activity.")
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Support")
                    .font(.headline)
                
                Button("View Documentation") {
                    NSWorkspace.shared.open(URL(string: "https://outerspaces.app/docs")!)
                }
                .buttonStyle(.bordered)
                
                Button("Open YouTube Tutorial") {
                    NSWorkspace.shared.open(URL(string: "https://www.youtube.com/watch?v=DTPDoeVhLaQ")!)
                }
                .buttonStyle(.bordered)
                
                Button("Report an Issue") {
                    NSWorkspace.shared.open(URL(string: "https://outerspaces.app/support")!)
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Shortcuts Panel

struct ShortcutsPanel: View {
    @Binding var isPresented: Bool
    
    let shortcuts = [
        ("Control + 1-9", "Switch to Desktop 1-9"),
        ("Control + Option + 1-9", "Switch to Desktop 10-19"),
        ("Control + Command + F", "Toggle Stage Manager"),
        ("Control + Option + Command + S", "Refresh Spaces"),
        ("Control + Option + Command + P", "Create New Preset"),
        ("Control + Option + Command + E", "Edit Current Preset")
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Keyboard Shortcuts")
                .font(.title2)
                .padding(.top, 16)
            
            Text("These shortcuts help you use Outer Spaces effectively. Make sure to enable space switching shortcuts in macOS System Settings.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundStyle(.secondary)
            
            Divider()
            
            VStack(spacing: 0) {
                ForEach(shortcuts, id: \.0) { shortcut in
                    HStack {
                        Text(shortcut.0)
                            .fontWeight(.medium)
                            .frame(width: 200, alignment: .leading)
                        
                        Spacer()
                        
                        Text(shortcut.1)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    
                    if shortcut.0 != shortcuts.last?.0 {
                        Divider()
                    }
                }
            }
            .background(Color.secondary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
            
            Spacer()
            
            HStack {
                Button("System Shortcuts") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.keyboard?Shortcuts")!)
                }
                
                Spacer()
                
                Button("Close") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(16)
            .background(Color.secondary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
