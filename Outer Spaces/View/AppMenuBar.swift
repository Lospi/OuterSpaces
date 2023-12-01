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
    @AppStorage("AppData", store: Repository.suiteUserDefaults)
    var appData: Data = .init()

    @StateObject var focusViewModel = FocusViewModel()
    @StateObject var spacesViewModel = SpacesViewModel()
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(sortDescriptors: []) var spaceModel: FetchedResults<SpaceData>
    @FetchRequest(sortDescriptors: []) var focusModel: FetchedResults<FocusData>
    @State var newPresetName = ""
    @State var settingsViewModel = SettingsViewModel(settingsModel: SettingsModel())

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

    func saveSpacesToCoreData() {
        spacesViewModel.desktopSpaces.forEach {
            $0.desktopSpaces.forEach {
                let space = SpaceData(context: managedObjectContext)
                space.displayId = $0.displayID
                space.spaceId = $0.spaceID
                space.id = $0.id
                space.spaceIndex = Int16($0.spaceIndex)
                PersistenceController.shared.save()
            }
        }
    }

    func saveFocusToCoreData() {
        focusViewModel.availableFocusPresets.forEach {
            let focus = FocusData(context: managedObjectContext)
            focus.id = $0.id
            focus.name = $0.name
            focus.spacesIds = $0.spaces.map { $0.spaceID }
            PersistenceController.shared.save()
        }
    }

    func loadSpacesFromCoreData() -> [Space] {
        let loadedSpaces = spaceModel.map { space in
            Space(id: space.id!, displayID: space.displayId!, spaceID: space.spaceId!, customName: space.customName, spaceIndex: Int(space.spaceIndex))
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

        return loadedSpaces
    }

    func saveNewSpaces() {
        let isUpdated = spacesViewModel.updateSystemSpaces()
        if isUpdated {
            deleteCoreDataModel(modelName: "SpaceData")
            saveSpacesToCoreData()
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

                       UserDefaults.resetStandardUserDefaults()
                   },
                   label: { Text("Delete CoreData")
                   })
            HStack {
                Menu(focusViewModel.selectedFocusPreset?.name ?? "Select a Preset") {
                    Button("New Preset...") {
                        focusViewModel.creatingPreset.toggle()
                    }
                    ForEach(focusViewModel.availableFocusPresets) { focus in
                        PresetInfoView(focus: focus, focusViewModel: focusViewModel)
                    }
                }
                Spacer()
                if focusViewModel.selectedFocusPreset != nil {
                    Button {
                        focusViewModel.deleteFocusPreset(focusPreset: focusViewModel.selectedFocusPreset!)
                        saveFocusToCoreData()
                        FocusManager.saveFocusModels(focusViewModel.availableFocusPresets)
                    } label: {
                        Image(systemSymbol: SFSymbol.trashFill)
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

                        FocusManager.saveFocusModels(focusViewModel.availableFocusPresets)

                        focusViewModel.availableFocusPresets.forEach {
                            let focus = FocusData(context: managedObjectContext)
                            focus.id = $0.id
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
        .onChange(of: appData) { _, newValue in
            let decoder = JSONDecoder()
            guard let appDataModelDecoded = try? decoder.decode(SettingsModel.self, from: newValue) else {
                return
            }
            settingsViewModel = SettingsViewModel(settingsModel: appDataModelDecoded)
            settingsViewModel.updateSpacesOnScreen(focus: focusViewModel.availableFocusPresets.first(where: { $0.id == settingsViewModel.selectedFocusPresetId })!)
            print("--------------")
            print(focusViewModel.availableFocusPresets)
        }

        .onAppear {
            let loadedSpaces = loadSpacesFromCoreData()
            var loadedFocus: [Focus] = []

            loadedFocus = focusModel.map { focus in
                var focusData: Focus?
                if focus.spacesIds != nil {
                    if !focus.spacesIds!.isEmpty {
                        focusData = Focus(id: focus.id!, name: focus.name!, spaces: focus.spacesIds!.isEmpty ? [] : loadedSpaces.filter { focus.spacesIds!.contains($0.spaceID)
                        })
                    }
                }
                return focusData ?? Focus(id: focus.id!, name: focus.name!, spaces: [])
            }

            focusViewModel.availableFocusPresets = loadedFocus
        }
        .padding()
    }
}
