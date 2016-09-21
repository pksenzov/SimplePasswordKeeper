//
//  PKRecordS.swift
//  Records
//
//  Created by Admin on 20/07/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import Foundation
import CloudKit

struct PKRecordS: PKObjectS {
    let uuid: String
    let creationDate: Date
    let date: Date
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
        uuid                = record.recordID.recordName
        creationDate        = record["creationDate"] as! Date
        date                = record["date"] as! Date
        detailedDescription = record["detailedDescription"] as? String
        login               = record["login"] as? String
        password            = record["password"] as? Data as NSObject?
        title               = record["title"] as! String
        folderUUID          = (record["folder"] as! CKReference).recordID.recordName
    }
}

