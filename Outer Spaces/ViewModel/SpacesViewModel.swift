//
//  SpacesViewModel.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 24/11/23.
//

import Foundation
import SwiftUI

class SpacesViewModel: ObservableObject {
    let spaceObserver = SpaceObserver()
    @Published var desktopSpaces: [DesktopSpaces] = []
    @Published var allSpaces: [Space] = []

    @MainActor func updateSystemSpaces() async -> Bool {
        await spaceObserver.updateSpaceInformation()

        let shouldUpdate = allSpaces.elementsEqual(spaceObserver.allSpaces, by: { $0.id == $1.id })
            || allSpaces.isEmpty || allSpaces.count != spaceObserver.allSpaces.count

        if shouldUpdate {
            desktopSpaces = spaceObserver.spaces
            allSpaces = spaceObserver.allSpaces
        }
        return shouldUpdate
    }
    
    func loadSpaces(desktopSpaces: [DesktopSpaces], allSpaces: [Space]) {
        self.desktopSpaces = desktopSpaces
        self.allSpaces = allSpaces
    }
}

extension Array where Element: Comparable {
    func containsSameElements(as other: [Element]) -> Bool {
        return count == other.count && sorted() == other.sorted()
    }
}

// Testing and debugging utilities
extension SpacesViewModel {
    // Debug function to print current space organization
    func debugPrintSpaceOrganization() {
        print("\n=== CURRENT SPACE ORGANIZATION ===")
        print("Total displays: \(desktopSpaces.count)")
        print("Total spaces: \(allSpaces.count)")
        
        for (i, display) in desktopSpaces.enumerated() {
            print("\nDISPLAY \(i+1) (\(display.displayID))")
            print("  Spaces count: \(display.desktopSpaces.count)")
            
            for (j, space) in display.desktopSpaces.enumerated() {
                print("  SPACE \(j+1):")
                print("    ID: \(space.spaceID)")
                print("    Display ID: \(space.displayID)")
                print("    Display Index: \(space.displayIndex)")
                print("    Space Index: \(space.spaceIndex)")
                print("    Custom Name: \(space.customName ?? "None")")
                print("    Active: \(space.isActive)")
            }
        }
        print("\n===============================\n")
    }
    
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
