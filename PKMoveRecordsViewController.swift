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

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


private extension Selector {
    static let handleTextFieldTextDidChange = #selector(PKFoldersTableViewController.handleTextFieldTextDidChange)
}

protocol PKMoveRecordsControllerDelegate {
    func disableEditMode()
}

class PKMoveRecordsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var tableView: UITableView!
    
    var inputTextField: UITextField?
    var saveAlertAction: UIAlertAction?
    var names = Set<String>()
    var records = [PKRecord]()
    var delegate: PKMoveRecordsControllerDelegate?
    var selectedFolderName = String()
    var destinationFolder: PKFolder! = nil
    
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        let entity = NSEntityDescription.entity(forEntityName: "Folder", in: self.managedObjectContext)
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
    var _fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? = nil
    
    var managedObjectContext: NSManagedObjectContext {
        if _managedObjectContext == nil {
            _managedObjectContext = PKCoreDataManager.sharedManager.managedObjectContext
        }
        
        return _managedObjectContext!
    }
    var _managedObjectContext: NSManagedObjectContext? = nil
    
    // MARK: - My Functions
    
    func updateNotes(_ name: String?) {
        var folder: PKFolder
        
        if let name = name {
            folder = self.managedObjectContext.insertObject()
            folder.name = name
            folder.date = Date()
            folder.uuid = UUID().uuidString
            
            PKCoreDataManager.sharedManager.saveContext()
        } else {
            folder = self.destinationFolder
            folder.date = Date()
        }
        
        self.records.forEach() {
            $0.folder = folder
            $0.date = Date()
        }
        
        PKCoreDataManager.sharedManager.saveContext()
        
        self.delegate?.disableEditMode()
        self.dismiss(animated: true, completion: nil)
    }
    
    func showNameTakenAlert() {
        let alertController = UIAlertController(title: "Name Taken", message: "Please choose a different name.", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Notifications
    
    func handleTextFieldTextDidChange() {
        self.saveAlertAction!.isEnabled = self.inputTextField?.text?.characters.count > 0
    }
    
    // MARK: - Actions
    
    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table View
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).row == 0 {
            let alertController = UIAlertController(title: "New Folder", message: "Enter a name for this folder.", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
                let folderName = (self.inputTextField?.text)!
                
                guard !self.names.contains(folderName) else {
                    self.showNameTakenAlert()
                    return
                }
                
                self.updateNotes(folderName)
            }
            
            saveAction.isEnabled = false
            self.saveAlertAction = saveAction
            
            alertController.view.tag = 1003
            alertController.addAction(cancelAction)
            alertController.addAction(saveAction)
            alertController.addTextField {
                self.inputTextField = $0
                $0.tag = 103
                $0.placeholder = "Name"
                $0.clearButtonMode = .whileEditing
                $0.keyboardAppearance = .dark
                $0.autocapitalizationType = .words
                
                NotificationCenter.default.removeObserver(self)
                NotificationCenter.default.addObserver(self, selector: .handleTextFieldTextDidChange,
                    name: NSNotification.Name.UITextFieldTextDidChange,
                    object: $0)
            }
            
            self.present(alertController, animated: true, completion: nil)
        } else {
            let newIndexPath = IndexPath(row: (indexPath as NSIndexPath).row - 1, section: 0)
            self.destinationFolder = self.fetchedResultsController.object(at: newIndexPath) as! PKFolder
            
            self.updateNotes(nil)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let shortPath = ((indexPath as NSIndexPath).section, (indexPath as NSIndexPath).row)
        
        switch shortPath {
        case (0, 0):
            let cell = tableView.dequeueReusableCell(withIdentifier: "NewFolderCell", for: indexPath)
            cell.textLabel?.text = "New Folder"
            cell.textLabel?.textColor = .flatSkyBlue()
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 17.0)
            
            return cell
        default:
            let newIndexPath = IndexPath(row: (indexPath as NSIndexPath).row - 1, section: 0)
            let folder = self.fetchedResultsController.object(at: newIndexPath) as! PKFolder
            let cell = tableView.dequeueReusableCell(withIdentifier: "FolderCell", for: indexPath)
            
            cell.textLabel?.text = folder.name
            cell.detailTextLabel?.text = "\(folder.records!.count)"
            
            if folder.name == self.selectedFolderName {
                cell.isUserInteractionEnabled = false
                cell.textLabel?.textColor = .gray
            }
            
            return cell
        }
    }
    
    // MARK: - Views
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        self.navigationBar.setBackgroundImage(UIImage(), forBarPosition: .Any, barMetrics: .Default)
//        self.navigationBar.shadowImage = UIImage()
        
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: .checkIsLocked, name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
        
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
