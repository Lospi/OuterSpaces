//
//  UpdateView.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 29/01/24.
//

import Sparkle
import SwiftUI

struct UpdateView: View {
    let updater: SPUUpdater

    var body: some View {
        CheckForUpdatesView(updater: updater)
    }
}
