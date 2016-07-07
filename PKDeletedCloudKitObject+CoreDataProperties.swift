//
//  PKDeletedCloudKitObject+CoreDataProperties.swift
//  Records
//
//  Created by Admin on 07/07/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import Foundation

extension PKDeletedCloudKitObject {
    
    @NSManaged var recordType: String?
    @NSManaged var recordID: NSData?
    
}