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

import AppIntents
import SettingsAccess
import SFSafeSymbols
import SwiftUI

struct AppMenuBar: View {
    // MARK: - Environment & Storage

    @AppStorage("AppData", store: Repository.suiteUserDefaults)
    private var appData: Data = .init()
        
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.openSettings) private var openSettings
    @Environment(\.colorScheme) private var colorScheme
        
    // MARK: - View Models

    @StateObject var focusViewModel: FocusViewModel
    @StateObject var spacesViewModel: SpacesViewModel
    @StateObject var focusStatusViewModel: FocusStatusViewModel
        
    // MARK: - State

    @State private var settingsViewModel = SettingsViewModel()
    @State private var errorState: ErrorState?
    @State private var isRefreshing = false
    @State private var showNewPresetSheet = false
    @State private var showSuccessAnimation = false
        
    // MARK: - Constants

    private let cardSpacing: CGFloat = 12
    private let actionButtonSize: CGFloat = 36
        
    // MARK: - Body

    var body: some View {
        content
            .alert(item: $errorState) { errorState in
                Alert(
                    title: Text(errorState.title),
                    message: Text(errorState.message),
                    dismissButton: .default(Text("OK")) {
                        if errorState.isPermissionIssue {
                            try? openSettings()
                        }
                    }
                )
            }
            .sheet(isPresented: $showNewPresetSheet) {
                NewPresetSheet(
                    focusViewModel: focusViewModel,
                    managedObjectContext: managedObjectContext,
                    onDismiss: { showNewPresetSheet = false }
                )
                .frame(width: 200, height: 250)
            }
            .overlay {
                if showSuccessAnimation {
                    SuccessAnimationView()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showSuccessAnimation = false
                            }
                        }
                }
            }
            .onAppear {
                Task {
                    onAppear()
                }
            }
            .padding()
    }
        
    // MARK: - Content Views
        
    @ViewBuilder
    private var content: some View {
        VStack(spacing: 16) {
            headerBar
                
            focusStatusBar
                
            presetSelectionBar
                
            Divider()
                .padding(.vertical, 4)
                
            if isRefreshing {
                loadingView
            } else if spacesViewModel.desktopSpaces.isEmpty {
                emptyStateView
            } else {
                spacesGrid
            }
        }
        .frame(width: 400)
    }
        
    private var headerBar: some View {
        HStack {
            refreshButton
                
            Spacer()
                
            configButtons
        }
        .padding(.bottom, 4)
    }
        
    private var refreshButton: some View {
        Button {
            refreshSpaces()
        } label: {
            HStack(spacing: 8) {
                Image(systemSymbol: isRefreshing ? .arrowClockwise : .arrowTriangle2CirclepathCircle)
                    .font(.system(size: 14, weight: .medium))
                    
                Text("Refresh Spaces")
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isRefreshing)
        .help("Refresh available spaces")
        .keyboardShortcut("r", modifiers: .command)
    }
        
    private var configButtons: some View {
        HStack(spacing: 12) {
            Button {
                showNewPresetSheet = true
            } label: {
                Image(systemSymbol: .plusCircle)
                    .font(.system(size: 16, weight: .medium))
            }
            .buttonStyle(PlainButtonStyle())
            .help("Create New Preset")
                
            Button {
                try? openSettings()
            } label: {
                Image(systemSymbol: .gearshape)
                    .font(.system(size: 16, weight: .medium))
            }
            .buttonStyle(PlainButtonStyle())
            .help("Open Settings")
                
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemSymbol: .power)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(PlainButtonStyle())
            .help("Quit Application")
        }
    }
        
    private var focusStatusBar: some View {
        Group {
            if focusStatusViewModel.isFocusActive {
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Focus mode active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 4)
                .background(Color.green.opacity(0.07))
                .cornerRadius(4)
            }
        }
    }
        
    private var presetSelectionBar: some View {
        VStack(spacing: 10) {
            HStack {
                PresetMenuButton(
                    focusViewModel: focusViewModel,
                    onNewPreset: { showNewPresetSheet = true }
                )
                    
                Spacer()
                    
                if let selectedPreset = focusViewModel.selectedFocusPreset {
                    HStack(spacing: 12) {
                        // Stage Manager toggle
                        Toggle(isOn: Binding(
                            get: { selectedPreset.stageManager },
                            set: { _ in
                                withAnimation {
                                    focusViewModel.toggleFocusStageManager()
                                    syncFocusPresets()
                                }
                            }
                        )) {
                            Image(systemSymbol: .squareOnSquare)
                                .help("Toggle Stage Manager")
                        }
                        .toggleStyle(SwitchToggleStyle())
                            
                        // Edit button
                        Button {
                            withAnimation {
                                focusViewModel.editingFocus.toggle()
                            }
                        } label: {
                            Image(systemSymbol: focusViewModel.editingFocus ? .checkmarkCircle : .pencil)
                                .foregroundColor(focusViewModel.editingFocus ? .green : .primary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help(focusViewModel.editingFocus ? "Done Editing" : "Edit Preset")
                            
                        // Delete button
                        Button {
                            withAnimation {
                                focusViewModel.deleteFocusPreset(focusPreset: selectedPreset)
                                syncFocusPresets()
                            }
                        } label: {
                            Image(systemSymbol: .trashCircle)
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Delete Preset")
                    }
                }
            }
                
            if focusViewModel.editingFocus, let selectedPreset = focusViewModel.selectedFocusPreset {
                HStack {
                    Image(systemSymbol: .infoCircle)
                        .font(.caption)
                        .foregroundColor(.blue)
                        
                    Text("Editing \"\(selectedPreset.name)\" - Select spaces to include")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                    Spacer()
                        
                    Button("Done") {
                        withAnimation {
                            focusViewModel.editingFocus = false
                        }
                    }
                    .font(.caption)
                    .buttonStyle(BorderlessButtonStyle())
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(4)
            }
                
            if focusViewModel.creatingPreset {
                PresetTextInputView(focusViewModel: focusViewModel)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
        
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .padding()
                
            Text("Refreshing available spaces...")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: 200)
    }
        
    private var emptyStateView: some View {
        EmptyStateView(
            icon: .questionmarkCircle,
            title: "No Spaces Found",
            subtitle: "Click the Refresh button to detect available desktop spaces",
            buttonTitle: "Refresh Spaces"
        ) {
            refreshSpaces()
        }
    }
        
    private var spacesGrid: some View {
        ScrollView {
            LazyVStack(spacing: cardSpacing) {
                ForEach(Array(spacesViewModel.desktopSpaces.enumerated()), id: \.element.id) { indexDesktop, desktopSpace in
                    SpacesDisplayCard(
                        desktopSpace: desktopSpace,
                        desktopIndex: indexDesktop,
                        focusViewModel: focusViewModel,
                        startIndex: previousDisplaySpacesCount(forIndex: indexDesktop),
                        onError: handleSpaceError
                    )
                }
            }
            .padding(.bottom, 8)
        }
        .animation(.easeInOut, value: spacesViewModel.desktopSpaces.count)
    }
        
    // MARK: - Helper Methods
        
    private func refreshSpaces() {
        isRefreshing = true
            
        Task {
            let isUpdated = await spacesViewModel.updateSystemSpaces()
                
            if isUpdated {
                // Update focus viewmodel spaces references
                focusViewModel.updateSpacesFromNewRefresh(newSpaces: spacesViewModel.allSpaces)
            }
                
            // Validate space organization for debugging
            #if DEBUG
            let issues = spacesViewModel.validateSpaceOrganization()
            if !issues.isEmpty {
                print("⚠️ Space organization issues detected:")
                issues.forEach { print("  - \($0)") }
            }
            #endif
                
            DispatchQueue.main.async {
                isRefreshing = false
            }
        }
    }
        
    private func handleSpaceError(_ message: String) {
        DispatchQueue.main.async {
            self.errorState = ErrorState(
                title: "Space Switching Error",
                message: "Please ensure Outer Spaces has the necessary permissions: \(message)",
                isPermissionIssue: message.contains("permission") || message.contains("System Events")
            )
        }
    }
        
    private func syncFocusPresets() {
        // Also update user defaults
        FocusManager.saveFocusModels(focusViewModel.availableFocusPresets)
    }
        
    private func previousDisplaySpacesCount(forIndex index: Int) -> Int {
        guard index > 0 && index < spacesViewModel.desktopSpaces.count else {
            return 0
        }
            
        return (0 ..< index).reduce(0) { count, i in
            count + spacesViewModel.desktopSpaces[i].desktopSpaces.count
        }
    }
        
    private func applySelectedPreset() {
        guard let selectedPreset = focusViewModel.selectedFocusPreset else { return }
            
        // Create settings model with the selected preset's ID
        let settingsModel = SettingsModel(focusPresetId: selectedPreset.id)
            
        // Encode and update app data
        if let encodedData = try? JSONEncoder().encode(settingsModel) {
            appData = encodedData
        }
    }
        
    private func isDefaultPreset(_ id: UUID) -> Bool {
        return focusStatusViewModel.defaultPresetID == id
    }
        
    private func toggleDefaultPreset(_ preset: Focus) {
        if isDefaultPreset(preset.id) {
            // Unset default
            focusStatusViewModel.setDefaultPreset(id: nil)
            UserDefaults.standard.removeObject(forKey: "DefaultPresetID")
        } else {
            // Set as default
            focusStatusViewModel.setDefaultPreset(id: preset.id)
            UserDefaults.standard.set(preset.id.uuidString, forKey: "DefaultPresetID")
        }
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

struct PresetMenuButton: View {
    @ObservedObject var focusViewModel: FocusViewModel
    var onNewPreset: () -> Void
    
    var body: some View {
        Menu {
            Button("New Preset...") {
                onNewPreset()
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
                Text(focusViewModel.selectedFocusPreset?.name ?? "Select Preset")
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer()
                Image(systemSymbol: .chevronDown)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            .frame(minWidth: 180)
        }
    }
}

struct SpacesDisplayCard: View {
    var desktopSpace: DesktopSpaces
    var desktopIndex: Int
    @ObservedObject var focusViewModel: FocusViewModel
    var startIndex: Int
    var onError: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Display header
            HStack {
                Text("Display \(desktopIndex + 1)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let firstSpace = desktopSpace.desktopSpaces.first {
                    Text("(\(firstSpace.displayID))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(desktopSpace.desktopSpaces.count) Spaces")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
            
            // Spaces grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                ForEach(Array(desktopSpace.desktopSpaces.enumerated()), id: \.element.id) { index, space in
                    SpaceCard(
                        space: space,
                        index: desktopIndex != 0 ? startIndex + index : index,
                        focusViewModel: focusViewModel,
                        isEditingSpace: $focusViewModel.editingFocus,
                        onError: onError
                    )
                    .transition(.scale)
                }
            }
        }
        .padding(16)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Helper Models

struct ErrorState: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let isPermissionIssue: Bool
}
