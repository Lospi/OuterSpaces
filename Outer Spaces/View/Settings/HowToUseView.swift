//
//  HowToUseView.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 06/02/24.
//

import SwiftUI

struct HowToUseView: View {
    @FetchRequest(sortDescriptors: []) var spaceModel: FetchedResults<SpaceData>
    @FetchRequest(sortDescriptors: []) var focusModel: FetchedResults<FocusData>
    @StateObject var focusViewModel: FocusViewModel
    @StateObject var spacesViewModel: SpacesViewModel

    var body: some View {
        VStack {
            HStack {
                Image(nsImage: NSImage(named: "AppIcon")!)
                    .resizable()
                    .frame(width: 100, height: 100)
                VStack(alignment: .leading) {
                    Text("Outer Spaces")
                        .font(.title)
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)")
                    Text("Developed by Lospi")
                    Text("Contact: admin@lospi.dev")
                }
            }

            VStack(alignment: .leading) {
                Text("How to Use")
                    .font(.title)
                    .padding()
                Text("1. Open the app and fetch the current available spaces (Desktops) (Only required on the first time or when new spaces are added)")
                Text("2. Create a focus preset for each focus mode that you with to use")
                Text("3. Assign the desired spaces to the focus preset")
                Text("4. Enable Automation and Accessibility permissions on the System Preferences > Security & Privacy > Accessibility for Outer Spaces (Might be prompted on the first time switching spaces)")
                Text("5. Open System Settings, Keyboard, Shortcuts, and enable Space switching shortcuts for every space on Mission Control")
                    .fontWeight(.bold)
                Text("6. Switch to Focus on System Settings, and for each focus mode, assign the corresponding focus preset to the focus filter")
                Text("7. Enjoy!")
            }

            VStack {
                Text("For a complete guide, visit our video guide on YouTube")
                    .padding()
                Button("Open YouTube") {
                    NSWorkspace.shared.open(URL(string: "https://www.youtube.com/watch?v=DTPDoeVhLaQ")!)
                }
            }
        }
        .onAppear(
        )
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
}
