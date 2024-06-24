//
//  PresetTextInputView.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 14/01/24.
//

import SwiftUI

struct PresetTextInputView: View {
    @State var newPresetName = ""
    @State var hasStageManager = false
    @ObservedObject var focusViewModel: FocusViewModel
    @Environment(\.managedObjectContext) var managedObjectContext

    var body: some View {
        HStack {
            TextField("New Preset Name", text: $newPresetName)
                .onSubmit {
                    focusViewModel.availableFocusPresets.append(Focus(name: newPresetName, spaces: [], stageManager: hasStageManager))
                    let focusFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FocusData")
                    let focusBatchDeleteRequest = NSBatchDeleteRequest(fetchRequest: focusFetchRequest)
                    do {
                        try managedObjectContext.execute(focusBatchDeleteRequest)
                    } catch {}

                    FocusManager.saveFocusModels(focusViewModel.availableFocusPresets)

                    for availableFocusPreset in focusViewModel.availableFocusPresets {
                        let focus = FocusData(context: managedObjectContext)
                        focus.id = availableFocusPreset.id
                        focus.name = availableFocusPreset.name
                        focus.spacesIds = availableFocusPreset.spaces.map { $0.spaceID }
                        focus.stageManager = availableFocusPreset.stageManager
                        PersistenceController.shared.save()
                    }

                    focusViewModel.creatingPreset.toggle()
                    newPresetName = ""
                }
            Toggle(isOn: $hasStageManager) {
                Text("Stage Manager")
            }
        }
    }
}
