import AppIntents
import CoreData
import FirebaseCore
import Sentry
import SFSafeSymbols
import Sparkle
import SwiftUI

@main
struct OuterSpacesApp: App {
    init() {
        SentrySDK.start { options in
            options.dsn = "https://82ab5e417af79a72560459cdf3f97cb3@o4506707942047744.ingest.sentry.io/4506707943161856"
            options.debug = true // Enabled debug when first installing is always helpful

            // Enable tracing to capture 100% of transactions for performance monitoring.
            // Use 'options.tracesSampleRate' to set the sampling rate.
            // We recommend setting a sample rate in production.
            options.enableTracing = true
            options.swiftAsyncStacktraces = true
        }

        FirebaseApp.configure()
    }

    let persistenceController = PersistenceController.shared
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.managedObjectContext) var managedObjectContext
    @StateObject var focusViewModel = FocusViewModel()
    @StateObject var spacesViewModel = SpacesViewModel()
    @StateObject var licensingViewModel = LicensingViewModel()

    var body: some Scene {
        Settings {
            SettingsView(spacesViewModel: spacesViewModel, licensingViewModel: licensingViewModel)
        }

        WindowGroup("How to Use", id: "how-to-use") {
            HowToUseView()
        }

        MenuBarExtra("Outer Spaces", systemImage: SFSymbol.displayAndArrowDown.rawValue) {
            AppMenuBar(focusViewModel: focusViewModel, spacesViewModel: spacesViewModel)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .menuBarExtraStyle(.window)
        .onChange(of: scenePhase) {
            persistenceController.save()
        }
    }
}
