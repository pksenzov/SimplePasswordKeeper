//
//  CoreDataManager.swift
//  SimplePasswordKeeper
//
//  Created by Admin on 17/02/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import CoreData
import UIKit

protocol ManagedObjectType {
    static var entityName: String { get }
}

class PKCoreDataManager: NSObject {
    static let sharedManager = PKCoreDataManager()
    
    let cloudGroup = dispatch_group_create()

    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.pavelksenzov.SimplePasswordKeeper" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Records", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("Records.sqlite")
        let failureReason = "There was an error creating or loading the application's saved data."
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true,
            NSSQLitePragmasOption: ["journal_mode": "DELETE"]
        ]
        
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: options)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error as NSError
            
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        //managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy// NEW
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if self.managedObjectContext.hasChanges {
            if PKAppDelegate.iCloudAccountIsSignedIn() && NSUserDefaults.standardUserDefaults().boolForKey(kSettingsICloud) {
                var deleted = [Any]()
                var updated = [Any]()
                var inserted = [Any]()
                
                self.managedObjectContext.deletedObjects.forEach() {
                    switch $0 {
                    case is PKFolder:
                        deleted.append(PKFolderS(folder: $0 as! PKFolder))
                    case is PKRecord:
                        deleted.append(PKRecordS(record: $0 as! PKRecord))
                    default:
                        break
                    }
                }
                
                self.managedObjectContext.updatedObjects.forEach() {
                    switch $0 {
                    case is PKFolder:
                        updated.append(PKFolderS(folder: $0 as! PKFolder))
                    case is PKRecord:
                        updated.append(PKRecordS(record: $0 as! PKRecord))
                    default:
                        break
                    }
                }
                
                self.managedObjectContext.insertedObjects.forEach() {
                    switch $0 {
                    case is PKFolder:
                        inserted.append(PKFolderS(folder: $0 as! PKFolder))
                    case is PKRecord:
                        inserted.append(PKRecordS(record: $0 as! PKRecord))
                    default:
                        break
                    }
                }
                
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                    dispatch_group_wait(self.cloudGroup, DISPATCH_TIME_FOREVER)
                    dispatch_group_enter(self.cloudGroup)
                    PKCloudKitManager.sharedManager.saveContext(deleted, updated: updated, inserted: inserted)
                    dispatch_group_leave(self.cloudGroup)
                }
            } else {
                self.managedObjectContext.deletedObjects.forEach() {
                    switch $0 {
                    case is PKFolder:
                        let folder = ($0 as! PKFolder)
                        folder.records?.forEach() { record in
                            let record = record as! PKRecord
                            
                            let deletedObject: PKDeletedObject = self.managedObjectContext.insertObject()
                            deletedObject.date = NSDate()
                            deletedObject.uuid = record.uuid
                        }
                        
                        let deletedObject: PKDeletedObject = self.managedObjectContext.insertObject()
                        deletedObject.date = NSDate()
                        deletedObject.uuid = folder.uuid
                    case is PKRecord:
                        let deletedObject: PKDeletedObject = self.managedObjectContext.insertObject()
                        deletedObject.date = NSDate()
                        deletedObject.uuid = ($0 as! PKRecord).uuid
                    case is PKDeletedObject:
                        break
                    default:
                        break
                    }
                }
            }
            
            do {
                try self.managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
}
