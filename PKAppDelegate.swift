//
//  AppDelegate.swift
//  SimplePasswordKeeper
//
//  Created by Admin on 12/02/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import UIKit
import CoreSpotlight
import CoreData

let kSettingsLockOnExit = "lockonexit"
let kSettingsSpotlight  = "spotlight"
let kSettingsAutoLock   = "autolock"

var isLocked = NSUserDefaults.standardUserDefaults().boolForKey(kSettingsLockOnExit)

@UIApplicationMain
class PKAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    var managedObjectContext: NSManagedObjectContext {
        if _managedObjectContext == nil {
            _managedObjectContext = PKCoreDataManager.sharedManager.managedObjectContext
        }
        
        return _managedObjectContext!
    }
    var _managedObjectContext: NSManagedObjectContext? = nil

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        NSUserDefaults.standardUserDefaults().registerDefaults([kSettingsLockOnExit : true,
                                                                kSettingsSpotlight  : true,
                                                                kSettingsAutoLock   : 15])
        
        print("APPLICATION DELEGATE - didFinishLaunchingWithOptions")
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        print("APPLICATION DELEGATE - applicationWillResignActive")
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        isLocked = NSUserDefaults.standardUserDefaults().boolForKey(kSettingsLockOnExit)
        
        print("APPLICATION DELEGATE - applicationDidEnterBackground")
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        print("APPLICATION DELEGATE - applicationWillEnterForeground")
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        print("APPLICATION DELEGATE - applicationDidBecomeActive")
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        print("APPLICATION DELEGATE - applicationWillTerminate")
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        isLocked = NSUserDefaults.standardUserDefaults().boolForKey(kSettingsLockOnExit)
        PKCoreDataManager.sharedManager.saveContext()
    }
    
    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
        print("APPLICATION DELEGATE - continueUserActivity")
        
        if userActivity.activityType == CSSearchableItemActionType {
            let uniqueIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String
            
            let mainVC = UIApplication.sharedApplication().windows.first?.rootViewController as! UINavigationController
            let recordsVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("PKRecordsTableViewController") as! PKRecordsTableViewController
            let recordEditingVc = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("PKRecordEditingViewController") as! PKRecordEditingViewController
            
            let fetchRequest = NSFetchRequest(entityName: "Record")
            var mainRecord: PKRecord?
            
            do {
                let records = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [PKRecord]
                
                loop: for record in records {
                    if String(record.objectID) == uniqueIdentifier {
                        mainRecord = record
                        break loop
                    }
                }
                
                guard mainRecord != nil else {
                    mainVC.popToRootViewControllerAnimated(true)
                    
                    return true
                }
            } catch {
                print("Unresolved error \(error), \(error)")
            }
            
            mainVC.popToRootViewControllerAnimated(true)
            
            recordsVC.folder = mainRecord!.folder
            
            let backItem = UIBarButtonItem()
            backItem.title = ""
            mainVC.navigationItem.backBarButtonItem = backItem
            
            mainVC.pushViewController(recordsVC, animated: true)
            
            recordEditingVc.record = mainRecord!
            recordEditingVc.folder = mainRecord!.folder
            
            mainVC.pushViewController(recordEditingVc, animated: true)
        }
        
        return true
    }
}

