import SwiftUI

struct HowToUseView: View {
    @FetchRequest(sortDescriptors: []) var spaceModel: FetchedResults<SpaceData>
    @FetchRequest(sortDescriptors: []) var focusModel: FetchedResults<FocusData>
    @ObservedObject var focusViewModel: FocusViewModel
    @ObservedObject var spacesViewModel: SpacesViewModel
    @Environment(\.managedObjectContext) var managedObjectContext

    // Add a state property to track whether data has been loaded
    @State private var dataLoaded = false

    var body: some View {
        VStack {
            HStack {
                Image(nsImage: NSImage(named: "AppIcon")!)
                    .resizable()
                    .frame(width: 100, height: 100)
                VStack(alignment: .leading) {
                    Text("Outer Spaces")
                        .font(.title)
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
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
        .onAppear {
            // Only load data if it hasn't been loaded yet
            if !dataLoaded {
                loadInitialData()
                dataLoaded = true
            }
        }
    }

    private func loadInitialData() {
        // Use our new CoreDataService to load data safely
        let loadedData = CoreDataService.shared.loadSpaces(from: managedObjectContext)
        spacesViewModel.loadSpaces(desktopSpaces: loadedData.desktops, allSpaces: loadedData.spaces)

        let focusPresets = CoreDataService.shared.loadFocusPresets(
            from: managedObjectContext,
            allSpaces: loadedData.spaces
        )
        focusViewModel.availableFocusPresets = focusPresets
    }
}
