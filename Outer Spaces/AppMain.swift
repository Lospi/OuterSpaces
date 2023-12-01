//
//  AppDelegate.swift
//  Spaceman
//
//  Created by Sasindu Jayasinghe on 23/11/20.
//

import AppIntents
import CoreData
import KeyboardShortcuts
import SFSafeSymbols
import SwiftUI

@main
struct SpacemanApp: App {
    let persistenceController = PersistenceController.shared
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.managedObjectContext) var managedObjectContext
    @State var settingsViewModel = SettingsViewModel(settingsModel: SettingsModel())
    @StateObject var focusViewModel = FocusViewModel()
    @AppStorage("AppData", store: Repository.suiteUserDefaults)
    var appData: Data = .init()

    var body: some Scene {
        MenuBarExtra("Outer Spaces", systemImage: SFSymbol.displayAndArrowDown.rawValue) {
            AppMenuBar(focusViewModel: focusViewModel)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .menuBarExtraStyle(.window)
        .onChange(of: scenePhase) {
            persistenceController.save()
        }
    }
}
