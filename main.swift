//
//  main.swift
//  Records
//
//  Created by Admin on 29/06/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import Foundation
import UIKit

UIApplicationMain(CommandLine.argc,
                  UnsafeMutableRawPointer(CommandLine.unsafeArgv).bindMemory(to: UnsafeMutablePointer<Int8>.self, capacity: Int(CommandLine.argc)),
                  NSStringFromClass(PKTimerApplication.self),
                  NSStringFromClass(PKAppDelegate.self))
