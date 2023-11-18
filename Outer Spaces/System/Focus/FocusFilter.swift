import AppIntents
import Foundation

struct SpacesFocusFilter: SetFocusFilterIntent {
    // The focus filter title as it appears in the Settings app
    static var title: LocalizedStringResource = .init(stringLiteral: "Select Space")
    // The description as it appears in the Settings app
    static var description: LocalizedStringResource? = "Select Space"

    // How a configured filter appears on the Focus details screen
    var displayRepresentation: DisplayRepresentation {
        taskCategory?.displayRepresentation ?? "No Space Defined"
    }

    // A custom parameter called Category
    @Parameter(title: "Space", description: "Select Space")
    var taskCategory: SpaceAppEntity?

    func perform() async throws -> some IntentResult {
        // Use the parameter to update the state of the app

        return .result()
    }
}
