//
//  Buttons.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 25/03/25.
//

import SFSafeSymbols
import SwiftUI

struct SpaceCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
