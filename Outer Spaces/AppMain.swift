import AppIntents
import CoreData
import SettingsAccess
import SFSafeSymbols
import Sparkle
import SwiftUI

@main
struct OuterSpacesApp: App {
    let persistenceController = PersistenceController.shared
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.managedObjectContext) var managedObjectContext
    @StateObject var focusViewModel = FocusViewModel()
    @StateObject var spacesViewModel = SpacesViewModel()

    var body: some Scene {
        Settings {
            SettingsView(spacesViewModel: spacesViewModel)
        }

        WindowGroup("How to Use", id: "how-to-use") {
            HowToUseView(focusViewModel: focusViewModel, spacesViewModel: spacesViewModel)
        }

        MenuBarExtra("Outer Spaces", systemImage: SFSymbol.displayAndArrowDown.rawValue) {
            AppMenuBar(focusViewModel: focusViewModel, spacesViewModel: spacesViewModel)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .openSettingsAccess()
        }
        .menuBarExtraStyle(.window)
        .onChange(of: scenePhase) { _ in
            persistenceController.save()
        }
    }
}
