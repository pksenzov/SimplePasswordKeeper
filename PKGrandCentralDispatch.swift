//
//  PKDispatchCancelableClosureFile.swift
//  Records
//
//  Created by Admin on 29/06/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import Foundation

typealias dispatch_cancelable_closure = (_ cancel: Bool) -> Void

func delay(_ time: TimeInterval, closure: @escaping () -> Void) -> dispatch_cancelable_closure? {
    func dispatch_later(_ clsr: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(time * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: clsr)
    }
    
    var closure: (()->())? = closure
    var cancelableClosure: dispatch_cancelable_closure?
    
    let delayedClosure: dispatch_cancelable_closure = { cancel in
        if closure != nil {
            if (cancel == false) {
                DispatchQueue.main.async(execute: closure!)
                //DispatchQueue.main.async(execute: closure as! @convention(block) () -> Void)//
            }
        }
        
        closure = nil
        cancelableClosure = nil
    }
    
    cancelableClosure = delayedClosure
    
    dispatch_later {
        if let delayedClosure = cancelableClosure {
            delayedClosure(false)
        }
    }
    
    return cancelableClosure;
}

func cancel_delay(_ closure: dispatch_cancelable_closure?) {
    if closure != nil {
        closure!(true)
    }
}
