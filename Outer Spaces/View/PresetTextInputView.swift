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
                    // Create new preset and add to view model
                    focusViewModel.availableFocusPresets.append(
                        Focus(name: newPresetName, spaces: [], stageManager: hasStageManager)
                    )

                    // Also save to UserDefaults via FocusManager
                    FocusManager.saveFocusModels(focusViewModel.availableFocusPresets)

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
