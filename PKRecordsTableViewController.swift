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
    var currentDate: Date! = nil
    var folder: PKFolder! = nil
    
    var addBarButton: UIBarButtonItem!
    
    lazy var textBarButton: UIBarButtonItem = {
        return UIBarButtonItem(customView: self.recordsLabel)
    }()
    
    lazy var doneBarButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .done, target: self, action: .doneAction)
    }()
    
    lazy var cancelBarButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: .cancelAction)
    }()
    
    lazy var moveBarButton: UIBarButtonItem = {
        return UIBarButtonItem(title: "Move All", style: .plain, target: self, action: .moveAction)
    }()
    
    lazy var deleteBarButton: UIBarButtonItem = {
        return UIBarButtonItem(title: "Delete All", style: .plain, target: self, action: .deleteAction)
    }()
    
    lazy var editBarButton: UIBarButtonItem = {
        return self.navigationItem.rightBarButtonItem!
    }()
    
    lazy var toolbarButtons: [UIBarButtonItem] = {
        return self.toolbarItems!
    }()
    
    @IBOutlet var recordsLabel: UILabel! {
        didSet {
            recordsLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.footnote)
        }
    }
    
    override var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        let entity = NSEntityDescription.entity(forEntityName: "Record", in: self.managedObjectContext)
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
    var _fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? = nil
    
    // MARK: - PKMoveRecordsControllerDelegate
    
    func disableEditMode() {
        self.cancelAction()
    }
    
    // MARK: - Actions
    
    func doneAction() {
        self.tableView.setEditing(false, animated: true)
    }
    
    func deleteAction(_ barButtonItem: UIBarButtonItem) {
        let context = self.fetchedResultsController.managedObjectContext
        
        if barButtonItem.title == "Delete All" {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let deleteAction = UIAlertAction(title: "Delete All", style: .destructive) { _ in
                self.fetchedResultsController.fetchedObjects?.forEach() {
                    context.delete($0 as! PKRecord)
                }
                
                self.folder.date = Date()
                
                PKCoreDataManager.sharedManager.saveContext()
                
                self.cancelAction()
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alertController.addAction(deleteAction)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
        } else {
            self.tableView.indexPathsForSelectedRows!.forEach {
                let record = self.fetchedResultsController.object(at: $0) as! PKRecord
                context.delete(record)
            }
            
            self.folder.date = Date()
            
            PKCoreDataManager.sharedManager.saveContext()
            
            self.cancelAction()
        }
    }
    
    func moveAction(_ barButtonItem: UIBarButtonItem) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PKMoveRecordsViewController") as! PKMoveRecordsViewController
        vc.delegate = self
        vc.selectedFolderName = self.folder.name!
        
        if barButtonItem.title == "Move All" {
            vc.records = self.fetchedResultsController.fetchedObjects as! [PKRecord]
        } else {
            var records = [PKRecord]()
            
            self.tableView.indexPathsForSelectedRows!.forEach {
                let record = self.fetchedResultsController.object(at: $0) as! PKRecord
                records.append(record)
            }
            
            vc.records = records
        }
        
        self.navigationController?.present(vc, animated: true, completion: nil)
    }
    
    func cancelAction() {
        self.changeToolbar(false)
        self.navigationItem.title = self.folder.name
        self.moveBarButton.title = "Move All"
        self.deleteBarButton.title = "Delete All"
    }
    
    @IBAction func editAction(_ sender: UIBarButtonItem) {
        self.changeToolbar(true)
    }
    
    // MARK: - Table View
    
    override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        self.navigationItem.setRightBarButton(self.doneBarButton, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        self.navigationItem.setRightBarButton(self.editBarButton, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let move = UITableViewRowAction(style: .normal, title: "Move") {_,_ in
            let record = self.fetchedResultsController.object(at: indexPath) as! PKRecord
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PKMoveRecordsViewController") as! PKMoveRecordsViewController
            vc.selectedFolderName = self.folder.name!
            vc.records = [record]
            
            self.navigationController?.present(vc, animated: true, completion: nil)
        }
        
        let delete = UITableViewRowAction(style: .normal, title: "Delete") {_,_ in
            let record = self.fetchedResultsController.object(at: indexPath) as! PKRecord
            let context = self.fetchedResultsController.managedObjectContext
            
            context.delete(record)
            self.folder.date = Date()
            
            PKCoreDataManager.sharedManager.saveContext()
        }
        
        delete.backgroundColor = .red
        
        return [delete, move]
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {}
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let number = super.tableView(tableView, numberOfRowsInSection: section)
        self.editBarButton.isEnabled = (number > 0)
        
        switch number {
        case 0: self.recordsLabel.text = "No Records"
        case 1: self.recordsLabel.text = "1 Record"
        default : self.recordsLabel.text = "\(number) Records"
        }
        
        return number
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecordCell", for: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            let selectedCount = tableView.indexPathsForSelectedRows!.count
            self.navigationItem.title = "\(selectedCount) Selected"
            
            if selectedCount == 1 {
                self.toolbarItems?.first!.title = "Move To..."
                self.toolbarItems?.last!.title = "Delete"
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
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
    
    func changeToolbar(_ isEditing: Bool) {
        self.tableView.setEditing(isEditing, animated: true)
        self.navigationItem.setRightBarButton(isEditing ? self.cancelBarButton : self.editBarButton, animated: true)
        self.navigationItem.setHidesBackButton(isEditing, animated: true)
        
        if isEditing {
            self.toolbarButtons.insert(self.moveBarButton, at: 0)
            self.toolbarButtons.remove(at: 2)
        } else {
            self.toolbarButtons.removeFirst()
            self.toolbarButtons.insert(self.textBarButton, at: 1)
        }
        
        self.toolbarButtons[self.toolbarButtons.count - 1] = isEditing ? self.deleteBarButton : self.addBarButton
        self.setToolbarItems(self.toolbarButtons, animated: isEditing)
    }
    
    func dateToString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: date, to: self.currentDate).day
        
        if calendar.isDateInToday(date) {
            dateFormatter.dateFormat = "HH:mm"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if days! < 6 {
            dateFormatter.dateFormat = "EEEE"
        } else if Locale.preferredLanguages[0] == "en-US" {
            dateFormatter.dateFormat = "MM/dd/yy HH:mm"
        } else {
            dateFormatter.dateFormat = "dd/MM/yy HH:mm"
        }
        
        return dateFormatter.string(from: date)
    }
    
    // MARK: - CoreDataTableViewController
    
    override func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let record = self.fetchedResultsController.object(at: indexPath) as! PKRecord
        cell.textLabel!.text = record.title
        cell.detailTextLabel!.text = dateToString(record.date!)
    }
    
    // MARK: - Views
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = self.folder.name
        self.toolbarItems?.insert(self.textBarButton, at: 1)
        self.addBarButton = self.toolbarButtons.last
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.currentDate = Date()
    }
    
    // MARK: - Navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return !self.tableView.isEditing
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! PKRecordEditingViewController
        vc.folder = self.folder
        
        if segue.identifier == "RecordsToEditingRecordSegue" {
            let indexPath = self.tableView.indexPath(for: sender as! UITableViewCell)
            let record = self.fetchedResultsController.object(at: indexPath!) as! PKRecord
            
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
