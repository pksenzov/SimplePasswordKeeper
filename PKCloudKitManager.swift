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
        let folderID = self.defaults.stringForKey(kSettingsSubscriptionFolderID)
        let recordID = self.defaults.stringForKey(kSettingsSubscriptionRecordID)
        
        self.privateDatabase.deleteSubscriptionWithID(folderID!) { (_, error) in
            if error != nil {
                abort()
            }
        }
        
        self.privateDatabase.deleteSubscriptionWithID(recordID!) { (_, error) in
            if error != nil {
                abort()
            }
        }
    }
    
    func addSubscriptionWithType(recordType: String) {
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let subscription = CKSubscription(recordType: recordType, predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordDeletion, .FiresOnRecordUpdate])
        
//        let notificationInfo = CKNotificationInfo()
//        subscription.notificationInfo = notificationInfo
        
        self.privateDatabase.saveSubscription(subscription) { (sub, error) in
            if error != nil {
                print(error?.localizedDescription)
                abort()
            }
            
            let key = (recordType == "Folder") ? kSettingsSubscriptionFolderID : kSettingsSubscriptionRecordID
            self.defaults.setObject(sub?.subscriptionID, forKey: key)
        }
    }
    
    func checkAndAddSubscriptions() {
        let folderID = self.defaults.stringForKey(kSettingsSubscriptionFolderID)
        let recordID = self.defaults.stringForKey(kSettingsSubscriptionRecordID)
        
        self.privateDatabase.fetchSubscriptionWithID(folderID!) { (sub, error) in
            if sub == nil {
                self.addSubscriptionWithType("Folder")
                return
            }
            
            if error != nil {
                print(error?.localizedDescription)
                abort()
            }
        }
        
        self.privateDatabase.fetchSubscriptionWithID(recordID!) { (sub, error) in
            if sub == nil {
                self.addSubscriptionWithType("Record")
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
