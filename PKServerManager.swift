//
//  ServerManager.swift
//  SimplePasswordKeeper
//
//  Created by Admin on 17/02/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import UIKit

class PKServerManager: NSObject {
    static let sharedManager = PKServerManager()
    
    // MARK: - My Functions
    
    static func getTopViewController() -> UIViewController? {
        var topVC = UIApplication.sharedApplication().windows.first?.rootViewController
        
        while (topVC?.presentedViewController != nil) {
            topVC = topVC?.presentedViewController;
        }
        
        return topVC
    }
    
    // MARK: - Authorization
    
    func presentLoginViewControllerOn(topVC: UIViewController?) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("PKLoginViewController") as! PKLoginViewController
        
        guard !(topVC is PKLoginViewController) else { return }
        
        vc.delegate = (topVC as? UINavigationController)?.topViewController as? PKFoldersTableViewController
        ((topVC as? UINavigationController)?.topViewController as? PKRecordEditingViewController)?.saveData()
        
        UIApplication.sharedApplication().sendAction(#selector(UIApplication.sharedApplication().resignFirstResponder), to: nil, from: nil, forEvent: nil)
        topVC?.presentViewController(vc, animated: false, completion: nil)
    }
    
    func authorizeUser() {
        var topVC = PKServerManager.getTopViewController()
        
        if topVC is UIAlertController {
            topVC?.dismissViewControllerAnimated(false) {
                topVC = PKServerManager.getTopViewController()
                self.presentLoginViewControllerOn(topVC)
                
                return
            }
        }
        
        print(topVC?.description)
        self.presentLoginViewControllerOn(topVC)
    }
    
    // MARK: - Sync
    
    func sync() {
        PKCloudKitManager.sharedManager.checkAndAddSubscriptions()
        
    }
    
    // MARK: - Notification Update UI
    
    func popIfNeeded(object: AnyObject) {
        let topVC = PKServerManager.getTopViewController()
        let navVC = topVC as? UINavigationController
        
        guard navVC != nil else {
            if let vc = topVC as? PKMoveRecordsViewController {
                let navVC = vc.presentingViewController as! UINavigationController
                
                if let folder = object as? PKFolder {
                    let recordsVC = navVC.topViewController as! PKRecordsTableViewController
                    
                    if recordsVC.folder == folder {
                        self.holdAndDismissAndPop(navVC)
                    }
                } else if let record = object as? PKRecord {
                    if vc.records.contains(record) {
                        self.holdAndDismiss(navVC)
                    }
                }
            }
            
            return
        }
        
        switch (object, navVC!.topViewController) {
        case (is PKRecord, is PKRecordEditingViewController):
            let record = object as! PKRecord
            let vc = navVC!.topViewController as! PKRecordEditingViewController
            
            if vc.record == record { self.holdAndPop(navVC!) }
        case (is PKFolder, is PKRecordsTableViewController):
            let folder = object as! PKFolder
            let vc = navVC!.topViewController as! PKRecordsTableViewController
            
            if vc.folder == folder { self.holdAndPop(navVC!) }
        case (is PKFolder, is PKRecordEditingViewController):
            let folder = object as! PKFolder
            let vc = navVC!.topViewController as! PKRecordEditingViewController
            
            if vc.folder == folder { self.holdAndPopToRoot(navVC!)}
        default:
            break
        }
    }
    
    func holdAndPop(navVC: UINavigationController) {
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        
        dispatch_async(dispatch_get_main_queue()) {
            navVC.popViewControllerAnimated(true)
        }
    }
    
    func holdAndPopToRoot(navVC: UINavigationController) {
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        
        dispatch_async(dispatch_get_main_queue()) {
            navVC.popToRootViewControllerAnimated(true)
        }
    }
    
    func holdAndDismiss(navVC: UINavigationController) {
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        
        dispatch_async(dispatch_get_main_queue()) {
            navVC.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func holdAndDismissAndPop(navVC: UINavigationController) {
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        
        dispatch_async(dispatch_get_main_queue()) {
            navVC.dismissViewControllerAnimated(true, completion: nil)
            navVC.popViewControllerAnimated(true)
        }
    }
}
