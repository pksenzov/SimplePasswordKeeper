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

let kSettingsLockOnExit = "lockonexit"
let kSettingsSpotlight  = "spotlight"
let kSettingsAutoLock   = "autolock"

var isLocked = NSUserDefaults.standardUserDefaults().boolForKey(kSettingsLockOnExit)

class PKSettingsTableViewController: UITableViewController {
    let defaults = NSUserDefaults.standardUserDefaults()
    var autoLockTime: Int!
    //var isSpotlightEnabled = true
    
    var managedObjectContext: NSManagedObjectContext {
        if _managedObjectContext == nil {
            _managedObjectContext = PKCoreDataManager.sharedManager.managedObjectContext
        }
        
        return _managedObjectContext!
    }
    var _managedObjectContext: NSManagedObjectContext? = nil
    
    @IBOutlet weak var spotlightSwitch: UISwitch!
    @IBOutlet weak var lockOnExitSwitch: UISwitch!
    @IBOutlet weak var autoLockLabel: UILabel!
    
    // MARK: - My Functions
    
    func updateSpotlight() {
        //if self.spotlightSwitch.on != self.isSpotlightEnabled {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            CSSearchableIndex.defaultSearchableIndex().deleteAllSearchableItemsWithCompletionHandler() { error in
                if error != nil {
                    print(error?.localizedDescription)
                } else if self.spotlightSwitch.on {
                    print("!!! - Items Indexes Deleted")
                    
                    let fetchRequest = NSFetchRequest(entityName: "Record")
                    
                    do {
                        var items = [CSSearchableItem]()
                        let records = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [PKRecord]
                        
                        records.forEach() {
                            let attributeSet = CSSearchableItemAttributeSet(itemContentType: kContentType)
                            attributeSet.title = $0.title
                            attributeSet.contentDescription = $0.login!.isEmpty ? "Secure Record" : "Login: \($0.login!)"
                            attributeSet.keywords = [$0.title!]
                            
                            let item = CSSearchableItem(uniqueIdentifier: String($0.objectID), domainIdentifier: nil, attributeSet: attributeSet)
                            item.expirationDate = NSDate.distantFuture()
                            items.append(item)
                        }
                        
                        CSSearchableIndex.defaultSearchableIndex().indexSearchableItems(items) { error in
                            if error != nil {
                                print(error?.localizedDescription)
                            } else {
                                print("!!! - All Items Indexed")
                            }
                        }
                    } catch {
                        print("Unresolved error \(error), \(error)")
                    }
                }
            }
        }
        //}
    }
    
    // MARK: - Load
    
    func loadSettings() {
        self.lockOnExitSwitch.on = self.defaults.boolForKey(kSettingsLockOnExit)
        
        self.spotlightSwitch.on = self.defaults.boolForKey(kSettingsSpotlight)
        //self.isSpotlightEnabled = self.defaults.boolForKey(kSettingsSpotlight)
        
        self.autoLockTime = self.defaults.integerForKey(kSettingsAutoLock)
        self.autoLockLabel.text = (self.autoLockTime != 0) ? "\(self.autoLockTime) minutes" : "Never"
        
        
    }
    
    // MARK: - Actions
    
    @IBAction func lockOnExitValueChanged(sender: UISwitch) { self.defaults.setBool(sender.on, forKey: kSettingsLockOnExit) }
    @IBAction func spotlightValueChanged(sender: UISwitch)  { self.defaults.setBool(sender.on, forKey: kSettingsSpotlight)  }
    @IBAction func closeAction(sender: UIBarButtonItem)     { self.dismissViewControllerAnimated(true, completion: nil)     }
    
    // MARK: - Views
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.contentInset = UIEdgeInsets(top: 20.0, left: 0, bottom: 20.0, right: 0)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.updateSpotlight()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.loadSettings()
        
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: .checkIsLocked, name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // FIXME: - Add editButton everywhere needed
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
