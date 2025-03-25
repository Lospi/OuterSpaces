//
//  KeycodeMapper.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 13/01/24.
//

import Foundation

enum NumberKeyCode {
    static let keycodeDictionary: [Int: Int] = [
        0: 29,
        1: 18,
        2: 19,
        3: 20,
        4: 21,
        5: 23,
        6: 22,
        7: 26,
        8: 28,
        9: 25
    ]
}

enum AppleScriptHelper {
    static func getCompleteAppleScriptPerIndex(index: Int, stageManager: Bool?,
                                               shouldAffectStage: Bool) -> String
    {
        let desiredKeycode = NumberKeyCode.keycodeDictionary[(index + 1) % 10]
        let hasOptionKey = index > 9

        let scriptSource = shouldAffectStage ? hasOptionKey ?
            """
            -- Set the index of the Space you want to switch to
            set targetSpaceIndex to \(desiredKeycode!) -- Change this to the desired Space index

            -- Change to the specified Space index
            tell application "System Events" to activate

            tell application "System Events"
                key code (targetSpaceIndex) using {control down, option down} -- Press Ctrl + (targetSpaceIndex)
            end tell

            do shell script "defaults write com.apple.WindowManager GloballyEnabled -bool \(stageManager!)"

            """
            :
            """
            -- Set the index of the Space you want to switch to
            set targetSpaceIndex to \(desiredKeycode!) -- Change this to the desired Space index

            -- Change to the specified Space index
            tell application "System Events"
                key code (targetSpaceIndex) using {control down} -- Press Ctrl + (targetSpaceIndex)
            end tell

            do shell script "defaults write com.apple.WindowManager GloballyEnabled -bool \(stageManager!)"

            """
            : hasOptionKey ?
            """
            -- Set the index of the Space you want to switch to
            set targetSpaceIndex to \(desiredKeycode!) -- Change this to the desired Space index

            -- Change to the specified Space index
            tell application "System Events" to activate

            tell application "System Events"
                key code (targetSpaceIndex) using {control down, option down} -- Press Ctrl + (targetSpaceIndex)
            end tell


            """ :

            """
            -- Set the index of the Space you want to switch to
            set targetSpaceIndex to \(desiredKeycode!) -- Change this to the desired Space index

            -- Change to the specified Space index
            tell application "System Events"
                key code (targetSpaceIndex) using {control down} -- Press Ctrl + (targetSpaceIndex)
            end tell

            """
        return scriptSource
    }
}
