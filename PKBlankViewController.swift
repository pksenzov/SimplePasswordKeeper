//
//  PKBlankViewController.swift
//  Records
//
//  Created by Admin on 30/06/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import UIKit

private extension Selector {
    static let applicationDidBecomeActive = #selector(PKBlankViewController.applicationDidBecomeActive)
}

class PKBlankViewController: UIViewController {
    
    // MARK: - Notifications
    
    func applicationDidBecomeActive() {
        if self.presentedViewController == nil { self.dismiss(animated: false, completion: nil) }
    }
    
    // MARK: - Init & Deinit
    
    deinit { NotificationCenter.default.removeObserver(self) }
    
    // MARK: - Views
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: .applicationDidBecomeActive, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
}
