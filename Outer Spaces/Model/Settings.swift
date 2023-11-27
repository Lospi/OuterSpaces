//
//  Settings.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 27/11/23.
//

import Foundation

struct SettingsModel: Codable {
    init(focusPresetId: UUID = UUID()) {
        self.focusPresetId = focusPresetId
    }

    let focusPresetId: UUID
}
