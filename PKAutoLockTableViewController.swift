//
//  PKAutoLockTableViewController.swift
//  SimplePasswordKeeper
//
//  Created by Admin on 25/05/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import UIKit

class PKAutoLockTableViewController: UITableViewController, UIToolbarDelegate {
    var minutes: Int!
    let rowIndexes = [1:0, 2:1, 5:2, 10:3, 15:4, 30:5, 60:6]
    
    @IBOutlet weak var upperToolbar: UIToolbar!
    
    @IBOutlet weak var autoLockLabel: UILabel! {
        didSet {
            autoLockLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        }
    }
    
    // MARK: - UIToolbarDelegate
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
    // MARK: - Actions
    
    @IBAction func cancelAction(_ sender: UIBarButtonItem) { self.dismiss(animated: true, completion: nil) }
    
    // MARK: - Views
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.contentInset = UIEdgeInsets(top: 20.0, left: 0, bottom: 20.0, right: 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.upperToolbar.clipsToBounds = true
        self.upperToolbar.delegate = self
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.cellForRow(at: IndexPath(row: self.rowIndexes[self.minutes]!, section: 0))?.accessoryType = .checkmark
    }

    // MARK: - Table View 
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let minutes = self.rowIndexes.filter() {
            $0.1 == (indexPath as NSIndexPath).row
        }.first!.0
        
        UserDefaults.standard.set(minutes, forKey: kSettingsAutoLock)
        
        let app = UIApplication.shared as? PKTimerApplication
        app?.resetIdleTimer()
        
        tableView.cellForRow(at: IndexPath(row: self.rowIndexes[self.minutes]!, section: 0))?.accessoryType = .none
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        
        self.dismiss(animated: true, completion: nil)
    }
}
