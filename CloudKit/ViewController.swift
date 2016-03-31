//
//  ViewController.swift
//  CloudKit
//
//  Created by Nam (Nick) N. HUYNH on 3/30/16.
//  Copyright (c) 2016 Enclave. All rights reserved.
//

import UIKit
import CloudKit

class ViewController: UIViewController {

    let container = CKContainer.defaultContainer()
    lazy var operationQueue = NSOperationQueue()
    
    enum MotobikeType: String {
        
        case Saving = "Saving"
        case HighQuality = "HighQuality"
        
        func zoneId() -> CKRecordZoneID {
            
            let zoneId = CKRecordZoneID(zoneName: self.rawValue, ownerName: CKOwnerDefaultName)
            return zoneId
            
        }
        
        func zone() -> CKRecordZone {
            
            return CKRecordZone(zoneID: self.zoneId())
            
        }
        
    }
    
    func recordId(#type: MotobikeType) -> CKRecordID {
        
        let key = "recordId"
        var recordName = NSUserDefaults.standardUserDefaults().stringForKey(key)
        if let record = recordName {
            
            if countElements(record) == 0 {
                
                recordName = NSUUID().UUIDString
                NSUserDefaults.standardUserDefaults().setValue(recordName, forKey: key)
                NSUserDefaults.standardUserDefaults().synchronize()
                
            } else {
                
                println("Previous generated record ID was recovered.")
                
            }
            
        } else {
            
            recordName = NSUUID().UUIDString
            NSUserDefaults.standardUserDefaults().setValue(recordName, forKey: key)
            NSUserDefaults.standardUserDefaults().synchronize()
            
        }
        return CKRecordID(recordName: recordName, zoneID: type.zoneId())
        
    }
    
    func motobikeWithType(type: MotobikeType) -> CKRecord {

        let motobike = CKRecord(recordType: "MyMotobike", recordID: recordId(type: type))
        return motobike
        
    }
    
    func motobikeWithType(type: MotobikeType, maker: String, model: String, year: Int) -> CKRecord {
        
        let record = motobikeWithType(type)
        record.setValue(maker, forKey: "maker")
        record.setValue(model, forKey: "model")
        record.setValue(year, forKey: "year")
        
        return record
        
    }
    
    func savingMotobikeWithMaker(maker: String, model: String, year: Int) -> CKRecord {
        
        return motobikeWithType(MotobikeType.Saving, maker: maker, model: model, year: year)
        
    }
    
    func highQuailityMotobikeWithMaker(maker: String, model: String, year: Int) -> CKRecord {
        
        return motobikeWithType(MotobikeType.HighQuality, maker: maker, model: model, year: year)
        
    }
    
    func saveAllClosure(record: CKRecord!, error: NSError!) {
        
        if error != nil {
            
            println("Failed with error: \(error)")
            
        } else {
            
            println("Successfully saved with type: \(record.recordType)")
            
        }
        
    }
    
    func saveMotobikes(motobikes: [CKRecord], inDatabase: CKDatabase!) {
        
        for motobike in motobikes {
            
            inDatabase.saveRecord(motobike, completionHandler: saveAllClosure)
            
        }
        
    }
    
    func saveSavingMotobikesInDatabase(database: CKDatabase!) {
        
        let waveAlpha = savingMotobikeWithMaker("Honda", model: "WaveAlpha", year: 2000)
        let waveRSX = savingMotobikeWithMaker("Honda", model: "WaveRSX", year: 2009)
        let dream = savingMotobikeWithMaker("Honda", model: "Dream", year: 1995)
        let sirius = savingMotobikeWithMaker("Yamaha", model: "Sirius", year: 2013)
        
        println("Saving...")
        saveMotobikes([waveAlpha, waveRSX, dream, sirius], inDatabase: database)
        
    }
    
    func saveHighQualityMotobikesInDatabase(database: CKDatabase!) {
        
        let exciter = highQuailityMotobikeWithMaker("Yamaha", model: "Exciter", year: 2016)
        let airblade = highQuailityMotobikeWithMaker("Honda", model: "Airblade", year: 2016)
        
        println("Saving...")
        saveMotobikes([exciter, airblade], inDatabase: database)
        
    }
    
    func saveMotobikesForType(type: MotobikeType, inDatabase: CKDatabase!) {
        
        switch type {
            
        case MotobikeType.Saving:
            saveSavingMotobikesInDatabase(inDatabase)
        case MotobikeType.HighQuality:
            saveHighQualityMotobikesInDatabase(inDatabase)
        default:
            println("Unknown")
            
        }
        
    }
    
    func useOrSaveZone(#zoneIsCreatedAlready: Bool, forMotobikeType: MotobikeType, inDatabase: CKDatabase!) {
        
        if zoneIsCreatedAlready {
            
            println("Found the \(forMotobikeType.rawValue) zone.")
            saveMotobikesForType(forMotobikeType, inDatabase: inDatabase)
            
        } else {
            
            inDatabase.saveRecordZone(forMotobikeType.zone(), completionHandler: { (zone, error) -> Void in
                
                if error != nil {
                    
                    println("Could not save the zone.")
                    
                } else {
                    
                    println("Successfully saved the zone")
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        
                        self.saveMotobikesForType(forMotobikeType, inDatabase: inDatabase)
                        
                    })
                    
                }
                
            })
            
        }
        
    }
    
    func applicationBecameActive(notification: NSNotification) {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleIdentityChanged:", name: NSUbiquityIdentityDidChangeNotification, object: nil)
        
    }
    
    func applicationBecameInActive(notification: NSNotification) {
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSUbiquityIdentityDidChangeNotification, object: nil)
        
    }
    
    func handleIdentityChanged(notification: NSNotification) {
        
        let fileManager = NSFileManager()
        if let token = fileManager.ubiquityIdentityToken {
            
            println("New token is \(token)")
            
        } else {
            
            println("User has logged out!")
            
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(animated)
        container.accountStatusWithCompletionHandler { (status, error) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                var title: String?
                var message: String?
                if error != nil {
                    
                    title = "Error"
                    message = "\(error)"
                    
                } else {
                    
                    switch status {
                        
                    case CKAccountStatus.Available:
                        message = "User is logged in!"
                        let database = self.container.privateCloudDatabase
                                            
                        let makerToLookFor = "Honda"
                        let smallestYearToLookFor = 2005
                        
                        let predicate = NSPredicate(format: "maker = %@ AND year >= %@", makerToLookFor, smallestYearToLookFor as NSNumber)
                        let query = CKQuery(recordType: "MyMotobike", predicate: predicate)
                        
                        let operation = CKQueryOperation(query: query)
                        operation.recordFetchedBlock = { (record) -> Void in
                            
                            println("Fetched a record = \(record)")
                            
                        }
                        
                        operation.queryCompletionBlock = { (cursor, error) -> Void in
                            
                            if cursor != nil {
                                
                                println("A cursor was sent to us. Fetching the rest of the records...")
                                let newOperation = CKQueryOperation(cursor: cursor)
                                newOperation.recordFetchedBlock = { (record) -> Void in
                                    
                                    println("Fetched a record = \(record)")
                                    
                                }
                                newOperation.queryCompletionBlock = operation.queryCompletionBlock
                                self.operationQueue.addOperation(newOperation)
                                
                            } else {
                                
                                println("No cursor came back.")
                                
                            }
                            
                        }
                        
                        self.operationQueue.addOperation(operation)
                        
                        database.performQuery(query, inZoneWithID: MotobikeType.Saving.zoneId(), completionHandler: { (records, error) -> Void in
                            
                            if error != nil {
                                
                                println("Error: \(error)")
                                
                            } else {
                                
                                for record in records {
                                    
                                    println("Record: \(record)")
                                    
                                }
                                
                            }
                            
                        })
                        
                        database.fetchAllRecordZonesWithCompletionHandler({ (zones, error) -> Void in
                            
                            if error != nil {
                                
                                println("Could not retrive the zones")
                                
                            } else {
                                
                                var foundSavingZone = false
                                var foundHighQualityZone = false
                                for zone in zones as [CKRecordZone] {
                                    
                                    if zone.zoneID.zoneName == MotobikeType.Saving.rawValue {
                                        
                                        database.fetchRecordWithID(self.recordId(type: MotobikeType.Saving), completionHandler: { (record, error) -> Void in
                                            
                                            if error != nil {
                                                
                                                println("Error: \(error)")
                                                
                                            } else {
                                                
                                                record.setValue(2015, forKey: "year")
                                                database.saveRecord(record, completionHandler: { (record, error) -> Void in
                                                    
                                                    if error != nil {
                                                        
                                                        println("Error: \(error)")
                                                        
                                                    } else {
                                                        
                                                        println("Edited Record!")
                                                        
                                                    }
                                                    
                                                })
                                                
                                            }
                                            
                                        })
                                        foundSavingZone = true
                                        
                                    } else if zone.zoneID.zoneName == MotobikeType.HighQuality.rawValue {
                                        
                                        foundHighQualityZone = true
                                        
                                    }
                                    
                                }
                                
                                self.useOrSaveZone(zoneIsCreatedAlready: foundSavingZone, forMotobikeType: MotobikeType.Saving, inDatabase: database)
                                self.useOrSaveZone(zoneIsCreatedAlready: foundHighQualityZone, forMotobikeType: MotobikeType.HighQuality, inDatabase: database)
                                
                            }
                            
                        })
                        
                    case CKAccountStatus.CouldNotDetermine:
                        message = "Could not determine"
                    case CKAccountStatus.NoAccount:
                        message = "No account"
                    case CKAccountStatus.Restricted:
                        message = "Restricted"
                        
                    }
                    
                }
                
                self.displayAlertWithTitle(title, message:message)
                
            })
            
        }
        
    }
    
    func displayAlertWithTitle(title: String?, message: String?) {
        
        let controller = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        controller.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        presentViewController(controller, animated: true, completion: nil)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationBecameActive:", name: UIApplicationDidBecomeActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationBecameInActive:", name: UIApplicationWillResignActiveNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

