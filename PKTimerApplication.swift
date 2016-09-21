//
//  PKTimerApplication.swift
//  Records
//
//  Created by Admin on 29/06/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import UIKit

class PKTimerApplication: UIApplication {
    var idleTimer       : dispatch_cancelable_closure?
    var idleClearTimer  : dispatch_cancelable_closure?
    
    override init() {
        super.init()
        self.resetIdleTimer()
        self.resetClearIdleTimer()
    }
    
    // MARK: - AutoLock Timer
    
    override func sendEvent(_ event: UIEvent) {
        super.sendEvent(event)
        
        if let allTouches = event.allTouches {
            if allTouches.count > 0 {
                let phase = allTouches.first?.phase
                if phase == .began {
                    self.resetIdleTimer()
                }
            }
        }
    }
    
    func resetIdleTimer() {
        cancel_delay(self.idleTimer)
        
        let seconds = Double(UserDefaults.standard.integer(forKey: kSettingsAutoLock) * 60)
        self.idleTimer = delay(seconds) { self.idleTimerExceeded() }
    }
    
    func idleTimerExceeded() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: kApplicationDidTimeoutNotification), object: nil)
        self.resetIdleTimer()
    }
    
    // MARK: - ClearClipboard Timer
    
    func resetClearIdleTimer() {
        cancel_delay(self.idleClearTimer)
        
        let seconds = Double(UserDefaults.standard.integer(forKey: kSettingsClearClipboard))
        guard seconds != 0 else { return }
        
        self.idleClearTimer = delay(seconds) { self.clearIdleTimerExceeded() }
    }
    
    func clearIdleTimerExceeded() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: kApplicationDidTimeoutClearNotification), object: nil)
        //self.resetClearIdleTimer()
    }
    
    func cancelClearTimer() {
        cancel_delay(self.idleClearTimer)
    }
}
