//
//  SpaceComponents.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 25/03/25.
//

import SFSafeSymbols
import SwiftUI

struct SpaceCard: View {
    let space: Space
    var index: Int
    @ObservedObject var focusViewModel: FocusViewModel
    @Binding var isEditingSpace: Bool
    var onError: (String) -> Void

    var body: some View {
        VStack(spacing: 4) {
            if isEditingSpace {
                Button {
                    focusViewModel.updateFocusSpaces(relatedSpace: space)
                } label: {
                    SpaceCardContent(
                        space: space,
                        index: index,
                        isSelected: focusViewModel.doesFocusHasSpace(space: space),
                        isEditMode: true
                    )
                }
                .buttonStyle(SpaceCardButtonStyle())
            } else {
                Button {
                    switchToSpace()
                } label: {
                    SpaceCardContent(
                        space: space,
                        index: index,
                        isSelected: space.isActive,
                        isEditMode: false
                    )
                }
                .buttonStyle(SpaceCardButtonStyle())
            }
        }
    }

    private func switchToSpace() {
        do {
            try SpaceSwitcher.switchToSpace(space)
            if let preset = focusViewModel.selectedFocusPreset {
                SpaceSwitcher.applyStageManager(enabled: preset.stageManager)
            }
        } catch {
            Logger.shared.logError("Space switch failed: \(error.localizedDescription)")
            onError(error.localizedDescription)
        }
    }
}

struct SpaceCardContent: View {
    var space: Space
    var index: Int
    var isSelected: Bool
    var isEditMode: Bool = false
    @State private var isHovered = false

    private var accentColor: Color {
        isEditMode ? .orange : .blue
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? accentColor.opacity(0.2) : isHovered ? Color.secondary.opacity(0.15) : Color.secondary.opacity(0.1))
                    .frame(width: 44, height: 36)

                Text("\(index + 1)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? accentColor : .primary)
            }

            Text(space.customName ?? "Desktop \(index + 1)")
                .font(.caption)
                .foregroundStyle(isSelected ? accentColor : .primary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 80)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
