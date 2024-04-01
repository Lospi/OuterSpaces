//
//  PresetTextInputView.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 14/01/24.
//

import SwiftUI

struct PresetTextInputView: View {
    @State var newPresetName = ""
    @ObservedObject var focusViewModel: FocusViewModel
    @Environment(\.managedObjectContext) var managedObjectContext

    var body: some View {
        TextField("New Preset Name", text: $newPresetName)
            .onSubmit {
                focusViewModel.availableFocusPresets.append(Focus(name: newPresetName, spaces: []))
                let focusFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FocusData")
                let focusBatchDeleteRequest = NSBatchDeleteRequest(fetchRequest: focusFetchRequest)
                do {
                    try managedObjectContext.execute(focusBatchDeleteRequest)
                } catch {}

                FocusManager.saveFocusModels(focusViewModel.availableFocusPresets)

                focusViewModel.availableFocusPresets.forEach {
                    let focus = FocusData(context: managedObjectContext)
                    focus.id = $0.id
                    focus.name = $0.name
                    focus.spacesIds = $0.spaces.map { $0.spaceID }
                    PersistenceController.shared.save()
                }

                focusViewModel.creatingPreset.toggle()
                newPresetName = ""
            }
    }
}
