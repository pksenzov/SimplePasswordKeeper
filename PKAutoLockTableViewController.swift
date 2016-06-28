//
//  PKAutoLockTableViewController.swift
//  SimplePasswordKeeper
//
//  Created by Admin on 25/05/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import UIKit

class PKAutoLockTableViewController: UITableViewController {
    var minutes: Int?
    
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
        
        //USE DICIONARY
        if let minutes = self.minutes {
            switch minutes {
            case 1:
                self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0))?.accessoryType = .Checkmark
            case 2:
                self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0))?.accessoryType = .Checkmark
            case 5:
                self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0))?.accessoryType = .Checkmark
            case 10:
                self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 3, inSection: 0))?.accessoryType = .Checkmark
            case 15:
                self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 4, inSection: 0))?.accessoryType = .Checkmark
            case 30:
                self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 5, inSection: 0))?.accessoryType = .Checkmark
            case 60:
                self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 6, inSection: 0))?.accessoryType = .Checkmark
            default:
                return
            }
        }
    }

    // MARK: - Table View 
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
}
