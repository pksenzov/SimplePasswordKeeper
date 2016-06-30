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
        
        //ALERT DISMIIS COMPLETION
        if topVC is UIAlertController {
            topVC?.dismissViewControllerAnimated(false, completion: nil)
            topVC = PKServerManager.getTopViewController()
        }
        
        print(topVC?.description)
        
        guard !(topVC is PKLoginViewController) else { return }
        
        if let topVC = topVC as? UINavigationController {
            if topVC.visibleViewController is PKFoldersTableViewController {
                vc.delegate = topVC.visibleViewController as! PKFoldersTableViewController
            }
        }
        
        UIApplication.sharedApplication().sendAction(#selector(UIApplication.sharedApplication().resignFirstResponder), to: nil, from: nil, forEvent: nil)
        topVC?.presentViewController(vc, animated: false, completion: nil)
    }
}
