//
//  PKSettingsTableViewController.swift
//  SimplePasswordKeeper
//
//  Created by Admin on 24/05/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import UIKit

let kSettingsLockOnExit = "lockonexit"        //?
let kSettingsSpotlight  = "spotlight"
let kSettingsAutoLock   = "autolock"

class PKSettingsTableViewController: UITableViewController {
    let defaults = NSUserDefaults.standardUserDefaults()
    var autoLockTime: Int!
    
    @IBOutlet weak var spotlightSwitch: UISwitch!
    @IBOutlet weak var lockOnExitSwitch: UISwitch!
    @IBOutlet weak var autoLockLabel: UILabel!
    
//    #pragma mark - Save and Load
//    
//    - (void)loadSettings {
//    
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    
//    self.firstnameTextField.text = [defaults objectForKey:kSettingsFirstname];
//    self.lastnameTextField.text = [defaults objectForKey:kSettingsLastname];
//    self.ageTextField.text = [defaults objectForKey:kSettingsAge];
//    self.loginTextField.text = [defaults objectForKey:kSettingsLogin];
//    self.passwordTextField.text = [defaults objectForKey:kSettingsPassword];
//    self.phoneTextField.text = [defaults objectForKey:kSettingsPhone];
//    self.emailTextField.text = [defaults objectForKey:kSettingsEmail];
//    self.marriedSwitch.on = [defaults boolForKey:kSettingsMarried];
//    self.countrySegmentedControl.selectedSegmentIndex = [defaults integerForKey:kSettingsCountry];
//    self.toleranceLevelSlider.value = [defaults floatForKey:kSettingsTolerance];
//    
//    }
//    
//    - (void)saveSettings {
//    
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    
//    [defaults setObject:self.firstnameTextField.text forKey:kSettingsFirstname];
//    [defaults setObject:self.lastnameTextField.text forKey:kSettingsLastname];
//    [defaults setObject:self.ageTextField.text forKey:kSettingsAge];
//    [defaults setObject:self.loginTextField.text forKey:kSettingsLogin];
//    [defaults setObject:self.passwordTextField.text forKey:kSettingsPassword];
//    [defaults setObject:self.phoneTextField.text forKey:kSettingsPhone];
//    [defaults setObject:self.emailTextField.text forKey:kSettingsEmail];
//    [defaults setBool:self.marriedSwitch.on forKey:kSettingsMarried];
//    [defaults setInteger:self.countrySegmentedControl.selectedSegmentIndex forKey:kSettingsCountry];
//    [defaults setFloat:self.toleranceLevelSlider.value forKey:kSettingsTolerance];
//    
//    [defaults synchronize];
//    
//    }
    
    // MARK: - Save and Load
    
    func saveSettings(flag: Bool, key: String) {
        //self.defaults.setBool(flag, forKey: key)
        //self.defaults.synchronize()
    }
    
    func loadSettings() {
        self.lockOnExitSwitch.on = self.defaults.boolForKey(kSettingsLockOnExit)
        self.spotlightSwitch.on = self.defaults.boolForKey(kSettingsSpotlight)
        
        self.autoLockTime = self.defaults.integerForKey(kSettingsAutoLock)
        self.autoLockLabel.text = (self.autoLockTime != 0) ? "\(self.autoLockTime) minutes" : "Never"
    }
    
    // MARK: - Actions
    
    @IBAction func lockOnExitValueChanged(sender: UISwitch) { self.defaults.setBool(sender.on, forKey: kSettingsLockOnExit) }
    @IBAction func spotlightValueChanged(sender: UISwitch)  { self.defaults.setBool(sender.on, forKey: kSettingsSpotlight)  }
    
    @IBAction func closeAction(sender: UIBarButtonItem) { self.dismissViewControllerAnimated(true, completion: nil) }
    
    // MARK: - Views
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.contentInset = UIEdgeInsets(top: 20.0, left: 0, bottom: 20.0, right: 0)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadSettings()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.defaults.registerDefaults([kSettingsLockOnExit : true,
                                        kSettingsSpotlight  : true,
                                        kSettingsAutoLock   : 15])

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
