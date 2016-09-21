//
//  PKClearClipboardTableViewController.swift
//  Records
//
//  Created by Admin on 12/09/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import UIKit

class PKClearClipboardTableViewController: UITableViewController, UIToolbarDelegate {
    var seconds: Int!
    let rowIndexes = [10:0, 30:1, 45:2, 60:3, 0:4]
    
    @IBOutlet weak var upperToolbar: UIToolbar!
    
    @IBOutlet weak var clearClipboardLabel: UILabel! {
        didSet {
            clearClipboardLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        }
    }
    
    // MARK: - UIToolbarDelegate
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
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
        self.tableView.cellForRow(at: IndexPath(row: self.rowIndexes[self.seconds]!, section: 0))?.accessoryType = .checkmark
    }
    
    // MARK: - Actions
    
    @IBAction func cancelAction(_ sender: UIBarButtonItem) { self.dismiss(animated: true, completion: nil) }
    
    // MARK: - Table View
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let seconds = self.rowIndexes.filter() {
            $0.1 == (indexPath as NSIndexPath).row
            }.first!.0
        
        UserDefaults.standard.set(seconds, forKey: kSettingsClearClipboard)
        
        let app = UIApplication.shared as? PKTimerApplication
        app?.resetClearIdleTimer()
        
        tableView.cellForRow(at: IndexPath(row: self.rowIndexes[self.seconds]!, section: 0))?.accessoryType = .none
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        
        self.dismiss(animated: true, completion: nil)
    }

}
