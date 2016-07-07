//
//  PKCloudKitManager.swift
//  Records
//
//  Created by Admin on 07/07/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import CloudKit

class PKCloudKitManager {
    static let sharedManager = PKCloudKitManager()
    
    // MARK: - My Functions
    
    func performFullSync() {
        self.queueFullSyncOperations()
    }
    
    private func queueFullSyncOperations() {
        // 1. Fetch all the changes both locally and from each zone
        let fetchOfflineChangesFromCoreDataOperation = PKFetchOfflineChangesFromCoreDataOperation(entityNames: ModelObjectType.allCloudKitModelObjectTypes)
        let fetchFolderZoneChangesOperation = PKFetchRecordChangesForCloudKitZoneOperation(cloudKitZone: CloudKitZone.FolderZone)
        let fetchRecordZoneChangesOperation = PKFetchRecordChangesForCloudKitZoneOperation(cloudKitZone: CloudKitZone.RecordZone)
        
        // 2. Process the changes after transfering
        let processSyncChangesOperation = PKProcessSyncChangesOperation()
        let transferDataToProcessSyncChangesOperation = NSBlockOperation {
            [unowned processSyncChangesOperation, unowned fetchOfflineChangesFromCoreDataOperation, unowned fetchFolderZoneChangesOperation, unowned fetchRecordZoneChangesOperation, unowned fetchBusZoneChangesOperation] in
            
            processSyncChangesOperation.preProcessLocalChangedObjectIDs.appendContentsOf(fetchOfflineChangesFromCoreDataOperation.updatedManagedObjects)
            processSyncChangesOperation.preProcessLocalDeletedRecordIDs.appendContentsOf(fetchOfflineChangesFromCoreDataOperation.deletedRecordIDs)
            
            processSyncChangesOperation.preProcessServerChangedRecords.appendContentsOf(fetchFolderZoneChangesOperation.changedRecords)
            processSyncChangesOperation.preProcessServerChangedRecords.appendContentsOf(fetchRecordZoneChangesOperation.changedRecords)
            
            processSyncChangesOperation.preProcessServerDeletedRecordIDs.appendContentsOf(fetchFolderZoneChangesOperation.deletedRecordIDs)
            processSyncChangesOperation.preProcessServerDeletedRecordIDs.appendContentsOf(fetchRecordZoneChangesOperation.deletedRecordIDs)
        }
        
        // 3. Fetch records from the server that we need to change
        let fetchRecordsForModifiedObjectsOperation = FetchRecordsForModifiedObjectsOperation(coreDataManager: coreDataManager)
        let transferDataToFetchRecordsOperation = NSBlockOperation {
            [unowned fetchRecordsForModifiedObjectsOperation, unowned processSyncChangesOperation] in
            
            fetchRecordsForModifiedObjectsOperation.preFetchModifiedRecords = processSyncChangesOperation.postProcessChangesToServer
        }
        
        // 4. Modify records in the cloud
        let modifyRecordsFromManagedObjectsOperation = ModifyRecordsFromManagedObjectsOperation(coreDataManager: coreDataManager, cloudKitManager: self)
        let transferDataToModifyRecordsOperation = NSBlockOperation {
            [unowned fetchRecordsForModifiedObjectsOperation, unowned modifyRecordsFromManagedObjectsOperation, unowned processSyncChangesOperation] in
            
            if let fetchedRecordsDictionary = fetchRecordsForModifiedObjectsOperation.fetchedRecords {
                modifyRecordsFromManagedObjectsOperation.fetchedRecordsToModify = fetchedRecordsDictionary
            }
            modifyRecordsFromManagedObjectsOperation.preModifiedRecords = processSyncChangesOperation.postProcessChangesToServer
            
            // also set the recordIDsToDelete from what we processed
            modifyRecordsFromManagedObjectsOperation.recordIDsToDelete = processSyncChangesOperation.postProcessDeletesToServer
        }
        
        // 5. Modify records locally
        let saveChangedRecordsToCoreDataOperation = SaveChangedRecordsToCoreDataOperation(coreDataManager: coreDataManager)
        let transferDataToSaveChangesToCoreDataOperation = NSBlockOperation {
            [unowned saveChangedRecordsToCoreDataOperation, unowned processSyncChangesOperation] in
            
            saveChangedRecordsToCoreDataOperation.changedRecords = processSyncChangesOperation.postProcessChangesToCoreData
            saveChangedRecordsToCoreDataOperation.deletedRecordIDs = processSyncChangesOperation.postProcessDeletesToCoreData
        }
        
        // 6. Delete all of the DeletedCloudKitObjects
        let clearDeletedCloudKitObjectsOperation = ClearDeletedCloudKitObjectsOperation(coreDataManager: coreDataManager)
        
        // set dependencies
        // 1. transfering all the fetched data to process for conflicts
        transferDataToProcessSyncChangesOperation.addDependency(fetchOfflineChangesFromCoreDataOperation)
        transferDataToProcessSyncChangesOperation.addDependency(fetchFolderZoneChangesOperation)
        transferDataToProcessSyncChangesOperation.addDependency(fetchRecordZoneChangesOperation)
        
        // 2. processing the data onces its transferred
        processSyncChangesOperation.addDependency(transferDataToProcessSyncChangesOperation)
        
        // 3. fetching records changed local
        transferDataToFetchRecordsOperation.addDependency(processSyncChangesOperation)
        fetchRecordsForModifiedObjectsOperation.addDependency(transferDataToFetchRecordsOperation)
        
        // 4. modifying records in CloudKit
        transferDataToModifyRecordsOperation.addDependency(fetchRecordsForModifiedObjectsOperation)
        modifyRecordsFromManagedObjectsOperation.addDependency(transferDataToModifyRecordsOperation)
        
        // 5. modifying records in CoreData
        transferDataToSaveChangesToCoreDataOperation.addDependency(processSyncChangesOperation)
        saveChangedRecordsToCoreDataOperation.addDependency(transferDataToModifyRecordsOperation)
        
        // 6. clear the deleteCloudKitObjects
        clearDeletedCloudKitObjectsOperation.addDependency(saveChangedRecordsToCoreDataOperation)
        
        // add operations to the queue
        operationQueue.addOperation(fetchOfflineChangesFromCoreDataOperation)
        operationQueue.addOperation(fetchFolderZoneChangesOperation)
        operationQueue.addOperation(fetchRecordZoneChangesOperation)
        operationQueue.addOperation(transferDataToProcessSyncChangesOperation)
        operationQueue.addOperation(processSyncChangesOperation)
        operationQueue.addOperation(transferDataToFetchRecordsOperation)
        operationQueue.addOperation(fetchRecordsForModifiedObjectsOperation)
        operationQueue.addOperation(transferDataToModifyRecordsOperation)
        operationQueue.addOperation(modifyRecordsFromManagedObjectsOperation)
        operationQueue.addOperation(transferDataToSaveChangesToCoreDataOperation)
        operationQueue.addOperation(saveChangedRecordsToCoreDataOperation)
        operationQueue.addOperation(clearDeletedCloudKitObjectsOperation)
    }
}
