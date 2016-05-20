//
//  AppDelegate.swift
//  SimplePasswordKeeper
//
//  Created by Admin on 12/02/16.
//  Copyright © 2016 pksenzov. All rights reserved.
//

import UIKit
import CryptoSwift

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

extension String {
    func aesDecrypt(key: String, iv: String) throws -> String {
        let data = NSData(base64EncodedString: self, options: NSDataBase64DecodingOptions(rawValue: 0))
        //let dec = try AES(key: key, iv: iv, blockMode:.CBC).decrypt(data!.arrayOfBytes(), padding: PKCS7())
        
        do {
            let dec = try AES(key: key, iv: iv, blockMode: .CBC, padding: PKCS7()).decrypt(data!.arrayOfBytes())
            let decData = NSData(bytes: dec, length: Int(dec.count))
            let result = NSString(data: decData, encoding: NSUTF8StringEncoding)
            return String(result!)
        } catch AES.Error.BlockSizeExceeded {
            // block size exceeded
        } catch {
            // some error
        }
        
        return ""
    }
    
    func aesEncrypt(key: String, iv: String) throws -> NSData {
        let data = self.dataUsingEncoding(NSUTF8StringEncoding)
        //let enc = try AES(key: key, iv: iv, blockMode:.CBC).encrypt(data!.arrayOfBytes(), padding: PKCS7())
        do {
            let enc = try AES(key: key, iv: iv, blockMode: .CBC, padding: PKCS7()).encrypt(data!.arrayOfBytes())
            let encData = NSData(bytes: enc, length: Int(enc.count))
            let base64String: String = encData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0));
            let result = iv + String(base64String)
            let dataResult = result.dataUsingEncoding(NSUTF8StringEncoding)
            
            return dataResult!
        } catch AES.Error.BlockSizeExceeded {
            // block size exceeded
        } catch {
            // some error
        }
        
        return NSData()
    }
    
    mutating func truncate(count: Int) -> String? {
        guard count > 0 && count < self.characters.count else { return nil }
        
        var newString = self
        let start = self.startIndex
        let end = self.startIndex.advancedBy(count)
        let range = start..<end
        
        newString = self.substringToIndex(end)
        self.removeRange(range)
        
        return newString
    }
}

@UIApplicationMain
class PKAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        PKCoreDataManager.sharedManager.saveContext()
    }
}

