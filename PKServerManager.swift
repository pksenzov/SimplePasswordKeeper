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
        var topVC = UIApplication.shared.windows.first?.rootViewController
        
        while (topVC?.presentedViewController != nil) {
            topVC = topVC?.presentedViewController;
        }
        
        return topVC
    }
    
    // MARK: - Authorization
    
    func presentLoginViewControllerOn(_ topVC: UIViewController?) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PKLoginViewController") as! PKLoginViewController
        
        guard !(topVC is PKLoginViewController) else { return }
        
        vc.delegate = (topVC as? UINavigationController)?.topViewController as? PKFoldersTableViewController
        ((topVC as? UINavigationController)?.topViewController as? PKRecordEditingViewController)?.saveData()
        
        UIApplication.shared.sendAction(#selector(UIApplication.shared.resignFirstResponder), to: nil, from: nil, for: nil)
        topVC?.present(vc, animated: false, completion: nil)
    }
    
    func authorizeUser() {
        var topVC = PKServerManager.getTopViewController()
        
        if topVC is UIAlertController {
            topVC?.dismiss(animated: false) {
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
        
//        let application = UIApplication.sharedApplication()
//        application.beginIgnoringInteractionEvents()
//        //show UI loading icon if needed
//        
//        let coreDataFolders = PKCoreDataManager.sharedManager.getFolders()
//        let coreDataRecords = PKCoreDataManager.sharedManager.getRecords()
//        let coreDataDeletedObjects = PKCoreDataManager.sharedManager.getDeletedObjects()
//        
//        let coreDataFolderUUIDS = Set(coreDataFolders.map() { $0.uuid! })
//        let coreDataRecordUUIDS = Set(coreDataRecords.map() { $0.uuid! })
//        let coreDataDeletedObjectUUIDS = Set(coreDataDeletedObjects.map() { $0.uuid! })
//        
//        let cloudKitFolders = PKCloudKitManager.sharedManager.getFolders()
//        let cloudKitRecords = PKCloudKitManager.sharedManager.getRecords()
//        let cloudKitDeletedObjects = PKCloudKitManager.sharedManager.getDeletedObjects()
//        
//        let cloudKitFolderUUIDS = Set(cloudKitFolders.map() { $0.recordID.recordName })
//        let cloudKitRecordUUIDS = Set(cloudKitRecords.map() { $0.recordID.recordName })
//        let cloudKitDeletedObjectUUIDS = Set(cloudKitDeletedObjects.map() { $0.objectForKey("uuid") as! String })
//        
//        let deletedObjectUUIDS = coreDataDeletedObjectUUIDS.intersect(cloudKitDeletedObjectUUIDS)
//        let toDelete = [PKDeletedObject]()
//        deletedObjectUUIDS.forEach() { uuid in
//            let deletedObject = coreDataDeletedObjects.filter() { $0.uuid == uuid }
//        }
//        
//        PKCoreDataManager.sharedManager.removeDeletedObjects()//[PKDeletedObject]
//        PKCloudKitManager.sharedManager.removeDeletedObjects(deletedObjectUUIDS)
//        
//        
//        
//        application.endIgnoringInteractionEvents()
    }
    
    // MARK: - Notification Update UI
    
    func popIfNeeded(_ object: AnyObject) {
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
    
    func holdAndPop(_ navVC: UINavigationController) {
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        DispatchQueue.main.async {
            navVC.popViewController(animated: true)
        }
    }
    
    func holdAndPopToRoot(_ navVC: UINavigationController) {
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        DispatchQueue.main.async {
            navVC.popToRootViewController(animated: true)
        }
    }
    
    func holdAndDismiss(_ navVC: UINavigationController) {
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        DispatchQueue.main.async {
            navVC.dismiss(animated: true, completion: nil)
        }
    }
    
    func holdAndDismissAndPop(_ navVC: UINavigationController) {
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        DispatchQueue.main.async {
            navVC.dismiss(animated: true, completion: nil)
            navVC.popViewController(animated: true)
        }
    }
}
