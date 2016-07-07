//
//  Extensions.swift
//  Records
//
//  Created by Admin on 04/07/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

// MARK: - Constants & Variables

let kApplicationDidTimeoutNotification = "ApplicationTimeout"

let kContentType = "record"

let kSettingsLockOnExit                 = "lockonexit"
let kSettingsSpotlight                  = "spotlight"
let kSettingsAutoLock                   = "autolock"
let kSettingsICloud                     = "icloud"
let kSettingsLastCloudKitSyncTimestamp  = "timestamp"

let firstFolderName = "Records"

var isLocked                = NSUserDefaults.standardUserDefaults().boolForKey(kSettingsLockOnExit)
var isNeededAuthorization   = false
var isSpotlightWaiting      = false

enum CloudKitZone: String {
    case FolderZone = "FolderZone"
    case RecordZone = "RecordZone"
    
    init?(recordType: String) {
        switch recordType {
        case ModelObjectType.Folder.rawValue : self = .FolderZone
        case ModelObjectType.Record.rawValue : self = .RecordZone
        default : return nil
        }
    }
    
    func serverTokenDefaultsKey() -> String {
        return rawValue + "ServerChangeTokenKey"
    }
    
    func recordZoneID() -> CKRecordZoneID {
        return CKRecordZoneID(zoneName: rawValue, ownerName: CKOwnerDefaultName)
    }
    
    func recordType() -> String {
        switch self {
        case .FolderZone : return ModelObjectType.Folder.rawValue
        case .RecordZone : return ModelObjectType.Record.rawValue
        }
    }
    
    func cloudKitSubscription() -> CKSubscription {
        // options must be set to 0 per current documentation
        // https://developer.apple.com/library/ios/documentation/CloudKit/Reference/CKSubscription_class/index.html#//apple_ref/occ/instm/CKSubscription/initWithZoneID:options:
        let subscription = CKSubscription(zoneID: recordZoneID(), options: CKSubscriptionOptions(rawValue: 0))
        subscription.notificationInfo = notificationInfo()
        return subscription
    }
    
    func notificationInfo() -> CKNotificationInfo {
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.alertBody = "Subscription notification for \(rawValue)"
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.shouldBadge = false
        return notificationInfo
    }
    
    static let allCloudKitZoneNames = [
        CloudKitZone.FolderZone.rawValue,
        CloudKitZone.RecordZone.rawValue
    ]
}

enum ModelObjectType: String {
    case Folder = "Folder"
    case Record = "Record"
    case DeletedCloudKitObject = "DeletedCloudKitObject"
    
//    init?(storyboardRestorationID: String) {
//        switch storyboardRestorationID {
//        case "FoldersListScene" : self = .Folder
//        case "RecordsListScene" : self = .Record
//        default : return nil
//        }
//    }
    
    static let allCloudKitModelObjectTypes = [
        ModelObjectType.Folder.rawValue,
        ModelObjectType.Record.rawValue
    ]
}

// MARK: - CloudKit Protocols

@objc protocol CloudKitManagedObject: CloudKitRecordIDObject {
    var recordName: String? { get set }
    var recordType: String { get }
    func managedObjectToRecord(record: CKRecord?) -> CKRecord
    func updateWithRecord(record: CKRecord)
}

@objc protocol CloudKitRecordIDObject {
    var recordID: NSData? { get set }
}

extension CloudKitRecordIDObject {
    func cloudKitRecordID() -> CKRecordID? {
        guard let recordID = recordID else {
            return nil
        }
        
        return NSKeyedUnarchiver.unarchiveObjectWithData(recordID) as? CKRecordID
    }
}

// MARK: - PKFoldersTableViewController, PKMoveRecordsViewController

extension UIAlertController {
    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        let tag = self.view.tag
        
        if (tag == 1001 || tag == 1002 || tag == 1003) {
            let textField = self.view.viewWithTag(tag - 900) as! UITextField // UITextField tag = UIAlertController tag - 900
            let zeroPosition = textField.beginningOfDocument
            
            textField.selectedTextRange = textField.textRangeFromPosition(zeroPosition, toPosition: zeroPosition)
        }
    }
}

// MARK: - PKMoveRecordsViewController

extension UITextView {
    var adjustHeightToRealIPhoneSize: Bool {
        set {
            if newValue {
                self.constraints.filter{ $0.identifier == "DescriptionHeight" }.first!.constant = UIScreen.mainScreen().bounds.size.height - self.frame.origin.y - 80.0
            }
        }
        
        get {
            return false
        }
    }
}

// MARK: - CoreData

extension NSManagedObjectContext {
    func insertObject<A: NSManagedObject where A: ManagedObjectType>() -> A {
        guard let obj = NSEntityDescription.insertNewObjectForEntityForName(A.entityName, inManagedObjectContext: self) as? A else {
            fatalError("Entity \(A.entityName) does not correspond to \(A.self)")
        }
        
        return obj
    }
}