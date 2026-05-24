import Foundation

struct SpaceSwitchCommand: Equatable {
    let keyCode: Int
    let usesOptionKey: Bool

    var appleScriptSource: String {
        if usesOptionKey {
            return """
            tell application "System Events"
                key code \(keyCode) using {control down, option down}
            end tell
            """
        }

        return """
        tell application "System Events"
            key code \(keyCode) using {control down}
        end tell
        """
    }
}

enum SpaceSwitchCommandFactory {
    private static let keyCodeByDigit: [Int: Int] = [
        0: 29, 1: 18, 2: 19, 3: 20, 4: 21,
        5: 23, 6: 22, 7: 26, 8: 28, 9: 25
    ]

    static func command(forSpaceIndex spaceIndex: Int) throws -> SpaceSwitchCommand {
        guard spaceIndex >= 0,
              let keyCode = keyCodeByDigit[(spaceIndex + 1) % 10]
        else {
            throw SpaceSwitchError.invalidSpaceIndex
        }

        return SpaceSwitchCommand(
            keyCode: keyCode,
            usesOptionKey: spaceIndex >= 9
        )
    }
}
