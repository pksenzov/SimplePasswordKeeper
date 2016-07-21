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
    
    // MARK: - Cloud Kit Saving support
    
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
    
    func saveContext(deleted: [Any], updated: [Any], inserted: [Any]) {
        deleted.forEach() {
            var uuid = ($0 as? PKFolderS)?.uuid
            uuid = ($0 as? PKRecordS)?.uuid
            
            let id = CKRecordID(recordName: uuid!)
            
            self.privateDatabase.deleteRecordWithID(id) {
                if $1 != nil {
                    abort()
                }
            }
        }

//        updated.forEach() {
//            
//        }
        
        inserted.forEach() {
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
                })
            case is PKRecordS:
                let recordID = CKRecordID(recordName: ($0 as! PKRecordS).uuid)
                let record = CKRecord(recordType: "Record", recordID: recordID)
                record.setObject(($0 as! PKRecordS).date, forKey: "date")
                record.setObject(($0 as! PKRecordS).creationDate, forKey: "creationDate")
                record.setObject(($0 as! PKRecordS).detailedDescription, forKey: "detailedDescription")
                record.setObject(($0 as! PKRecordS).login, forKey: "login")
                record.setObject((($0 as! PKRecordS).password as! String), forKey: "password")
                record.setObject(($0 as! PKRecordS).title, forKey: "title")
                
                let folderID = CKRecordID(recordName: ($0 as! PKRecordS).folderUUID)
                let folderReference = CKReference(recordID: folderID, action: .None)
                record.setObject(folderReference, forKey: "folder")
                
                self.privateDatabase.saveRecord(record) {
                    if $1 != nil {
                        abort()
                    } else {
                        self.privateDatabase.fetchRecordWithID(folderID) {
                            if $1 != nil {
                                abort()
                            } else {
                                guard $0 != nil else { abort() }
                                
                                var records = $0!.objectForKey("records") as! [CKReference]
                                let recordReference = CKReference(recordID: recordID, action: .DeleteSelf)
                                records.append(recordReference)
                                $0!.setObject(records, forKey: "records")
                                
                                self.privateDatabase.saveRecord($0!) {
                                    if $1 != nil {
                                        abort()
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
    }
}
