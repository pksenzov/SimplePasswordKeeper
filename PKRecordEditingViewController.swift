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

private extension Selector {
    static let keyboardWillShowOrHide = #selector(PKRecordEditingViewController.keyboardWillShowOrHide(_:))
}

class PKRecordEditingViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate, UIScrollViewDelegate {
    enum TextFieldTag: Int {
        case PKRecordEditingViewControllerTextFieldTagTitle = 0,
        PKRecordEditingViewControllerTextFieldTagLogin,
        PKRecordEditingViewControllerTextFieldTagPassword
    }
    
    var savedTitle:     String?
    var savedLogin:     String?
    var savedPassword:  String?
    var savedDetails:   String?
    
    var savedIsTitleOnFocus:    Bool?
    var savedIsLoginOnFocus:    Bool?
    var savedIsPasswordOnFocus: Bool?
    var savedIsDetailsOnFocus:  Bool?
    
    var savedRange:    UITextRange?
    
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
    
    // MARK: - My Functions
    
    func fillInData() {
        if self.savedTitle != nil {
            self.titleTextField.text    = self.savedTitle
            self.loginTextField.text    = self.savedLogin
            self.passwordTextField.text = self.savedPassword
            
            if self.savedDetails != "" {
                self.descriptionTextView.text = self.savedDetails
            }
            
            if self.savedIsTitleOnFocus!            { self.titleTextField.becomeFirstResponder()        }
            else if self.savedIsLoginOnFocus!       { self.loginTextField.becomeFirstResponder()        }
            else if self.savedIsPasswordOnFocus!    { self.passwordTextField.becomeFirstResponder()     }
            else if self.savedIsDetailsOnFocus!     { self.descriptionTextView.becomeFirstResponder()   }
            
            self.savedTitle     = nil
            self.savedLogin     = nil
            self.savedPassword  = nil
            self.savedDetails   = nil
            
            self.savedIsTitleOnFocus    = nil
            self.savedIsLoginOnFocus    = nil
            self.savedIsPasswordOnFocus = nil
            self.savedIsDetailsOnFocus  = nil
        } else if let record = self.record {
            var forcePassword: String?
            
            if record.password != nil && !(record.password is String) {
                self.managedObjectContext.refreshObject(record, mergeChanges: false)
                
                if !(record.password is String) {
                    forcePassword = PKPwdTransformer().reversTransformValue(record.password) //HACK =((
                }
            }
            
            self.titleTextField.text    = record.title
            self.loginTextField.text    = record.login
            self.passwordTextField.text = forcePassword ?? (record.password as? String)
            
            if record.detailedDescription != "" {
                self.descriptionTextView.text = record.detailedDescription
            }
        }
    }
    
    func saveData() {
        self.savedTitle     = self.titleTextField.text
        self.savedLogin     = self.loginTextField.text
        self.savedPassword  = self.passwordTextField.text
        self.savedDetails   = self.descriptionTextView.text
        
        self.savedIsTitleOnFocus    = self.titleTextField.isFirstResponder()
        self.savedIsLoginOnFocus    = self.loginTextField.isFirstResponder()
        self.savedIsPasswordOnFocus = self.passwordTextField.isFirstResponder()
        self.savedIsDetailsOnFocus  = self.descriptionTextView.isFirstResponder()
        
        if self.savedIsTitleOnFocus!            { self.savedRange       = self.titleTextField.selectedTextRange          }
        else if self.savedIsLoginOnFocus!       { self.savedRange       = self.loginTextField.selectedTextRange          }
        else if self.savedIsPasswordOnFocus!    { self.savedRange       = self.passwordTextField.selectedTextRange       }
        else if self.savedIsDetailsOnFocus!     { self.savedRange       = self.descriptionTextView.selectedTextRange     }
    }
    
    // MARK: - Spotlight
    
    func titleIndexing(title: String, id: String) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let attributeSet = CSSearchableItemAttributeSet(itemContentType: kContentType)
            attributeSet.title = title
            attributeSet.contentDescription = "Secure Record"
            attributeSet.keywords = [title]
            
            let item = CSSearchableItem(uniqueIdentifier: id, domainIdentifier: nil, attributeSet: attributeSet)
            item.expirationDate = NSDate.distantFuture()
            
            CSSearchableIndex.defaultSearchableIndex().indexSearchableItems([item]) { error in
                if error != nil {
                    print(error?.localizedDescription)
                } else {
                    print("Item Indexed")
                }
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
            textField.font = nil
            textField.font = UIFont.systemFontOfSize(14.0)
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
            
            if notification.name == "UIKeyboardWillShowNotification" && self.savedRange != nil {
                self.allTextFields.forEach() {
                    if $0.isFirstResponder() {
                        $0.selectedTextRange = $0.textRangeFromPosition(self.savedRange!.start, toPosition: self.savedRange!.end)
                        self.savedRange = nil
                        return
                    }
                }
                
                if self.savedRange != nil {
                    self.descriptionTextView.selectedTextRange = self.descriptionTextView.textRangeFromPosition(self.savedRange!.start, toPosition: self.savedRange!.end)
                    self.savedRange = nil
                }
            }
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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: .keyboardWillShowOrHide, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: .keyboardWillShowOrHide, name: UIKeyboardWillHideNotification, object: nil)
        
        self.fillInData()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarPosition: .Any, barMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(false, animated: false)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        
        self.navigationController?.navigationBar.setBackgroundImage(nil, forBarPosition: .Any, barMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = nil
    }
    
    // MARK: - Init & Deinit
    
    deinit { NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil) }
    
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
        
        let record: PKRecord = self.record ?? self.managedObjectContext.insertObject()
        
        record.title = title
        record.login = login
        record.password = password
        record.detailedDescription = description
        record.date = date
        record.folder = self.folder
        if self.record == nil {
            record.creationDate = NSDate()
            record.uuid = NSUUID().UUIDString
        }
        
        PKCoreDataManager.sharedManager.saveContext()
        
        let isSpotlightEnabled = NSUserDefaults.standardUserDefaults().boolForKey(kSettingsSpotlight)
        
        if isSpotlightEnabled {
            self.titleIndexing(title!, id: String(record.objectID))
        }
        
        self.navigationController?.popViewControllerAnimated(true)
    }
}
