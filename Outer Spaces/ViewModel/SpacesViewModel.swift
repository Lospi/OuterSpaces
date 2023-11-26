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

    @MainActor func updateSystemSpaces() {
        spaceObserver.updateSpaceInformation()
        desktopSpaces = spaceObserver.spaces
        allSpaces = spaceObserver.allSpaces
    }

    func loadSpaces(desktopSpaces: [DesktopSpaces], allSpaces: [Space]) {
        self.desktopSpaces = desktopSpaces
        self.allSpaces = allSpaces
    }
}
