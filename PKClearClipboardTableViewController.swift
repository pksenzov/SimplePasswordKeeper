//
//  PKClearClipboardTableViewController.swift
//  Records
//
//  Created by Admin on 12/09/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import UIKit

class PKClearClipboardTableViewController: UITableViewController {
    var seconds: Int!
    let rowIndexes = [10:0, 30:1, 45:2, 60:3, 0:4]
    
    @IBOutlet weak var upperToolbar: UIToolbar!
    
    @IBOutlet weak var clearClipboardLabel: UILabel! {
        didSet {
            clearClipboardLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        }
    }
    
    // MARK: - Views
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.contentInset = UIEdgeInsets(top: 20.0, left: 0, bottom: 20.0, right: 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.upperToolbar.clipsToBounds = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: self.rowIndexes[self.seconds]!, inSection: 0))?.accessoryType = .Checkmark
    }
    
    // MARK: - Actions
    
    @IBAction func cancelAction(sender: UIBarButtonItem) { self.dismissViewControllerAnimated(true, completion: nil) }
    
    // MARK: - Table View
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let seconds = self.rowIndexes.filter() {
            $0.1 == indexPath.row
            }.first!.0
        
        NSUserDefaults.standardUserDefaults().setInteger(seconds, forKey: kSettingsClearClipboard)
        
        let app = UIApplication.sharedApplication() as? PKTimerApplication
        app?.resetClearIdleTimer()
        
        tableView.cellForRowAtIndexPath(NSIndexPath(forRow: self.rowIndexes[self.seconds]!, inSection: 0))?.accessoryType = .None
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = .Checkmark
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}
