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
import CloudKit

private extension Selector {
    static let applicationDidTimeout = #selector(PKAppDelegate.applicationDidTimeout)
}

class PKAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    var managedObjectContext: NSManagedObjectContext {
        if _managedObjectContext == nil {
            _managedObjectContext = PKCoreDataManager.sharedManager.managedObjectContext
        }
        
        return _managedObjectContext!
    }
    var _managedObjectContext: NSManagedObjectContext? = nil
    
    // MARK: - iCloud
    
    static func iCloudAccountIsSignedIn() -> Bool {
        let token = NSFileManager.defaultManager().ubiquityIdentityToken
        guard token != nil else { return false }
        
        return true
    }
    
    // MARK: - Notifications
    
    func applicationDidTimeout() {
        if UIApplication.sharedApplication().applicationState == .Active {
            PKServerManager.sharedManager.authorizeUser()
        } else {
            isNeededAuthorization = true
        }
    }
    
    // MARK: - Application Lifecycle
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        NSUserDefaults.standardUserDefaults().registerDefaults([kSettingsLockOnExit                 : true,
                                                                kSettingsSpotlight                  : true,
                                                                kSettingsSubscriptions              : false,
                                                                kSettingsICloud                     : PKAppDelegate.iCloudAccountIsSignedIn(),
                                                                kSettingsAutoLock                   : 15])
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: .applicationDidTimeout, name: kApplicationDidTimeoutNotification, object: nil)
        
        if PKAppDelegate.iCloudAccountIsSignedIn() && NSUserDefaults.standardUserDefaults().boolForKey(kSettingsICloud) {
            PKServerManager.sharedManager.sync()
        }
        
        let notificationSettings = UIUserNotificationSettings(forTypes: .None, categories: nil)
        application.registerUserNotificationSettings(notificationSettings)
        application.registerForRemoteNotifications()
        
//        UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert categories:nil];
//        [application registerUserNotificationSettings:notificationSettings];
//        [application registerForRemoteNotifications];
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        print("APPLICATION DELEGATE - applicationWillResignActive")
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        isLocked = NSUserDefaults.standardUserDefaults().boolForKey(kSettingsLockOnExit)
        var topVC = PKServerManager.getTopViewController()
        
        if topVC is UIAlertController {
            topVC?.dismissViewControllerAnimated(false, completion: nil)
            topVC = PKServerManager.getTopViewController()
        }
        
        if isLocked && !(topVC is PKLoginViewController) {
            PKServerManager.sharedManager.authorizeUser()
            return
        } else if isLocked && topVC is PKLoginViewController {
            (topVC as! PKLoginViewController).isRepeatAlert = true
            return
        } else if !(topVC is PKLoginViewController) {
            ((topVC as? UINavigationController)?.topViewController as? PKRecordEditingViewController)?.saveData()
            
            let blankVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("PKBlankViewController")
            topVC?.presentViewController(blankVC, animated: false, completion: nil)
            
            
            //            var backgroundTask = UIBackgroundTaskInvalid
            //
            //            backgroundTask = application.beginBackgroundTaskWithName("SpotlightTask") {
            //                application.endBackgroundTask(backgroundTask)
            //                backgroundTask = UIBackgroundTaskInvalid
            //            }
            //
            //            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            //                let isSwitchedOn = NSUserDefaults.standardUserDefaults().boolForKey(kSettingsSpotlight)
            //
            //                CSSearchableIndex.defaultSearchableIndex().deleteAllSearchableItemsWithCompletionHandler() { error in
            //                    if error != nil {
            //                        print(error?.localizedDescription)
            //
            //                        application.endBackgroundTask(backgroundTask)
            //                        backgroundTask = UIBackgroundTaskInvalid
            //                    } else if isSwitchedOn {
            //                        print("APP - Items Indexes Deleted")
            //
            //                        let fetchRequest = NSFetchRequest(entityName: "Record")
            //
            //                        do {
            //                            var items = [CSSearchableItem]()
            //                            let records = try PKCoreDataManager.sharedManager.managedObjectContext.executeFetchRequest(fetchRequest) as! [PKRecord]
            //
            //                            records.forEach() {
            //                                let attributeSet = CSSearchableItemAttributeSet(itemContentType: kContentType)
            //
            //                                attributeSet.title = $0.title
            //                                attributeSet.contentDescription = "Secure Record" 
            //                                attributeSet.keywords = [$0.title!]
            //
            //                                let item = CSSearchableItem(uniqueIdentifier: String($0.objectID), domainIdentifier: nil, attributeSet: attributeSet)
            //                                item.expirationDate = NSDate.distantFuture()
            //
            //                                items.append(item)
            //                            }
            //
            //                            CSSearchableIndex.defaultSearchableIndex().indexSearchableItems(items) { error in
            //                                if error != nil {
            //                                    print(error?.localizedDescription)
            //                                } else {
            //                                    print("APP - All Items Indexed")
            //                                }
            //
            //                                application.endBackgroundTask(backgroundTask)
            //                                backgroundTask = UIBackgroundTaskInvalid
            //                            }
            //                        } catch {
            //                            print("Unresolved error \(error), \(error)")
            //
            //                            application.endBackgroundTask(backgroundTask)
            //                            backgroundTask = UIBackgroundTaskInvalid
            //                        }
            //                    } else {
            //                        application.endBackgroundTask(backgroundTask)
            //                        backgroundTask = UIBackgroundTaskInvalid
            //                    }
            //                }
            //            }
        }
        
        print("APPLICATION DELEGATE - applicationDidEnterBackground")
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        if PKAppDelegate.iCloudAccountIsSignedIn() && NSUserDefaults.standardUserDefaults().boolForKey(kSettingsICloud) {
            PKServerManager.sharedManager.sync()
        }
        
        print("APPLICATION DELEGATE - applicationWillEnterForeground")
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        if isNeededAuthorization {
            isNeededAuthorization = false
            PKServerManager.sharedManager.authorizeUser()
        }
        
        print("APPLICATION DELEGATE - applicationDidBecomeActive")
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        print("APPLICATION DELEGATE - applicationWillTerminate")
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
            
            let topVC = PKServerManager.getTopViewController()
            
            if topVC is PKLoginViewController || isNeededAuthorization {
                isSpotlightWaiting = true
                isNeededAuthorization = false
                PKServerManager.sharedManager.authorizeUser()
            } else {
                mainVC.dismissViewControllerAnimated(true, completion: nil)
            }
            
            mainVC.popToRootViewControllerAnimated(true)
            
            recordsVC.folder = mainRecord!.folder
            recordsVC.navigationItem.title = mainRecord!.folder!.name
            
            let backItem = UIBarButtonItem()
            backItem.title = ""
            mainVC.viewControllers.first?.navigationItem.backBarButtonItem = backItem
            
            mainVC.pushViewController(recordsVC, animated: true)
            
            recordEditingVc.record = mainRecord!
            recordEditingVc.folder = mainRecord!.folder
            
            mainVC.pushViewController(recordEditingVc, animated: true)
        }
        
        return true
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject: AnyObject]) {
        guard PKAppDelegate.iCloudAccountIsSignedIn() && NSUserDefaults.standardUserDefaults().boolForKey(kSettingsICloud) else { return }
        
        if let userInfo = userInfo as? [String: NSObject] {
            let cloudKitNotification = CKNotification(fromRemoteNotificationDictionary: userInfo)
            
            if (cloudKitNotification.notificationType == .Query) {
                let ckQueryNotification = cloudKitNotification as! CKQueryNotification
                let recordID = ckQueryNotification.recordID
                
                switch ckQueryNotification.queryNotificationReason {
                case .RecordCreated:
                    print(ckQueryNotification.recordFields)
                    if ckQueryNotification.recordFields!["name"] != nil {
                        let newFolder: PKFolder = self.managedObjectContext.insertObject()
                        newFolder.name = (ckQueryNotification.recordFields!["name"] as! String)
                        newFolder.date = NSDate.init(timeIntervalSince1970: (ckQueryNotification.recordFields!["date"] as! NSNumber).doubleValue)
                        print(newFolder.date?.description)
                        newFolder.uuid = recordID!.recordName
                        //no records in new folder
                    } else {
                        let newRecord: PKRecord = self.managedObjectContext.insertObject()
                        newRecord.title = (ckQueryNotification.recordFields!["title"] as! String)
                        newRecord.login = (ckQueryNotification.recordFields!["login"] as! String)
                        newRecord.password = (ckQueryNotification.recordFields!["password"] as! NSData)
                        newRecord.detailedDescription = (ckQueryNotification.recordFields!["detailedDescription"] as! String)
                        newRecord.creationDate = (ckQueryNotification.recordFields!["createdDT"] as! NSDate)
                        newRecord.date = (ckQueryNotification.recordFields!["date"] as! NSDate)
                        newRecord.uuid = recordID!.recordName
                        
                        let folderUUID = (ckQueryNotification.recordFields!["folder"] as! CKReference).recordID.recordName
                        let predicate = NSPredicate(format: "uuid == %@", folderUUID)
                        let fetchRequest = NSFetchRequest(entityName: "Folder")
                        fetchRequest.predicate = predicate
                        
                        var folder: PKFolder!
                        do {
                            let folders = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [PKFolder]
                            folder = folders.first!
                        } catch {
                            // что-то делаем в зависимости от ошибки
                        }
                        
                        newRecord.folder = folder
                    }
                case .RecordUpdated:
                    if ckQueryNotification.recordFields!["name"] != nil {
                        let predicate = NSPredicate(format: "uuid == %@", recordID!.recordName)
                        let fetchRequest = NSFetchRequest(entityName: "Folder")
                        fetchRequest.predicate = predicate
                        
                        var folder: PKFolder!
                        do {
                            let folders = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [PKFolder]
                            folder = folders.first!
                        } catch {
                            // что-то делаем в зависимости от ошибки
                        }
                        
                        folder.name = (ckQueryNotification.recordFields!["name"] as! String)
                        folder.date = (ckQueryNotification.recordFields!["date"] as! NSDate)
                        
                        let references = ckQueryNotification.recordFields!["records"] as! [CKReference]
                        let UUIDs = references.map() { $0.recordID.recordName }
                        let recordsPredicate = NSPredicate(format: "uuid in %@", UUIDs)
                        let recordsRequest = NSFetchRequest(entityName: "Record")
                        recordsRequest.predicate = recordsPredicate
                        
                        do {
                            let records = try self.managedObjectContext.executeFetchRequest(recordsRequest) as! [PKRecord]
                            folder.records = Set(records)
                        } catch {
                            // что-то делаем в зависимости от ошибки
                        }
                    } else {
                        let predicate = NSPredicate(format: "uuid == %@", recordID!.recordName)
                        let fetchRequest = NSFetchRequest(entityName: "Record")
                        fetchRequest.predicate = predicate
                        
                        var record: PKRecord!
                        do {
                            let records = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [PKRecord]
                            record = records.first!
                        } catch {
                            // что-то делаем в зависимости от ошибки
                        }
                        
                        record.title = (ckQueryNotification.recordFields!["title"] as! String)
                        record.login = (ckQueryNotification.recordFields!["login"] as! String)
                        record.password = (ckQueryNotification.recordFields!["password"] as! NSData)
                        record.detailedDescription = (ckQueryNotification.recordFields!["detailedDescription"] as! String)
                        record.creationDate = (ckQueryNotification.recordFields!["createdDT"] as! NSDate)
                        record.date = (ckQueryNotification.recordFields!["date"] as! NSDate)
                        
                        let uuid = (ckQueryNotification.recordFields!["folder"] as! CKReference).recordID.recordName
                        let foldersPredicate = NSPredicate(format: "uuid == %@", uuid)
                        let foldersRequest = NSFetchRequest(entityName: "Folder")
                        foldersRequest.predicate = foldersPredicate
                        
                        do {
                            let folders = try self.managedObjectContext.executeFetchRequest(foldersRequest) as! [PKFolder]
                            record.folder = folders.first!
                        } catch {
                            // что-то делаем в зависимости от ошибки
                        }
                    }
                case .RecordDeleted:
                    if ckQueryNotification.recordFields!["name"] != nil {
                        let predicate = NSPredicate(format: "uuid == %@", recordID!.recordName)
                        let fetchRequest = NSFetchRequest(entityName: "Folder")
                        fetchRequest.predicate = predicate
                        
                        var folder: PKFolder!
                        do {
                            let folders = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [PKFolder]
                            folder = folders.first!
                        } catch {
                            // что-то делаем в зависимости от ошибки
                        }
                        
                        self.managedObjectContext.deleteObject(folder)
                           
                    } else {
                        let predicate = NSPredicate(format: "uuid == %@", recordID!.recordName)
                        let fetchRequest = NSFetchRequest(entityName: "Record")
                        fetchRequest.predicate = predicate
                        
                        var record: PKRecord!
                        do {
                            let records = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [PKRecord]
                            record = records.first!
                        } catch {
                            // что-то делаем в зависимости от ошибки
                        }
                        
                        self.managedObjectContext.deleteObject(record)
                    }
                }
                
                PKCoreDataManager.sharedManager.saveContext()
                
                //update local db
                //refresh UI if needed
            }
        }
    }
}

