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
    
    func addSubscriptions() {
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let folderSubscription = CKSubscription(recordType: "Folder", predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordDeletion, .FiresOnRecordUpdate])
        let recordSubscription = CKSubscription(recordType: "Record", predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordDeletion, .FiresOnRecordUpdate])
        
        self.privateDatabase.saveSubscription(folderSubscription) { (sub, error) in
            if error != nil {
                print(error?.localizedDescription)
                abort()
            }
            
            self.privateDatabase.saveSubscription(recordSubscription) { (sub, error) in
                if error != nil {
                    print(error?.localizedDescription)
                    abort()
                }
                
                self.defaults.setBool(true, forKey: kSettingsSubscriptions)
            }
        }
    }
    
    func addSubscriptionWithType(recordType: String) {
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let subscription = CKSubscription(recordType: recordType, predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordDeletion, .FiresOnRecordUpdate])
        
        self.privateDatabase.saveSubscription(subscription) { (sub, error) in
            if error != nil {
                print(error?.localizedDescription)
                abort()
            }
            
            self.defaults.setBool(true, forKey: kSettingsSubscriptions)
        }
    }
    
    func checkAndAddSubscriptions() {
        guard !self.defaults.boolForKey(kSettingsSubscriptions) else { return }
        
        self.privateDatabase.fetchAllSubscriptionsWithCompletionHandler() { (subs, error) in
            if subs == nil || subs?.count == 0 {
                self.addSubscriptions()
                return
            } else if subs?.count == 1 {
                let recordType = (subs!.first!.recordType == "Folder") ? "Record" : "Folder"
                self.addSubscriptionWithType(recordType)
                return
            }
            
            if error != nil {
                print(error?.localizedDescription)
                abort()
            }
        }
    }
    
    // MARK: - Context
    
    func saveContext(deleted: [Any], updated: [Any], inserted: [Any]) {
        let iCloudGroup = dispatch_group_create()
        
        inserted.forEach() {
            dispatch_group_enter(iCloudGroup)
            
            switch $0 {
            case is PKFolderS:
                let folderID = CKRecordID(recordName: ($0 as! PKFolderS).uuid)
                let folder = CKRecord(recordType: "Folder", recordID: folderID)
                folder.setObject(($0 as! PKFolderS).date, forKey: "date")
                folder.setObject(($0 as! PKFolderS).name, forKey: "name")
                //reference to records must be empty
                
                self.privateDatabase.saveRecord(folder, completionHandler: {
                    if $1 != nil {
                        abort()
                    }
                    
                    dispatch_group_leave(iCloudGroup)
                })
            case is PKRecordS:
                let recordID = CKRecordID(recordName: ($0 as! PKRecordS).uuid)
                let record = CKRecord(recordType: "Record", recordID: recordID)
                record.setObject(($0 as! PKRecordS).date, forKey: "date")
                record.setObject(($0 as! PKRecordS).creationDate, forKey: "createdDT")
                record.setObject(($0 as! PKRecordS).detailedDescription, forKey: "detailedDescription")
                record.setObject(($0 as! PKRecordS).login, forKey: "login")
                record.setObject(PKPwdTransformer().transformValue(($0 as! PKRecordS).password), forKey: "password")
                record.setObject(($0 as! PKRecordS).title, forKey: "title")
                
                let folderID = CKRecordID(recordName: ($0 as! PKRecordS).folderUUID)
                let folderReference = CKReference(recordID: folderID, action: .DeleteSelf)
                record.setObject(folderReference, forKey: "folder")
                
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
                
                self.privateDatabase.fetchRecordWithID(folderID) { (folder, error) in
                    if error != nil {
                        abort()
                    } else {
                        guard folder != nil else { abort() }
                        
                        folder!.setObject(folderS.date, forKey: "date")
                        folder!.setObject(folderS.name, forKey: "name")
                        
                        var records = [CKReference]()
                        
                        folderS.recordsUUID.forEach() {
                            let recordID = CKRecordID(recordName: $0)
                            let recordReference = CKReference(recordID: recordID, action: .None)
                            records.append(recordReference)
                        }
                        
                        folder!.setObject(records, forKey: "records")
                        
                        self.privateDatabase.saveRecord(folder!) {
                            if $1 != nil {
                                print($1?.localizedDescription)
                                abort()
                            }
                            
                            dispatch_group_leave(iCloudGroup)
                        }
                    }
                }
            case is PKRecordS:
                let recordS = $0 as! PKRecordS
                let recordID = CKRecordID(recordName: recordS.uuid)
                
                self.privateDatabase.fetchRecordWithID(recordID) { (record, error) in
                    if error != nil {
                        print(error?.localizedDescription)
                        abort()
                    } else {
                        guard record != nil else { abort() }
                        
                        record!.setObject(recordS.date, forKey: "date")
                        record!.setObject(recordS.creationDate, forKey: "createdDT")
                        record!.setObject(recordS.detailedDescription, forKey: "detailedDescription")
                        record!.setObject(recordS.login, forKey: "login")
                        record!.setObject(PKPwdTransformer().transformValue(recordS.password), forKey: "password")
                        record!.setObject(recordS.title, forKey: "title")
                        
                        let folderID = CKRecordID(recordName: recordS.folderUUID)
                        let folderReference = CKReference(recordID: folderID, action: .DeleteSelf)
                        record!.setObject(folderReference, forKey: "folder")
                        
                        self.privateDatabase.saveRecord(record!) {
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
                uuid = ($0 as! PKFolderS).uuid
                let id = CKRecordID(recordName: uuid)
                
                self.privateDatabase.deleteRecordWithID(id) {
                    if $1 != nil {
                        abort()
                    }
                    
                    dispatch_group_leave(iCloudGroup)
                }
            case is PKRecordS:
                dispatch_group_wait(theSameFolderGroup, DISPATCH_TIME_FOREVER)
                dispatch_group_enter(theSameFolderGroup)
                
                let recordS = $0 as! PKRecordS
                uuid = recordS.uuid
                let id = CKRecordID(recordName: uuid)
                
                let folderID = CKRecordID(recordName: recordS.folderUUID)
                
                self.privateDatabase.fetchRecordWithID(folderID) { (folder, error) in
                    if error != nil {
                        abort()
                    } else {
                        guard folder != nil else { abort() }
                        
                        var records = folder!.objectForKey("records") as! [CKReference]
                        records = records.filter() {
                            $0.recordID.recordName !=  recordS.uuid
                        }
                        
                        folder!.setObject(records, forKey: "records")
                        
                        self.privateDatabase.saveRecord(folder!) {
                            if $1 != nil {
                                print($1?.localizedDescription)
                                abort()
                            } else {
                                self.privateDatabase.deleteRecordWithID(id) {
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
            default:
                break
            }
        }
        
        dispatch_group_wait(iCloudGroup, DISPATCH_TIME_FOREVER)
    }
}
