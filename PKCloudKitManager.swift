//
//  PKCloudKitManager.swift
//  Records
//
//  Created by Admin on 13/07/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import UIKit
import CloudKit

class PKCloudKitManager: NSObject {
    static let sharedManager = PKCloudKitManager()
    
    let privateDatabase = CKContainer.defaultContainer().privateCloudDatabase
    let defaults = NSUserDefaults.standardUserDefaults()
    
    // MARK: - Cloud Kit Saving support
    
    func deleteSubscriptions() {
        self.privateDatabase.fetchAllSubscriptionsWithCompletionHandler() { (subs, error) in
            if subs == nil || subs?.count == 0 { return }
            
            if error != nil {
                print(error?.localizedDescription)
                abort()
            }
            
            subs!.forEach() {
                self.privateDatabase.deleteSubscriptionWithID($0.subscriptionID) { (_, error) in
                    if error != nil {
                        abort()
                    }
                }
            }
        }
    }
    
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
        }
    }
    
    func checkAndAddSubscriptions() {
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
    
    func saveContext() {
        
    }
}
