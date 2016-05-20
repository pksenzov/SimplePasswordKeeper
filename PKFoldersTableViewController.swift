//
//  PKFoldersTableViewController.swift
//  SimplePasswordKeeper
//
//  Created by Pavel Ksenzov on 12/02/16.
//  Copyright © 2016 pksenzov. All rights reserved.
//

import UIKit
import CoreData

private extension Selector {
    static let handleTextFieldTextDidChangeNotification = #selector(PKFoldersTableViewController.handleTextFieldTextDidChangeNotification)
    static let handleTextDidBeginEditingNotification = #selector(PKFoldersTableViewController.handleTextDidBeginEditingNotification)
    static let handleTap = #selector(PKFoldersTableViewController.handleTap(_:))
    static let doneAction = #selector(PKFoldersTableViewController.doneAction)
    static let deleteAction = #selector(PKFoldersTableViewController.deleteAction)
}

class PKFoldersTableViewController: PKCoreDataTableViewController, PKLoginControllerDelegate, UIGestureRecognizerDelegate {
    var isAuthenticated = false
    var names = Set<String>()
    let firstFolderName = "General"
    let navigationItemDefaultName = "Folders"
    //let editBarButtonName = "Edit"
    var saveAlertAction: UIAlertAction?
    var inputTextField: UITextField?
    var doneBarButton: UIBarButtonItem?
    var editBarButton: UIBarButtonItem?
    var toolbarButtons: [UIBarButtonItem]?
    var deleteBarButton: UIBarButtonItem?
    var addBarButton: UIBarButtonItem?
    var tapGesture: UITapGestureRecognizer!
    var longTapGesture: UILongPressGestureRecognizer!
    
    override var fetchedResultsController: NSFetchedResultsController {
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
    
    // MARK: - Notifications
    
    func handleTextFieldTextDidChangeNotification() {
        self.saveAlertAction!.enabled = self.inputTextField?.text?.characters.count > 0
    }
    
    func handleTextDidBeginEditingNotification() {
        self.inputTextField?.selectedTextRange = self.inputTextField?.textRangeFromPosition(self.inputTextField!.beginningOfDocument,
                                                                                            toPosition: self.inputTextField!.endOfDocument)
    }
    
    // MARK: - Actions
    
    func deleteAction() {
        let context = self.fetchedResultsController.managedObjectContext
        var folderNames = [String]()
        
        self.tableView.indexPathsForSelectedRows!.forEach {
            let folder = self.fetchedResultsController.objectAtIndexPath($0) as! PKFolder
            folderNames.append(folder.name!)
            context.deleteObject(folder)
        }
        
        do {
            try context.save()
        } catch {
            print("Unresolved error \(error), \(error)")
            return
        }
        
        folderNames.forEach { self.names.remove($0) }
        self.doneAction()
    }
    
    func doneAction() {
        self.tableView.setEditing(false, animated: true)
        self.tableView.removeGestureRecognizer(self.tapGesture)
        self.tableView.removeGestureRecognizer(self.longTapGesture)
        self.navigationItem.title = self.navigationItemDefaultName
        self.deleteBarButton?.enabled = false
        self.changeButtons(rightBarButtonItem: self.editBarButton!, toolbarButtonItem: self.addBarButton!)
    }
    
    @IBAction func editAction(sender: UIBarButtonItem) {
        self.tableView.setEditing(true, animated: true)
        self.tableView.addGestureRecognizer(self.tapGesture)
        self.tableView.addGestureRecognizer(self.longTapGesture)
        self.changeButtons(rightBarButtonItem: self.doneBarButton!, toolbarButtonItem: self.deleteBarButton!)
    }
    
    @IBAction func newFolderAction(sender: UIBarButtonItem) {
        let alertController: UIAlertController = UIAlertController(title: "New Folder", message: "Enter a name for this folder.", preferredStyle: .Alert)
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        let saveAction: UIAlertAction = UIAlertAction(title: "Save", style: .Default) { _ in
            let folderName = (self.inputTextField?.text)!
            
            guard !self.names.contains(folderName) else {
                self.showNameTakenAlert()
                return
            }
            
            self.insertFolder(name: folderName)
        }
        
        saveAction.enabled = false
        self.saveAlertAction = saveAction
        
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        alertController.addTextFieldWithConfigurationHandler {
            self.inputTextField = $0
            $0.placeholder = "Name"
            $0.clearButtonMode = .WhileEditing
            $0.keyboardAppearance = .Dark
            $0.autocapitalizationType = .Words
            
            NSNotificationCenter.defaultCenter().removeObserver(self)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: .handleTextFieldTextDidChangeNotification,
                                                                   name: UITextFieldTextDidChangeNotification,
                                                                   object: $0)
        }
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        let tableView = gestureRecognizer.view as? UITableView
        if tableView == nil { return false }
        
        let point = gestureRecognizer.locationInView(gestureRecognizer.view)
        
        if (tableView!.indexPathForRowAtPoint(point) != nil) { return true }
        return false
    }
    
    func handleTap(tap: UIGestureRecognizer) {
        if tap is UILongPressGestureRecognizer { return }
        
        if tap.state == UIGestureRecognizerState.Ended {
            let tableView = tap.view as? UITableView
            if tableView == nil { return }
            
            let point = tap.locationInView(tap.view)
            let indexPath = tableView!.indexPathForRowAtPoint(point)
            if indexPath == nil { return }
            
            let cell = tableView!.cellForRowAtIndexPath(indexPath!)
            if cell == nil || cell?.textLabel?.text == self.firstFolderName { return }
            
            let indent = cell!.contentView.frame.origin.x + cell!.indentationWidth
            let rect = CGRectMake(cell!.frame.origin.x + indent, cell!.frame.origin.y, cell!.frame.size.width - indent, cell!.frame.size.height)

            if CGRectContainsPoint(rect, point) {
                let alertController: UIAlertController = UIAlertController(title: "Rename Folder", message: "Enter a new name for this folder.", preferredStyle: .Alert)
                let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                let saveAction: UIAlertAction = UIAlertAction(title: "Save", style: .Default) { _ in
                    let folderName = (self.inputTextField?.text)!
                    
                    if self.names.contains(folderName) {
                        if folderName != cell!.textLabel!.text! { self.showNameTakenAlert() }
                        return
                    }
                    
                    self.updateFolder(oldName: cell!.textLabel!.text!, newName: self.inputTextField!.text!)
                }
                
                self.saveAlertAction = saveAction
                
                alertController.addAction(cancelAction)
                alertController.addAction(saveAction)
                alertController.addTextFieldWithConfigurationHandler {
                    self.inputTextField = $0
                    $0.placeholder = "Name"
                    $0.text = cell!.textLabel?.text
                    $0.clearButtonMode = .WhileEditing
                    $0.keyboardAppearance = .Dark
                    $0.autocapitalizationType = .Words
                    
                    NSNotificationCenter.defaultCenter().removeObserver(self)
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: .handleTextFieldTextDidChangeNotification,
                        name: UITextFieldTextDidChangeNotification,
                        object: $0)
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: .handleTextDidBeginEditingNotification,
                        name: UITextFieldTextDidBeginEditingNotification,
                        object: $0)
                }
                
                self.presentViewController(alertController, animated: true, completion: nil)
            } else {
                if cell!.selected {
                    tableView!.deselectRowAtIndexPath(indexPath!, animated: true)
                } else {
                    tableView!.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .None)
                }
                
                if let selectedCount = tableView!.indexPathsForSelectedRows?.count {
                    self.navigationItem.title = "\(selectedCount) Selected"
                    self.deleteBarButton?.enabled = true
                } else {
                    self.navigationItem.title = self.navigationItemDefaultName
                    self.deleteBarButton?.enabled = false
                }
            }
        }
    }
    
    // MARK: - PKLoginControllerDelegate
    
    // FIXME: - БРАТЬ ДАННЫЕ ИЗ FetchedResultController!!!
    func loadData() {
        let preFetchRequest = NSFetchRequest(entityName: "Folder")
        
        do {
            let folders = try self.managedObjectContext.executeFetchRequest(preFetchRequest) as! [PKFolder]
            
            guard folders.count != 0 else {
                self.insertFolder(name: self.firstFolderName)
                return
            }
            
            folders.forEach { self.names.insert($0.name!) }
            
            self.tableView.reloadData()
        } catch {
            print("Unresolved error \(error), \(error)")
        }
    }
    
    // MARK: - Table View
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let folder = self.fetchedResultsController.objectAtIndexPath(indexPath) as! PKFolder
            let context = self.fetchedResultsController.managedObjectContext
            let folderName = folder.name!
            context.deleteObject(folder)
            
            do {
                try context.save()
            } catch {
                print("Unresolved error \(error), \(error)")
                return
            }
            
            self.names.remove(folderName)
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let folder = self.fetchedResultsController.objectAtIndexPath(indexPath) as! PKFolder
        return !(folder.name == self.firstFolderName)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FolderCell", forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !isAuthenticated {
            return 0
        }
        
        let number = super.tableView(tableView, numberOfRowsInSection: section)
        self.editBarButton?.enabled = (number > 1)

        return number
    }
    
    // MARK: - CoreDataTableViewController
    
    override func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let folder = self.fetchedResultsController.objectAtIndexPath(indexPath) as! PKFolder

        cell.textLabel!.text = folder.name
        cell.detailTextLabel!.text = "\(folder.records!.count)"
    }
    
    // MARK: - My Functions
    
    func changeButtons(rightBarButtonItem rightBarButtonItem: UIBarButtonItem, toolbarButtonItem: UIBarButtonItem) {
        self.navigationItem.setRightBarButtonItem(rightBarButtonItem, animated: true)
        
        self.toolbarButtons![1] = toolbarButtonItem
        self.setToolbarItems(self.toolbarButtons, animated: true)
    }
    
    func showNameTakenAlert() {
        let alertController: UIAlertController = UIAlertController(title: "Name Taken", message: "Please choose a different name.", preferredStyle: .Alert)
        let action: UIAlertAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        
        alertController.addAction(action)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func insertFolder(name name: String) {
        let newFolder = NSEntityDescription.insertNewObjectForEntityForName("Folder", inManagedObjectContext: self.managedObjectContext) as! PKFolder
        newFolder.name = name
        
        do {
            try self.managedObjectContext.save()
        } catch {
            print("Unresolved error \(error), \(error)")
            return
        }
        
        self.names.insert(name)
    }
    
    func updateFolder(oldName oldName: String, newName: String) {
        let predicate = NSPredicate(format: "name == %@", oldName)
        let fetchRequest = NSFetchRequest(entityName: "Folder")
        fetchRequest.predicate = predicate
        
        do {
            let folders = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [PKFolder]
            guard folders.count == 1 else { return }
            
            folders.first?.name = newName
        } catch {
            print("Unresolved error \(error), \(error)")
            return
        }
        
        do {
            try self.managedObjectContext.save()
        } catch {
            print("Unresolved error \(error), \(error)")
            return
        }
        
        self.names.remove(oldName)
        self.names.insert(newName)
    }
    
    // MARK: - Views
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tapGesture = UITapGestureRecognizer(target: self, action: .handleTap)
        self.longTapGesture = UILongPressGestureRecognizer(target: self, action: .handleTap)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.editBarButton = self.navigationItem.rightBarButtonItem
        self.doneBarButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: .doneAction)
        
        self.toolbarButtons = self.toolbarItems
        self.deleteBarButton = UIBarButtonItem(title: "Delete", style: .Plain, target: self, action: .deleteAction)
        self.deleteBarButton?.enabled = false
        self.addBarButton = self.toolbarButtons![1]
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarPosition: .Any, barMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if !isAuthenticated {
            isAuthenticated = true
            PKServerManager.sharedManager.authorizeUser()
        }
    }
    
    // MARK: - Navigation
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        return !self.tableView.editing
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "FolderToRecordsSegue" {
            let vc = segue.destinationViewController as! PKRecordsTableViewController
            let indexPath = self.tableView.indexPathForCell(sender as! UITableViewCell)
            let folder = self.fetchedResultsController.objectAtIndexPath(indexPath!) as! PKFolder
            
            let backItem = UIBarButtonItem()
            backItem.title = ""
            self.navigationItem.backBarButtonItem = backItem
            
            vc.folder = folder
        }
    }


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
