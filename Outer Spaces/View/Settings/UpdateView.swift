//
//  UpdateView.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 29/01/24.
//

import Sparkle
import SwiftUI

struct UpdateView: View {
    private let updaterController: SPUStandardUpdaterController

    init() {
        // If you want to start the updater manually, pass false to startingUpdater and call .startUpdater() later
        // This is where you can also pass an updater delegate if you need one
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }

    var body: some View {
        CheckForUpdatesView(updater: updaterController.updater)
    }
}

#Preview {
    UpdateView()
}
