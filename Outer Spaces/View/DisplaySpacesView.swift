//
//  DisplaySpacesView.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 23/11/23.
//

import SwiftUI

struct DisplaySpacesView: View {
    var desktopSpaces: [Space]
    var desktopSpace: DesktopSpaces
    var desktopIndex: Int
    @State var flags: [Bool]
    @Binding var editingFocus: Bool

    var body: some View {
        VStack {
            Text("Display \(desktopIndex + 1)")
            ForEach(Array(desktopSpace.desktopSpaces.enumerated()), id: \.element) { index, space in
                SpaceInfoView(space: space, index: index, isEditingSpace: $editingFocus, toggleItem: ToggleItem(storage: self.$flags, tag: index))
            }
        }
    }
}
