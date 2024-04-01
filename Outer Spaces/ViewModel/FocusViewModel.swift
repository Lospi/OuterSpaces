//
//  FocusViewModel.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 23/11/23.
//

import Foundation

class FocusViewModel: ObservableObject {
    @Published var availableFocusPresets: [Focus] = []
    @Published var selectedFocusPreset: Focus? = nil
    @Published var creatingPreset = false
    @Published var editingFocus: Bool = false

    func selectFocusPreset(preset: Focus) {
        selectedFocusPreset = preset
        editingFocus = true
    }

    func deleteFocusPreset(focusPreset: Focus) {
        availableFocusPresets.removeAll(where: { $0 == focusPreset })
        editingFocus = false
        selectedFocusPreset = nil
    }

    func updateSpacesFromNewRefresh(newSpaces: [Space]) {
        for space in newSpaces {
            if !availableFocusPresets.isEmpty {
                for i in 0 ..< availableFocusPresets.count {
                    if availableFocusPresets[i].spaces.contains(where: { $0.spaceID == space.spaceID }) {
                        let index = availableFocusPresets[i].spaces.firstIndex(where: { $0.spaceID == space.spaceID })
                        availableFocusPresets[i].spaces[index!] = space
                    }
                }
            }
        }

        selectedFocusPreset = nil
        editingFocus = false
    }

    func updateFocusSpaces(relatedSpace: Space) {
        let focusIndex = availableFocusPresets.firstIndex(of: selectedFocusPreset!)
        if selectedFocusPreset!.spaces.contains(where: { $0 == relatedSpace }) {
            selectedFocusPreset!.spaces.removeAll(where: { $0 == relatedSpace })
        } else {
            if !selectedFocusPreset!.spaces.contains(where: { $0.displayID == relatedSpace.displayID }) {
                selectedFocusPreset!.spaces.append(relatedSpace)
            } else {
                selectedFocusPreset!.spaces.removeAll(where: { $0.displayID == relatedSpace.displayID })
                selectedFocusPreset!.spaces.append(relatedSpace)
            }
        }

        availableFocusPresets[focusIndex!].spaces = selectedFocusPreset!.spaces
    }

    func doesFocusHasSpace(space: Space) -> Bool {
        return selectedFocusPreset!.spaces.contains(space)
    }
}
