//
//  PKRecordsTableViewController.swift
//  SimplePasswordKeeper
//
//  Created by Admin on 17/02/16.
//  Copyright © 2016 pksenzov. All rights reserved.
//

import UIKit
import CoreData

class PKRecordsTableViewController: PKCoreDataTableViewController {
    var folder: PKFolder! = nil
    var editBarButton: UIBarButtonItem?
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
    
    // MARK: - Table View
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let number = super.tableView(tableView, numberOfRowsInSection: section)
        self.editBarButton?.enabled = (number > 1)
        
        switch number {
        case 0: self.recordsLabel.text = "No Records"
        case 1: self.recordsLabel.text = "1 Record"
        default : self.recordsLabel.text = "\(number) Records"
        }
        
        return number
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool { return true }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("RecordCell", forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    // MARK: - My Functions
    
    func dateToString(date: NSDate) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy HH:mm"
        
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
        self.navigationItem.title = self.folder.name!
        
        let textBarButton = UIBarButtonItem(customView: self.recordsLabel)
        self.toolbarItems?.insert(textBarButton, atIndex: 1)
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "RecordsToNewRecordSegue" {
            let vc = segue.destinationViewController as! PKRecordEditingViewController
            vc.folder = self.folder
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
