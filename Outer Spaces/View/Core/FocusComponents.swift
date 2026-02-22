//
//  FocusComponents.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 25/03/25.
//

import SFSafeSymbols
import SwiftUI

struct NewPresetSheet: View {
    @ObservedObject var focusViewModel: FocusViewModel
    let onDismiss: () -> Void

    @State private var presetName = ""
    @State private var hasStageManager = false
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text("Create New Focus Preset")
                .font(.headline)

            TextField("Preset Name", text: $presetName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isNameFieldFocused)

            Toggle("Enable Stage Manager", isOn: $hasStageManager)

            HStack {
                Button("Cancel") {
                    onDismiss()
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("Create") {
                    createPreset()
                    onDismiss()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(presetName.isEmpty)
            }
        }
        .padding()
        .onAppear {
            isNameFieldFocused = true
        }
    }

    private func createPreset() {
        let newPreset = Focus(name: presetName, spaces: [], stageManager: hasStageManager)
        focusViewModel.availableFocusPresets.append(newPreset)
        focusViewModel.saveFocusPresets()
    }
}
