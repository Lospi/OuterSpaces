//
//  SpacesViewModel.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 24/11/23.
//

import Foundation

class SpacesViewModel: ObservableObject {
    let spaceObserver = SpaceObserver()
    @Published var desktopSpaces: [DesktopSpaces] = []

    @MainActor func updateSystemSpaces() {
        SpaceObserver().updateSpaceInformation()
        desktopSpaces = spaceObserver.spaces
    }
}
