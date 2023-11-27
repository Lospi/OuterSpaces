//
//  SettingsViewModel.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 27/11/23.
//

import Foundation

struct SettingsViewModel {
    var selectedFocusPresetId: UUID?

    init(settingsModel: SettingsModel) {
        self.selectedFocusPresetId = settingsModel.focusPresetId
    }
}
