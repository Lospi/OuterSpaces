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

    static let shared = FocusViewModel()

    func selectFocusPreset(preset: Focus) {
        selectedFocusPreset = preset
        editingFocus = true
    }

    init() {
        loadFocusPresets()
    }

    func deleteFocusPreset(focusPreset: Focus) {
        availableFocusPresets.removeAll(where: { $0 == focusPreset })
        editingFocus = false
        selectedFocusPreset = nil
        saveFocusPresets()
    }

    func loadFocusPresets() {
        if let data = Repository.suiteUserDefaults.data(forKey: "FocusPresets") {
            let decoder = JSONDecoder()
            do {
                availableFocusPresets = try decoder.decode([Focus].self, from: data)
            } catch {
                Logger.shared.logError("Error decoding FocusPresets: \(error)")
            }
        }
    }

    func saveFocusPresets() {
        let encoder = JSONEncoder()
        do {
            let appDataModelEncoded = try encoder.encode(availableFocusPresets)
            Repository.suiteUserDefaults.set(appDataModelEncoded, forKey: "FocusPresets")
        } catch {
            Logger.shared.logError("Error encoding FocusPresets: \(error)")
        }
    }

    func updateSpacesFromNewRefresh(newSpaces: [Space]) {
        for space in newSpaces {
            if !availableFocusPresets.isEmpty {
                for i in 0 ..< availableFocusPresets.count {
                    if availableFocusPresets[i].spaces.contains(where: { $0.spaceID == space.spaceID }) {
                        guard let index = availableFocusPresets[i].spaces.firstIndex(where: { $0.spaceID == space.spaceID }) else { continue }
                        availableFocusPresets[i].spaces[index] = space
                    }
                }
            }
        }

        selectedFocusPreset = nil
        editingFocus = false
        saveFocusPresets()
    }

    func toggleFocusStageManager() {
        guard var selected = selectedFocusPreset,
              let focusIndex = availableFocusPresets.firstIndex(of: selected) else {
            Logger.shared.logWarning("toggleFocusStageManager called with no selected preset")
            return
        }

        selected.stageManager.toggle()
        selectedFocusPreset = selected
        availableFocusPresets[focusIndex].stageManager.toggle()
        saveFocusPresets()
    }

    func updateFocusSpaces(relatedSpace: Space) {
        guard var selected = selectedFocusPreset,
              let focusIndex = availableFocusPresets.firstIndex(of: selected) else { return }

        if selected.spaces.contains(where: { $0 == relatedSpace }) {
            selected.spaces.removeAll(where: { $0 == relatedSpace })
        } else {
            if !selected.spaces.contains(where: { $0.displayID == relatedSpace.displayID }) {
                selected.spaces.append(relatedSpace)
            } else {
                selected.spaces.removeAll(where: { $0.displayID == relatedSpace.displayID })
                selected.spaces.append(relatedSpace)
            }
        }

        selectedFocusPreset = selected
        availableFocusPresets[focusIndex].spaces = selected.spaces
        saveFocusPresets()
    }

    func doesFocusHasSpace(space: Space) -> Bool {
        return selectedFocusPreset?.spaces.contains(space) ?? false
    }
}
