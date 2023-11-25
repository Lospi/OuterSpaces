//
//  FocusModel+CoreDataProperties.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 23/11/23.
//
//

import Foundation
import CoreData


extension FocusModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FocusModel> {
        return NSFetchRequest<FocusModel>(entityName: "FocusModel")
    }

    @NSManaged public var name: String?
    @NSManaged public var spaces: NSSet?

}

// MARK: Generated accessors for spaces
extension FocusModel {

    @objc(addSpacesObject:)
    @NSManaged public func addToSpaces(_ value: SpaceModel)

    @objc(removeSpacesObject:)
    @NSManaged public func removeFromSpaces(_ value: SpaceModel)

    @objc(addSpaces:)
    @NSManaged public func addToSpaces(_ values: NSSet)

    @objc(removeSpaces:)
    @NSManaged public func removeFromSpaces(_ values: NSSet)

}

extension FocusModel : Identifiable {

}
