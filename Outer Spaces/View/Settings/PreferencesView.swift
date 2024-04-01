//
//  PreferencesView.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 22/12/23.
//

import LaunchAtLogin
import SettingsAccess
import SwiftUI

struct PreferencesView: View {
    @Binding var showOnLogin: Bool

    var body: some View {
        VStack {
            LaunchAtLogin.Toggle()
            Button("Open Keyboard Settings") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.keyboard?Shortcuts")!)
            }
            .onDrag {
                NSItemProvider()
            }
            Button("Open Privacy and Security Settings") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension")!)
            }
            .onDrag {
                NSItemProvider()
            }
        }

        AboutView()
    }
}
