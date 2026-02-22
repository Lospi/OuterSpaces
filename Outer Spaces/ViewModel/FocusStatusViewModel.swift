//
//  FocusStatusViewModel.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 25/03/25.
//

import Intents
import IntentsUI
import SwiftUI

@MainActor
class FocusStatusViewModel: ObservableObject {
    static let shared = FocusStatusViewModel()

    @Published var isFocusActive = false
    @Published var defaultPresetID: UUID? = nil

    var focusTimer: Timer?

    private init() {
        updateCurrentFocusState()
        startFocusTimer()
    }

    /// Updates the current focus state and triggers preset changes if needed
    private func updateCurrentFocusState() {
        let focusStatus = INFocusStatusCenter.default

        let authorized = focusStatus.authorizationStatus == .authorized

        guard authorized else {
            isFocusActive = false
            applyDefaultPresetIfNeeded()
            return
        }

        let isFocusActive = focusStatus.focusStatus.isFocused ?? false
        self.isFocusActive = isFocusActive

        if !isFocusActive {
            applyDefaultPresetIfNeeded()
        }
    }

    /// Sets the default preset ID to use when no focus is active
    func setDefaultPreset(id: UUID?) {
        defaultPresetID = id

        if !isFocusActive {
            applyDefaultPresetIfNeeded()
        }
    }

    /// Applies the default preset if one is set and no focus is active
    private func applyDefaultPresetIfNeeded() {
        guard let presetID = defaultPresetID, !isFocusActive else {
            return
        }

        applyPreset(id: presetID)
    }

    /// Applies a specific preset by ID
    private func applyPreset(id: UUID) {
        if let preset = FocusViewModel.shared.availableFocusPresets.first(where: { $0.id == id }) {
            let _ = SettingsViewModel.shared.updateSpacesOnScreen(focus: preset)
        }
    }

    /// Request authorization to access focus status if needed
    func requestFocusAuthorization() {
        INFocusStatusCenter.default.requestAuthorization { [weak self] status in
            Task { @MainActor in
                if status == .authorized {
                    self?.updateCurrentFocusState()
                }
            }
        }
    }
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

    func startFocusTimer() {
        focusTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if INFocusStatusCenter.default.focusStatus.isFocused != self.isFocusActive {
                    self.updateCurrentFocusState()
                }
            }
        }
    }
}
