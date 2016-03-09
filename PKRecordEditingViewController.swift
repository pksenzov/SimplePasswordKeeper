//
//  PKRecordEditingViewController.swift
//  SimplePasswordKeeper
//
//  Created by Admin on 19/02/16.
//  Copyright © 2016 pksenzov. All rights reserved.
//

import UIKit

class PKRecordEditingViewController: UIViewController {

    // MARK: - Views
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Actions
    
    @IBAction func doneAction(sender: UIBarButtonItem) {
        //Validate required fields
        
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let count = UInt32(letters.characters.count)
        var initVector = ""
        
        for _ in 0..<16 {
            let index = Int(arc4random_uniform(count))
            
            initVector += String(letters[letters.startIndex.advancedBy(index)])
        }
        
        //let password = initVector + "1234"
        
        //if true - generate iv, save static iv
        
        //save context, password(iv+password)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
