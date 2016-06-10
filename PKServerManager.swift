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
    
    func authorizeUser() {
        let mainVC = UIApplication.sharedApplication().windows.first?.rootViewController as! UINavigationController
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("PKLoginViewController") as! PKLoginViewController
        //vc.delegate = mainVC.viewControllers.first as! PKFoldersTableViewController
        
        mainVC.dismissViewControllerAnimated(false, completion: nil)
        mainVC.presentViewController(vc, animated: false, completion: nil)
    }
}
