//
//  PKPasswordTransformer.swift
//  SimplePasswordKeeper
//
//  Created by Admin on 18/02/16.
//  Copyright © 2016 Pavel Ksenzov. All rights reserved.
//

import CryptoSwift

private extension String {
    func aesDecrypt(_ key: String, iv: String) throws -> String {
        let data = Data(base64Encoded: self, options: Data.Base64DecodingOptions(rawValue: 0))
        
        do {
            let dataArr = data!.withUnsafeBytes() { [UInt8](UnsafeBufferPointer(start: $0, count: data!.count)) }
            let dec = try AES(key: key, iv: iv, blockMode: .CBC, padding: PKCS7()).decrypt(dataArr)
            let decData = Data(bytes: dec, count: Int(dec.count))
            //let decData = Data(bytes: dec, length: Int(dec.count))
            let result = NSString(data: decData, encoding: String.Encoding.utf8.rawValue)
            return String(result!)
        } catch {
            // some error
        }
        
        return ""
    }
    
    func aesEncrypt(_ key: String, iv: String) throws -> Data {
        let data = self.data(using: String.Encoding.utf8)
        
        do {
            let dataArr = data!.withUnsafeBytes() { [UInt8](UnsafeBufferPointer(start: $0, count: data!.count)) }
            let enc = try AES(key: key, iv: iv, blockMode: .CBC, padding: PKCS7()).encrypt(dataArr)
            let encData = Data(bytes: enc, count: Int(enc.count))
            let base64String: String = encData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
            let result = iv + String(base64String)
            let dataResult = result.data(using: String.Encoding.utf8)
            
            return dataResult!
        } catch {
            // some error
        }
        
        return Data()
    }
    
    mutating func truncate(_ count: Int) -> String? {
        guard count > 0 && count < self.characters.count else { return nil }
        
        var newString = self
        let start = self.startIndex
        let end = self.characters.index(self.startIndex, offsetBy: count)
        let range = start..<end
        
        newString = self.substring(to: end)
        self.removeSubrange(range)
        
        return newString
    }
}

@objc(PKPasswordTransformer)
private class PKPasswordTransformer: ValueTransformer {
    let luckystrike = "kOFAwgHmSrfeMFs8fY0FlAejm9nSUVeFgEA5MehV1QcyIayyCsocD1LDW0de2czqUt2DAPeWhXfpAVAKPtry2rdFTlMPn8iL273PDyErA3QhN103em8yWdizTDCdpJSWkO187kTuXubFyOM97iHQKZ2FRxjCGvvMOuYffwqIfYgCKSjCJHGynJOLXPJ0gA2ZgAI7oZkp7k5G9qdAuJYHhADTLkSYgn3p5gnncK8LZwzlXSP2M3BPAt4WhDzS6g0jlHHK6YALmqgChiRTFEN6ufNpABqYQzPCGDQOxXJPxhWBgrgyLIuWgz2UWnkEsgrMTaCegtRP56Uia01KxznrLvQfYzO3xmeK31460KF2tvHmdd3VJJ3qWeBT1dVLz1h6MP6V7wTCQzhg79iuBrdYHdpOhj8Gr5NfIGiu5ZlcuTKFfiTEGQamsaKqU4Y4J35LbanWHY5Yi0Hz7Q5CJ26zpVhHPJWXt1plBAhFcik4SVKMNA1skSybUwtG98wsZh5puB1qegYXCudYYCcPGqKeVMEI9xB7Ms60ZCyYNKkZI1vSw9lCohxhq57QsbQmTbxYzEJKpyh0qOpcuxaayH7pze327VeCE5wLUN0bDjTH4Lk0z69bRvgB9do5772g0AvYVaulXZhnl1WxX4y1icDBPQ76UMdSWM1VHXKz6CanRN0dqjOyMTNQpSoWOJ7I9izJpkJWxFsdnQp8KnoU2z22hD3InYGeMuj495nT4AvmerPy3NMEJVY043t1GKwIlmZimjXLeX7garnyxgfcIxPQemzlVevxengZtE2Y4CTJLs0cJdOlETN9RcaehtZi6crKHYfo91ipUANLJBVMJcgURhiVcPvQV7bmY9jdD4JOp0PmnjhHZNHOdQ9Y9aNFrpUFS40gXuupyV7gK5xMGv3wJndnOUKz3NEv54R4pcJmYy3QnSCAFi9Ax3he5mLGumUxzgphve87uIK8bQ4qejd5BQWcSxvc3n4GJ0ZxKdVMi5Laomo6AgrFzKTOwhYIgbEW"
    
    // MARK: - My Functions
    
    func strike() -> String {
        var value = ""
        
        for (i, char) in self.luckystrike.characters.enumerated() {
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
            iv += String(letters[letters.index(letters.startIndex, offsetBy: index)])
        }
        
        return iv
    }
    
    // MARK: - NSValueTransformer
    
//    open class func setValueTransformer(_ transformer: ValueTransformer?, forName name: NSValueTransformerName)
//    open class func valueTransformerNames() -> [NSValueTransformerName]
//
//    open class func transformedValueClass() -> Swift.AnyClass
//    open class func allowsReverseTransformation() -> Bool
//
//    open func transformedValue(_ value: Any?) -> Any?
//    open func reverseTransformedValue(_ value: Any?) -> Any?
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        if let value = value as? Data {
            return value
        }
        
        guard let value = value as? String else {
            return nil
        }
        
        return try! NSData(data: value.aesEncrypt(strike(), iv: getInitVector()))
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let encData = value as? Data else {
            return nil
        }
        
        var str = NSString(data: encData, encoding: String.Encoding.utf8.rawValue) as! String
        let iv = str.truncate(16)
        
        return try! str.aesDecrypt(strike(), iv: iv!)
    }
}
