import Intents
import SFSafeSymbols
import SwiftUI
import UserNotifications

struct DefaultPresetSettingsView: View {
    @ObservedObject var focusStatusViewModel: FocusStatusViewModel
    @ObservedObject var focusViewModel: FocusViewModel

    var body: some View {
        SettingsSection(title: "Default Preset") {
            VStack(alignment: .leading, spacing: 12) {
                Text("This preset will be applied when no Focus mode is active")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("Default Preset", selection: Binding(
                    get: { focusStatusViewModel.defaultPresetID },
                    set: { newValue in
                        focusStatusViewModel.setDefaultPreset(id: newValue)
                        if let presetID = newValue {
                            UserDefaults.standard.set(presetID.uuidString, forKey: Constants.StorageKeys.defaultPresetID)
                        } else {
                            UserDefaults.standard.removeObject(forKey: Constants.StorageKeys.defaultPresetID)
                        }
                    }
                )) {
                    Text("None").tag(nil as UUID?)

                    if !focusViewModel.availableFocusPresets.isEmpty {
                        Divider()

                        ForEach(focusViewModel.availableFocusPresets) { preset in
                            Text(preset.name).tag(preset.id as UUID?)
                        }
                    }
                }
                .pickerStyle(.menu)

                HStack {
                    Text("Current Status:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if focusStatusViewModel.isFocusActive {
                        HStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("Focus active")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    } else {
                        HStack {
                            Circle()
                                .fill(Color.secondary)
                                .frame(width: 8, height: 8)
                            Text("No focus active")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .onAppear {
            // Load saved default preset ID
            if let savedIDString = UserDefaults.standard.string(forKey: Constants.StorageKeys.defaultPresetID),
               let savedID = UUID(uuidString: savedIDString)
            {
                focusStatusViewModel.setDefaultPreset(id: savedID)
            }
        }
    }
}

// MARK: - Permissions Section (for General Settings tab)

struct PermissionsSettingsView: View {
    @ObservedObject var focusStatusViewModel: FocusStatusViewModel
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Focus Authorization
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Focus Status")
                        .font(.subheadline.weight(.medium))
                    Text("Required to detect active Focus modes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    focusStatusViewModel.requestFocusAuthorization()
                } label: {
                    Text("Request Authorization")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Divider()

            // Notification Authorization
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Notifications")
                        .font(.subheadline.weight(.medium))
                    Text("Optional — notifies when presets are applied")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    if notificationStatus != .notDetermined {
                        Circle()
                            .fill(notificationStatus == .authorized ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                    }

                    if notificationStatus == .denied {
                        Button("Open Notification Settings") {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    } else {
                        Button("Request Authorization") {
                            requestNotificationAuthorization()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(notificationStatus == .authorized)
                    }
                }
            }
        }
        .onAppear {
            checkNotificationAuthorizationStatus()
        }
    }

    private func checkNotificationAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.notificationStatus = settings.authorizationStatus
            }
        }
    }

    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            Task { @MainActor in
                self.notificationStatus = granted ? .authorized : .denied
                if let error = error {
                    Logger.shared.logError("Notification authorization error: \(error.localizedDescription)")
                }
            }
        }
    }
}
