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
    
    func saveContext(deleted: [Any], updated: [Any], inserted: [Any]) {
        let iCloudGroup = dispatch_group_create()
        
        inserted.forEach() {
            dispatch_group_enter(iCloudGroup)
            
            switch $0 {
            case is PKFolderS:
                let folder = self.saveFolder($0 as! PKFolderS, folder: nil)
                
                self.privateDatabase.saveRecord(folder, completionHandler: {
                    if $1 != nil {
                        abort()
                    }
                    
                    dispatch_group_leave(iCloudGroup)
                })
            case is PKRecordS:
                let record = self.saveRecord($0 as! PKRecordS, record: nil)
                
                self.privateDatabase.saveRecord(record) {
                    if $1 != nil {
                        print($1!.localizedDescription)
                        abort()
                    }
                    
                    dispatch_group_leave(iCloudGroup)
                }
            default:
                break
            }
        }
        
        dispatch_group_wait(iCloudGroup, DISPATCH_TIME_FOREVER)
        
        updated.forEach() {
            dispatch_group_enter(iCloudGroup)
            
            switch $0 {
            case is PKFolderS:
                let folderS = $0 as! PKFolderS
                let folderID = CKRecordID(recordName: folderS.uuid)
                
                self.privateDatabase.fetchRecordWithID(folderID) {
                    if $1 != nil {
                        abort()
                    } else {
                        guard $0 != nil else { abort() }
                        
                        let folder = self.saveFolder(folderS, folder: $0!)
                        
                        self.privateDatabase.saveRecord(folder) {
                            if $1 != nil {
                                abort()
                            }
                            
                            dispatch_group_leave(iCloudGroup)
                        }
                    }
                }
            case is PKRecordS:
                let recordS = $0 as! PKRecordS
                let recordID = CKRecordID(recordName: recordS.uuid)
                
                self.privateDatabase.fetchRecordWithID(recordID) {
                    if $1 != nil {
                        abort()
                    } else {
                        guard $0 != nil else { abort() }
                        
                        let record = self.saveRecord(recordS, record: $0!)
                        
                        self.privateDatabase.saveRecord(record) {
                            if $1 != nil {
                                abort()
                            }
                            
                            dispatch_group_leave(iCloudGroup)
                        }
                    }
                }
            default:
                break
            }
        }
        
        dispatch_group_wait(iCloudGroup, DISPATCH_TIME_FOREVER)
        let theSameFolderGroup = dispatch_group_create()
        
        deleted.forEach() {
            dispatch_group_enter(iCloudGroup)
            
            var uuid: String!
            
            switch $0 {
            case is PKFolderS:
                let folderS = ($0 as! PKFolderS)
                uuid = folderS.uuid
                let id = CKRecordID(recordName: uuid)
                
                self.privateDatabase.deleteRecordWithID(id) {
                    if $1 != nil {
                        abort()
                    }
                    
                    let deletedObject = CKRecord(recordType: "DeletedObject")
                    deletedObject["uuid"] = folderS.uuid
                    deletedObject["date"] = NSDate()
                    
                    self.privateDatabase.saveRecord(deletedObject) {
                        if $1 != nil {
                            abort()
                        }
                        
                        dispatch_group_leave(iCloudGroup)
                    }
                }
            case is PKRecordS:
                dispatch_group_wait(theSameFolderGroup, DISPATCH_TIME_FOREVER)
                dispatch_group_enter(theSameFolderGroup)
                
                let recordS = $0 as! PKRecordS
                uuid = recordS.uuid
                let id = CKRecordID(recordName: uuid)
                
                let folderID = CKRecordID(recordName: recordS.folderUUID)
                
                self.privateDatabase.fetchRecordWithID(folderID) { (folder, error) in //1
                    if error != nil {
                        abort()
                    } else {
                        guard folder != nil else { abort() }
                        
                        var records = folder!.objectForKey("records") as! [CKReference]
                        records = records.filter() {
                            $0.recordID.recordName != recordS.uuid
                        }
                        
                        folder!.setObject(records, forKey: "records")
                        
                        self.privateDatabase.saveRecord(folder!) { //2
                            if $1 != nil {
                                print($1?.localizedDescription)
                                abort()
                            } else {
                                self.privateDatabase.deleteRecordWithID(id) { //3
                                    if $1 != nil {
                                        abort()
                                    }
                                    
                                    let deletedObject = CKRecord(recordType: "DeletedObject")
                                    deletedObject["uuid"] = recordS.uuid
                                    deletedObject["date"] = NSDate()
                                    
                                    self.privateDatabase.saveRecord(deletedObject) { //4
                                        if $1 != nil {
                                            abort()
                                        }
                                        
                                        dispatch_group_leave(theSameFolderGroup)
                                        dispatch_group_leave(iCloudGroup)
                                    }
                                }
                            }
                        }
                    }
                }
            default:
                break
            }
        }
        
        dispatch_group_wait(iCloudGroup, DISPATCH_TIME_FOREVER)
    }
    
    func saveFolder(folderS: PKFolderS, folder: CKRecord?) -> CKRecord {
        var folder = folder
        
        if folder == nil {
            let folderID = CKRecordID(recordName: folderS.uuid)
            folder = CKRecord(recordType: "Folder", recordID: folderID)
        }
        
        folder!["date"] = folderS.date
        folder!["name"] = folderS.name
        
        var records = [CKReference]()
        
        folderS.recordsUUID.forEach() {
            let recordID = CKRecordID(recordName: $0)
            let recordReference = CKReference(recordID: recordID, action: .None)
            records.append(recordReference)
        }
        
        folder!.setObject(records, forKey: "records")
        
        return folder!
    }
    
    func saveRecord(recordS: PKRecordS, record: CKRecord?) -> CKRecord {
        var record = record
        
        if record == nil {
            let recordID = CKRecordID(recordName: recordS.uuid)
            record = CKRecord(recordType: "Record", recordID: recordID)
        }
        
        record!["date"] = recordS.date
        record!["createdDT"] = recordS.creationDate
        record!["detailedDescription"] = recordS.detailedDescription
        record!["login"] = recordS.login
        record!["password"] = PKPwdTransformer().transformValue(recordS.password)
        record!["title"] = recordS.title
        
        let folderID = CKRecordID(recordName: recordS.folderUUID)
        let folderReference = CKReference(recordID: folderID, action: .DeleteSelf)
        record!["folder"] = folderReference
        
        return record!
    }
}
