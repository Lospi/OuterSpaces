//
//  SpaceInfoView.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 22/11/23.
//

import CoreData
import SFSafeSymbols
import SwiftUI

struct SpaceInfoView: View {
    @State var space: Space
    var index: Int
    @Environment(\.managedObjectContext) var managedObjectContext
    @ObservedObject var focusViewModel: FocusViewModel
    @State var isEditingName = false
    @State var customName = ""
    @Binding var isEditingSpace: Bool
    @State var isSelected = false

    var body: some View {
        VStack {
            HStack {
                if isEditingSpace {
                    Toggle(isOn: Binding(
                        get: { focusViewModel.doesFocusHasSpace(space: space) },
                        set: { _ in
                            withAnimation {
                                focusViewModel.updateFocusSpaces(relatedSpace: space)

                                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FocusData")
                                let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

                                do {
                                    try managedObjectContext.execute(batchDeleteRequest)
                                } catch {}

                                focusViewModel.availableFocusPresets.forEach {
                                    let focus = FocusData(context: managedObjectContext)
                                    focus.id = UUID()
                                    focus.name = $0.name
                                    focus.spacesIds = $0.spaces.map { $0.spaceID }
                                    PersistenceController.shared.save()
                                }
                            }
                        }
                    )) {}
                }
                Text(space.customName ?? "Desktop \(index)")
                Spacer()
                Button {
                    NSAppleScript(source: """
                    -- Set the index of the Space you want to switch to
                    set targetSpaceIndex to \(index) -- Change this to the desired Space index

                    -- Change to the specified Space index
                    tell application "System Events"
                        key code (18 + targetSpaceIndex) using {control down} -- Press Ctrl + (targetSpaceIndex)
                    end tell

                    """)!.executeAndReturnError(nil)
                } label: {
                    Image(systemName: SFSymbol.display2.rawValue)
                }
                Button {
                    isEditingName = !isEditingName
                } label: {
                    Image(systemName: SFSymbol.rectangleAndPencilAndEllipsis.rawValue)
                }
            }
            if isEditingName {
                TextField("Custom Name", text: $customName)
                    .onSubmit {
                        let request = NSFetchRequest<NSFetchRequestResult>(entityName: SpaceData.entity().name!)
                        let spaceModelResult = try! managedObjectContext.fetch(request)
                        let oldSpace = spaceModelResult.first(where: { ($0 as! SpaceData).spaceId == space.spaceID })
                        if oldSpace != nil {
                            managedObjectContext.delete(oldSpace! as! NSManagedObject)
                        }

                        let updatedSpace = SpaceData(context: managedObjectContext)

                        updatedSpace.displayId = space.displayID
                        updatedSpace.spaceId = space.spaceID
                        updatedSpace.id = space.id
                        updatedSpace.customName = customName.isEmpty ? "Desktop \(index)" : customName
                        space = Space(id: updatedSpace.id!, displayID: updatedSpace.displayId!, spaceID: updatedSpace.spaceId!, customName: updatedSpace.customName)
                        isEditingName = !isEditingName
                        PersistenceController.shared.save()
                    }
            }
        }
    }
}
