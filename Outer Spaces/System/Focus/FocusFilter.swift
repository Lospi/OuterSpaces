import AppIntents
import Foundation
import IOKit

struct SpacesFocusFilter: SetFocusFilterIntent {
    // The focus filter title as it appears in the Settings app
    static var title: LocalizedStringResource = .init(stringLiteral: "Select Preset")
    // The description as it appears in the Settings app
    static var description: LocalizedStringResource? = "Select your built preset with the desired spaces"

    // How a configured filter appears on the Focus details screen
    var displayRepresentation: DisplayRepresentation {
        spaceFilterPreset.displayRepresentation
    }

    // A custom parameter called Focus
    @Parameter(title: "Focus Preset", description: "Select Preset")
    var spaceFilterPreset: SpaceAppEntity

    func perform() async throws -> some IntentResult {
        let focus = FocusViewModel.shared.availableFocusPresets.first { $0.id == spaceFilterPreset.id }
        print("Selected focus: \(focus?.name ?? "None")")
        do {
            let _ = try await SettingsViewModel.shared.updateSpacesOnScreen(focus: focus!)
        }
        catch {
            print("Error updating spaces on screen: \(error)")
        }

        return .result()
    }
}
