//
//  ExclusiveToggleView.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 23/11/23.
//

import SwiftUI

struct ToggleItem: View {
    @Binding var storage: [Bool]
    @ObservedObject var focusViewModel: FocusViewModel
    var relatedSpace: Space
    var tag: Int

    var body: some View {
        let isOn = Binding(get: { self.storage[self.tag] },
                           set: { value in
                               withAnimation {
                                   // If the toggle is being turned off, set all toggles to false
                                   if !value {
                                       self.storage = Array(repeating: false, count: self.storage.count)
                                   } else {
                                       // If the toggle is being turned on, set only the selected toggle to true
                                       self.storage = self.storage.enumerated().map { $0.0 == self.tag }
                                   }
                                   focusViewModel.updateFocusSpaces(relatedSpace: relatedSpace)
                               }
                           })
        return Toggle(isOn: isOn) {}
            .toggleStyle(.checkbox)
    }
}
