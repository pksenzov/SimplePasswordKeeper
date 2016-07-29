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
    
    // MARK: - Sync
    
    func removeDeletedObjects(deletedObjects: [PKDeletedObject]) {
        deletedObjects.forEach() {
            self.managedObjectContext.deleteObject($0)
        }
        
        self.saveWithIgnoringUI()
    }
    
    func getFolders() -> [PKFolder] {
        let fetchRequest = NSFetchRequest(entityName: "Folder")
        do {
            let folders = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [PKFolder]
            return folders
        } catch {
            abort()
        }
    }
    
    func getRecords() -> [PKRecord] {
        let fetchRequest = NSFetchRequest(entityName: "Record")
        do {
            let records = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [PKRecord]
            return records
        } catch {
            abort()
        }
    }
    
    func getDeletedObjects() -> [PKDeletedObject] {
        let fetchRequest = NSFetchRequest(entityName: "DeletedObject")
        do {
            let deletedObjects = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [PKDeletedObject]
            return deletedObjects
        } catch {
            abort()
        }
    }
    
    // MARK: - CloudKit update
    
    func update(reason: String, type: String, object: Any) {
        switch (reason, type) {
        case ("Created", "Folder"):
            let folderS = object as! PKFolderS
            let newFolder: PKFolder = self.managedObjectContext.insertObject()
            newFolder.name = folderS.name
            newFolder.date = folderS.date
            newFolder.uuid = folderS.uuid
            //no records in new folder
        case ("Created", "Record"):
            let recordS = object as! PKRecordS
            let newRecord: PKRecord = self.managedObjectContext.insertObject()
            newRecord.title = recordS.title
            newRecord.login = recordS.login
            newRecord.password = recordS.password
            newRecord.detailedDescription = recordS.detailedDescription
            newRecord.creationDate = recordS.creationDate
            newRecord.date = recordS.date
            newRecord.uuid = recordS.uuid
            
            let predicate = NSPredicate(format: "uuid == %@", recordS.folderUUID)
            let fetchRequest = NSFetchRequest(entityName: "Folder")
            fetchRequest.predicate = predicate
            
            var folder: PKFolder!
            do {
                let folders = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [PKFolder]
                if folders.isEmpty {
                    //dispatch_group_leave(PKCloudKitManager.sharedManager.notificationGroup)
                    return
                }
                folder = folders.first!
            } catch {
                // что-то делаем в зависимости от ошибки
            }
            
            newRecord.folder = folder
            
            if newRecord.folder == nil { abort() }
        case ("Updated", "Folder"):
            let folderS = object as! PKFolderS
            
            let predicate = NSPredicate(format: "uuid == %@", folderS.uuid)
            let fetchRequest = NSFetchRequest(entityName: "Folder")
            fetchRequest.predicate = predicate
            
            var folder: PKFolder!
            do {
                let folders = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [PKFolder]
                if folders.isEmpty {
                    //dispatch_group_leave(PKCloudKitManager.sharedManager.notificationGroup)
                    return
                }
                folder = folders.first!
            } catch {
                // что-то делаем в зависимости от ошибки
            }
            
            folder.name = folderS.name
            folder.date = folderS.date
            
            let recordsUUID = folderS.recordsUUID
            let recordsPredicate = NSPredicate(format: "uuid in %@", recordsUUID)
            let recordsRequest = NSFetchRequest(entityName: "Record")
            recordsRequest.predicate = recordsPredicate
            
            do {
                let records = try self.managedObjectContext.executeFetchRequest(recordsRequest) as! [PKRecord]
                if records.isEmpty {
                    //dispatch_group_leave(PKCloudKitManager.sharedManager.notificationGroup)
                    return
                }
                folder.records = Set(records)
            } catch {
                // что-то делаем в зависимости от ошибки
            }
        case ("Updated", "Record"):
            let recordS = object as! PKRecordS
            
            let predicate = NSPredicate(format: "uuid == %@", recordS.uuid)
            let fetchRequest = NSFetchRequest(entityName: "Record")
            fetchRequest.predicate = predicate
            
            var record: PKRecord!
            do {
                let records = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [PKRecord]
                if records.isEmpty {
                    //dispatch_group_leave(PKCloudKitManager.sharedManager.notificationGroup)
                    return
                }
                record = records.first!
            } catch {
                // что-то делаем в зависимости от ошибки
            }
            
            record.title = recordS.title
            record.login = recordS.login
            record.password = recordS.password
            record.detailedDescription = recordS.detailedDescription
            record.creationDate = recordS.creationDate
            record.date = recordS.date
            
            let foldersPredicate = NSPredicate(format: "uuid == %@", recordS.folderUUID)
            let foldersRequest = NSFetchRequest(entityName: "Folder")
            foldersRequest.predicate = foldersPredicate
            
            do {
                let folders = try self.managedObjectContext.executeFetchRequest(foldersRequest) as! [PKFolder]
                if folders.isEmpty {
                    //dispatch_group_leave(PKCloudKitManager.sharedManager.notificationGroup)
                    return
                }
                record.folder = folders.first!
            } catch {
                // что-то делаем в зависимости от ошибки
            }
            
            if record.folder == nil { abort() }
        case ("Deleted", "Folder"):
            let uuid = object as! String
            
            let predicate = NSPredicate(format: "uuid == %@", uuid)
            let fetchRequest = NSFetchRequest(entityName: "Folder")
            fetchRequest.predicate = predicate
            
            var folder: PKFolder!
            do {
                let folders = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [PKFolder]
                if folders.isEmpty {
                    //dispatch_group_leave(PKCloudKitManager.sharedManager.notificationGroup)
                    return
                }
                folder = folders.first!
            } catch {
                // что-то делаем в зависимости от ошибки
            }
            
            self.managedObjectContext.deleteObject(folder)
        case ("Deleted", "Record"):
            let uuid = object as! String
            
            let predicate = NSPredicate(format: "uuid == %@", uuid)
            let fetchRequest = NSFetchRequest(entityName: "Record")
            fetchRequest.predicate = predicate
            
            var record: PKRecord!
            do {
                let records = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [PKRecord]
                if records.isEmpty {
                    //dispatch_group_leave(PKCloudKitManager.sharedManager.notificationGroup)
                    return
                }
                record = records.first!
            } catch {
                // что-то делаем в зависимости от ошибки
            }
            
            self.managedObjectContext.deleteObject(record)
        default:
            break
        }
        
        if self.managedObjectContext.hasChanges {
            self.managedObjectContext.insertedObjects.forEach() { self.refreshObjectIfNeeded($0) }
            self.managedObjectContext.updatedObjects.forEach()  { self.refreshObjectIfNeeded($0) }
            self.managedObjectContext.deletedObjects.forEach()  {
                self.refreshObjectIfNeeded($0)
                PKServerManager.sharedManager.popIfNeeded($0)
            }
            
            self.save()
            //dispatch_group_leave(PKCloudKitManager.sharedManager.notificationGroup)
        }
    }
    
    func refreshObjectIfNeeded(object: NSManagedObject) {
        if let record = object as? PKRecord {
            if record.folder == nil {
                self.managedObjectContext.refreshObject(record, mergeChanges: false)
            }
        }
    }
    
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
        
        //NEEDED ?
//        let options = [
//            NSMigratePersistentStoresAutomaticallyOption: true,
//            NSInferMappingModelAutomaticallyOption: true,
//            NSSQLitePragmasOption: ["journal_mode": "DELETE"]
//        ]
        
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
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
            
            self.save()
        }
    }
    
    func save() {
        do {
            try self.managedObjectContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
            abort()
        }
        
        let application =  UIApplication.sharedApplication()
        if  application.isIgnoringInteractionEvents() { application.endIgnoringInteractionEvents() }
    }
    
    func saveWithIgnoringUI() {
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
