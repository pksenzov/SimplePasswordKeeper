//
//  PKPasswordTransformer.swift
//  SimplePasswordKeeper
//
//  Created by Admin on 18/02/16.
//  Copyright © 2016 pksenzov. All rights reserved.
//

import UIKit

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
    
    // MARK: - NSValueTransformer
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override func transformedValue(value: AnyObject?) -> AnyObject? {
        guard var value = value as? String else {
            return nil
        }
        
        let iv = value.truncate(16)
        
        return try! value.aesEncrypt(strike(), iv: iv!)
    }
    
    override func reverseTransformedValue(value: AnyObject?) -> AnyObject? {
        guard let encData = value as? NSData else {
            return nil
        }
        
        var str = String(NSString(data: encData, encoding: NSUTF8StringEncoding))
        let iv = str.truncate(16)
        
        return try! str.aesDecrypt(strike(), iv: iv!)
    }
}
