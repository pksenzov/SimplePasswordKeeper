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
    static let applicationDidTimeout        = #selector(PKAppDelegate.applicationDidTimeout)
    static let applicationDidTimeoutClear   = #selector(PKAppDelegate.applicationDidTimeoutClear)
    static let pasteboardChanged            = #selector(PKAppDelegate.pasteboardChanged(_:))
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
    
    let app = UIApplication.shared as? PKTimerApplication
    
    // MARK: - My Functions
    
    func cancelTimerIfBackgrounded() {
        if UIApplication.shared.applicationState == .background {
            self.app?.cancelClearTimer()
            
            isNeededClearTimerRestart = true
        }
    }
    
    // MARK: - iCloud
    
    static func iCloudAccountIsSignedIn() -> Bool {
        let token = FileManager.default.ubiquityIdentityToken
        guard token != nil else { return false }
        
        return true
    }
    
    // MARK: - Notifications
    
    func applicationDidTimeout() {
        if UIApplication.shared.applicationState == .active {
            PKServerManager.sharedManager.authorizeUser()
        } else {
            isNeededAuthorization = true
        }
    }
    
    func applicationDidTimeoutClear() {
        UIPasteboard.general.string = ""
        self.cancelTimerIfBackgrounded()
    }
    
    func pasteboardChanged(_ notification: Notification) {
        let seconds = UserDefaults.standard.integer(forKey: kSettingsClearClipboard)
        guard seconds != 0 else { return }
        
        self.app?.resetClearIdleTimer()
        self.cancelTimerIfBackgrounded()
    }
    
    // MARK: - Application Lifecycle
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let isSigned = PKAppDelegate.iCloudAccountIsSignedIn()
        
        UserDefaults.standard.register(defaults: [kSettingsLockOnExit                 : true,
                                                  kSettingsSpotlight                  : true,
                                                  kSettingsSubscriptions              : false,
                                                  kSettingsICloud                     : isSigned,
                                                  kSettingsAutoLock                   : 15,
                                                  kSettingsClearClipboard             : 0])
        
        let isSynced = UserDefaults.standard.bool(forKey: kSettingsICloud)
        
        NotificationCenter.default.addObserver(self, selector: .applicationDidTimeout, name: NSNotification.Name(rawValue: kApplicationDidTimeoutNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: .applicationDidTimeoutClear, name: NSNotification.Name(rawValue: kApplicationDidTimeoutClearNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: .pasteboardChanged, name: NSNotification.Name.UIPasteboardChanged, object: nil)
        
        if isSigned && isSynced {
            PKServerManager.sharedManager.sync()
        }
        
        application.registerForRemoteNotifications()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        print("APPLICATION DELEGATE - applicationWillResignActive")
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        isLocked = UserDefaults.standard.bool(forKey: kSettingsLockOnExit)
        var topVC = PKServerManager.getTopViewController()
        
        if topVC is UIAlertController {
            topVC?.dismiss(animated: false, completion: nil)
            topVC = PKServerManager.getTopViewController()
        }
        
        let seconds = UserDefaults.standard.integer(forKey: kSettingsClearClipboard)
        if seconds != 0 { UIPasteboard.general.string = "" }
        
        if isLocked && !(topVC is PKLoginViewController) {
            PKServerManager.sharedManager.authorizeUser()
            return
        } else if isLocked && topVC is PKLoginViewController {
            (topVC as! PKLoginViewController).isRepeatAlert = true
            return
        } else if !(topVC is PKLoginViewController) {
            ((topVC as? UINavigationController)?.topViewController as? PKRecordEditingViewController)?.saveData()
            
            let blankVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PKBlankViewController")
            topVC?.present(blankVC, animated: false, completion: nil)
            
            
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

    func applicationWillEnterForeground(_ application: UIApplication) {
        if PKAppDelegate.iCloudAccountIsSignedIn() && UserDefaults.standard.bool(forKey: kSettingsICloud) {
            PKServerManager.sharedManager.sync()
        }
        
        print("APPLICATION DELEGATE - applicationWillEnterForeground")
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        if isNeededAuthorization {
            isNeededAuthorization = false
            PKServerManager.sharedManager.authorizeUser()
        }
        
        if isNeededClearTimerRestart {
            isNeededClearTimerRestart = false
            self.app?.resetClearIdleTimer()
        }
        
        print("APPLICATION DELEGATE - applicationDidBecomeActive")
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("APPLICATION DELEGATE - applicationWillTerminate")
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        NotificationCenter.default.removeObserver(self)
        isLocked = UserDefaults.standard.bool(forKey: kSettingsLockOnExit)
        PKCoreDataManager.sharedManager.saveContext()
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        print("APPLICATION DELEGATE - continueUserActivity")
        
        if userActivity.activityType == CSSearchableItemActionType {
            let uniqueIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String
            
            let mainVC = UIApplication.shared.windows.first?.rootViewController as! UINavigationController
            let recordsVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PKRecordsTableViewController") as! PKRecordsTableViewController
            let recordEditingVc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PKRecordEditingViewController") as! PKRecordEditingViewController
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Record")
            var mainRecord: PKRecord?
            
            do {
                let records = try self.managedObjectContext.fetch(fetchRequest) as! [PKRecord]
                
                loop: for record in records {
                    if String(describing: record.objectID) == uniqueIdentifier {
                        mainRecord = record
                        break loop
                    }
                }
                
                guard mainRecord != nil else {
                    mainVC.popToRootViewController(animated: true)
                    
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
                mainVC.dismiss(animated: true, completion: nil)
            }
            
            mainVC.popToRootViewController(animated: true)
            
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
    
    // MARK: - Remote Notifications
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                                                  fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        let userInfo = userInfo as! [String: NSObject]
        let cloudKitNotification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        
        if (cloudKitNotification.notificationType == .query) {
            //PKCloudKitManager.sharedManager.fetchSharedChanges { completionHandler(UIBackgroundFetchResult.NewData) }
            
            let ckQueryNotification = cloudKitNotification as! CKQueryNotification
            let recordID = ckQueryNotification.recordID
            
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async {
                let isFolder = ckQueryNotification.recordFields != nil
                PKCloudKitManager.sharedManager.updateCoreData(recordID!, reason: ckQueryNotification.queryNotificationReason, isFolder: isFolder)
            }
        }
    }
    
//    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject: AnyObject]) {
//        guard PKAppDelegate.iCloudAccountIsSignedIn() && NSUserDefaults.standardUserDefaults().boolForKey(kSettingsICloud) else { return }
//        
//        if let userInfo = userInfo as? [String: NSObject] {
//            let cloudKitNotification = CKNotification(fromRemoteNotificationDictionary: userInfo)
//            
//            if (cloudKitNotification.notificationType == .Query) {
//                let ckQueryNotification = cloudKitNotification as! CKQueryNotification
//                let recordID = ckQueryNotification.recordID
//                
//                dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
//                    let isFolder = ckQueryNotification.recordFields != nil
//                    PKCloudKitManager.sharedManager.updateCoreData(recordID!, reason: ckQueryNotification.queryNotificationReason, isFolder: isFolder)
//                }
//            }
//        }
//    }
    
//    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
//        print(error.localizedDescription)
//        abort()
//    }
}

