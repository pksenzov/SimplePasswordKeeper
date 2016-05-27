//
//  PKRecordsTableViewController.swift
//  SimplePasswordKeeper
//
//  Created by Admin on 17/02/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import UIKit
import CoreData

private extension Selector {
    static let cancelAction = #selector(PKRecordsTableViewController.cancelAction)
    static let moveAction = #selector(PKRecordsTableViewController.moveAction(_:))
    static let deleteAction = #selector(PKRecordsTableViewController.deleteAction(_:))
    static let doneAction = #selector(PKRecordsTableViewController.doneAction)
}

class PKRecordsTableViewController: PKCoreDataTableViewController, PKMoveRecordsControllerDelegate {
    var currentDate: NSDate! = nil
    var folder: PKFolder! = nil
    var textBarButton: UIBarButtonItem!
    var doneBarButton: UIBarButtonItem?
    var cancelBarButton: UIBarButtonItem?
    var moveBarButton: UIBarButtonItem?
    var deleteBarButton: UIBarButtonItem?
    var editBarButton: UIBarButtonItem?
    var addBarButton: UIBarButtonItem?
    var toolbarButtons: [UIBarButtonItem]?
    @IBOutlet var recordsLabel: UILabel!
    
    override var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entityForName("Record", inManagedObjectContext: self.managedObjectContext)
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        let predicate = NSPredicate(format: "folder.name = %@", self.folder.name!)
        
        fetchRequest.entity = entity
        fetchRequest.fetchBatchSize = 20
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = predicate
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //print("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController? = nil
    
    // MARK: - PKMoveRecordsControllerDelegate
    
    func disableEditMode() {
        self.cancelAction()
    }
    
    // MARK: - Actions
    
    func doneAction() {
        self.tableView.setEditing(false, animated: true)
    }
    
    func deleteAction(barButtonItem: UIBarButtonItem) {
        let context = self.fetchedResultsController.managedObjectContext
        
        if barButtonItem.title == "Delete All" {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            
            let deleteAction = UIAlertAction(title: "Delete All", style: .Destructive) { _ in
                self.fetchedResultsController.fetchedObjects?.forEach() {
                    context.deleteObject($0 as! PKRecord)
                }
                
                PKCoreDataManager.sharedManager.saveContext()
                
                self.cancelAction()
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            
            alertController.addAction(deleteAction)
            alertController.addAction(cancelAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        } else {
            self.tableView.indexPathsForSelectedRows!.forEach {
                let record = self.fetchedResultsController.objectAtIndexPath($0) as! PKRecord
                context.deleteObject(record)
            }
            
            PKCoreDataManager.sharedManager.saveContext()
            
            self.cancelAction()
        }
    }
    
    func moveAction(barButtonItem: UIBarButtonItem) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("PKMoveRecordsViewController") as! PKMoveRecordsViewController
        vc.delegate = self
        vc.selectedFolderName = self.folder.name!
        
        if barButtonItem.title == "Move All" {
            vc.records = self.fetchedResultsController.fetchedObjects as! [PKRecord]
        } else {
            var records = [PKRecord]()
            
            self.tableView.indexPathsForSelectedRows!.forEach {
                let record = self.fetchedResultsController.objectAtIndexPath($0) as! PKRecord
                records.append(record)
            }
            
            vc.records = records
        }
        
        self.navigationController?.presentViewController(vc, animated: true, completion: nil)
    }
    
    func cancelAction() {
        self.changeToolbar(false)
        self.navigationItem.title = self.folder.name
        self.moveBarButton?.title = "Move All"
        self.deleteBarButton?.title = "Delete All"
    }
    
    @IBAction func editAction(sender: UIBarButtonItem) {
        self.changeToolbar(true)
    }
    
    // MARK: - Table View
    
    override func tableView(tableView: UITableView, willBeginEditingRowAtIndexPath indexPath: NSIndexPath) {
        self.navigationItem.setRightBarButtonItem(self.doneBarButton, animated: true)
    }
    
    override func tableView(tableView: UITableView, didEndEditingRowAtIndexPath indexPath: NSIndexPath) {
        self.navigationItem.setRightBarButtonItem(self.editBarButton, animated: true)
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let move = UITableViewRowAction(style: .Normal, title: "Move") {_,_ in
            let record = self.fetchedResultsController.objectAtIndexPath(indexPath) as! PKRecord
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("PKMoveRecordsViewController") as! PKMoveRecordsViewController
            vc.selectedFolderName = self.folder.name!
            vc.records = [record]
            
            self.navigationController?.presentViewController(vc, animated: true, completion: nil)
        }
        
        let delete = UITableViewRowAction(style: .Normal, title: "Delete") {_,_ in
            let record = self.fetchedResultsController.objectAtIndexPath(indexPath) as! PKRecord
            let context = self.fetchedResultsController.managedObjectContext
            
            context.deleteObject(record)
            
            PKCoreDataManager.sharedManager.saveContext()
        }
        
        delete.backgroundColor = .redColor()
        
        return [delete, move]
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {}
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let number = super.tableView(tableView, numberOfRowsInSection: section)
        self.editBarButton?.enabled = (number > 0)
        
        switch number {
        case 0: self.recordsLabel.text = "No Records"
        case 1: self.recordsLabel.text = "1 Record"
        default : self.recordsLabel.text = "\(number) Records"
        }
        
        return number
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("RecordCell", forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.editing {
            let selectedCount = tableView.indexPathsForSelectedRows!.count
            self.navigationItem.title = "\(selectedCount) Selected"
            
            if selectedCount == 1 {
                self.toolbarItems?.first!.title = "Move To..."
                self.toolbarItems?.last!.title = "Delete"
            }
        }
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.editing {
            if let selectedCount = tableView.indexPathsForSelectedRows?.count {
                self.navigationItem.title = "\(selectedCount) Selected"
            } else {
                self.navigationItem.title = self.folder.name
                self.toolbarItems?.first!.title = "Move All"
                self.toolbarItems?.last!.title = "Delete All"
            }
        }
    }
    
    // MARK: - My Functions
    
    func changeToolbar(isEditing: Bool) {
        self.tableView.setEditing(isEditing, animated: true)
        self.navigationItem.setRightBarButtonItem(isEditing ? self.cancelBarButton : self.editBarButton, animated: true)
        self.navigationItem.setHidesBackButton(isEditing, animated: true)
        
        if isEditing {
            self.toolbarButtons?.insert(self.moveBarButton!, atIndex: 0)
            self.toolbarButtons?.removeAtIndex(2)
        } else {
            self.toolbarButtons?.removeFirst()
            self.toolbarButtons?.insert(self.textBarButton, atIndex: 1)
        }
        
        self.toolbarButtons?[self.toolbarButtons!.count - 1] = isEditing ? self.deleteBarButton! : self.addBarButton!
        self.setToolbarItems(self.toolbarButtons, animated: isEditing)
    }
    
    func dateToString(date: NSDate) -> String {
        let dateFormatter = NSDateFormatter()
        let calendar = NSCalendar.currentCalendar()
        let days = calendar.components(.Day, fromDate: date, toDate: self.currentDate, options: []).day
        
        if calendar.isDateInToday(date) {
            dateFormatter.dateFormat = "HH:mm"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if days < 6 {
            dateFormatter.dateFormat = "EEEE"
        } else if NSLocale.preferredLanguages()[0] == "en-US" {
            dateFormatter.dateFormat = "MM/dd/yy HH:mm"
        } else {
            dateFormatter.dateFormat = "dd/MM/yy HH:mm"
        }
        
        return dateFormatter.stringFromDate(date)
    }
    
    // MARK: - CoreDataTableViewController
    
    override func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let record = self.fetchedResultsController.objectAtIndexPath(indexPath) as! PKRecord
        cell.textLabel!.text = record.title
        cell.detailTextLabel!.text = dateToString(record.date!)
    }
    
    // MARK: - Views
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.editBarButton = self.navigationItem.rightBarButtonItem
        self.navigationItem.title = self.folder.name
        
        self.textBarButton = UIBarButtonItem(customView: self.recordsLabel)
        self.toolbarItems?.insert(self.textBarButton, atIndex: 1)
        
        self.cancelBarButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: .cancelAction)
        self.moveBarButton = UIBarButtonItem(title: "Move All", style: .Plain, target: self, action: .moveAction)
        self.deleteBarButton = UIBarButtonItem(title: "Delete All", style: .Plain, target: self, action: .deleteAction)
        self.doneBarButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: .doneAction)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.currentDate = NSDate()
        
        if self.toolbarButtons == nil {
            self.toolbarButtons = self.toolbarItems
            self.addBarButton = self.toolbarButtons?.last
        }
    }
    
    // MARK: - Navigation
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        return !self.tableView.editing
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let vc = segue.destinationViewController as! PKRecordEditingViewController
        vc.folder = self.folder
        
        if segue.identifier == "RecordsToEditingRecordSegue" {
            let indexPath = self.tableView.indexPathForCell(sender as! UITableViewCell)
            let record = self.fetchedResultsController.objectAtIndexPath(indexPath!) as! PKRecord
            vc.record = record
        }
    }

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
