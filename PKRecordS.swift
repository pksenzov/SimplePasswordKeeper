//
//  PKRecordS.swift
//  Records
//
//  Created by Admin on 20/07/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import Foundation
import CloudKit

struct PKRecordS {
    let uuid: String
    let creationDate: NSDate
    let date: NSDate
    let detailedDescription: String?
    let login: String?
    let password: NSObject?
    let title: String
    let folderUUID: String
    
    init(record: PKRecord) {
        uuid = record.uuid!
        creationDate = record.creationDate!
        date = record.date!
        detailedDescription = record.detailedDescription
        login = record.login
        password = record.password
        title = record.title!
        folderUUID = record.folder!.uuid!
    }
    
    init(record: CKRecord) {
        uuid = record.recordID.recordName
        creationDate = record.objectForKey("creationDate") as! NSDate
        date = record.objectForKey("date") as! NSDate
        detailedDescription = record.objectForKey("detailedDescription") as? String
        login = record.objectForKey("login") as? String
        password = record.objectForKey("password") as? NSData
        title = record.objectForKey("title") as! String
        folderUUID = (record.objectForKey("folder") as! CKReference).recordID.recordName
    }
}

