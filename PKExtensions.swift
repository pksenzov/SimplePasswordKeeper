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

let firstFolderName = "Records"

var isLocked                = NSUserDefaults.standardUserDefaults().boolForKey(kSettingsLockOnExit)
var isNeededAuthorization   = false
var isSpotlightWaiting      = false

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