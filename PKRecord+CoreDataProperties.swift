//
//  PKRecord+CoreDataProperties.swift
//  SimplePasswordKeeper
//
//  Created by Admin on 03/03/16.
//  Copyright © 2016 pksenzov. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension PKRecord {

    @NSManaged var date: NSDate?
    @NSManaged var detailedDescription: String?
    @NSManaged var login: String?
    @NSManaged var password: NSObject?
    @NSManaged var title: String?
    @NSManaged var folder: PKFolder?

}
