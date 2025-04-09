import SFSafeSymbols
import SwiftUI

struct SpaceInfoView: View {
    @State var space: Space
    var index: Int
    @Environment(\.managedObjectContext) var managedObjectContext
    @ObservedObject var focusViewModel: FocusViewModel
    @State var customName = ""
    @Binding var isEditingSpace: Bool
    @State var isSelected = false
    
    // Use the shared permission handler
    @ObservedObject private var permissionHandler = PermissionHandler.shared
    
    var body: some View {
        VStack {
            HStack {
                if isEditingSpace {
                    Toggle(isOn: Binding(
                        get: { focusViewModel.doesFocusHasSpace(space: space) },
                        set: { _ in
                            withAnimation {
                                focusViewModel.updateFocusSpaces(relatedSpace: space)

                                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FocusData")
                                let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

                                do {
                                    try managedObjectContext.execute(batchDeleteRequest)
                                } catch {}

                                for availableFocusPreset in focusViewModel.availableFocusPresets {
                                    let focus = FocusData(context: managedObjectContext)
                                    focus.id = availableFocusPreset.id
                                    focus.name = availableFocusPreset.name
                                    
                                    // Serialize space IDs
                                    let spaceIDs = availableFocusPreset.spaces.map { $0.spaceID }
                                    if let serializedData = try? JSONEncoder().encode(spaceIDs) {
                                        focus.spacesIdsData = serializedData
                                    }
                                    
                                    focus.stageManager = availableFocusPreset.stageManager
                                }

                                FocusManager.saveFocusModels(focusViewModel.availableFocusPresets)
                            }
                        }
                    )) {}
                }
                Text(space.customName ?? "Desktop \(index + 1)")
                Spacer()
                Button {
                    switchToSpace()
                } label: {
                    Image(systemName: SFSymbol.display2.rawValue)
                }
            }
        }
        // Apply the permission handling modifier
        .withAccessibilityPermissionHandling()
    }
    
    private func switchToSpace() {
        let scriptSource = AppleScriptHelper.getCompleteAppleScriptPerIndex(
            index: index,
            stageManager: focusViewModel.selectedFocusPreset?.stageManager,
            shouldAffectStage: focusViewModel.selectedFocusPreset != nil
        )
        
        var error: NSDictionary?
        
        guard let script = NSAppleScript(source: scriptSource) else {
            print("Failed to create AppleScript")
            return
        }
        
        // Execute script without using if let
        _ = script.executeAndReturnError(&error)
        
        if error == nil {
            print("Script executed successfully")
        } else {
            if let errorDescription = error?["NSAppleScriptErrorMessage"] as? String {
                print("Script failed: \(errorDescription)")
                
                // Handle permission error
                permissionHandler.handleAppleScriptError(errorDescription)
            }
        }
    }
}
