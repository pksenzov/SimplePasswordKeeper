//
//  PKSettingsTableViewController.swift
//  SimplePasswordKeeper
//
//  Created by Admin on 24/05/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import UIKit
import CoreSpotlight
import CoreData

class PKSettingsTableViewController: UITableViewController {
    let defaults = UserDefaults.standard
    var autoLockTime: Int!
    var clearClipboardTime: Int!
    
    var managedObjectContext: NSManagedObjectContext {
        if _managedObjectContext == nil {
            _managedObjectContext = PKCoreDataManager.sharedManager.managedObjectContext
        }
        
        return _managedObjectContext!
    }
    var _managedObjectContext: NSManagedObjectContext? = nil
    
    @IBOutlet weak var upperToolbar: UIToolbar!
    @IBOutlet weak var iCloudSwitch: UISwitch!
    @IBOutlet weak var spotlightSwitch: UISwitch!
    @IBOutlet weak var lockOnExitSwitch: UISwitch!
    @IBOutlet weak var autoLockLabel: UILabel!
    @IBOutlet weak var clearClipboardLabel: UILabel!
    
    @IBOutlet weak var settingsLabel: UILabel! {
        didSet {
            settingsLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        }
    }
    
    // MARK: - My Functions
    
    func updateSpotlight() {
        var backgroundTask = UIBackgroundTaskInvalid
        let application = UIApplication.shared
        
        backgroundTask = application.beginBackgroundTask(withName: "SpotlightTask") {
            application.endBackgroundTask(backgroundTask)
            backgroundTask = UIBackgroundTaskInvalid
        }
        
        DispatchQueue.global().async {
            CSSearchableIndex.default().deleteAllSearchableItems() { error in
                if error != nil {
                    print(error?.localizedDescription)
                    
                    application.endBackgroundTask(backgroundTask)
                    backgroundTask = UIBackgroundTaskInvalid
                } else if self.spotlightSwitch.isOn {
                    print("!!! - Items Indexes Deleted")
                    
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Record")
                    
                    do {
                        var items = [CSSearchableItem]()
                        let records = try self.managedObjectContext.fetch(fetchRequest) as! [PKRecord]
                        
                        records.forEach() {
                            let attributeSet = CSSearchableItemAttributeSet(itemContentType: kContentType)
                            attributeSet.title = $0.title
                            attributeSet.contentDescription = "Secure Record"
                            attributeSet.keywords = [$0.title!]
                            
                            let item = CSSearchableItem(uniqueIdentifier: String(describing: $0.objectID), domainIdentifier: nil, attributeSet: attributeSet)
                            item.expirationDate = Date.distantFuture
                            items.append(item)
                        }
                        
                        CSSearchableIndex.default().indexSearchableItems(items) { error in
                            if error != nil {
                                print(error?.localizedDescription)
                            } else {
                                print("!!! - All Items Indexed")
                            }
                            
                            application.endBackgroundTask(backgroundTask)
                            backgroundTask = UIBackgroundTaskInvalid
                        }
                    } catch {
                        print("Unresolved error \(error), \(error)")
                        
                        application.endBackgroundTask(backgroundTask)
                        backgroundTask = UIBackgroundTaskInvalid
                    }
                } else {
                    application.endBackgroundTask(backgroundTask)
                    backgroundTask = UIBackgroundTaskInvalid
                }
            }
        }
    }
    
    // MARK: - Load
    
    func loadSettings() {
        if PKAppDelegate.iCloudAccountIsSignedIn() && self.defaults.bool(forKey: kSettingsICloud) {
            self.iCloudSwitch.isOn = true
        } else if !self.defaults.bool(forKey: kSettingsICloud) {
            self.iCloudSwitch.isOn = false
        } else if !PKAppDelegate.iCloudAccountIsSignedIn() {
            self.iCloudSwitch.isOn = false
            self.defaults.set(false, forKey: kSettingsICloud)
            //PKCloudKitManager.sharedManager.deleteSubscriptions()
        }
        
        self.lockOnExitSwitch.isOn      = self.defaults.bool(forKey: kSettingsLockOnExit)
        self.spotlightSwitch.isOn       = self.defaults.bool(forKey: kSettingsSpotlight)
        self.autoLockTime               = self.defaults.integer(forKey: kSettingsAutoLock)
        self.clearClipboardTime         = self.defaults.integer(forKey: kSettingsClearClipboard)
        
        switch self.autoLockTime {
        case 1:
            self.autoLockLabel.text = "1 minute"
        case 60:
            self.autoLockLabel.text = "1 hour"
        default:
            self.autoLockLabel.text = "\(self.autoLockTime!) minutes"
        }
        
        switch self.clearClipboardTime {
        case 0:
            self.clearClipboardLabel.text = "Never"
        default:
            self.clearClipboardLabel.text = "\(self.clearClipboardTime!) seconds"
        }
    }
    
    // MARK: - Actions
    
    @IBAction func iCloudValueChanged(_ sender: UISwitch)     {
        if !sender.isOn {
            self.defaults.set(false, forKey: kSettingsICloud)
            //PKCloudKitManager.sharedManager.deleteSubscriptions()
        } else if PKAppDelegate.iCloudAccountIsSignedIn() {
            PKServerManager.sharedManager.sync()
            self.defaults.set(true, forKey: kSettingsICloud)
        } else if !PKAppDelegate.iCloudAccountIsSignedIn() {
            //show alert
        }
        
    }
    
    @IBAction func lockOnExitValueChanged(_ sender: UISwitch) { self.defaults.set(sender.isOn, forKey: kSettingsLockOnExit) }
    @IBAction func spotlightValueChanged(_ sender: UISwitch)  { self.defaults.set(sender.isOn, forKey: kSettingsSpotlight)  }
    @IBAction func closeAction(_ sender: UIBarButtonItem)     { self.dismiss(animated: true, completion: nil)               }
    
    // MARK: - Views
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.contentInset = UIEdgeInsets(top: 20.0, left: 0, bottom: 20.0, right: 0)
        tableView.setContentOffset(CGPoint(x: 0, y: -tableView.contentInset.top), animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.upperToolbar.clipsToBounds = true
        tableView.delegate = self //fixing bug
        tableView.tableFooterView = UIView()
        
        // FIXME: - Add editButton everywhere needed
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadSettings()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.updateSpotlight()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AutoLockSegue" {
            let vc = segue.destination as! PKAutoLockTableViewController
            vc.minutes = self.autoLockTime
        } else if segue.identifier == "ClearClipboardSegue" {
            let vc = segue.destination as! PKClearClipboardTableViewController
            vc.seconds = self.clearClipboardTime
        }
    }
    
//    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        if section == 0 {
//            return 30.0 //?
//        } else {
//            return super.tableView(tableView, heightForHeaderInSection: section)
//        }
//    }
    
    // MARK: - Table view data source
    
    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
}
