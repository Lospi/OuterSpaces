//
//  SpaceInfoView.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 22/11/23.
//

import CoreData
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
    @Binding var didError: Bool

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
                                    focus.spacesIds = availableFocusPreset.spaces.map { $0.spaceID }
                                    PersistenceController.shared.save()
                                }

                                FocusManager.saveFocusModels(focusViewModel.availableFocusPresets)
                            }
                        }
                    )) {}
                }
                Text(space.customName ?? "Desktop \(index)")
                Spacer()
                Button {
                    var error: NSDictionary?

                    let scriptSource = AppleScriptHelper.getCompleteAppleScriptPerIndex(index: index, stageManager: focusViewModel.selectedFocusPreset?.stageManager, shouldAffectStage: focusViewModel.selectedFocusPreset != nil)

                    if let result = try? NSAppleScript(source: scriptSource)!.executeAndReturnError(&error) {
                        if let stringValue = result.stringValue {
                            print("Script executed successfully. Result: \(stringValue)")
                        } else {
                            print("Script executed successfully.")
                        }
                    } else {
                        if let errorDescription = error?["NSAppleScriptErrorMessage"] as? String {
                            print("Script failed: \(errorDescription)")
                            if errorDescription.contains("System Events") {
                                didError = true
                            }
                            print(didError)
                        }
                    }
                } label: {
                    Image(systemName: SFSymbol.display2.rawValue)
                }
            }
        }
    }
}
