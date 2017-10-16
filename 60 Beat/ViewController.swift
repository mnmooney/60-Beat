//
//  ViewController.swift
//  60 Beat
//
//  Created by Michael Mooney on 21/12/2015.
//  Copyright © 2015 Michael Mooney. All rights reserved.
//

import UIKit
import HealthKit
import iAd

class ViewController: UIViewController, ADBannerViewDelegate {
    
    let HealthStore = HKHealthStore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.canDisplayBannerAds = true
        // Do any additional setup after loading the view, typically from a nib.
        
        if let sleepType = HKObjectType.categoryTypeForIdentifier(HKQuantityTypeIdentifierHeartRate) {
            
            let setType = Set<HKSampleType>(arrayLiteral: sleepType)
            HealthStore.requestAuthorizationToShareTypes(setType, readTypes: setType, completion: { (success, error) -> Void in
                // here is your code
            })
        }
        self.alertController.addAction(destroyAction)
        self.alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true) {
            // ...
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    let alertController = UIAlertController(title: "HealthKit", message: "HealthKit is used within the apple watch to gather information of your heat rate. The infromation is immediatly erased at the end of each game.", preferredStyle: .Alert)
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
        print(action)
    }
    
    
    let destroyAction = UIAlertAction(title: "OK", style: .Destructive) { (action) in
        print(action)
    }
}

