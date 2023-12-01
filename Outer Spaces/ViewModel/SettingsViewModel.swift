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

    func updateSpacesOnScreen(focus: Focus) {
        print("UPDATING FOCUS")
        print(focus)

        focus.spaces.forEach { space in
            print("SPACE INDEX = \(space)")
            let result = NSAppleScript(source: """
            -- Set the index of the Space you want to switch to
            set targetSpaceIndex to \(space.spaceIndex) -- Change this to the desired Space index

            -- Change to the specified Space index
            tell application "System Events"
                key code (18 + targetSpaceIndex) using {control down} -- Press Ctrl + (targetSpaceIndex)
            end tell

            """)!.executeAndReturnError(nil)
        }
    }
}
