import SwiftUI
import UserNotifications

import SwiftUI
import UserNotifications

struct DefaultPresetSettingsView: View {
    @ObservedObject var focusStatusViewModel: FocusStatusViewModel
    @ObservedObject var focusViewModel: FocusViewModel
    @State private var selectedPresetID: UUID? = nil
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        SettingsSection(title: "Default Preset") {
            VStack(alignment: .leading, spacing: 12) {
                Text("This preset will be applied when no Focus mode is active")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("Default Preset", selection: $selectedPresetID) {
                    Text("None").tag(nil as UUID?)
                    
                    if !focusViewModel.availableFocusPresets.isEmpty {
                        Divider()
                        
                        ForEach(focusViewModel.availableFocusPresets) { preset in
                            Text(preset.name).tag(preset.id as UUID?)
                        }
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedPresetID) { newValue in
                    focusStatusViewModel.setDefaultPreset(id: newValue)
                    
                    // Save the selection to UserDefaults
                    if let presetID = newValue {
                        UserDefaults.standard.set(presetID.uuidString, forKey: "DefaultPresetID")
                    } else {
                        UserDefaults.standard.removeObject(forKey: "DefaultPresetID")
                    }
                }
                
                HStack {
                    Text("Current Status:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if focusStatusViewModel.isFocusActive {
                        HStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("Focus active")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    } else {
                        HStack {
                            Circle()
                                .fill(Color.secondary)
                                .frame(width: 8, height: 8)
                            Text("No focus active")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Permission Buttons Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Permissions")
                        .font(.caption.bold())
                        .padding(.top, 8)
                    
                    // Focus Authorization Button
                    Button(action: {
                        focusStatusViewModel.requestFocusAuthorization()
                    }) {
                        HStack {
                            Image(systemName: "eye")
                            Text("Request Focus Authorization")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    // Notification Authorization Button
                    Button(action: {
                        requestNotificationAuthorization()
                    }) {
                        HStack {
                            Image(systemName: "bell")
                            Text("Request Notification Authorization")
                            
                            Spacer()
                            
                            // Status indicator for notifications
                            if notificationStatus != .notDetermined {
                                Circle()
                                    .fill(notificationStatus == .authorized ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .onAppear {
            // Request focus authorization when the view appears
            focusStatusViewModel.requestFocusAuthorization()
            
            // Load saved default preset ID
            if let savedIDString = UserDefaults.standard.string(forKey: "DefaultPresetID"),
               let savedID = UUID(uuidString: savedIDString)
            {
                selectedPresetID = savedID
                focusStatusViewModel.setDefaultPreset(id: savedID)
            }
            
            // Check notification authorization status
            checkNotificationAuthorizationStatus()
        }
    }
    
    // Check current notification authorization status
    private func checkNotificationAuthorizationStatus() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationStatus = settings.authorizationStatus
            }
        }
    }
    
    // Request notification authorization
    private func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.notificationStatus = granted ? .authorized : .denied
                
                if let error = error {
                    print("Notification authorization error: \(error.localizedDescription)")
                } else if granted {
                    print("Notification authorization granted")
                } else {
                    print("Notification authorization denied")
                }
            }
        }
    }
}
