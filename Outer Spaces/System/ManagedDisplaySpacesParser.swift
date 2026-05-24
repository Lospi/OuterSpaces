import Foundation

struct ManagedDisplaySpacesSnapshot {
    var desktopSpaces: [DesktopSpaces]
    var allSpaces: [Space]
    var activeSpaceID: String?
}

enum ManagedDisplaySpacesParser {
    static func parse(_ displays: [NSDictionary]) -> ManagedDisplaySpacesSnapshot {
        var allSpacesList: [Space] = []
        var desktopSpacesList: [DesktopSpaces] = []
        var mainDisplayActiveSpaceID: String?

        for (displayIndex, display) in displays.enumerated() {
            guard let currentSpace = display["Current Space"] as? [String: Any],
                  let displaySpaces = display["Spaces"] as? [[String: Any]],
                  let displayID = display["Display Identifier"] as? String,
                  let activeSpaceID = currentSpace["ManagedSpaceID"] as? Int
            else {
                continue
            }

            if displayIndex == 0 {
                mainDisplayActiveSpaceID = String(activeSpaceID)
            }

            var spacesForDisplay: [Space] = []
            var regularSpaceIndex = 0

            for spaceInfo in displaySpaces {
                guard let type = spaceInfo["type"] as? Int, type == 0,
                      let spaceID = spaceInfo["ManagedSpaceID"] as? Int
                else {
                    continue
                }

                let space = Space(
                    displayID: displayID,
                    displayIndex: displayIndex + 1,
                    spaceID: String(spaceID),
                    spaceIndex: regularSpaceIndex,
                    isActive: spaceID == activeSpaceID
                )
                regularSpaceIndex += 1

                spacesForDisplay.append(space)
                allSpacesList.append(space)
            }

            desktopSpacesList.append(
                DesktopSpaces(
                    displayID: displayID,
                    displayIndex: displayIndex + 1,
                    spaces: spacesForDisplay
                )
            )
        }

        return ManagedDisplaySpacesSnapshot(
            desktopSpaces: desktopSpacesList,
            allSpaces: allSpacesList,
            activeSpaceID: mainDisplayActiveSpaceID
        )
    }
}
