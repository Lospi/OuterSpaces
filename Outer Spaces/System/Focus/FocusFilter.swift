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

    // A custom parameter called Category
    @Parameter(title: "Focus Preset", description: "Select Preset")
    var spaceFilterPreset: SpaceAppEntity

    func perform() async throws -> some IntentResult {
        let settingsModel = SettingsModel(focusPresetId: spaceFilterPreset.id)
        Repository.shared.updateAppDataModelStore(settingsModel)
        if let deviceUUID = getDeviceUUID() {
            print("Device UUID: \(deviceUUID)")
        } else {
            print("Unable to retrieve device UUID.")
        }
        return .result()
    }

    func getDeviceUUID() -> String? {
        let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))

        guard platformExpert != 0 else {
            return nil
        }

        defer {
            IOObjectRelease(platformExpert)
        }

        if let serialNumber = (IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0).takeUnretainedValue() as? String) {
            return serialNumber
        }

        return nil
    }
}
