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
    
    static func getTopViewController() -> UIViewController? {
        var topVC = UIApplication.sharedApplication().windows.first?.rootViewController
        
        while (topVC?.presentedViewController != nil) {
            topVC = topVC?.presentedViewController;
        }
        
        return topVC
    }
    
    func authorizeUser() {
        var topVC = PKServerManager.getTopViewController()
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("PKLoginViewController") as! PKLoginViewController
        
        if topVC is UIAlertController {
            topVC?.dismissViewControllerAnimated(false, completion: nil)
            topVC = PKServerManager.getTopViewController()
        }
        
        if let topVC = topVC as? UINavigationController {
            switch topVC.visibleViewController {
            case is PKFoldersTableViewController:
                vc.delegate = topVC.visibleViewController as! PKFoldersTableViewController
            case is PKRecordEditingViewController:
                (topVC.visibleViewController as! PKRecordEditingViewController).saveData()
            default:
                break
            }
        }
        
//        if (topVC as? UINavigationController)?.visibleViewController is PKFoldersTableViewController {
//            vc.delegate = (topVC as! UINavigationController).visibleViewController as! PKFoldersTableViewController
//        }
//        
//        if (topVC as? UINavigationController)?.visibleViewController is PKRecordEditingViewController {
//            ((topVC as! UINavigationController).visibleViewController as! PKRecordEditingViewController).saveData()
//        }
        
        topVC?.presentViewController(vc, animated: false, completion: nil)
    }
}
