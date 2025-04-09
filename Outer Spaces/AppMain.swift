import AppIntents
import SettingsAccess
import SFSafeSymbols
import Sparkle
import SwiftUI

@main
struct OuterSpacesApp: App {
    @Environment(\.scenePhase) var scenePhase
    @StateObject var focusViewModel = FocusViewModel.shared
    @StateObject var spacesViewModel = SpacesViewModel.shared
    @StateObject var focusStatusViewModel = FocusStatusViewModel.shared

    var body: some Scene {
        Settings {
            SettingsView(spacesViewModel: spacesViewModel, focusViewModel: focusViewModel, focusStatusViewModel: focusStatusViewModel)
        }

        WindowGroup("How to Use", id: "how-to-use") {
            HowToUseView(focusViewModel: focusViewModel, spacesViewModel: spacesViewModel)
        }

        MenuBarExtra("Outer Spaces", systemImage: SFSymbol.displayAndArrowDown.rawValue) {
            AppMenuBar(focusViewModel: focusViewModel, spacesViewModel: spacesViewModel, focusStatusViewModel: focusStatusViewModel)
                .openSettingsAccess()
        }
        .menuBarExtraStyle(.window)
    }
}
