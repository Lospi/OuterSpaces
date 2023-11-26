//
//  DisplaySpacesView.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 23/11/23.
//

import SwiftUI

struct DisplaySpacesView: View {
    @State var desktopSpace: DesktopSpaces
    var desktopIndex: Int
    @Binding var editingFocus: Bool
    @ObservedObject var focusViewModel: FocusViewModel

    var body: some View {
        VStack {
            Text("Display \(desktopIndex + 1)")
            ForEach(Array(desktopSpace.desktopSpaces.enumerated()), id: \.element) { index, space in
                SpaceInfoView(space: space, index: index, focusViewModel: focusViewModel, isEditingSpace: $editingFocus)
            }
        }
    }
}
