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
    static let keyboardWillShowOrHide = #selector(PKRecordEditingViewController.keyboardWillShowOrHide(_:))
}

class PKRecordEditingViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate, UIScrollViewDelegate {
    enum TextFieldTag: Int {
        case pkRecordEditingViewControllerTextFieldTagTitle = 0,
        pkRecordEditingViewControllerTextFieldTagLogin,
        pkRecordEditingViewControllerTextFieldTagPassword
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
            revealButton.imageView?.contentMode = .scaleAspectFit
            revealButton.setImage(image, for: UIControlState())
        }
    }
    
    @IBOutlet weak var descriptionTextView: UITextView! {
        didSet {
            if self.record == nil || self.record?.detailedDescription == "" {
                descriptionTextView.text = "Details"
                descriptionTextView.textColor = .lightGray
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
                self.managedObjectContext.refresh(record, mergeChanges: false)
                
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
        
        self.savedIsTitleOnFocus    = self.titleTextField.isFirstResponder
        self.savedIsLoginOnFocus    = self.loginTextField.isFirstResponder
        self.savedIsPasswordOnFocus = self.passwordTextField.isFirstResponder
        self.savedIsDetailsOnFocus  = self.descriptionTextView.isFirstResponder
        
        if self.savedIsTitleOnFocus!            { self.savedRange       = self.titleTextField.selectedTextRange          }
        else if self.savedIsLoginOnFocus!       { self.savedRange       = self.loginTextField.selectedTextRange          }
        else if self.savedIsPasswordOnFocus!    { self.savedRange       = self.passwordTextField.selectedTextRange       }
        else if self.savedIsDetailsOnFocus!     { self.savedRange       = self.descriptionTextView.selectedTextRange     }
    }
    
    // MARK: - Spotlight
    
    func titleIndexing(_ title: String, id: String) {
        DispatchQueue.global().async {
            let attributeSet = CSSearchableItemAttributeSet(itemContentType: kContentType)
            attributeSet.title = title
            attributeSet.contentDescription = "Secure Record"
            attributeSet.keywords = [title]
            
            let item = CSSearchableItem(uniqueIdentifier: id, domainIdentifier: nil, attributeSet: attributeSet)
            item.expirationDate = Date.distantFuture
            
            CSSearchableIndex.default().indexSearchableItems([item]) { error in
                if error != nil {
                    print(error?.localizedDescription)
                } else {
                    print("Item Indexed")
                }
            }
        }
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let index = self.allTextFields.index(of: textField) else { return false }
        
        if textField.tag == TextFieldTag.pkRecordEditingViewControllerTextFieldTagPassword.rawValue {
            self.descriptionTextView.becomeFirstResponder()
            return false
        }
        else {
            self.allTextFields[index + 1].becomeFirstResponder()
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.tag == TextFieldTag.pkRecordEditingViewControllerTextFieldTagPassword.rawValue {
            textField.font = nil
            textField.font = UIFont.systemFont(ofSize: 14.0)
            textField.isSecureTextEntry = false
            self.revealButton.isEnabled = false
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.tag == TextFieldTag.pkRecordEditingViewControllerTextFieldTagPassword.rawValue {
            textField.isSecureTextEntry = true
            self.revealButton.isEnabled = true
        }
    }
    
    // MARK: - UITextViewDelegate
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            textView.text = nil
            textView.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Details"
            textView.textColor = .lightGray
        }
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { self.descriptionTextView.resignFirstResponder() }
    
    // MARK: - Notifications
    
    func keyboardWillShowOrHide(_ notification: Notification) {
        if let userInfo = (notification as NSNotification).userInfo,
            let endValue = userInfo[UIKeyboardFrameEndUserInfoKey],
            let durationValue = userInfo[UIKeyboardAnimationDurationUserInfoKey],
            let curveValue = userInfo[UIKeyboardAnimationCurveUserInfoKey] {
            
            let endRect = self.view.convert((endValue as AnyObject).cgRectValue, from: self.view.window)
            let keyboardOverlap = self.scrollView.frame.maxY - endRect.origin.y
            
            self.scrollView.contentInset.bottom = keyboardOverlap + (keyboardOverlap == 0 ? 0 : 20)
            self.scrollView.scrollIndicatorInsets.bottom = keyboardOverlap + (keyboardOverlap == 0 ? 0 : 20)
            
            let duration = (durationValue as AnyObject).doubleValue
            let options = UIViewAnimationOptions(rawValue: UInt((curveValue as AnyObject).intValue << 16))
            UIView.animate(withDuration: duration!, delay: 0, options: options, animations: {
                self.view.layoutIfNeeded()
                }, completion: nil)
            
            if notification.name == NSNotification.Name.UIKeyboardWillShow && self.savedRange != nil {
                self.allTextFields.forEach() {
                    if $0.isFirstResponder {
                        $0.selectedTextRange = $0.textRange(from: self.savedRange!.start, to: self.savedRange!.end)
                        self.savedRange = nil
                        return
                    }
                }
                
                if self.savedRange != nil {
                    self.descriptionTextView.selectedTextRange = self.descriptionTextView.textRange(from: self.savedRange!.start, to: self.savedRange!.end)
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
        
        guard self.descriptionTextView.intrinsicContentSize.height > self.defaultDescriptionHeightConstraintHeight else { return }
        
        self.scrollView.contentSize.height = self.descriptionTextView.frame.origin.y + self.descriptionTextView.frame.size.height
        descriptionHeightConstraint!.constant = self.descriptionTextView.intrinsicContentSize.height
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setToolbarHidden(true, animated: false)
        self.defaultDescriptionHeightConstraintHeight = self.descriptionTextView.constraints.filter{ $0.identifier == "DescriptionHeight" }.first!.constant
        
        NotificationCenter.default.addObserver(self, selector: .keyboardWillShowOrHide, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: .keyboardWillShowOrHide, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.fillInData()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(false, animated: false)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .any, barMetrics: .default)
        self.navigationController?.navigationBar.shadowImage = nil
    }
    
    // MARK: - Init & Deinit
    
    deinit { NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil) }
    
    // MARK: - Actions
    
    @IBAction func revealAction(_ sender: UIButton) {
        let index = TextFieldTag.pkRecordEditingViewControllerTextFieldTagPassword.rawValue
        self.allTextFields[index].isSecureTextEntry = !self.allTextFields[index].isSecureTextEntry
    }
    
    @IBAction func saveAction(_ sender: UIBarButtonItem) {
        let title = self.allTextFields[TextFieldTag.pkRecordEditingViewControllerTextFieldTagTitle.rawValue].text
        
        guard !title!.isEmpty else {
            let alertController = UIAlertController(title: "The title is empty", message: "Please fill in the title field", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            
            alertController.addAction(action)
            self.present(alertController, animated: true, completion: nil)
            
            return
        }
        
        let login = self.allTextFields[TextFieldTag.pkRecordEditingViewControllerTextFieldTagLogin.rawValue].text
        
        var password = self.allTextFields[TextFieldTag.pkRecordEditingViewControllerTextFieldTagPassword.rawValue].text
        if password == "" { password = nil }
        
        let description = (self.descriptionTextView.textColor == .lightGray) ? "" : self.descriptionTextView.text
        let date =  Date()
        
        let record: PKRecord = self.record ?? self.managedObjectContext.insertObject()
        
        record.title = title
        record.login = login
        record.password = password as NSObject?
        record.detailedDescription = description
        record.date = date
        record.folder = self.folder
        if self.record == nil {
            record.creationDate = Date()
            record.uuid = UUID().uuidString
        }
        
        PKCoreDataManager.sharedManager.saveContext()
        
        let isSpotlightEnabled = UserDefaults.standard.bool(forKey: kSettingsSpotlight)
        
        if isSpotlightEnabled {
            self.titleIndexing(title!, id: String(describing: record.objectID))
        }
        
        _ = self.navigationController?.popViewController(animated: true)
    }
}
