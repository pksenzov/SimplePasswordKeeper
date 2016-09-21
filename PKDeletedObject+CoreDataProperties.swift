//
//  PKDeletedObject+CoreDataProperties.swift
//  Records
//
//  Created by Admin on 25/07/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension PKDeletedObject {

    @NSManaged var date: Date?
    @NSManaged var uuid: String?

}

extension PKDeletedObject: ManagedObjectType {
    @nonobjc static let entityName = "DeletedObject"
}
