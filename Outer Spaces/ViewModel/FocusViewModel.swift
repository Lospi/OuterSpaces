//
//  FocusViewModel.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 23/11/23.
//

import Foundation

class FocusViewModel: ObservableObject {
    @Published var availableFocusPresets: [Focus] = []
    @Published var selectedFocusPreset: Focus? = nil
    @Published var selectedFocusPresetSpaces: [Space] = []
    @Published var creatingPreset = false
    @Published var editingFocus: Bool = false

    func toggleFocusEditing() {
        editingFocus.toggle()
    }

    func selectFocusPreset(preset: Focus) {
        selectedFocusPreset = preset
        editingFocus = true
    }
}
