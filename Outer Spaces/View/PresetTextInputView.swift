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
                    // Create a new preset
                    let newPreset = Focus(
                        name: newPresetName,
                        spaces: [],
                        stageManager: hasStageManager
                    )
                    focusViewModel.availableFocusPresets.append(newPreset)

                    // Clear existing FocusData entities
                    let focusFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FocusData")
                    let focusBatchDeleteRequest = NSBatchDeleteRequest(fetchRequest: focusFetchRequest)
                    do {
                        try managedObjectContext.execute(focusBatchDeleteRequest)
                    } catch {}

                    // Save to UserDefaults
                    FocusManager.saveFocusModels(focusViewModel.availableFocusPresets)

                    // Save to Core Data
                    for availableFocusPreset in focusViewModel.availableFocusPresets {
                        let focus = FocusData(context: managedObjectContext)
                        focus.id = availableFocusPreset.id
                        focus.name = availableFocusPreset.name

                        // Serialize the space IDs
                        let spaceIDs = availableFocusPreset.spaces.map { $0.spaceID }
                        if let serializedData = try? JSONEncoder().encode(spaceIDs) {
                            focus.spacesIdsData = serializedData
                        }

                        focus.stageManager = availableFocusPreset.stageManager
                        PersistenceController.shared.save()
                    }

                    // Reset UI state
                    focusViewModel.creatingPreset.toggle()
                    newPresetName = ""
                }

            Toggle(isOn: $hasStageManager) {
                Text("Stage Manager")
            }
        }
    }
}
