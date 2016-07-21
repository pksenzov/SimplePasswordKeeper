//
//  PKFolderS.swift
//  Records
//
//  Created by Admin on 20/07/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import Foundation

struct PKFolderS {
    let uuid: String
    let date: NSDate
    let name: String
    var recordsUUID = Set<String>()
    
    init(folder: PKFolder) {
        uuid = folder.uuid!
        date = folder.date!
        name = folder.name!
        
        folder.records?.forEach() {
            recordsUUID.insert(($0 as! PKRecord).uuid!)
        }
    }
}