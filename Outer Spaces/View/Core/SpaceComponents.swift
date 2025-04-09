//
//  SpaceComponents.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 25/03/25.
//

import SFSafeSymbols
import SwiftUI

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
