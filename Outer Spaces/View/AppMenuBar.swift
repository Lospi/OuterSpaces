import AppIntents
import SettingsAccess
import SFSafeSymbols
import SwiftUI

// Status enum for operations
enum OperationStatus {
    case idle
    case loading
    case success
    case error(String)
    
    var icon: SFSymbol {
        switch self {
        case .idle: return .circleFill
        case .loading: return .clockFill
        case .success: return .checkmarkCircleFill
        case .error: return .exclamationmarkCircleFill
        }
    }
    
    var color: Color {
        switch self {
        case .idle: return .gray
        case .loading: return .blue
        case .success: return .green
        case .error: return .red
        }
    }
}

struct AppMenuBar: View {
    @AppStorage("AppData", store: Repository.suiteUserDefaults)
    var appData: Data = .init()

    @ObservedObject var focusViewModel: FocusViewModel
    @ObservedObject var spacesViewModel: SpacesViewModel

    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) var openWindow
    
    @State private var refreshStatus: OperationStatus = .idle
    @State private var focusStatus: OperationStatus = .idle
    @State private var showingNewPresetSheet = false
    @State private var settingsViewModel = SettingsViewModel(settingsModel: SettingsModel())
    
    // Animation states
    @State private var isRefreshing = false
    @State private var showSuccessAnimation = false
    
    // Use the shared permission handler
    @ObservedObject private var permissionHandler = PermissionHandler.shared
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with action buttons
            HStack {
                Spacer()
                HeaderButton(icon: .arrowClockwise, action: refreshSpaces, tooltip: "Refresh Spaces")
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    .animation(isRefreshing ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                
                HeaderButton(icon: .gearshape, action: openSystemSettings, tooltip: "Settings")
                HeaderButton(icon: .questionmarkCircle, action: openHelpWindow, tooltip: "Help")
                HeaderButton(icon: .power, action: quitApp, tooltip: "Quit")
            }
            .padding(.bottom, 8)
            
            // Permission warning if needed
            if !permissionHandler.hasAccessibilityPermission {
                HStack {
                    Image(systemSymbol: .exclamationmarkTriangleFill)
                        .foregroundColor(.orange)
                    
                    Text("Accessibility permission needed")
                        .font(.caption)
                    
                    Spacer()
                    
                    Button("Fix") {
                        permissionHandler.requestAccessibilityPermission()
                    }
                    .font(.caption)
                    .buttonStyle(.borderedProminent)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Focus selection area
            FocusSelectionBar(
                focusViewModel: focusViewModel,
                onAddNew: { showingNewPresetSheet = true }
            )
            
            Divider()
                .padding(.vertical, 4)
            
            // Spaces list
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(spacesViewModel.desktopSpaces.enumerated()), id: \.element) { indexDesktop, desktopSpace in
                        DisplayCard(
                            title: "Display \(indexDesktop + 1)",
                            desktopSpace: desktopSpace,
                            desktopIndex: indexDesktop,
                            focusViewModel: focusViewModel,
                            startIndex: indexDesktop > 0 ?
                                spacesViewModel.desktopSpaces[indexDesktop - 1].desktopSpaces.count : 0,
                            onError: handleError
                        )
                    }
                    
                    // Empty state
                    if spacesViewModel.desktopSpaces.isEmpty {
                        EmptyStateView(
                            icon: .display,
                            title: "No Spaces Found",
                            subtitle: "Click the refresh button to detect spaces",
                            buttonTitle: "Refresh Spaces",
                            action: refreshSpaces
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(maxHeight: 400)
        }
        .padding(16)
        .frame(width: 360)
        .onChange(of: appData) { newValue in
            handleAppDataChange(newValue)
        }
        .sheet(isPresented: $showingNewPresetSheet) {
            NewPresetSheet(
                focusViewModel: focusViewModel,
                managedObjectContext: managedObjectContext,
                onDismiss: { showingNewPresetSheet = false }
            )
            .frame(width: 340, height: 200)
        }
        .onAppear {
            loadInitialData()
            // Check accessibility permission on appear
            permissionHandler.checkAccessibilityPermission()
        }
        .overlay(
            // Success animation overlay
            ZStack {
                if showSuccessAnimation {
                    SuccessAnimationView()
                        .transition(.opacity)
                }
            }
        )
        // Add permission handling alerts
        .withAccessibilityPermissionHandling()
    }
    
    // MARK: - Action Methods
    
    private func refreshSpaces() {
        withAnimation {
            refreshStatus = .loading
            isRefreshing = true
        }
        
        Task {
            await Task.sleep(500_000_000) // Simulate network delay - 0.5s
            
            let isUpdated = await spacesViewModel.updateSystemSpaces()
            if isUpdated {
                CoreDataService.shared.syncSpaces(
                    allSpaces: spacesViewModel.allSpaces,
                    in: managedObjectContext
                )
                focusViewModel.updateSpacesFromNewRefresh(newSpaces: spacesViewModel.allSpaces)
                
                // Show success animation
                withAnimation {
                    refreshStatus = .success
                    showSuccessAnimation = true
                }
                
                // Hide after delay
                Task {
                    await Task.sleep(1_500_000_000) // 1.5s
                    withAnimation {
                        showSuccessAnimation = false
                        refreshStatus = .idle
                    }
                }
            } else {
                refreshStatus = .idle
            }
            
            isRefreshing = false
        }
    }
    
    private func openSystemSettings() {
        Task {
            try? openSettings()
        }
    }
    
    private func openHelpWindow() {
        // Opening the window using the ID we registered in the App struct
        openWindow(id: "how-to-use")
        
        // Note: The Core Data context will be provided by the environment
        // in the OuterSpacesApp struct for the window
    }
    
    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    private func handleError(_ message: String) {
        refreshStatus = .error(message)
    }
    
    private func loadInitialData() {
        let loadedData = CoreDataService.shared.loadSpaces(from: managedObjectContext)
        spacesViewModel.loadSpaces(desktopSpaces: loadedData.desktops, allSpaces: loadedData.spaces)
        
        let focusPresets = CoreDataService.shared.loadFocusPresets(
            from: managedObjectContext,
            allSpaces: loadedData.spaces
        )
        focusViewModel.availableFocusPresets = focusPresets
    }
    
    private func handleAppDataChange(_ newValue: Data) {
        let decoder = JSONDecoder()
        guard let appDataModelDecoded = try? decoder.decode(SettingsModel.self, from: newValue) else {
            return
        }
        
        settingsViewModel = SettingsViewModel(settingsModel: appDataModelDecoded)
        
        guard let selectedFocus = focusViewModel.availableFocusPresets.first(where: {
            $0.id == settingsViewModel.selectedFocusPresetId
        }) else {
            return
        }
        
        // Use Task to call the async method
        Task {
            do {
                let didError = try await settingsViewModel.updateSpacesOnScreen(focus: selectedFocus)
                if didError {
                    // Permission error was already handled by PermissionHandler
                }
            } catch {
                // Handle any other errors
                print("Error switching spaces: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Supporting Views

struct HeaderButton: View {
    let icon: SFSymbol
    let action: () -> Void
    let tooltip: String
    
    var body: some View {
        Button(action: action) {
            Image(systemSymbol: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .help(tooltip)
    }
}

struct FocusSelectionBar: View {
    @ObservedObject var focusViewModel: FocusViewModel
    @Environment(\.managedObjectContext) var managedObjectContext
    let onAddNew: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Menu {
                    Button("New Preset...") {
                        onAddNew()
                    }
                    
                    if !focusViewModel.availableFocusPresets.isEmpty {
                        Divider()
                        
                        ForEach(focusViewModel.availableFocusPresets) { focus in
                            Button(focus.name) {
                                focusViewModel.selectFocusPreset(preset: focus)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(focusViewModel.selectedFocusPreset?.name ?? "Select Focus Preset")
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        Spacer()
                        Image(systemSymbol: .chevronDown)
                            .font(.caption)
                    }
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
                }
                
                if let selectedPreset = focusViewModel.selectedFocusPreset {
                    Spacer().frame(width: 8)
                    
                    // Stage Manager toggle
                    Toggle(isOn: Binding(
                        get: { selectedPreset.stageManager },
                        set: { _ in
                            focusViewModel.toggleFocusStageManager()
                            CoreDataService.shared.syncFocusPresets(
                                focusPresets: focusViewModel.availableFocusPresets,
                                in: managedObjectContext
                            )
                        }
                    )) {
                        Image(systemSymbol: .squareOnSquare)
                    }
                    .toggleStyle(SwitchToggleStyle())
                    .help("Enable/Disable Stage Manager")
                    
                    // Delete button
                    Button {
                        focusViewModel.deleteFocusPreset(focusPreset: selectedPreset)
                        CoreDataService.shared.syncFocusPresets(
                            focusPresets: focusViewModel.availableFocusPresets,
                            in: managedObjectContext
                        )
                    } label: {
                        Image(systemSymbol: .trashFill)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Delete Focus Preset")
                }
            }
            
            // Editing indicator
            if focusViewModel.editingFocus, let selectedPreset = focusViewModel.selectedFocusPreset {
                HStack {
                    Image(systemSymbol: .infoCircle)
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text("Editing \"\(selectedPreset.name)\" - Select spaces to include")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Done") {
                        focusViewModel.editingFocus = false
                    }
                    .font(.caption)
                    .buttonStyle(BorderlessButtonStyle())
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

struct DisplayCard: View {
    var title: String
    var desktopSpace: DesktopSpaces
    var desktopIndex: Int
    @ObservedObject var focusViewModel: FocusViewModel
    var startIndex: Int
    var onError: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Display header
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            // Spaces grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                ForEach(Array(desktopSpace.desktopSpaces.enumerated()), id: \.element) { index, space in
                    SpaceCard(
                        space: space,
                        index: desktopIndex != 0 ? startIndex + index : index,
                        focusViewModel: focusViewModel,
                        isEditingSpace: $focusViewModel.editingFocus,
                        onError: onError
                    )
                }
            }
        }
        .padding(12)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

struct SpaceCard: View {
    @State var space: Space
    var index: Int
    @ObservedObject var focusViewModel: FocusViewModel
    @Environment(\.managedObjectContext) var managedObjectContext
    @Binding var isEditingSpace: Bool
    var onError: (String) -> Void
    
    @State private var isHovering = false
    @State private var isSelected = false
    @State private var customName = ""
    
    var body: some View {
        VStack(spacing: 4) {
            if isEditingSpace, let selectedPreset = focusViewModel.selectedFocusPreset {
                // Selection mode for focus editing
                Button {
                    focusViewModel.updateFocusSpaces(relatedSpace: space)
                    CoreDataService.shared.syncFocusPresets(
                        focusPresets: [selectedPreset],
                        in: managedObjectContext
                    )
                } label: {
                    SpaceCardContent(
                        space: space,
                        index: index,
                        isSelected: focusViewModel.doesFocusHasSpace(space: space)
                    )
                }
                .buttonStyle(SpaceCardButtonStyle())
            } else {
                // Regular display mode
                Button {
                    switchToSpace(index: index)
                } label: {
                    SpaceCardContent(
                        space: space,
                        index: index,
                        isSelected: space.isActive
                    )
                }
                .buttonStyle(SpaceCardButtonStyle())
            }
        }
    }
    
    private func switchToSpace(index: Int) {
        let scriptSource = AppleScriptHelper.getCompleteAppleScriptPerIndex(
            index: index,
            stageManager: focusViewModel.selectedFocusPreset?.stageManager,
            shouldAffectStage: focusViewModel.selectedFocusPreset != nil
        )
        
        var error: NSDictionary?
        
        guard let script = NSAppleScript(source: scriptSource) else {
            onError("Failed to create AppleScript")
            return
        }
        
        // Execute script and check for errors - don't use if let here
        _ = script.executeAndReturnError(&error)
        
        if error == nil {
            // Success
            print("Space switched successfully")
        } else {
            if let errorDescription = error?["NSAppleScriptErrorMessage"] as? String {
                print("Script failed: \(errorDescription)")
                onError(errorDescription)
            } else {
                onError("Unknown script execution error")
            }
        }
    }
}

struct SpaceCardContent: View {
    var space: Space
    var index: Int
    var isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.1))
                    .frame(width: 44, height: 36)
                
                Text("\(index + 1)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .primary)
            }
            
            Text(space.customName ?? "Desktop \(index + 1)")
                .font(.caption)
                .foregroundColor(isSelected ? .blue : .primary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 80)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

struct SpaceCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct NewPresetSheet: View {
    @ObservedObject var focusViewModel: FocusViewModel
    var managedObjectContext: NSManagedObjectContext
    let onDismiss: () -> Void
    
    @State private var presetName = ""
    @State private var hasStageManager = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Create New Focus Preset")
                .font(.headline)
            
            TextField("Preset Name", text: $presetName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Toggle("Enable Stage Manager", isOn: $hasStageManager)
            
            HStack {
                Button("Cancel") {
                    onDismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Create") {
                    createPreset()
                    onDismiss()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(presetName.isEmpty)
            }
        }
        .padding()
    }
    
    private func createPreset() {
        let newPreset = Focus(name: presetName, spaces: [], stageManager: hasStageManager)
        focusViewModel.availableFocusPresets.append(newPreset)
        
        CoreDataService.shared.syncFocusPresets(
            focusPresets: focusViewModel.availableFocusPresets,
            in: managedObjectContext
        )
        
        // Also update user defaults
        FocusManager.saveFocusModels(focusViewModel.availableFocusPresets)
    }
}

struct EmptyStateView: View {
    var icon: SFSymbol
    var title: String
    var subtitle: String
    var buttonTitle: String
    var action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemSymbol: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: action) {
                Text(buttonTitle)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct SuccessAnimationView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            Circle()
                .fill(Color.green)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemSymbol: .checkmark)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                )
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Auto-dismiss after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.2)) {
                    opacity = 0
                }
            }
        }
    }
}
