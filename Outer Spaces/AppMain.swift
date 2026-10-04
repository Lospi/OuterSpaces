import AppIntents
import SettingsAccess
import SFSafeSymbols
import Sparkle
import SwiftUI

@main
struct OuterSpacesApp: App {
    @StateObject var focusViewModel = FocusViewModel.shared
    @StateObject var spacesViewModel = SpacesViewModel.shared
    @StateObject var focusStatusViewModel = FocusStatusViewModel.shared

    @ObservedObject private var returnController = FocusReturnCoordinator.shared.controller

    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: !Constants.isRunningTests,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    var body: some Scene {
        Settings {
            SettingsView(
                spacesViewModel: spacesViewModel,
                focusViewModel: focusViewModel,
                focusStatusViewModel: focusStatusViewModel,
                updater: updaterController.updater
            )
        }

        WindowGroup("How to Use", id: "how-to-use") {
            HowToUseView(focusViewModel: focusViewModel, spacesViewModel: spacesViewModel)
        }

        MenuBarExtra {
            AppMenuBar(focusViewModel: focusViewModel, spacesViewModel: spacesViewModel, focusStatusViewModel: focusStatusViewModel, returnController: returnController)
                .openSettingsAccess()
        }
        label: {
            HStack {
                Image(systemSymbol: .displayAndArrowDown)
                if let countdown = returnController.countdownText {
                    Text(countdown).monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
