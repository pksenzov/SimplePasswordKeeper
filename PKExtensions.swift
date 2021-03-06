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

let kApplicationDidTimeoutNotification      = "ApplicationTimeout"
let kApplicationDidTimeoutClearNotification = "ApplicationTimeoutClear"

let kContentType = "record"

let kSettingsLockOnExit                 = "lockonexit"
let kSettingsSpotlight                  = "spotlight"
let kSettingsAutoLock                   = "autolock"
let kSettingsICloud                     = "icloud"
let kSettingsSubscriptions              = "subscriptions"
let kSettingsClearClipboard             = "clearclipboard"
let kSettingsToken                      = "token"

let firstFolderName = "Records"

var isLocked                    = UserDefaults.standard.bool(forKey: kSettingsLockOnExit)
var isNeededAuthorization       = false
var isSpotlightWaiting          = false
var isNeededClearTimerRestart   = false

// MARK: - Fatal Errors

//enum CKFatalErrorCode: Int {
//    case internalError
//    case serverRejectedRequest
//    case invalidArguments
//    case permissionFailure
//}

// MARK: - Retry Cases

//public enum CKRetryErrorCode: Int {
//    case zoneBusy
//    case serviceUnavailable
//    case requestRateLimited
//}

// Using CKErrorRetryAfterKey
//var error = ... // Error from the previous CKOperation
//if let retryAfter = error.userInfo[CKErrorRetryAfterKey] as? Double {
//    let delayTime = DispatchTime.now() + retryAfter
//    DispatchQueue.main.after(when: delayTime) {
//        // Initialize CKOperation for a retry
//    }
//}

// MARK: - PKFoldersTableViewController, PKMoveRecordsViewController

extension UIAlertController {
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        let tag = self.view.tag
        
        if (tag == 1001 || tag == 1002 || tag == 1003) {
            let textField = self.view.viewWithTag(tag - 900) as! UITextField // UITextField tag = UIAlertController tag - 900
            let zeroPosition = textField.beginningOfDocument
            
            textField.selectedTextRange = textField.textRange(from: zeroPosition, to: zeroPosition)
        }
    }
}

// MARK: - PKMoveRecordsViewController

extension UITextView {
    var adjustHeightToRealIPhoneSize: Bool {
        set {
            if newValue {
                self.constraints.filter{ $0.identifier == "DescriptionHeight" }.first!.constant = UIScreen.main.bounds.size.height - self.frame.origin.y - 80.0
            }
        }
        
        get {
            return false
        }
    }
}

// MARK: - CoreData

extension NSManagedObjectContext {
    func insertObject<A: NSManagedObject>() -> A where A: ManagedObjectType {
        guard let obj = NSEntityDescription.insertNewObject(forEntityName: A.entityName, into: self) as? A else {
            fatalError("Entity \(A.entityName) does not correspond to \(A.self)")
        }
        
        return obj
    }
}
