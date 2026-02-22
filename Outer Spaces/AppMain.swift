import AppIntents
import SettingsAccess
import SFSafeSymbols
import Sparkle
import SwiftUI

@main
struct OuterSpacesApp: App {
    @ObservedObject var focusViewModel = FocusViewModel.shared
    @ObservedObject var spacesViewModel = SpacesViewModel.shared
    @ObservedObject var focusStatusViewModel = FocusStatusViewModel.shared

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
