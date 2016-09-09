//
//  PKCloudKitManager.swift
//  Records
//
//  Created by Admin on 13/07/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import UIKit
import CloudKit
import CoreData

class PKCloudKitManager: NSObject {
    static let sharedManager = PKCloudKitManager()
    
    let privateDatabase = CKContainer.defaultContainer().privateCloudDatabase
    let defaults = NSUserDefaults.standardUserDefaults()
    
    lazy var operationQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.qualityOfService = .Background
        
        return queue
    }()
    
//    private var _notificationGroup = dispatch_group_create()
//    
//    var notificationGroup: dispatch_group_t! {
//        var notificationGroupCopy: dispatch_group_t!
//        
//        dispatch_sync(concurrentNotificationGroupQueue) {
//            notificationGroupCopy = self._notificationGroup
//        }
//        
//        return notificationGroupCopy
//    }
//    
//    private let concurrentNotificationGroupQueue = dispatch_queue_create("com.pavelksenzov.records.notificationGroupQueue", DISPATCH_QUEUE_CONCURRENT)
    
    // MARK: - Sync
    
    func getFolders() -> [CKRecord] {
        let iCloudFoldersGroup = dispatch_group_create()
        dispatch_group_enter(iCloudFoldersGroup)
        
        var folders: [CKRecord]!
        
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let query = CKQuery(recordType: "Folder", predicate: predicate)
        self.privateDatabase.performQuery(query, inZoneWithID: nil) {
            if $1 != nil {
                abort()
            }
            
            guard $0 != nil else { abort() }
            
            folders = $0!
            
            dispatch_group_leave(iCloudFoldersGroup)
        }
        
        dispatch_group_wait(iCloudFoldersGroup, DISPATCH_TIME_FOREVER)
        
        return folders
    }
    
    func getRecords() -> [CKRecord] {
        let iCloudRecordsGroup = dispatch_group_create()
        dispatch_group_enter(iCloudRecordsGroup)
        
        var records: [CKRecord]!
        
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let query = CKQuery(recordType: "Record", predicate: predicate)
        self.privateDatabase.performQuery(query, inZoneWithID: nil) {
            if $1 != nil {
                abort()
            }
            
            guard $0 != nil else { abort() }
            
            records = $0!
            
            dispatch_group_leave(iCloudRecordsGroup)
        }
        
        dispatch_group_wait(iCloudRecordsGroup, DISPATCH_TIME_FOREVER)
        
        return records
    }
    
    func getDeletedObjects() -> [CKRecord] {
        let iCloudDeletedObjectsGroup = dispatch_group_create()
        dispatch_group_enter(iCloudDeletedObjectsGroup)
        
        var deletedObjects: [CKRecord]!
        
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let query = CKQuery(recordType: "DeletedObject", predicate: predicate)
        self.privateDatabase.performQuery(query, inZoneWithID: nil) {
            if $1 != nil {
                abort()
            }
            
            guard $0 != nil else { abort() }
            
            deletedObjects = $0!
            
            dispatch_group_leave(iCloudDeletedObjectsGroup)
        }
        
        dispatch_group_wait(iCloudDeletedObjectsGroup, DISPATCH_TIME_FOREVER)
        
        return deletedObjects
    }
    
    // MARK: - Update CoreData
    
    func updateCoreData(recordID: CKRecordID, reason: CKQueryNotificationReason, isFolder: Bool) {
        //dispatch_group_wait(self.notificationGroup, DISPATCH_TIME_FOREVER)
        //dispatch_group_enter(self.notificationGroup)
        
        if reason == .RecordDeleted {
            if isFolder {
                PKCoreDataManager.sharedManager.update("Deleted", type: "Folder", object: recordID.recordName)
            } else {
                PKCoreDataManager.sharedManager.update("Deleted", type: "Record", object: recordID.recordName)
            }
            return
        }
        
        self.privateDatabase.fetchRecordWithID(recordID) { (object, error) in
            if error != nil {
                print(error!.localizedDescription)
                abort()
            }
            
            guard object != nil else { return }
            let type = object!.recordType
            
            switch (reason, type) {
            case (.RecordCreated, "Folder"):
                PKCoreDataManager.sharedManager.update("Created", type: type, object: PKFolderS(folder: object!))
            case (.RecordCreated, "Record"):
                PKCoreDataManager.sharedManager.update("Created", type: type, object: PKRecordS(record: object!))
            case (.RecordUpdated, "Folder"):
                PKCoreDataManager.sharedManager.update("Updated", type: type, object: PKFolderS(folder: object!))
            case (.RecordUpdated, "Record"):
                PKCoreDataManager.sharedManager.update("Updated", type: type, object: PKRecordS(record: object!))
            default:
                break
            }
        }
    }
    
    // MARK: - Subscriptions
    
//    func deleteSubscriptions() {
//        self.privateDatabase.fetchAllSubscriptionsWithCompletionHandler() { (subs, error) in
//            if subs == nil || subs?.count == 0 { return }
//            
//            if error != nil {
//                print(error?.localizedDescription)
//                abort()
//            }
//            
//            subs!.forEach() {
//                self.privateDatabase.deleteSubscriptionWithID($0.subscriptionID) { (_, error) in
//                    if error != nil {
//                        abort()
//                    }
//                }
//            }
//        }
//    }
    
//    func addSubscriptions() {
//        let predicate = NSPredicate(format: "TRUEPREDICATE")
//        let folderSubscription = CKSubscription(recordType: "Folder", predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordDeletion, .FiresOnRecordUpdate])
//        let recordSubscription = CKSubscription(recordType: "Record", predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordDeletion, .FiresOnRecordUpdate])
//        
//        let folderNotificationInfo = CKNotificationInfo()
//        folderNotificationInfo.desiredKeys = ["name"]
//        folderNotificationInfo.shouldSendContentAvailable = true
//        folderSubscription.notificationInfo = folderNotificationInfo
//        
//        let recordNotificationInfo = CKNotificationInfo()
//        recordNotificationInfo.shouldSendContentAvailable = true
//        recordSubscription.notificationInfo = recordNotificationInfo
//        
//        self.privateDatabase.saveSubscription(folderSubscription) { (sub, error) in
//            if error != nil {
//                print(error?.localizedDescription)
//                abort()
//            }
//            
//            self.privateDatabase.saveSubscription(recordSubscription) { (sub, error) in
//                if error != nil {
//                    print(error?.localizedDescription)
//                    abort()
//                }
//                
//                self.defaults.setBool(true, forKey: kSettingsSubscriptions)
//            }
//        }
//    }
//    
//    func addSubscriptionWithType(recordType: String) {
//        let predicate = NSPredicate(format: "TRUEPREDICATE")
//        let subscription = CKSubscription(recordType: recordType, predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordDeletion, .FiresOnRecordUpdate])
//        
//        if recordType == "Folder" {
//            let folderNotificationInfo = CKNotificationInfo()
//            folderNotificationInfo.desiredKeys = ["name"]
//            folderNotificationInfo.shouldSendContentAvailable = true
//            subscription.notificationInfo = folderNotificationInfo
//        } else {
//            let recordNotificationInfo = CKNotificationInfo()
//            recordNotificationInfo.shouldSendContentAvailable = true
//            subscription.notificationInfo = recordNotificationInfo
//        }
//        
//        self.privateDatabase.saveSubscription(subscription) { (sub, error) in
//            if error != nil {
//                print(error?.localizedDescription)
//                abort()
//            }
//            
//            self.defaults.setBool(true, forKey: kSettingsSubscriptions)
//        }
//    }
//    
//    func checkAndAddSubscriptionsOLD() {
//        guard !self.defaults.boolForKey(kSettingsSubscriptions) else { return }
//        
//        self.privateDatabase.fetchAllSubscriptionsWithCompletionHandler() { (subs, error) in
//            if subs == nil || subs?.count == 0 {
//                self.addSubscriptions()
//                return
//            } else if subs?.count == 1 {
//                let recordType = (subs!.first!.recordType == "Folder") ? "Record" : "Folder"
//                self.addSubscriptionWithType(recordType)
//                return
//            }
//            
//            if error != nil {
//                print(error?.localizedDescription)
//                abort()
//            }
//            
//            self.defaults.setBool(true, forKey: kSettingsSubscriptions)
//        }
//    }
    
    func checkAndAddSubscriptions() {
        guard !self.defaults.boolForKey(kSettingsSubscriptions) else { return }
        
        self.privateDatabase.fetchAllSubscriptionsWithCompletionHandler() {
            if $1 != nil {
                print($1?.localizedDescription)
                abort()
            } else {
                
            }
        }
        
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let folderSubscription = CKSubscription(recordType: "Folder", predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordDeletion, .FiresOnRecordUpdate])
        let recordSubscription = CKSubscription(recordType: "Record", predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordDeletion, .FiresOnRecordUpdate])
        
        let folderNotificationInfo = CKNotificationInfo()
        folderNotificationInfo.desiredKeys = ["name"]
        folderNotificationInfo.shouldSendContentAvailable = true
        folderSubscription.notificationInfo = folderNotificationInfo
        
        let recordNotificationInfo = CKNotificationInfo()
        recordNotificationInfo.shouldSendContentAvailable = true
        recordSubscription.notificationInfo = recordNotificationInfo
        
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [folderSubscription, recordSubscription], subscriptionIDsToDelete: nil)
        operation.modifySubscriptionsCompletionBlock = {
            if $2 != nil {
                print($2?.localizedDescription)
                if $2?.code == 9 || $2?.code == 2 { self.defaults.setBool(true, forKey: kSettingsSubscriptions) }
                else { abort() }
            } else {
                self.defaults.setBool(true, forKey: kSettingsSubscriptions)
            }
        }
        
        operation.qualityOfService = .Utility
        self.privateDatabase.addOperation(operation)
    }
    
    // MARK: - Context
    
//    func fetchSharedChanges(callback: () -> Void) {
//        let changesOperation = CKFetchDatabaseChangesOperation(previousServerChangeToken: sharedDBChangeToken) // previously cached
//        changesOperation.fetchAllChanges = true
//        changesOperation.recordZoneWithIDChangedBlock = { … } // collect zone IDs
//        changesOperation.recordZoneWithIDWasDeletedBlock = { … } // delete local cache
//        changesOperation.changeTokenUpdatedBlock = { … } // cache new token
//        changesOperation.fetchDatabaseChangesCompletionBlock = {
//            (newToken: CKServerChangeToken?, more: Bool, error: NSError?) -> Void in
//            // error handling here
//            self.sharedDBChangeToken = newToken // cache new token
//            self.fetchZoneChanges(callback) // using CKFetchRecordZoneChangesOperation
//        }
//        self.sharedDB.add(changesOperation)
//    }
    
    func saveContext(deleted: [PKObjectS], updated: [PKObjectS], inserted: [PKObjectS]) {
        var deletedRecordsSet = Set<String>()
        deleted.forEach() {
            if let record = $0 as? PKRecordS {
                deletedRecordsSet.insert(record.uuid)
            }
        }
        
        print(inserted)
        print(updated)
        print(deleted)
        
        var newRecs = [CKRecord]()
        
        inserted.forEach() {
            switch $0 {
            case is PKFolderS:
                print(($0 as! PKFolderS).uuid)
                let folder = self.saveFolder($0 as! PKFolderS)
                newRecs.append(folder)
            case is PKRecordS:
                let record = self.saveRecord($0 as! PKRecordS)
                newRecs.append(record)
            default:
                break
            }
        }
        
        let newRecOperation = CKModifyRecordsOperation(recordsToSave: newRecs, recordIDsToDelete: nil)
        newRecOperation.database = self.privateDatabase
        
        if self.operationQueue.operationCount != 0 {
            newRecOperation.addDependency(self.operationQueue.operations.last!)
        }
        
        self.operationQueue.addOperation(newRecOperation)
        
        var foldersDictToUpdate = [CKReference: PKObjectS]()
        var recordsDictToUpdate = [CKReference: PKObjectS]()
        
        updated.forEach() {
            switch $0 {
            case is PKFolderS:
                let folderS = $0 as! PKFolderS
                let folderID = CKRecordID(recordName: folderS.uuid)
                
                let reference = CKReference(recordID: folderID, action: .None)
                foldersDictToUpdate[reference] = folderS
            case is PKRecordS:
                let recordS = $0 as! PKRecordS
                let recordID = CKRecordID(recordName: recordS.uuid)
                
                let reference = CKReference(recordID: recordID, action: .None)
                recordsDictToUpdate[reference] = recordS
            default:
                break
            }
        }
        
        //Fetch Folders
        if foldersDictToUpdate.count != 0 {
            let foldersArrToUpdate = foldersDictToUpdate.map() { $0.0 }
            let predicate = NSPredicate(format: "recordID IN %@", foldersArrToUpdate)//foldersArrToUpdate
            let query = CKQuery(recordType: "Folder", predicate: predicate)
            
            let queryOperation = CKQueryOperation(query: query)
            
            if self.operationQueue.operationCount != 0 {
                queryOperation.addDependency(self.operationQueue.operations.last!)
            }
            
            self.executeQueryOperation(queryOperation, onOperationQueue: self.operationQueue, dict: foldersDictToUpdate)
        }
        
        //Fetch Records
        if recordsDictToUpdate.count != 0 {
            let recordsArrToUpdate = recordsDictToUpdate.map() { $0.0 }
            let predicate = NSPredicate(format: "recordID IN %@", recordsArrToUpdate)
            let query = CKQuery(recordType: "Record", predicate: predicate)
            
            let queryOperation = CKQueryOperation(query: query)
            
            if self.operationQueue.operationCount != 0 {
                queryOperation.addDependency(self.operationQueue.operations.last!)
            }
            
            self.executeQueryOperation(queryOperation, onOperationQueue: self.operationQueue, dict: recordsDictToUpdate)
        }
        
        var recordsIDToDelete           = [CKRecordID]()
        var recordsUUIDToDelete         = [String]()
        var foldersReferenceToUpdate    = Set<CKReference>()
        
        deleted.forEach() {
            switch $0 {
            case is PKFolderS:
                let folderS = $0 as! PKFolderS
                let id = CKRecordID(recordName: folderS.uuid)
                
                recordsIDToDelete.append(id)
                recordsUUIDToDelete.append(folderS.uuid)
                
                folderS.recordsUUID.forEach() {
                    recordsUUIDToDelete.append($0)
                }
            case is PKRecordS:
                let recordS = $0 as! PKRecordS
                let id = CKRecordID(recordName: recordS.uuid)
                
                recordsIDToDelete.append(id)
                recordsUUIDToDelete.append(recordS.uuid)
                
                let folderID = CKRecordID(recordName: recordS.folderUUID)
                
                let reference = CKReference(recordID: folderID, action: .None)
                foldersReferenceToUpdate.insert(reference)
            default:
                break
            }
        }
        
        //Delete Folders & Records
        let deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordsIDToDelete)
        deleteOperation.database = self.privateDatabase
        
        self.operationQueue.addOperation(deleteOperation)
        
        //Save Deleted Folders & Records
        var deletedObjects = [CKRecord]()
        recordsUUIDToDelete.forEach() {
            let deletedObject = CKRecord(recordType: "DeletedObject")
            deletedObject["uuid"] = $0
            deletedObject["date"] = NSDate()
            
            deletedObjects.append(deletedObject)
        }
        
        let saveOperation = CKModifyRecordsOperation(recordsToSave: deletedObjects, recordIDsToDelete: nil)
        saveOperation.database = self.privateDatabase
        
        self.operationQueue.addOperation(saveOperation)
        
        //Update Folder
        if foldersReferenceToUpdate.count != 0 {
            let predicate = NSPredicate(format: "recordID IN %@", foldersReferenceToUpdate)
            let query = CKQuery(recordType: "Folder", predicate: predicate)
            
            let queryOperation = CKQueryOperation(query: query)
            
            self.executeQueryOperation(queryOperation, onOperationQueue: self.operationQueue, deletedRecordsSet: deletedRecordsSet)
        }
    }
    
    func saveFolder(folderS: PKFolderS) -> CKRecord {
        let folderID = CKRecordID(recordName: folderS.uuid)
        let folder = CKRecord(recordType: "Folder", recordID: folderID)
        
        folder["date"] = folderS.date
        folder["name"] = folderS.name
        
        var records = [CKReference]()
        
        folderS.recordsUUID.forEach() {
            let recordID = CKRecordID(recordName: $0)
            let recordReference = CKReference(recordID: recordID, action: .None)
            records.append(recordReference)
        }
        
        folder["records"] = records
        
        return folder
    }
    
    func saveRecord(recordS: PKRecordS) -> CKRecord {
        let recordID = CKRecordID(recordName: recordS.uuid)
        let record = CKRecord(recordType: "Record", recordID: recordID)
        
        record["date"] = recordS.date
        record["createdDT"] = recordS.creationDate
        record["detailedDescription"] = recordS.detailedDescription
        record["login"] = recordS.login
        record["password"] = PKPwdTransformer().transformValue(recordS.password)
        record["title"] = recordS.title
        
        let folderID = CKRecordID(recordName: recordS.folderUUID)
        let folderReference = CKReference(recordID: folderID, action: .None)//.DeleteSelf
        record["folder"] = folderReference
        
        return record
    }
    
    //Deleted
    
    func executeQueryOperation(queryOperation: CKQueryOperation, onOperationQueue operationQueue: NSOperationQueue, deletedRecordsSet: Set<String>) {
        queryOperation.database = self.privateDatabase
        
        queryOperation.recordFetchedBlock = { (record: CKRecord) -> Void in
            self.updateFolder(record, deletedRecordsSet: deletedRecordsSet)
        }
        
        queryOperation.queryCompletionBlock = { (cursor: CKQueryCursor?, error: NSError?) -> Void in
            if error != nil {
                print(error!)
                print(error!.code)
                abort()
            } else if let queryCursor = cursor {
                let queryCursorOperation = CKQueryOperation(cursor: queryCursor)
                
                self.executeQueryOperation(queryCursorOperation, onOperationQueue: operationQueue, deletedRecordsSet: deletedRecordsSet)
            }
        }
        
        //self.operationQueue.waitUntilAllOperationsAreFinished()
        self.operationQueue.addOperation(queryOperation)
    }
    
    func updateFolder(folder: CKRecord, deletedRecordsSet: Set<String>) {
        var records = folder["records"] as! [CKReference]
        records = records.filter() {
            !deletedRecordsSet.contains($0.recordID.recordName)
        }
        
        folder["records"] = records
        
        let updateFoldersOperation = CKModifyRecordsOperation(recordsToSave: [folder], recordIDsToDelete: nil)
        updateFoldersOperation.database = self.privateDatabase
        
        updateFoldersOperation.modifyRecordsCompletionBlock = {
            if $2 != nil {
                print($2)
                print($2?.code)
                abort()
            }
        }
        
        self.operationQueue.addOperation(updateFoldersOperation)
    }
    
    //Updated
    
    func executeQueryOperation(queryOperation: CKQueryOperation, onOperationQueue operationQueue: NSOperationQueue, dict: [CKReference: PKObjectS]) {
        queryOperation.database = self.privateDatabase
        
        queryOperation.recordFetchedBlock = { (record: CKRecord) -> Void in
            let ref = CKReference(record: record, action: .None)
            
            if let dict = dict as? [CKReference: PKFolderS] {
                print(dict[ref])
                self.updateFolder(record, fromFolderS: dict[ref]!)
            } else if let dict = dict as? [CKReference: PKRecordS] {
                self.updateRecord(record, fromRecordS: dict[ref]!)
            }
        }
        
        queryOperation.queryCompletionBlock = { (cursor: CKQueryCursor?, error: NSError?) -> Void in
            if error != nil {
                print(error!)
                print(error!.code)
                abort()
            } else if let queryCursor = cursor {
                let queryCursorOperation = CKQueryOperation(cursor: queryCursor)
                
                self.executeQueryOperation(queryCursorOperation, onOperationQueue: operationQueue, dict: dict)
            }
        }
        
        self.operationQueue.addOperation(queryOperation)
    }
    
    func updateFolder(folder: CKRecord, fromFolderS folderS: PKFolderS) {
        folder["date"] = folderS.date
        folder["name"] = folderS.name
        
        var records = [CKReference]()
        
        folderS.recordsUUID.forEach() {
            let recordID = CKRecordID(recordName: $0)
            let recordReference = CKReference(recordID: recordID, action: .None)
            records.append(recordReference)
        }
        
        folder["records"] = records
        
        let updateFoldersOperation = CKModifyRecordsOperation(recordsToSave: [folder], recordIDsToDelete: nil)
        updateFoldersOperation.database = self.privateDatabase
        
        updateFoldersOperation.modifyRecordsCompletionBlock = {
            if $2 != nil {
                print($2)
                print($2?.code)
                
                if $2!.code == 2 {
                    print($2!.userInfo[CKPartialErrorsByItemIDKey])
                } else {
                    abort()
                }
            }
        }
        
        self.operationQueue.addOperation(updateFoldersOperation)
    }
    
    func updateRecord(record: CKRecord, fromRecordS recordS: PKRecordS) {
        record["date"]                  = recordS.date
        record["createdDT"]             = recordS.creationDate
        record["detailedDescription"]   = recordS.detailedDescription
        record["login"]                 = recordS.login
        record["password"]              = PKPwdTransformer().transformValue(recordS.password)
        record["title"]                 = recordS.title
        
        let folderID = CKRecordID(recordName: recordS.folderUUID)
        let folderReference = CKReference(recordID: folderID, action: .None)//DeleteSelf
        record["folder"] = folderReference
        
        let updateRecordsOperation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        updateRecordsOperation.database = self.privateDatabase
        
        updateRecordsOperation.modifyRecordsCompletionBlock = {
            if $2 != nil {
                print($2)
                print($2?.code)
                
                if $2!.code == 2 {
                    print($2!.userInfo[CKPartialErrorsByItemIDKey])
                } else if $2!.code == 23 {
                    if let retryAfterValue = $2!.userInfo[CKErrorRetryAfterKey] as? NSNumber {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(retryAfterValue.doubleValue * Double(NSEC_PER_SEC))), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                            self.updateRecord(record, fromRecordS: recordS)
                        }
                        return
                    }
                } else {
                    abort()
                }
            }
        }
        
        self.operationQueue.addOperation(updateRecordsOperation)
    }
}
