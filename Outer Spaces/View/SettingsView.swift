import AppKit // For NSUserNotification
import LaunchAtLogin
import SFSafeSymbols
import Sparkle
import StoreKit
import SwiftUI
import UniformTypeIdentifiers // For UTType
import UserNotifications // For UNUserNotificationCenter

struct SettingsView: View {
    @ObservedObject var spacesViewModel: SpacesViewModel
    @ObservedObject private var permissionHandler = PermissionHandler.shared
    @ObservedObject var focusViewModel: FocusViewModel
    @ObservedObject var focusStatusViewModel: FocusStatusViewModel
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.openWindow) var openWindow
    @AppStorage("showSpaceNumbers") private var showSpaceNumbers = true
    @AppStorage("autoSwitchSpaces") private var autoSwitchSpaces = true
    @AppStorage("useTrayMenuBar") private var useTrayMenuBar = true
    @State private var isDisplayingShortcutsPanel = false
    @State private var showResetConfirmation = false
    @State private var activeTab = "general"
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom tab bar
            HStack(spacing: 0) {
                TabButton(title: "General", systemSymbol: .gearshape, isActive: activeTab == "general") {
                    activeTab = "general"
                }
                
                TabButton(title: "Appearance", systemSymbol: .paintbrush, isActive: activeTab == "appearance") {
                    activeTab = "appearance"
                }
                
                TabButton(title: "Advanced", systemSymbol: .wrenchAndScrewdriver, isActive: activeTab == "advanced") {
                    activeTab = "advanced"
                }
                
                TabButton(title: "About", systemSymbol: .infoCircle, isActive: activeTab == "about") {
                    activeTab = "about"
                }
            }
            .padding(.horizontal)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content area
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch activeTab {
                    case "general":
                        GeneralSettingsView(
                            permissionHandler: permissionHandler,
                            isDisplayingShortcutsPanel: $isDisplayingShortcutsPanel
                        )
                    case "appearance":
                        AppearanceSettingsView(
                            showSpaceNumbers: $showSpaceNumbers,
                            useTrayMenuBar: $useTrayMenuBar
                        )
                    case "advanced":
                        AdvancedSettingsView(
                            autoSwitchSpaces: $autoSwitchSpaces,
                            showResetConfirmation: $showResetConfirmation,
                            spacesViewModel: spacesViewModel,
                            focusViewModel: focusViewModel,
                            focusStatusViewModel: focusStatusViewModel,
                            managedObjectContext: managedObjectContext
                        )
                    case "about":
                        AboutSettingsView()
                    default:
                        GeneralSettingsView(
                            permissionHandler: permissionHandler,
                            isDisplayingShortcutsPanel: $isDisplayingShortcutsPanel
                        )
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
        // Clear Core Data
        let entities = ["SpaceData", "FocusData"]
        
        for entity in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try managedObjectContext.execute(batchDeleteRequest)
                try managedObjectContext.save()
            } catch {
                print("Error resetting \(entity): \(error)")
            }
        }
        
        // Reset UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        
        // Reset app storage values
        showSpaceNumbers = true
        autoSwitchSpaces = true
        useTrayMenuBar = true
        
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
            .foregroundColor(isActive ? .accentColor : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - General Settings View

struct GeneralSettingsView: View {
    @ObservedObject var permissionHandler: PermissionHandler
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
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Accessibility")
                        .font(.headline)
                    
                    Text("Required for switching between spaces")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack {
                    Circle()
                        .fill(permissionHandler.hasAccessibilityPermission ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    
                    Text(permissionHandler.hasAccessibilityPermission ? "Enabled" : "Disabled")
                        .foregroundColor(permissionHandler.hasAccessibilityPermission ? .green : .red)
                }
                
                Button(permissionHandler.hasAccessibilityPermission ? "Settings" : "Enable") {
                    permissionHandler.openAccessibilitySettings()
                }
                .buttonStyle(.borderedProminent)
                .disabled(permissionHandler.hasAccessibilityPermission)
            }
            .padding(.vertical, 4)
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

// MARK: - Appearance Settings View

struct AppearanceSettingsView: View {
    @Binding var showSpaceNumbers: Bool
    @Binding var useTrayMenuBar: Bool
    @State private var useCustomAppIcon = false
    @State private var selectedIconIndex = 0
    
    let appIcons = ["Default", "Minimal", "Colorful", "Dark"]
    
    var body: some View {
        SettingsSection(title: "Spaces") {
            Toggle("Show Space Numbers", isOn: $showSpaceNumbers)
                .toggleStyle(SwitchToggleStyle())
            
            // Custom space layout preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Preview")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    ForEach(1 ... 4, id: \.self) { index in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 44, height: 36)
                                .overlay(
                                    Text(showSpaceNumbers ? "\(index)" : "")
                                        .foregroundColor(.primary)
                                )
                            
                            Text("Space \(index)")
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(8)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Advanced Settings View

struct AdvancedSettingsView: View {
    @Binding var autoSwitchSpaces: Bool
    @Binding var showResetConfirmation: Bool
    @ObservedObject var spacesViewModel: SpacesViewModel
    @ObservedObject var focusViewModel: FocusViewModel
    @ObservedObject var focusStatusViewModel: FocusStatusViewModel
    var managedObjectContext: NSManagedObjectContext
    @State private var loggingEnabled = false
    @State private var debugMode = false
    @State private var validationResult: (success: Bool, message: String)? = nil
        
    var body: some View {
        SettingsSection(title: "Behavior") {
            Toggle("Auto-switch spaces with Focus modes", isOn: $autoSwitchSpaces)
                .toggleStyle(SwitchToggleStyle())
                
            Button("Validate Space Organization") {
                validateSpaces()
            }
            .buttonStyle(.bordered)
                
            // Show validation result if available
            if let result = validationResult {
                HStack {
                    Image(systemSymbol: result.success ? .checkmarkCircleFill : .exclamationmarkTriangleFill)
                        .foregroundColor(result.success ? .green : .orange)
                        
                    Text(result.message)
                        .foregroundColor(result.success ? .green : .orange)
                        
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
                .cornerRadius(6)
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
                    .foregroundColor(.secondary)
                    
                Button("Open Focus Settings") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Focus")!)
                }
                .buttonStyle(.bordered)
            }
        }
            
        SettingsSection(title: "Debugging") {
            Toggle("Enable Logging", isOn: $loggingEnabled)
                .toggleStyle(SwitchToggleStyle())
                
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
                    .foregroundColor(.secondary)
                    
                Button("Reset All Settings") {
                    showResetConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .foregroundColor(.white)
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
                print("Space validation issue: \(issue)")
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
        
        // Use compatible file type approach
        if #available(macOS 11.0, *) {
            savePanel.allowedContentTypes = [UTType.plainText]
        } else {
            savePanel.allowedFileTypes = ["txt", "text"]
        }
        
        if let window = NSApplication.shared.windows.first {
            savePanel.beginSheetModal(for: window) { response in
                if response == .OK, let url = savePanel.url {
                    do {
                        try diagnosticsText.write(to: url, atomically: true, encoding: .utf8)
                    } catch {
                        print("Failed to save diagnostics: \(error)")
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
                Image(nsImage: NSImage(named: "AppIcon")!)
                    .resizable()
                    .frame(width: 100, height: 100)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Outer Spaces")
                        .font(.title)
                    
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                        .foregroundColor(.secondary)
                    
                    Text("Developed by Lospi")
                    
                    Text("Contact: admin@lospi.dev")
                        .foregroundColor(.secondary)
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
                .foregroundColor(.secondary)
            
            Divider()
            
            VStack(spacing: 0) {
                ForEach(shortcuts, id: \.0) { shortcut in
                    HStack {
                        Text(shortcut.0)
                            .fontWeight(.medium)
                            .frame(width: 200, alignment: .leading)
                        
                        Spacer()
                        
                        Text(shortcut.1)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    
                    if shortcut.0 != shortcuts.last?.0 {
                        Divider()
                    }
                }
            }
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
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
            .cornerRadius(8)
        }
    }
}
