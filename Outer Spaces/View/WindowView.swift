//
//  WindowView.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 01/12/23.
//

import LaunchAtLogin
import SFSafeSymbols
import SwiftUI

struct SettingsView: View {
    @State var showOnLogin = true
    @StateObject var spacesViewModel: SpacesViewModel
    @Environment(\.managedObjectContext) var managedObjectContext
    @State private var rectPosition = CGPoint(x: 50, y: 50)

    func saveNewSpaces() {
        let isUpdated = spacesViewModel.updateSystemSpaces()
        if isUpdated {
            CoreDataManager.shared.deleteCoreDataModel(modelName: "SpaceData", managedObjectContext: managedObjectContext)
            CoreDataManager.shared.saveSpacesToCoreData(spacesViewModel: spacesViewModel, managedObjectContext: managedObjectContext)
        }
    }

    var body: some View {
        VStack {
            VStack {
                Text("Settings")
                    .font(.title)
                    .padding()
                LaunchAtLogin.Toggle {
                    Text("Launch at login")
                }
            }
            .padding()

            VStack {
                Text("Shortcuts")
                    .font(.title)
                    .padding()
                Button("Keyboard Shortcuts") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.keyboard?Shortcuts")!)
                }
                .onDrag {
                    NSItemProvider()
                }
                Button("Privacy and Security") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension")!)
                }
            }

            VStack {
                Text("About")
                    .font(.title)
                    .padding()
                HStack {
                    Image(nsImage: NSImage(named: "AppIcon")!)
                        .resizable()
                        .frame(width: 50, height: 50)
                    VStack {
                        Text("New Spaces")
                        Text("Developed by Lospi")
                        Text("Contact: admin@lospi.dev")
                    }
                }
            }
        }
        .frame(width: 500, height: 500)
    }
}
