//
//  PKTimerApplication.swift
//  Records
//
//  Created by Admin on 29/06/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import UIKit

class PKTimerApplication: UIApplication {
    var idleTimer: dispatch_cancelable_closure?
    
    override init() {
        super.init()
        self.resetIdleTimer()
    }
    
    override func sendEvent(event: UIEvent) {
        super.sendEvent(event)
        
        if let allTouches = event.allTouches() {
            if allTouches.count > 0 {
                let phase = allTouches.first?.phase
                if phase == .Began {
                    self.resetIdleTimer()
                }
            }
        }
    }
    
    func resetIdleTimer() {
        cancel_delay(self.idleTimer)
        
        let seconds = Double(NSUserDefaults.standardUserDefaults().integerForKey(kSettingsAutoLock) * 60)
        self.idleTimer = delay(seconds) { self.idleTimerExceeded() }
    }
    
    func idleTimerExceeded() {
        NSNotificationCenter.defaultCenter().postNotificationName(kApplicationDidTimeoutNotification, object: nil)
        self.resetIdleTimer()
    }
}
