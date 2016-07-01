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
    
    func presentLoginViewControllerOn(topVC: UIViewController?) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("PKLoginViewController") as! PKLoginViewController
        
        guard !(topVC is PKLoginViewController) else { return }
        print(topVC)
        vc.delegate = (topVC as? UINavigationController)?.topViewController as? PKFoldersTableViewController
        
        ((topVC as? UINavigationController)?.topViewController as? PKRecordEditingViewController)?.saveData()
        
//        if let topVC = topVC as? UINavigationController {
//            switch topVC.topViewController {
//            case is PKFoldersTableViewController:
//                vc.delegate = topVC.topViewController as! PKFoldersTableViewController
//            case is PKRecordEditingViewController:
//                print(topVC.topViewController)
//                (topVC.topViewController as! PKRecordEditingViewController).saveData()
//            default:
//                break
//            }
        
//            if topVC.topViewController is PKFoldersTableViewController {
//                vc.delegate = topVC.topViewController as! PKFoldersTableViewController
//            }
//        }
        
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
}
