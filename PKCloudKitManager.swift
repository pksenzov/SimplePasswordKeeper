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
    
    let privateDatabase = CKContainer.default().privateCloudDatabase
    let defaults = UserDefaults.standard
    
    lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .background
        
        return queue
    }()
    
    // MARK: - Sync
    
    func prepareRecord(_ record: CKRecord) {
        var deleted     = [PKObjectS]()
        var updated     = [PKObjectS]()
        var inserted    = [PKObjectS]()
        
        self.managedObjectContext.deletedObjects.forEach() {
            if $0 is PKFolder {
                deleted.insert(PKFolderS(folder: $0 as! PKFolder), at: 0)
            } else {
                deleted.insert(PKRecordS(record: $0 as! PKRecord), at: max(inserted.count - 1, 0))
            }
        }
        
        self.managedObjectContext.updatedObjects.forEach() {
            if $0 is PKFolder {
                updated.insert(PKFolderS(folder: $0 as! PKFolder), at: 0)
            } else {
                updated.insert(PKRecordS(record: $0 as! PKRecord), at: max(inserted.count - 1, 0))
            }
        }
        
        self.managedObjectContext.insertedObjects.forEach() {
            if $0 is PKFolder {
                inserted.insert(PKFolderS(folder: $0 as! PKFolder), at: 0)
            } else {
                inserted.insert(PKRecordS(record: $0 as! PKRecord), at: max(inserted.count - 1, 0))
            }
        }
        
        PKCloudKitManager.sharedManager.saveContext(deleted, updated: updated, inserted: inserted)
    }
    
    func sync() {
        let token = self.defaults.object(forKey: kSettingsToken) as? CKServerChangeToken
        let zoneID = CKRecordZone.default().zoneID
        let options = CKFetchRecordZoneChangesOptions()
        options.previousServerChangeToken = token
        
        let changesOperation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneID], optionsByRecordZoneID: [zoneID: options])
        
        changesOperation.recordChangedBlock = { record in
            self.prepareRecord(record)
        }
        
        changesOperation.recordZoneFetchCompletionBlock = { (zoneID: CKRecordZoneID,
                                                             newToken: CKServerChangeToken?,
                                                             data: Data?,
                                                             more: Bool,
                                                             error: Error?) in
            
            if error != nil {
                abort()
            } else {
                self.defaults.set(newToken, forKey: kSettingsToken)
            }
        }
        
        self.privateDatabase.add(changesOperation)
        
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
    }
    
    // MARK: - Update CoreData
    
    func updateCoreData(_ recordID: CKRecordID, reason: CKQueryNotificationReason, isFolder: Bool) {
        //dispatch_group_wait(self.notificationGroup, DISPATCH_TIME_FOREVER)
        //dispatch_group_enter(self.notificationGroup)
        
        if reason == .recordDeleted {
            if isFolder {
                PKCoreDataManager.sharedManager.update("Deleted", type: "Folder", object: recordID.recordName)
            } else {
                PKCoreDataManager.sharedManager.update("Deleted", type: "Record", object: recordID.recordName)
            }
            return
        }
        
        self.privateDatabase.fetch(withRecordID: recordID) { (object, error) in
            if error != nil {
                print(error!.localizedDescription)
                abort()
            }
            
            guard object != nil else { return }
            let type = object!.recordType
            
            switch (reason, type) {
            case (.recordCreated, "Folder"):
                PKCoreDataManager.sharedManager.update("Created", type: type, object: PKFolderS(folder: object!))
            case (.recordCreated, "Record"):
                PKCoreDataManager.sharedManager.update("Created", type: type, object: PKRecordS(record: object!))
            case (.recordUpdated, "Folder"):
                PKCoreDataManager.sharedManager.update("Updated", type: type, object: PKFolderS(folder: object!))
            case (.recordUpdated, "Record"):
                PKCoreDataManager.sharedManager.update("Updated", type: type, object: PKRecordS(record: object!))
            default:
                break
            }
        }
    }
    
    // MARK: - Subscriptions
    
    func checkAndAddSubscriptions() {
        guard !self.defaults.bool(forKey: kSettingsSubscriptions) else { return }
        
//        self.privateDatabase.fetchAllSubscriptions() {
//            if $1 != nil {
//                print($1?.localizedDescription)
//                abort()
//            } else {
//                
//            }
//        }
        
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let folderSubscription = CKQuerySubscription(recordType: "Folder",
                                                     predicate: predicate,
                                                     options: [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate])
        let recordSubscription = CKQuerySubscription(recordType: "Record",
                                                     predicate: predicate,
                                                     options: [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate])
        
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
                let error = $2 as! NSError
                
                print(error.localizedDescription)
                abort()
//                if error.code == 9 || error.code == 2 {
//                    self.defaults.set(true, forKey: kSettingsSubscriptions)
//                }
//                else {
//                    abort()
//                }
            } else {
                self.defaults.set(true, forKey: kSettingsSubscriptions)
            }
        }
        
        operation.qualityOfService = .utility
        self.privateDatabase.add(operation)
    }
    
    // MARK: - Context
    
    func saveContext(_ deleted: [PKObjectS], updated: [PKObjectS], inserted: [PKObjectS]) {
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
                
                let reference = CKReference(recordID: folderID, action: .none)
                foldersDictToUpdate[reference] = folderS
            case is PKRecordS:
                let recordS = $0 as! PKRecordS
                let recordID = CKRecordID(recordName: recordS.uuid)
                
                let reference = CKReference(recordID: recordID, action: .none)
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
                
                let reference = CKReference(recordID: folderID, action: .none)
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
            deletedObject["uuid"] = $0 as CKRecordValue?
            deletedObject["date"] = Date() as CKRecordValue?
            
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
    
    func saveFolder(_ folderS: PKFolderS) -> CKRecord {
        let folderID = CKRecordID(recordName: folderS.uuid)
        let folder = CKRecord(recordType: "Folder", recordID: folderID)
        
        folder["date"] = folderS.date as CKRecordValue?
        folder["name"] = folderS.name as CKRecordValue?
        
        var records = [CKReference]()
        
        folderS.recordsUUID.forEach() {
            let recordID = CKRecordID(recordName: $0)
            let recordReference = CKReference(recordID: recordID, action: .none)
            records.append(recordReference)
        }
        
        folder["records"] = records as CKRecordValue?
        
        return folder
    }
    
    func saveRecord(_ recordS: PKRecordS) -> CKRecord {
        let recordID = CKRecordID(recordName: recordS.uuid)
        let record = CKRecord(recordType: "Record", recordID: recordID)
        
        record["date"] = recordS.date as CKRecordValue?
        record["createdDT"] = recordS.creationDate as CKRecordValue?
        record["detailedDescription"] = recordS.detailedDescription as CKRecordValue?
        record["login"] = recordS.login as CKRecordValue?
        record["password"] = PKPwdTransformer().transformValue(recordS.password)
        record["title"] = recordS.title as CKRecordValue?
        
        let folderID = CKRecordID(recordName: recordS.folderUUID)
        let folderReference = CKReference(recordID: folderID, action: .none)//.DeleteSelf
        record["folder"] = folderReference
        
        return record
    }
    
    //Deleted
    
    func executeQueryOperation(_ queryOperation: CKQueryOperation, onOperationQueue operationQueue: OperationQueue, deletedRecordsSet: Set<String>) {
        queryOperation.database = self.privateDatabase
        
        queryOperation.recordFetchedBlock = { (record: CKRecord) -> Void in
            self.updateFolder(record, deletedRecordsSet: deletedRecordsSet)
        }
        
        queryOperation.queryCompletionBlock = { (cursor: CKQueryCursor?, error: Error?) -> Void in
            if error != nil {
                let error = error as! NSError
                
                print(error)
                print(error.code)
                abort()
            } else if let queryCursor = cursor {
                let queryCursorOperation = CKQueryOperation(cursor: queryCursor)
                
                self.executeQueryOperation(queryCursorOperation, onOperationQueue: operationQueue, deletedRecordsSet: deletedRecordsSet)
            }
        }
        
        //self.operationQueue.waitUntilAllOperationsAreFinished()
        self.operationQueue.addOperation(queryOperation)
    }
    
    func updateFolder(_ folder: CKRecord, deletedRecordsSet: Set<String>) {
        var records = folder["records"] as! [CKReference]
        records = records.filter() {
            !deletedRecordsSet.contains($0.recordID.recordName)
        }
        
        folder["records"] = records as CKRecordValue?
        
        let updateFoldersOperation = CKModifyRecordsOperation(recordsToSave: [folder], recordIDsToDelete: nil)
        updateFoldersOperation.database = self.privateDatabase
        
        updateFoldersOperation.modifyRecordsCompletionBlock = {
            if $2 != nil {
                let error = $2 as! NSError
                
                print($2)
                print(error.code)
                abort()
            }
        }
        
        self.operationQueue.addOperation(updateFoldersOperation)
    }
    
    //Updated
    
    func executeQueryOperation(_ queryOperation: CKQueryOperation, onOperationQueue operationQueue: OperationQueue, dict: [CKReference: PKObjectS]) {
        queryOperation.database = self.privateDatabase
        
        queryOperation.recordFetchedBlock = { (record: CKRecord) -> Void in
            let ref = CKReference(record: record, action: .none)
            
            if let dict = dict as? [CKReference: PKFolderS] {
                print(dict[ref])
                self.updateFolder(record, fromFolderS: dict[ref]!)
            } else if let dict = dict as? [CKReference: PKRecordS] {
                self.updateRecord(record, fromRecordS: dict[ref]!)
            }
        }
        
        queryOperation.queryCompletionBlock = { (cursor: CKQueryCursor?, error: Error?) -> Void in
            if error != nil {
                let error = error as! NSError
                
                print(error)
                print(error.code)
                abort()
            } else if let queryCursor = cursor {
                let queryCursorOperation = CKQueryOperation(cursor: queryCursor)
                
                self.executeQueryOperation(queryCursorOperation, onOperationQueue: operationQueue, dict: dict)
            }
        }
        
        self.operationQueue.addOperation(queryOperation)
    }
    
    func updateFolder(_ folder: CKRecord, fromFolderS folderS: PKFolderS) {
        folder["date"] = folderS.date as CKRecordValue?
        folder["name"] = folderS.name as CKRecordValue?
        
        var records = [CKReference]()
        
        folderS.recordsUUID.forEach() {
            let recordID = CKRecordID(recordName: $0)
            let recordReference = CKReference(recordID: recordID, action: .none)
            records.append(recordReference)
        }
        
        folder["records"] = records as CKRecordValue?
        
        let updateFoldersOperation = CKModifyRecordsOperation(recordsToSave: [folder], recordIDsToDelete: nil)
        updateFoldersOperation.database = self.privateDatabase
        
        updateFoldersOperation.modifyRecordsCompletionBlock = {
            if $2 != nil {
                let error = $2 as! NSError
                
                print(error)
                print(error.code)
                
                if error.code == 2 {
                    print(error.userInfo[CKPartialErrorsByItemIDKey])
                } else {
                    abort()
                }
            }
        }
        
        self.operationQueue.addOperation(updateFoldersOperation)
    }
    
    func updateRecord(_ record: CKRecord, fromRecordS recordS: PKRecordS) {
        record["date"]                  = recordS.date as CKRecordValue?
        record["createdDT"]             = recordS.creationDate as CKRecordValue?
        record["detailedDescription"]   = recordS.detailedDescription as CKRecordValue?
        record["login"]                 = recordS.login as CKRecordValue?
        record["password"]              = PKPwdTransformer().transformValue(recordS.password)
        record["title"]                 = recordS.title as CKRecordValue?
        
        let folderID = CKRecordID(recordName: recordS.folderUUID)
        let folderReference = CKReference(recordID: folderID, action: .none)//DeleteSelf
        record["folder"] = folderReference
        
        let updateRecordsOperation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        updateRecordsOperation.database = self.privateDatabase
        
        updateRecordsOperation.modifyRecordsCompletionBlock = {
            if $2 != nil {
                let error = $2 as! NSError
                
                print(error)
                print(error.code)
                
                if error.code == 2 {
                    print(error.userInfo[CKPartialErrorsByItemIDKey])
                } else if error.code == 23 {
                    if let retryAfterValue = error.userInfo[CKErrorRetryAfterKey] as? NSNumber {
                        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + Double(Int64(retryAfterValue.doubleValue * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
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
