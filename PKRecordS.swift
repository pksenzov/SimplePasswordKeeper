//
//  PKRecordS.swift
//  Records
//
//  Created by Admin on 20/07/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import Foundation

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
}

//// MARK: - Hashable
//
//extension PKRecordS: Hashable {
//    var hashValue: Int { return 0 }
//}
//
//// MARK: - Equatable
//
//func ==(lhs: PKRecordS, rhs: PKRecordS) -> Bool {
//    return lhs.uuid == rhs.uuid
//}

