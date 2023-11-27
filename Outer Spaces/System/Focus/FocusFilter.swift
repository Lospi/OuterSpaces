import AppIntents
import Foundation

struct SpacesFocusFilter: SetFocusFilterIntent {
    // The focus filter title as it appears in the Settings app
    static var title: LocalizedStringResource = .init(stringLiteral: "Select Preset")
    // The description as it appears in the Settings app
    static var description: LocalizedStringResource? = "Select your built preset with the desired spaces"

    // How a configured filter appears on the Focus details screen
    var displayRepresentation: DisplayRepresentation {
        spaceFilterPreset?.displayRepresentation ?? .init(title: .init(stringLiteral: "Select Preset"))
    }

    // A custom parameter called Category
    @Parameter(title: "Focus Preset", description: "Select Preset")
    var spaceFilterPreset: SpaceAppEntity?

    func perform() async throws -> some IntentResult {
        // Use the parameter to update the state of the app

        return .result()
    }
}
