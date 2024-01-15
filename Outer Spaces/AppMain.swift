import AppIntents
import CoreData
import SettingsAccess
import SFSafeSymbols
import SwiftUI

@main
struct OuterSpacesApp: App {
    let persistenceController = PersistenceController.shared
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.managedObjectContext) var managedObjectContext
    @State var settingsViewModel = SettingsViewModel(settingsModel: SettingsModel())
    @StateObject var focusViewModel = FocusViewModel()
    @StateObject var spacesViewModel = SpacesViewModel()
    @AppStorage("AppData", store: Repository.suiteUserDefaults)
    var appData: Data = .init()

    var body: some Scene {
        Settings {
            SettingsView(spacesViewModel: spacesViewModel)
        }

        MenuBarExtra("New Spaces", systemImage: SFSymbol.displayAndArrowDown.rawValue) {
            AppMenuBar(focusViewModel: focusViewModel, spacesViewModel: spacesViewModel)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .openSettingsAccess()
        }
        .menuBarExtraStyle(.window)
        .onChange(of: scenePhase) {
            persistenceController.save()
        }
    }
}
