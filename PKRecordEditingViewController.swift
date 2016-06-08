//
//  PKRecordEditingViewController.swift
//  SimplePasswordKeeper
//
//  Created by Admin on 19/02/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import UIKit
import CoreData
import CoreSpotlight

let kContentType = "record"

extension UITextView {
    var adjustHeightToRealIPhoneSize: Bool {
        set {
            if newValue {
                self.constraints.filter{ $0.identifier == "DescriptionHeight" }.first!.constant = UIScreen.mainScreen().bounds.size.height - self.frame.origin.y - 80.0
            }
        }
        
        get {
            return false
        }
    }
}

private extension Selector {
    static let keyboardWillShowOrHide = #selector(PKRecordEditingViewController.keyboardWillShowOrHide(_:))
}

class PKRecordEditingViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate, UIScrollViewDelegate {
    enum TextFieldTag: Int {
        case PKRecordEditingViewControllerTextFieldTagTitle = 0,
        PKRecordEditingViewControllerTextFieldTagLogin,
        PKRecordEditingViewControllerTextFieldTagPassword
    }
    
    var folder: PKFolder! = nil
    var record: PKRecord?
    
    var managedObjectContext: NSManagedObjectContext {
        if _managedObjectContext == nil {
            _managedObjectContext = PKCoreDataManager.sharedManager.managedObjectContext
        }
        
        return _managedObjectContext!
    }
    var _managedObjectContext: NSManagedObjectContext? = nil
    
    var defaultDescriptionHeightConstraintHeight: CGFloat!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    lazy var allTextFields: [UITextField] = { [unowned self] in
        return [self.titleTextField, self.loginTextField, self.passwordTextField]
    }()
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var revealButton: UIButton! {
        didSet {
            let image = UIImage(named: "eye.png")
            revealButton.imageView?.contentMode = .ScaleAspectFit
            revealButton.setImage(image, forState: .Normal)
        }
    }
    
    @IBOutlet weak var descriptionTextView: UITextView! {
        didSet {
            if self.record == nil || self.record?.detailedDescription == "" {
                descriptionTextView.text = "Details"
                descriptionTextView.textColor = .lightGrayColor()
            }
        }
    }
    
    // MARK: - Spotlight
    
    func titleIndexing(title: String, login: String, id: String) {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kContentType)
        
        attributeSet.title = title
        attributeSet.contentDescription = login.isEmpty ? "Secure Record" : "Login: \(login)"
        attributeSet.keywords = [title]
        
        let item = CSSearchableItem(uniqueIdentifier: id, domainIdentifier: nil, attributeSet: attributeSet)
        
        CSSearchableIndex.defaultSearchableIndex().indexSearchableItems([item]) { error in
            if error != nil {
                print(error?.localizedDescription)
            } else {
                print("Item Indexed")
            }
        }
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        guard let index = self.allTextFields.indexOf(textField) else { return false }
        
        if textField.tag == TextFieldTag.PKRecordEditingViewControllerTextFieldTagPassword.rawValue {
            self.descriptionTextView.becomeFirstResponder()
            return false
        }
        else {
            self.allTextFields[index + 1].becomeFirstResponder()
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if textField.tag == TextFieldTag.PKRecordEditingViewControllerTextFieldTagPassword.rawValue {
            textField.secureTextEntry = false
            self.revealButton.enabled = false
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField.tag == TextFieldTag.PKRecordEditingViewControllerTextFieldTagPassword.rawValue {
            textField.secureTextEntry = true
            self.revealButton.enabled = true
        }
    }
    
    // MARK: - UITextViewDelegate
    
    func textViewDidBeginEditing(textView: UITextView) {
        if textView.textColor == .lightGrayColor() {
            textView.text = nil
            textView.textColor = .blackColor()
        }
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Details"
            textView.textColor = .lightGrayColor()
        }
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) { self.descriptionTextView.resignFirstResponder() }
    
    // MARK: - Notifications
    
    func keyboardWillShowOrHide(notification: NSNotification) {
        if let userInfo = notification.userInfo,
            endValue = userInfo[UIKeyboardFrameEndUserInfoKey],
            durationValue = userInfo[UIKeyboardAnimationDurationUserInfoKey],
            curveValue = userInfo[UIKeyboardAnimationCurveUserInfoKey] {
            
            let endRect = self.view.convertRect(endValue.CGRectValue, fromView: self.view.window)
            let keyboardOverlap = self.scrollView.frame.maxY - endRect.origin.y
            
            self.scrollView.contentInset.bottom = keyboardOverlap + (keyboardOverlap == 0 ? 0 : 20)
            self.scrollView.scrollIndicatorInsets.bottom = keyboardOverlap + (keyboardOverlap == 0 ? 0 : 20)
            
            let duration = durationValue.doubleValue
            let options = UIViewAnimationOptions(rawValue: UInt(curveValue.integerValue << 16))
            UIView.animateWithDuration(duration, delay: 0, options: options, animations: {
                self.view.layoutIfNeeded()
                }, completion: nil)
        }
    }
    
    // MARK: - Views
    
    override func viewDidLayoutSubviews() {
        let descriptionHeightConstraint = self.descriptionTextView.constraints.filter{ $0.identifier == "DescriptionHeight" }.first
        guard descriptionHeightConstraint != nil else { return }
        
        guard !self.descriptionTextView.text.isEmpty else {
            self.scrollView.contentSize.height = self.descriptionTextView.frame.origin.y + self.defaultDescriptionHeightConstraintHeight
            descriptionHeightConstraint!.constant = self.defaultDescriptionHeightConstraintHeight
            return
        }
        
        guard self.descriptionTextView.intrinsicContentSize().height > self.defaultDescriptionHeightConstraintHeight else { return }
        
        self.scrollView.contentSize.height = self.descriptionTextView.frame.origin.y + self.descriptionTextView.frame.size.height
        descriptionHeightConstraint!.constant = self.descriptionTextView.intrinsicContentSize().height
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setToolbarHidden(true, animated: false)
        self.defaultDescriptionHeightConstraintHeight = self.descriptionTextView.constraints.filter{ $0.identifier == "DescriptionHeight" }.first!.constant
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: .keyboardWillShowOrHide, name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: .keyboardWillShowOrHide, name:UIKeyboardWillHideNotification, object: nil)
        
        if let record = self.record {
            self.allTextFields[TextFieldTag.PKRecordEditingViewControllerTextFieldTagTitle.rawValue].text = record.title
            self.allTextFields[TextFieldTag.PKRecordEditingViewControllerTextFieldTagLogin.rawValue].text = record.login
            self.allTextFields[TextFieldTag.PKRecordEditingViewControllerTextFieldTagPassword.rawValue].text = record.password as? String
            
            if record.detailedDescription != "" {
                self.descriptionTextView.text = record.detailedDescription
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(false, animated: false)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Actions
    
    @IBAction func revealAction(sender: UIButton) {
        let index = TextFieldTag.PKRecordEditingViewControllerTextFieldTagPassword.rawValue
        self.allTextFields[index].secureTextEntry = !self.allTextFields[index].secureTextEntry
    }
    
    @IBAction func saveAction(sender: UIBarButtonItem) {
        let title = self.allTextFields[TextFieldTag.PKRecordEditingViewControllerTextFieldTagTitle.rawValue].text
        
        guard !title!.isEmpty else {
            let alertController = UIAlertController(title: "The title is empty", message: "Please fill in the title field", preferredStyle: .Alert)
            let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
            
            alertController.addAction(action)
            self.presentViewController(alertController, animated: true, completion: nil)
            
            return
        }
        
        let login = self.allTextFields[TextFieldTag.PKRecordEditingViewControllerTextFieldTagLogin.rawValue].text
        
        var password = self.allTextFields[TextFieldTag.PKRecordEditingViewControllerTextFieldTagPassword.rawValue].text
        if password == "" { password = nil }
        
        let description = (self.descriptionTextView.textColor == .lightGrayColor()) ? "" : self.descriptionTextView.text
        let date =  NSDate()
        
        let record = self.record ?? (NSEntityDescription.insertNewObjectForEntityForName("Record", inManagedObjectContext: self.managedObjectContext) as! PKRecord)
        
        record.title = title
        record.login = login
        record.password = password
        record.detailedDescription = description
        record.date = date
        record.folder = self.folder
        
        PKCoreDataManager.sharedManager.saveContext()
        
        let isSpotlightEnabled = NSUserDefaults.standardUserDefaults().boolForKey(kSettingsSpotlight)
        
        if isSpotlightEnabled {
            self.titleIndexing(title!, login: login!, id: String(record.objectID))
        }
        
        self.navigationController?.popViewControllerAnimated(true)
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
