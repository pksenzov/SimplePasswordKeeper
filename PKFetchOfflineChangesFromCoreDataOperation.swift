//
//  PKFetchOfflineChangesFromCoreDataOperation.swift
//  Records
//
//  Created by Admin on 07/07/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import CoreData
import CloudKit

class PKFetchOfflineChangesFromCoreDataOperation: NSOperation {
    var updatedManagedObjects: [NSManagedObjectID]
    var deletedRecordIDs: [CKRecordID]
    
    private let coreDataManager = PKCoreDataManager.sharedManager
    private let cloudKitManager = PKCloudKitManager.sharedManager
    private let entityNames: [String]
    
    init(entityNames: [String]) {
        self.entityNames = entityNames
        
        self.updatedManagedObjects = []
        self.deletedRecordIDs = []
        
        super.init()
    }
    
    override func main() {
        print("FetchOfflineChangesFromCoreDataOperation.main()")
        
        let managedObjectContext = self.coreDataManager.createBackgroundManagedContext()
        
        managedObjectContext.performBlockAndWait {
            [unowned self] in
            
            guard let lastCloudKitSyncTimestamp = NSUserDefaults.standardUserDefaults().objectForKey(kSettingsLastCloudKitSyncTimestamp) as? NSDate else { return }
            
            for entityName in self.entityNames {
                self.fetchOfflineChangesForEntityName(entityName, lastCloudKitSyncTimestamp: lastCloudKitSyncTimestamp, managedObjectContext: managedObjectContext)
            }
            
            self.deletedRecordIDs = self.fetchDeletedRecordIDs(managedObjectContext)
        }
    }
    
    func fetchOfflineChangesForEntityName(entityName: String, lastCloudKitSyncTimestamp: NSDate, managedObjectContext: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "lastUpdate > %@", lastCloudKitSyncTimestamp)
        
        do {
            let fetchResults = try managedObjectContext.executeFetchRequest(fetchRequest)
            let managedObjectIDs = fetchResults.flatMap() { ($0 as? NSManagedObject)?.objectID  }
            
            updatedManagedObjects.appendContentsOf(managedObjectIDs)
        }
        catch let error as NSError {
            print("Error fetching from CoreData: \(error.localizedDescription)")
        }
    }
    
    func fetchDeletedRecordIDs(managedObjectContext: NSManagedObjectContext) -> [CKRecordID] {
        let fetchRequest = NSFetchRequest(entityName: ModelObjectType.DeletedCloudKitObject.rawValue)
        
        do {
            let fetchResults = try managedObjectContext.executeFetchRequest(fetchRequest)
            return fetchResults.flatMap() { ($0 as? PKDeletedCloudKitObject)?.cloudKitRecordID()  }
        }
        catch let error as NSError {
            print("Error fetching from CoreData: \(error.localizedDescription)")
        }
        
        return []
    }
}
