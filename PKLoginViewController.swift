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
    
    @IBAction func enterAction(_ sender: UIButton) { self.authenticateUser() }
    
    // MARK: - Notifications
    
    func applicationWillResignActive() {
        if self.presentedViewController != nil {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    func applicationDidBecomeActive() {
        if self.isRepeatAlert && self.presentedViewController == nil {
            self.isRepeatAlert = false
            self.authenticateUser()
        }
    }
    
    // MARK: - Init & Deinit
    
    deinit { NotificationCenter.default.removeObserver(self) }
    
    // MARK: - My Functions
    
    func showAlert(text: (String, String, String), action: ((UIAlertAction) -> ())?) {
        let alertController = UIAlertController(title: text.0, message: text.1, preferredStyle: .alert)
        let action = UIAlertAction(title: text.2, style: .default, handler: action)
        
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func authenticateUser() {
        let context = LAContext()
        var error: NSError?
        let reasonString = "Authentication is needed to protect your passwords."
        let settingsAction: ((UIAlertAction) -> ()) = { action in
            let settingsURL = URL(string: UIApplicationOpenSettingsURLString)!
            
            DispatchQueue.main.async(execute: { UIApplication.shared.openURL(settingsURL) })
        }
        
        context.localizedFallbackTitle = ""
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            switch error!.code {
            case LAError.Code.touchIDNotEnrolled.rawValue:
                self.showAlert(text: ("Touch ID is NOT enrolled", "Please, enroll your fingers!\nSettings -> Touch ID & Passcode", "Settings"), action: settingsAction)
                self.isRepeatAlert = true
            case LAError.Code.touchIDNotAvailable.rawValue:
                self.showAlert(text: ("Touch ID is NOT available on the device", "Sorry, you can NOT use this application.\nPlease, exit the application", "Okay"), action: nil)
            case LAError.Code.passcodeNotSet.rawValue:
                self.showAlert(text: ("A passcode has not been set", "Please, set a passcode on your device!\nSettings -> Touch ID & Passcode", "Settings"), action: settingsAction)
                self.isRepeatAlert = true
            case LAError.Code.invalidContext.rawValue:
                self.showAlert(text: ("Context has been previously invalidated", "Oops... something has gone wrong, please restart the application!", "Ok"), action: nil)
            case LAError.Code.touchIDLockout.rawValue:
                self.showAlert(text:  ("Authentication was not successful",
                    "There were too many failed Touch ID attempts and Touch ID is now locked. Please, enter your passcode in Settings for unlock Touch ID" +
                    "\nSettings -> Touch ID & Passcode",
                    "Settings"),
                               action: settingsAction)
                self.isRepeatAlert = true
            case LAError.Code.appCancel.rawValue:
                self.showAlert(text: ("Authentication was canceled by application", "Oops... something has gone wrong, please restart the application!", "Ok"), action: nil)
            default:
                self.showAlert(text: ("Touch ID is NOT available on the device", "Sorry, you can NOT use this application.\nPlease, exit the application", "Okay"), action: nil)
            }
            
            return
        }
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString, reply: { (success, evalPolicyError) in
            
            if success {
                OperationQueue.main.addOperation() {
                    isLocked = false
                    
                    self.delegate?.loadData()
                    
                    if isSpotlightWaiting {
                        isSpotlightWaiting = false
                        
                        let rootVC = UIApplication.shared.windows.first?.rootViewController
                        rootVC?.dismiss(animated: true, completion: nil)
                    } else {
                        if self.presentingViewController is PKBlankViewController {
                            let blankVC = self.presentingViewController
                            blankVC?.presentingViewController?.dismiss(animated: true, completion: nil)
                        } else {
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                }
            } else {
                switch (evalPolicyError! as NSError).code {
                case LAError.Code.systemCancel.rawValue, LAError.Code.userCancel.rawValue, LAError.Code.authenticationFailed.rawValue:
                    return
                case LAError.Code.touchIDLockout.rawValue:
                    OperationQueue.main.addOperation() {
                        self.showAlert(text:  ("Authentication was not successful",
                            "There were too many failed Touch ID attempts and Touch ID is now locked. Please, enter your passcode in Settings for unlock Touch ID" +
                            "\nSettings -> Touch ID & Passcode",
                            "Settings"),
                            action: settingsAction)
                    }
                    self.isRepeatAlert = true
                case LAError.Code.appCancel.rawValue:
                    OperationQueue.main.addOperation() {
                        self.showAlert(text: ("Authentication was canceled by application", "Oops... something has gone wrong, please restart the application!", "Ok"), action: nil)
                    }
                case LAError.Code.invalidContext.rawValue:
                    OperationQueue.main.addOperation({
                        self.showAlert(text: ("Context has been previously invalidated", "Oops... something has gone wrong, please restart the application!", "Ok"), action: nil)
                    })
                default:
                    OperationQueue.main.addOperation() {
                        self.showAlert(text: ("Authentication failed", "Oops... something has gone wrong, please restart the application!", "Ok"), action: nil)
                    }
                }
            }
            
        })
    }
    
    // MARK: - Views
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: .applicationDidBecomeActive, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: .applicationWillResignActive, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let state = UIApplication.shared.applicationState
        
        if (state == .active) {
            self.authenticateUser()
        } else {
            self.isRepeatAlert = true
        }
    }
}
