//
//  FocusStatusViewModel.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 25/03/25.
//

import Combine
import Intents
import IntentsUI
import SwiftUI

class FocusStatusViewModel: ObservableObject {
    static let shared = FocusStatusViewModel()
    
    @Published var isFocusActive = false
    @Published var defaultPresetID: UUID? = nil
    
    var focusCancellable: AnyCancellable?
    var focusTimer: Timer?
    
    private init() {
        // Initialize by checking current focus status
        updateCurrentFocusState()
        startFocusTimer()
    }
    
    /// Updates the current focus state and triggers preset changes if needed
    private func updateCurrentFocusState() {
        let focusStatus = INFocusStatusCenter.default
        print("Focus status: \(focusStatus.focusStatus)")
        
        // Check if focus is active
        Task {
            let authorized = focusStatus.authorizationStatus == .authorized
            
            // If not authorized, we can't determine if focus is active
            guard authorized else {
                DispatchQueue.main.async {
                    self.isFocusActive = false
                    self.applyDefaultPresetIfNeeded()
                }
                return
            }
            
            // Get the current focus status
            let isFocusActive = focusStatus.focusStatus.isFocused ?? true
            
            DispatchQueue.main.async {
                self.isFocusActive = isFocusActive
                
                // Apply default preset if no focus is active
                if !isFocusActive {
                    self.applyDefaultPresetIfNeeded()
                }
            }
        }
    }
    
    /// Sets the default preset ID to use when no focus is active
    func setDefaultPreset(id: UUID?) {
        defaultPresetID = id
        
        // If no focus is active, apply the default preset immediately
        if !isFocusActive {
            applyDefaultPresetIfNeeded()
        }
    }
    
    /// Applies the default preset if one is set and no focus is active
    private func applyDefaultPresetIfNeeded() {
        guard let presetID = defaultPresetID, !isFocusActive else {
            return
        }
        
        // Apply the default preset
        applyPreset(id: presetID)
    }
    
    /// Applies a specific preset by ID
    private func applyPreset(id: UUID) {
        print("Applying preset with ID: \(id)")
        // Find the preset with the given ID
        if let preset = FocusManager.loadFocusModels().first(where: { $0.id == id }) {
            SettingsViewModel.shared.updateSpacesOnScreen(focus: preset)
        }
    }
    
    /// Request authorization to access focus status if needed
    func requestFocusAuthorization() {
        INFocusStatusCenter.default.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .authorized {
                    self.updateCurrentFocusState()
                } else {
                    print("Focus status authorization denied")
                }
            }
        }
    }
}

extension FocusStatusViewModel {
    /// Request authorization for both focus status and notifications
    func requestAuthorizations() {
        // Request Focus authorization
        requestFocusAuthorization()
        
        // Request Notification authorization
        requestNotificationAuthorization()
    }
    
    /// Request authorization for user notifications
    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("Notification permission granted")
                } else {
                    print("Notification permission denied")
                    if let error = error {
                        print("Notification authorization error: \(error.localizedDescription)")
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
                print("Error sending notification: \(error.localizedDescription)")
            }
        }
    }
    
    func startFocusTimer() {
        focusTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            if INFocusStatusCenter.default.focusStatus.isFocused != self.isFocusActive {
                self.updateCurrentFocusState()
            }
        }
    }
}
