//
//  Constants.swift
//  Outer Spaces
//
//  Created by Sasindu Jayasinghe on 7/11/21.
//

import Foundation

enum Constants {

    enum AppInfo {
        static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        static let repo = URL(string: "https://github.com/Lospi/OuterSpaces")!
        static let website = URL(string: "https://github.com/Lospi/OuterSpaces")!
    }

    enum StorageKeys {
        static let defaultPresetID = "DefaultPresetID"
        static let focusPresets = "FocusPresets"
        static let availableSpaces = "AvailableSpaces"
        static let suiteName = "dev.Lospi.OuterSpaces"
    }
}
