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

    func updateSelectedPresetSpaces(selectedSpace: Space) {}

    func saveNewSpaces() {
        deleteCoreDataModel(modelName: "SpaceData")
        spacesViewModel.desktopSpaces.forEach {
            $0.desktopSpaces.forEach {
                let space = SpaceData(context: managedObjectContext)
                space.displayId = $0.displayID
                space.spaceId = $0.spaceID
                space.id = UUID()
                PersistenceController.shared.save()
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

                       // Create Batch Delete Request
                       let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

                       do {
                           try managedObjectContext.execute(batchDeleteRequest)

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
                        focusViewModel.creatingPreset.toggle()
                    }
            }
            Divider()
            VStack {
                ForEach(Array(spacesViewModel.desktopSpaces.enumerated()), id: \.element) { indexDesktop, desktopSpace in
                    DisplaySpacesView(desktopSpaces: desktopSpace.desktopSpaces, desktopSpace: desktopSpace, desktopIndex: indexDesktop, flags: Array(repeating: false, count: desktopSpace.desktopSpaces.count), editingFocus: $focusViewModel.editingFocus)
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
            spacesViewModel.desktopSpaces = desktopSpaces

            var spaceAppEntities: [SpaceAppEntity] = []

            spacesViewModel.desktopSpaces.forEach { desktopSpace in
                desktopSpace.desktopSpaces.forEach { space in
                    let spaceAppEntity = SpaceAppEntity(id: space.id, title: space.customName ?? "Desktop")
                    spaceAppEntities.append(spaceAppEntity)
                }
            }

            SpaceAppEntityQuery.entities = spaceAppEntities
        }
        .padding()
    }
}
