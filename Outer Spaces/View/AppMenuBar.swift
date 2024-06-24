//
//  AppMenuBar.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 19/11/23.
//

import AppIntents
import SettingsAccess
import SFSafeSymbols
import SwiftUI

struct AppMenuBar: View {
    @AppStorage("AppData", store: Repository.suiteUserDefaults)
    var appData: Data = .init()

    @ObservedObject var focusViewModel: FocusViewModel
    @ObservedObject var spacesViewModel: SpacesViewModel

    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.openSettings) private var openSettings
    @FetchRequest(sortDescriptors: []) var spaceModel: FetchedResults<SpaceData>
    @FetchRequest(sortDescriptors: []) var focusModel: FetchedResults<FocusData>
    @State var settingsViewModel = SettingsViewModel(settingsModel: SettingsModel())
    @State var didError = false

    func loadSpacesFromCoreData() -> (spaces: [Space], desktops: [DesktopSpaces]) {
        let loadedSpaces = spaceModel.map { space in
            Space(id: space.id!, displayID: space.displayId!, spaceID: space.spaceId!, customName: space.customName, spaceIndex: Int(space.spaceIndex))
        }
        var desktopIds: [String] = []
        for loadedSpace in loadedSpaces {
            if !desktopIds.contains(loadedSpace.displayID) {
                desktopIds.append(loadedSpace.displayID)
            }
        }
        var desktopSpaces: [DesktopSpaces] = []
        for desktopId in desktopIds {
            let desktopPerSpace = loadedSpaces.filter { $0.displayID == desktopId }
            desktopSpaces.append(DesktopSpaces(desktopSpaces: desktopPerSpace))
        }

        return (spaces: loadedSpaces, desktops: desktopSpaces)
    }

    func saveNewSpaces() {
        let isUpdated = spacesViewModel.updateSystemSpaces()
        if isUpdated {
            CoreDataManager.shared.deleteCoreDataModel(modelName: "SpaceData", managedObjectContext: managedObjectContext)
            CoreDataManager.shared.saveSpacesToCoreData(spacesViewModel: spacesViewModel, managedObjectContext: managedObjectContext)
        }
    }

    func onAppear() {
        let loadedSpaces = loadSpacesFromCoreData()
        spacesViewModel.loadSpaces(desktopSpaces: loadedSpaces.desktops, allSpaces: loadedSpaces.spaces)
        var loadedFocus: [Focus] = []

        loadedFocus = focusModel.map { focus in
            var focusData: Focus?
            if focus.spacesIds != nil {
                if !focus.spacesIds!.isEmpty {
                    focusData = Focus(id: focus.id!, name: focus.name!, spaces: focus.spacesIds!.isEmpty ? [] : loadedSpaces.spaces.filter { focus.spacesIds!.contains($0.spaceID)
                    }, stageManager: focus.stageManager)
                }
            }
            return focusData ?? Focus(id: focus.id!, name: focus.name!, spaces: [], stageManager: false)
        }

        focusViewModel.availableFocusPresets = loadedFocus
    }

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                           saveNewSpaces()
                           focusViewModel.updateSpacesFromNewRefresh(newSpaces: spacesViewModel.allSpaces)
                       },
                       label: { Text("Refresh Available Spaces")
                       })
                Spacer()
                Button(action: { try? openSettings() }, label: {
                    Image(systemSymbol: SFSymbol.gearshape)
                })
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }, label: {
                    Image(systemSymbol: SFSymbol.power)
                })
            }
            HStack {
                Menu(focusViewModel.selectedFocusPreset?.name ?? String(localized: "Select Preset")) {
                    Button("New Preset...") {
                        focusViewModel.selectedFocusPreset = nil
                        focusViewModel.creatingPreset = true
                        focusViewModel.editingFocus = false
                    }
                    ForEach(focusViewModel.availableFocusPresets) { focus in
                        Button(focus.name) {
                            focusViewModel.selectFocusPreset(preset: focus)
                            focusViewModel.creatingPreset = false
                        }
                    }
                }
                Spacer()
                if focusViewModel.selectedFocusPreset != nil {
                    Toggle(isOn: Binding(
                        get: { focusViewModel.selectedFocusPreset!.stageManager },
                        set: { _ in
                            withAnimation {
                                focusViewModel.toggleFocusStageManager()

                                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FocusData")
                                let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

                                do {
                                    try managedObjectContext.execute(batchDeleteRequest)
                                } catch {}

                                focusViewModel.availableFocusPresets.forEach {
                                    let focus = FocusData(context: managedObjectContext)
                                    focus.id = $0.id
                                    focus.name = $0.name
                                    focus.spacesIds = $0.spaces.map { $0.spaceID }
                                    PersistenceController.shared.save()
                                }

                                FocusManager.saveFocusModels(focusViewModel.availableFocusPresets)
                            }
                        }
                    )) {
                        Image(systemSymbol: .squareOnSquare)
                    }
                    Button {
                        focusViewModel.deleteFocusPreset(focusPreset: focusViewModel.selectedFocusPreset!)
                        CoreDataManager.shared.saveFocusToCoreData(focusViewModel: focusViewModel, managedObjectContext: managedObjectContext)
                        FocusManager.saveFocusModels(focusViewModel.availableFocusPresets)
                    } label: {
                        Image(systemSymbol: SFSymbol.trashFill)
                    }
                }
            }
            if focusViewModel.creatingPreset {
                PresetTextInputView(focusViewModel: focusViewModel)
            }
            Divider()
            VStack {
                ForEach(Array(spacesViewModel.desktopSpaces.enumerated()), id: \.element) { indexDesktop, desktopSpace in
                    DisplaySpacesView(desktopSpace: desktopSpace, desktopIndex: indexDesktop, editingFocus: $focusViewModel.editingFocus, focusViewModel: focusViewModel, startIndex: spacesViewModel.desktopSpaces[(indexDesktop - 1).clamped(to: 0 ... Int.max)].desktopSpaces.count, didError: $didError)
                }
            }
        }
        .onChange(of: appData) { newValue in
            let decoder = JSONDecoder()
            guard let appDataModelDecoded = try? decoder.decode(SettingsModel.self, from: newValue) else {
                return
            }
            settingsViewModel = SettingsViewModel(settingsModel: appDataModelDecoded)
            didError = settingsViewModel.updateSpacesOnScreen(focus: focusViewModel.availableFocusPresets.first(where: { $0.id == settingsViewModel.selectedFocusPresetId })!)
        }
        .alert(isPresented: $didError) {
            Alert(title: Text("Error"),
                  message: Text("Please enable System Events for Outer Spaces in System Preferences > Security & Privacy > Accessibility & Automation: " + (settingsViewModel.errorMessage ?? "")),
                  dismissButton: .default(Text("OK")))
        }

        .onAppear {
            onAppear()
        }
        .padding()
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
