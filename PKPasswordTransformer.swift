//
//  PKPasswordTransformer.swift
//  SimplePasswordKeeper
//
//  Created by Admin on 18/02/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import UIKit
import CryptoSwift

private extension String {
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

@objc(PKPasswordTransformer)
private class PKPasswordTransformer: NSValueTransformer {
    let luckystrike = "kOFAwgHmSrfeMFs8fY0FlAejm9nSUVeFgEA5MehV1QcyIayyCsocD1LDW0de2czqUt2DAPeWhXfpAVAKPtry2rdFTlMPn8iL273PDyErA3QhN103em8yWdizTDCdpJSWkO187kTuXubFyOM97iHQKZ2FRxjCGvvMOuYffwqIfYgCKSjCJHGynJOLXPJ0gA2ZgAI7oZkp7k5G9qdAuJYHhADTLkSYgn3p5gnncK8LZwzlXSP2M3BPAt4WhDzS6g0jlHHK6YALmqgChiRTFEN6ufNpABqYQzPCGDQOxXJPxhWBgrgyLIuWgz2UWnkEsgrMTaCegtRP56Uia01KxznrLvQfYzO3xmeK31460KF2tvHmdd3VJJ3qWeBT1dVLz1h6MP6V7wTCQzhg79iuBrdYHdpOhj8Gr5NfIGiu5ZlcuTKFfiTEGQamsaKqU4Y4J35LbanWHY5Yi0Hz7Q5CJ26zpVhHPJWXt1plBAhFcik4SVKMNA1skSybUwtG98wsZh5puB1qegYXCudYYCcPGqKeVMEI9xB7Ms60ZCyYNKkZI1vSw9lCohxhq57QsbQmTbxYzEJKpyh0qOpcuxaayH7pze327VeCE5wLUN0bDjTH4Lk0z69bRvgB9do5772g0AvYVaulXZhnl1WxX4y1icDBPQ76UMdSWM1VHXKz6CanRN0dqjOyMTNQpSoWOJ7I9izJpkJWxFsdnQp8KnoU2z22hD3InYGeMuj495nT4AvmerPy3NMEJVY043t1GKwIlmZimjXLeX7garnyxgfcIxPQemzlVevxengZtE2Y4CTJLs0cJdOlETN9RcaehtZi6crKHYfo91ipUANLJBVMJcgURhiVcPvQV7bmY9jdD4JOp0PmnjhHZNHOdQ9Y9aNFrpUFS40gXuupyV7gK5xMGv3wJndnOUKz3NEv54R4pcJmYy3QnSCAFi9Ax3he5mLGumUxzgphve87uIK8bQ4qejd5BQWcSxvc3n4GJ0ZxKdVMi5Laomo6AgrFzKTOwhYIgbEW"
    
    // MARK: - My Functions
    
    func strike() -> String {
        var value = ""
        
        for (i, char) in luckystrike.characters.enumerate() {
            if i % 21 == 0 {
                value += String(char)
            }
            
            if value.characters.count == 32 {
                return value
            }
        }
        
        return value
    }
    
    
    // FIXME - NEED USE IV GENERATOR
    
    func getInitVector() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let count = UInt32(letters.characters.count)
        var iv = ""
        
        for _ in 0..<16 {
            let index = Int(arc4random_uniform(count))
            iv += String(letters[letters.startIndex.advancedBy(index)])
        }
        
        return iv
    }
    
    // MARK: - NSValueTransformer
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override func transformedValue(value: AnyObject?) -> AnyObject? {
        guard let value = value as? String else {
            return nil
        }
        
        return try! value.aesEncrypt(strike(), iv: getInitVector())
    }
    
    override func reverseTransformedValue(value: AnyObject?) -> AnyObject? {
        guard let encData = value as? NSData else {
            return nil
        }
        
        var str = NSString(data: encData, encoding: NSUTF8StringEncoding) as! String
        let iv = str.truncate(16)
        
        return try! str.aesDecrypt(strike(), iv: iv!)
    }
}
