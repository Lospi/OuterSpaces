//
//  CoreDataManager.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 01/12/23.
//

import CoreData
import Foundation

struct CoreDataManager {
    static let shared = CoreDataManager()

    func saveSpacesToCoreData(spacesViewModel: SpacesViewModel, managedObjectContext: NSManagedObjectContext) {
        spacesViewModel.desktopSpaces.forEach {
            $0.desktopSpaces.forEach {
                let space = SpaceData(context: managedObjectContext)
                space.displayId = $0.displayID
                space.spaceId = $0.spaceID
                space.id = $0.id
                space.spaceIndex = Int16($0.spaceIndex)
                PersistenceController.shared.save()
            }
        }
    }

    func saveFocusToCoreData(focusViewModel: FocusViewModel, managedObjectContext: NSManagedObjectContext) {
        focusViewModel.availableFocusPresets.forEach {
            let focus = FocusData(context: managedObjectContext)
            focus.id = $0.id
            focus.name = $0.name
            focus.spacesIds = $0.spaces.map { $0.spaceID }
            PersistenceController.shared.save()
        }
    }

    func deleteCoreDataModel(modelName: String, managedObjectContext: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: modelName)
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try managedObjectContext.execute(batchDeleteRequest)
        } catch {}
    }
}
