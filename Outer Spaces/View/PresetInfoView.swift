//
//  PresetInfoView.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 01/12/23.
//

import SFSafeSymbols
import SwiftUI

struct PresetInfoView: View {
    @State var focus: Focus
    @ObservedObject var focusViewModel: FocusViewModel

    var body: some View {
        Button(focus.name) {
            focusViewModel.selectFocusPreset(preset: focus)
        }
    }
}
