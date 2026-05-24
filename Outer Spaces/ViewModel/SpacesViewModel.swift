//
//  SpacesViewModel.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 24/11/23.
//

import Foundation
import SwiftUI

@MainActor
class SpacesViewModel: ObservableObject {
    let spaceObserver = SpaceObserver()
    @Published var desktopSpaces: [DesktopSpaces] = []
    @Published var allSpaces: [Space] = []

    static let shared = SpacesViewModel()

    init() {
        loadSpaces()
    }

    func updateSystemSpaces() async -> Bool {
        await spaceObserver.updateSpaceInformation()

        let shouldUpdate = !allSpaces.elementsEqual(spaceObserver.allSpaces, by: { $0.spaceID == $1.spaceID })
            || allSpaces.isEmpty

        if shouldUpdate {
            desktopSpaces = spaceObserver.spaces
            allSpaces = spaceObserver.allSpaces
            saveSpaces()
        }
        return shouldUpdate
    }

    func loadSpaces() {
        let defaults = UserDefaults.standard
        if let savedData = defaults.data(forKey: Constants.StorageKeys.availableSpaces) {
            let decoder = JSONDecoder()
            do {
                allSpaces = try decoder.decode([Space].self, from: savedData)
                let displayIDs = Array(Set(allSpaces.map { $0.displayID }))
                desktopSpaces = displayIDs.map { displayID in
                    let spacesForDisplay = allSpaces.filter { $0.displayID == displayID }
                    return DesktopSpaces(desktopSpaces: spacesForDisplay)
                }

            } catch {
                Logger.shared.logError("Error decoding spaces: \(error)")
            }
        } else {
            Logger.shared.logInfo("No saved spaces found")
        }
    }

    func saveSpaces() {
        let encoder = JSONEncoder()
        do {
            let encodedData = try encoder.encode(allSpaces)
            let defaults = UserDefaults.standard
            defaults.set(encodedData, forKey: Constants.StorageKeys.availableSpaces)
        } catch {
            Logger.shared.logError("Error encoding spaces: \(error)")
        }
    }
}

// Testing and debugging utilities
extension SpacesViewModel {
    // Check for inconsistencies in space organization
    func validateSpaceOrganization() -> [String] {
        var issues: [String] = []

        // Check if there are duplicates in the display groups
        let displayIDs = desktopSpaces.map { $0.displayID }
        if Set(displayIDs).count != displayIDs.count {
            issues.append("Duplicate display IDs detected")
        }

        // Check if spaces are correctly assigned to their displays
        for display in desktopSpaces {
            for space in display.desktopSpaces {
                if space.displayID != display.displayID {
                    issues.append("Space \(space.spaceID) has displayID \(space.displayID) but is assigned to display \(display.displayID)")
                }
            }
        }

        // Check for missing displayIndex values
        for display in desktopSpaces {
            if display.displayIndex == 0 {
                issues.append("Display \(display.displayID) has an invalid displayIndex (0)")
            }

            for space in display.desktopSpaces {
                if space.displayIndex == 0 {
                    issues.append("Space \(space.spaceID) has an invalid displayIndex (0)")
                }

                if space.displayIndex != display.displayIndex {
                    issues.append("Space \(space.spaceID) has displayIndex \(space.displayIndex) but is in display with index \(display.displayIndex)")
                }
            }
        }

        return issues
    }
}
