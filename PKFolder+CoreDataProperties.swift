//
//  PKFolder+CoreDataProperties.swift
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

extension PKFolder {
    
    @NSManaged var recordName: String?
    @NSManaged var recordID: NSData?
    @NSManaged var name: String?
    @NSManaged var records: NSSet?
    
}

extension PKFolder: ManagedObjectType {
    @nonobjc static let entityName = "Folder"
}