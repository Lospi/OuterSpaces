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

    @MainActor func updateSystemSpaces() -> Bool {
        spaceObserver.updateSpaceInformation()

        let shouldUpdate = allSpaces.elementsEqual(spaceObserver.allSpaces, by: { $0.id == $1.id }) || allSpaces.isEmpty

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
