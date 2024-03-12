//
//  SettingsViewModel.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 27/11/23.
//

import Foundation

struct SettingsViewModel {
    var selectedFocusPresetId: UUID?
    var errorMessage: String?

    init(settingsModel: SettingsModel) {
        self.selectedFocusPresetId = settingsModel.focusPresetId
    }

    mutating func updateSpacesOnScreen(focus: Focus) -> Bool {
        var error: NSDictionary?
        var didError = false

        focus.spaces.forEach { space in
            let scriptSource = AppleScriptHelper.getCompleteAppleScriptPerIndex(index: space.spaceIndex)
            let result = try? NSAppleScript(source: scriptSource)!.executeAndReturnError(&error)

            if result != nil {
                print(result)
                if let stringValue = result?.stringValue {
                    print("Script executed successfully. Result: \(stringValue)")
                } else {
                    print("Script executed successfully.")
                }
            } else {
                print(result)
                if let errorDescription = error?["NSAppleScriptErrorMessage"] as? String {
                    print(errorDescription)
                    self.errorMessage = errorDescription
                    if errorDescription.contains("System Events") {
                        didError = true
                    }
                }
            }
        }
        return didError
    }
}
