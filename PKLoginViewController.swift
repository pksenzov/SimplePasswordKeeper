//
//  PKLoginViewController.swift
//  SimplePasswordKeeper
//
//  Created by Admin on 17/02/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import UIKit
import LocalAuthentication

private extension Selector {
    static let applicationDidBecomeActive = #selector(PKLoginViewController.applicationDidBecomeActive)
    static let applicationWillResignActive = #selector(PKLoginViewController.applicationWillResignActive)
}

protocol PKLoginControllerDelegate {
    func loadData()
}

class PKLoginViewController: UIViewController {
    var isRepeatAlert = false
    var delegate: PKLoginControllerDelegate? //! = nil
    
    // MARK: - Actions
    
    @IBAction func enterAction(sender: UIButton) {
        self.authenticateUser()
    }
    
    // MARK: - Notifications
    
    func applicationWillResignActive() {
        if self.presentedViewController != nil {
            self.dismissViewControllerAnimated(false, completion: nil)
        }
    }
    
    func applicationDidBecomeActive() {
        if self.isRepeatAlert && self.presentedViewController == nil {
            self.isRepeatAlert = false
            self.authenticateUser()
        }
    }
    
    // MARK: - Init & Deinit
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - My Functions
    
    func showAlert(text text: (String, String, String), action: ((UIAlertAction) -> ())?) {
        let alertController = UIAlertController(title: text.0, message: text.1, preferredStyle: .Alert)
        let action = UIAlertAction(title: text.2, style: .Default, handler: action)
        
        alertController.addAction(action)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func authenticateUser() {
        let context = LAContext()
        var error: NSError?
        let reasonString = "Authentication is needed to protect your passwords."
        let settingsAction: ((UIAlertAction) -> ()) = { action in
            let settingsURL = NSURL(string: UIApplicationOpenSettingsURLString)!
            
            dispatch_async(dispatch_get_main_queue(), { UIApplication.sharedApplication().openURL(settingsURL) })
        }
        
        context.localizedFallbackTitle = ""
        
        guard context.canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: &error) else {
            switch error!.code {
            case LAError.TouchIDNotEnrolled.rawValue:
                self.showAlert(text: ("Touch ID is NOT enrolled", "Please, enroll your fingers!\nSettings -> Touch ID & Passcode", "Settings"), action: settingsAction)
                self.isRepeatAlert = true
            case LAError.TouchIDNotAvailable.rawValue:
                self.showAlert(text: ("Touch ID is NOT available on the device", "Sorry, you can NOT use this application.\nPlease, exit the application", "Okay"), action: nil)
            case LAError.PasscodeNotSet.rawValue:
                self.showAlert(text: ("A passcode has not been set", "Please, set a passcode on your device!\nSettings -> Touch ID & Passcode", "Settings"), action: settingsAction)
                self.isRepeatAlert = true
            case LAError.InvalidContext.rawValue:
                self.showAlert(text: ("Context has been previously invalidated", "Oops... something has gone wrong, please restart the application!", "Ok"), action: nil)
            case LAError.TouchIDLockout.rawValue:
                self.showAlert(text:  ("Authentication was not successful",
                    "There were too many failed Touch ID attempts and Touch ID is now locked. Please, enter your passcode in Settings for unlock Touch ID" +
                    "\nSettings -> Touch ID & Passcode",
                    "Settings"),
                               action: settingsAction)
                self.isRepeatAlert = true
            case LAError.AppCancel.rawValue:
                self.showAlert(text: ("Authentication was canceled by application", "Oops... something has gone wrong, please restart the application!", "Ok"), action: nil)
            default:
                self.showAlert(text: ("Touch ID is NOT available on the device", "Sorry, you can NOT use this application.\nPlease, exit the application", "Okay"), action: nil)
            }
            
            return
        }
        
        context.evaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString, reply: { (success, evalPolicyError) in
            
            if success {
                NSOperationQueue.mainQueue().addOperationWithBlock() {
                    isLocked = false
                    
                    self.delegate?.loadData()
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            } else {
                switch evalPolicyError!.code {
                case LAError.SystemCancel.rawValue, LAError.UserCancel.rawValue, LAError.AuthenticationFailed.rawValue:
                    return
                case LAError.TouchIDLockout.rawValue:
                    NSOperationQueue.mainQueue().addOperationWithBlock() {
                        self.showAlert(text:  ("Authentication was not successful",
                            "There were too many failed Touch ID attempts and Touch ID is now locked. Please, enter your passcode in Settings for unlock Touch ID" +
                            "\nSettings -> Touch ID & Passcode",
                            "Settings"),
                            action: settingsAction)
                    }
                    self.isRepeatAlert = true
                case LAError.AppCancel.rawValue:
                    NSOperationQueue.mainQueue().addOperationWithBlock() {
                        self.showAlert(text: ("Authentication was canceled by application", "Oops... something has gone wrong, please restart the application!", "Ok"), action: nil)
                    }
                case LAError.InvalidContext.rawValue:
                    NSOperationQueue.mainQueue().addOperationWithBlock({
                        self.showAlert(text: ("Context has been previously invalidated", "Oops... something has gone wrong, please restart the application!", "Ok"), action: nil)
                    })
                default:
                    NSOperationQueue.mainQueue().addOperationWithBlock() {
                        self.showAlert(text: ("Authentication failed", "Oops... something has gone wrong, please restart the application!", "Ok"), action: nil)
                    }
                }
            }
            
        })
    }
    
    // MARK: - Views
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let state = UIApplication.sharedApplication().applicationState
        
        if (state == .Active) {
            self.authenticateUser()
        } else {
            self.isRepeatAlert = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: .applicationDidBecomeActive, name: UIApplicationDidBecomeActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: .applicationWillResignActive, name: UIApplicationWillResignActiveNotification, object: nil)
    }
}
