//
//  DemoCell.swift
//  SimplePasswordKeeper
//
//  Created by Admin on 04/03/16.
//  Copyright © 2016 pksenzov. All rights reserved.
//

import UIKit
import FoldingCell

class PKFolderCell: FoldingCell {
    @IBOutlet weak var folderNameLabel: UILabel!
    @IBOutlet weak var recordsCountLabel: UILabel!
    @IBOutlet weak var openedFolderNameLabel: UILabel!
    @IBOutlet weak var openedRecordsCountLabel: UILabel!
    
    override func awakeFromNib() {
        foregroundView.layer.cornerRadius = 10
        foregroundView.layer.masksToBounds = true
        
        super.awakeFromNib()
    }
    
    override func animationDuration(itemIndex:NSInteger, type:AnimationType)-> NSTimeInterval {
        
        let durations = [0.26, 0.2]
        return durations[itemIndex]
    }

}
