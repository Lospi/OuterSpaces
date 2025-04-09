//
//  FocusComponents.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 25/03/25.
//

import SFSafeSymbols
import SwiftUI

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
                        }
                    )) {
                        Image(systemSymbol: .squareOnSquare)
                    }
                    .toggleStyle(SwitchToggleStyle())
                    .help("Enable/Disable Stage Manager")
                    
                    // Delete button
                    Button {
                        focusViewModel.deleteFocusPreset(focusPreset: selectedPreset)
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
        focusViewModel.saveFocusPresets()
        // Also update user defaults
        FocusManager.saveFocusModels(focusViewModel.availableFocusPresets)
    }
}
