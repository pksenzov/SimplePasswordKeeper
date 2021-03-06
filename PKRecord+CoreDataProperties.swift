//
//  PKRecord+CoreDataProperties.swift
//  SimplePasswordKeeper
//
//  Created by Admin on 08/06/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension PKRecord {
    
    @NSManaged var uuid: String?
    @NSManaged var creationDate: Date?
    @NSManaged var date: Date?
    @NSManaged var detailedDescription: String?
    @NSManaged var login: String?
    @NSManaged var password: NSObject?
    @NSManaged var title: String?
    @NSManaged var folder: PKFolder?

}

extension PKRecord: ManagedObjectType {
    @nonobjc static let entityName = "Record"
}


