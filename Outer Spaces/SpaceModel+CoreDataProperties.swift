//
//  SpaceModel+CoreDataProperties.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 23/11/23.
//
//

import CoreData
import Foundation

public extension SpaceModel {
    @nonobjc class func fetchRequest() -> NSFetchRequest<SpaceModel> {
        return NSFetchRequest<SpaceModel>(entityName: "SpaceData")
    }

    @NSManaged var displayId: String?
    @NSManaged var id: String?
    @NSManaged var customName: String?
    @NSManaged var focus: FocusModel?
}

extension SpaceModel: Identifiable {}
