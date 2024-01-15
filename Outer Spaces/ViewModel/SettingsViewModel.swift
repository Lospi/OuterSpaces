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

    func updateSpacesOnScreen(focus: Focus) -> Bool {
        var error: NSDictionary?
        var didError = false

        focus.spaces.forEach { space in
            let scriptSource = AppleScriptHelper.getCompleteAppleScriptPerIndex(index: space.spaceIndex)

            if let result = try? NSAppleScript(source: scriptSource)!.executeAndReturnError(&error) {
                if let stringValue = result.stringValue {
                    print("Script executed successfully. Result: \(stringValue)")
                } else {
                    print("Script executed successfully.")
                }
            } else {
                if let errorDescription = error?["NSAppleScriptErrorMessage"] as? String {
                    if errorDescription.contains("System Events") {
                        didError = true
                    }
                }
            }
        }
        return didError
    }
}
