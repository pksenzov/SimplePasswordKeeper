//
//  PKMoveRecordsViewController.swift
//  SimplePasswordKeeper
//
//  Created by Admin on 12/05/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import UIKit
import ChameleonFramework
import CoreData

private extension Selector {
    static let handleTextFieldTextDidChange = #selector(PKFoldersTableViewController.handleTextFieldTextDidChange)
}

protocol PKMoveRecordsControllerDelegate {
    func disableEditMode()
}

class PKMoveRecordsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    var inputTextField: UITextField?
    var saveAlertAction: UIAlertAction?
    var names = Set<String>()
    var records = [PKRecord]()
    var delegate: PKMoveRecordsControllerDelegate?
    var selectedFolderName = String()
    var destinationFolder: PKFolder! = nil
    
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entityForName("Folder", inManagedObjectContext: self.managedObjectContext)
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        
        fetchRequest.entity = entity
        fetchRequest.fetchBatchSize = 20
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            print("Unresolved error \(error), \(error)")
        }
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController? = nil
    
    var managedObjectContext: NSManagedObjectContext {
        if _managedObjectContext == nil {
            _managedObjectContext = PKCoreDataManager.sharedManager.managedObjectContext
        }
        
        return _managedObjectContext!
    }
    var _managedObjectContext: NSManagedObjectContext? = nil
    
    // MARK: - My Functions
    
    func updateNotes(name: String?) {
        var folder: PKFolder
        
        if let name = name {
            folder = self.managedObjectContext.insertObject()
            folder.name = name
            folder.date = NSDate()
            folder.uuid = NSUUID().UUIDString
            
            PKCoreDataManager.sharedManager.saveContext()
        } else {
            folder = self.destinationFolder
            folder.date = NSDate()
        }
        
        self.records.forEach() {
            $0.folder = folder
            $0.date = NSDate()
        }
        
        PKCoreDataManager.sharedManager.saveContext()
        
        self.delegate?.disableEditMode()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showNameTakenAlert() {
        let alertController = UIAlertController(title: "Name Taken", message: "Please choose a different name.", preferredStyle: .Alert)
        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
        
        alertController.addAction(action)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Notifications
    
    func handleTextFieldTextDidChange() {
        self.saveAlertAction!.enabled = self.inputTextField?.text?.characters.count > 0
    }
    
    // MARK: - Actions
    
    @IBAction func cancelAction(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Table View
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            let alertController = UIAlertController(title: "New Folder", message: "Enter a name for this folder.", preferredStyle: .Alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            let saveAction = UIAlertAction(title: "Save", style: .Default) { _ in
                let folderName = (self.inputTextField?.text)!
                
                guard !self.names.contains(folderName) else {
                    self.showNameTakenAlert()
                    return
                }
                
                self.updateNotes(folderName)
            }
            
            saveAction.enabled = false
            self.saveAlertAction = saveAction
            
            alertController.view.tag = 1003
            alertController.addAction(cancelAction)
            alertController.addAction(saveAction)
            alertController.addTextFieldWithConfigurationHandler {
                self.inputTextField = $0
                $0.tag = 103
                $0.placeholder = "Name"
                $0.clearButtonMode = .WhileEditing
                $0.keyboardAppearance = .Dark
                $0.autocapitalizationType = .Words
                
                NSNotificationCenter.defaultCenter().removeObserver(self)
                NSNotificationCenter.defaultCenter().addObserver(self, selector: .handleTextFieldTextDidChange,
                    name: UITextFieldTextDidChangeNotification,
                    object: $0)
            }
            
            self.presentViewController(alertController, animated: true, completion: nil)
        } else {
            let newIndexPath = NSIndexPath(forRow: indexPath.row - 1, inSection: 0)
            self.destinationFolder = self.fetchedResultsController.objectAtIndexPath(newIndexPath) as! PKFolder
            
            self.updateNotes(nil)
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects + 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let shortPath = (indexPath.section, indexPath.row)
        
        switch shortPath {
        case (0, 0):
            let cell = tableView.dequeueReusableCellWithIdentifier("NewFolderCell", forIndexPath: indexPath)
            cell.textLabel?.text = "New Folder"
            cell.textLabel?.textColor = .flatSkyBlueColor()
            cell.textLabel?.font = UIFont.boldSystemFontOfSize(17.0)
            
            return cell
        default:
            let newIndexPath = NSIndexPath(forRow: indexPath.row - 1, inSection: 0)
            let folder = self.fetchedResultsController.objectAtIndexPath(newIndexPath) as! PKFolder
            let cell = tableView.dequeueReusableCellWithIdentifier("FolderCell", forIndexPath: indexPath)
            
            cell.textLabel?.text = folder.name
            cell.detailTextLabel?.text = "\(folder.records!.count)"
            
            if folder.name == self.selectedFolderName {
                cell.userInteractionEnabled = false
                cell.textLabel?.textColor = .grayColor()
            }
            
            return cell
        }
    }
    
    // MARK: - Views
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        //NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationBar.setBackgroundImage(UIImage(), forBarPosition: .Any, barMetrics: .Default)
        self.navigationBar.shadowImage = UIImage()
        
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: .checkIsLocked, name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let folders = self.fetchedResultsController.fetchedObjects as! [PKFolder]
        guard folders.count != 0 else { return }
        
        folders.forEach { self.names.insert($0.name!) }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
