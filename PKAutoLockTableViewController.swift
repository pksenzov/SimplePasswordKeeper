//
//  PKAutoLockTableViewController.swift
//  SimplePasswordKeeper
//
//  Created by Admin on 25/05/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import UIKit

class PKAutoLockTableViewController: UITableViewController {
    var minutes: Int!
    let rowIndexes = [1:0, 2:1, 5:2, 10:3, 15:4, 30:5, 60:6]
    
    @IBOutlet weak var upperToolbar: UIToolbar!
    
    @IBOutlet weak var autoLockLabel: UILabel! {
        didSet {
            autoLockLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func cancelAction(sender: UIBarButtonItem) { self.dismissViewControllerAnimated(true, completion: nil) }
    
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
        self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: self.rowIndexes[self.minutes]!, inSection: 0))?.accessoryType = .Checkmark
    }

    // MARK: - Table View 
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let minutes = self.rowIndexes.filter() {
            $0.1 == indexPath.row
        }.first!.0
        
        NSUserDefaults.standardUserDefaults().setInteger(minutes, forKey: kSettingsAutoLock)
        
        let app = UIApplication.sharedApplication() as? PKTimerApplication
        app?.resetIdleTimer()
        
        tableView.cellForRowAtIndexPath(NSIndexPath(forRow: self.rowIndexes[self.minutes]!, inSection: 0))?.accessoryType = .None
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = .Checkmark
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
