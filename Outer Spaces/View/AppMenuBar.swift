//
//  AppMenuBar.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 19/11/23.
//

import AppIntents
import SFSafeSymbols
import SwiftUI

struct AppMenuBar: View {
    let spaceObserver = SpaceObserver()
    @StateObject var focusViewModel = FocusViewModel()
    @StateObject var spacesViewModel = SpacesViewModel()
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(sortDescriptors: []) var spaceModel: FetchedResults<SpaceData>
    @FetchRequest(sortDescriptors: []) var focusModel: FetchedResults<FocusData>
    @State var newPresetName = ""

    let checkSpace = { (space: Space, setSpaces: [Space]) -> Bool in
        if setSpaces.contains(where: { $0.displayID == space.displayID }) {
            return true
        } else {
            return false
        }
    }

    func deleteCoreDataModel(modelName: String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: modelName)
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try managedObjectContext.execute(batchDeleteRequest)
        } catch {}
    }

    func saveNewSpaces() {
        let isUpdated = spacesViewModel.updateSystemSpaces()
        if isUpdated {
            deleteCoreDataModel(modelName: "SpaceData")
            spacesViewModel.desktopSpaces.forEach {
                $0.desktopSpaces.forEach {
                    let space = SpaceData(context: managedObjectContext)
                    space.displayId = $0.displayID
                    space.spaceId = $0.spaceID
                    space.id = $0.id
                    PersistenceController.shared.save()
                }
            }
        }
    }

    var body: some View {
        VStack {
            Button(action: {
                       saveNewSpaces()
                   },
                   label: { Text("Refresh Available Spaces")
                   })
            Button(action: {
                       // Create Fetch Request
                       let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SpaceData")
                       let focusFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FocusData")

                       // Create Batch Delete Request
                       let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                       let focusBatchDeleteRequest = NSBatchDeleteRequest(fetchRequest: focusFetchRequest)

                       do {
                           try managedObjectContext.execute(batchDeleteRequest)
                           try managedObjectContext.execute(focusBatchDeleteRequest)

                       } catch {
                           // Error Handling
                       }
                   },
                   label: { Text("Delete CoreData")
                   })
            Menu(focusViewModel.selectedFocusPreset?.name ?? "Select a Preset") {
                Button("New Preset...") {
                    focusViewModel.creatingPreset.toggle()
                }
                ForEach(focusViewModel.availableFocusPresets) { focus in
                    Button(focus.name) {
                        focusViewModel.selectFocusPreset(preset: focus)
                    }
                }
            }
            if focusViewModel.creatingPreset {
                TextField("New Preset Name", text: $newPresetName)
                    .onSubmit {
                        focusViewModel.availableFocusPresets.append(Focus(name: newPresetName, spaces: []))
                        let focusFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FocusData")
                        let focusBatchDeleteRequest = NSBatchDeleteRequest(fetchRequest: focusFetchRequest)
                        do {
                            try managedObjectContext.execute(focusBatchDeleteRequest)
                        } catch {}

                        focusViewModel.availableFocusPresets.forEach {
                            let focus = FocusData(context: managedObjectContext)
                            focus.id = UUID()
                            focus.name = $0.name
                            focus.spacesIds = $0.spaces.map { $0.spaceID }
                            PersistenceController.shared.save()
                        }

                        focusViewModel.creatingPreset.toggle()
                    }
            }
            Divider()
            VStack {
                ForEach(Array(spacesViewModel.desktopSpaces.enumerated()), id: \.element) { indexDesktop, desktopSpace in
                    DisplaySpacesView(desktopSpace: desktopSpace, desktopIndex: indexDesktop, editingFocus: $focusViewModel.editingFocus, focusViewModel: focusViewModel)
                }
            }
        }
        .onAppear {
            let loadedSpaces = spaceModel.map { space in
                Space(id: space.id!, displayID: space.displayId!, spaceID: space.spaceId!, customName: space.customName)
            }
            var desktopIds: [String] = []
            loadedSpaces.forEach {
                if !desktopIds.contains($0.displayID) {
                    desktopIds.append($0.displayID)
                }
            }
            var desktopSpaces: [DesktopSpaces] = []
            desktopIds.forEach { desktopId in
                let desktopPerSpace = loadedSpaces.filter { $0.displayID == desktopId }
                desktopSpaces.append(DesktopSpaces(desktopSpaces: desktopPerSpace))
            }
            spacesViewModel.loadSpaces(desktopSpaces: desktopSpaces, allSpaces: loadedSpaces)

            let loadedFocus = focusModel.map { focus in
                Focus(id: focus.id!, name: focus.name!, spaces: focus.spacesIds!.map { spaceId in
                    loadedSpaces.first(where: { $0.spaceID == spaceId })!
                })
            }

            focusViewModel.availableFocusPresets = loadedFocus
        }
        .padding()
    }
}
