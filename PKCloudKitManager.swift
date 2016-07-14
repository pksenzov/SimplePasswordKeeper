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
//        let ID = self.defaults.stringForKey(kSettingsSubscriptionID)
//        
//        self.privateDatabase.deleteSubscriptionWithID(ID!) { (_, error) in
//            if error != nil {
//                abort()
//            }
//        }
    }
    
    func addSubscriptionWithType(recordType: String) {
//        let predicate = NSPredicate(format: "TRUEPREDICATE")
//        let subscription = CKSubscription(recordType: recordType, predicate: predicate, options: .FiresOnRecordCreation)
//        
//        let notificationInfo = CKNotificationInfo()
//        subscription.notificationInfo = notificationInfo
//        
//        self.privateDatabase.saveSubscription(subscription) { (sub, error) in
//            if error != nil {
//                abort()
//            }
//            
//            self.defaults.setObject(sub?.subscriptionID, forKey: kSettingsSubscriptionID)
//        }
    }
    
    func checkAndAddSubscriptions() {
//        let folderID = self.defaults.stringForKey(kSettingsSubscriptionFolderID)
//        let recordID = self.defaults.stringForKey(kSettingsSubscriptionRecordID)
//        
//        self.privateDatabase.fetchSubscriptionWithID(folderID!) { (sub, error) in
//            if error != nil {
//                abort()
//            }
//            
//            if sub == nil { self.addSubscriptionWithType("Folder") }
//        }
//        
//        self.privateDatabase.fetchSubscriptionWithID(recordID!) { (sub, error) in
//            if error != nil {
//                abort()
//            }
//            
//            if sub == nil { self.addSubscriptionWithType("Record") }
//        }
    }
    
    func saveContext() {
        
    }
}
