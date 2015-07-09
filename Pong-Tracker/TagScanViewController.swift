//
//  TagScanViewController.swift
//  Pong-Tracker
//
//  Created by Christian Gossain on 2015-07-05.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

protocol TagScanViewControllerDelegate {
    
    func tagScanViewControllerDidCancel(controller: TagScanViewController)
    func tagScanViewController(controller: TagScanViewController, didSelectTag tag: String?)
    
}

class TagScanViewController: UIViewController {
    
    /// The player that is being edited
    var player: Player?
    
    var delegate: TagScanViewControllerDelegate?
    var scannedTag: String?
    var managedObjectContext: NSManagedObjectContext {
        return GSCoreDataManager.sharedManager().managedObjectContext
    }
    
    @IBOutlet weak var informationLabel: UILabel!
    
    // MARK: - Initialization
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: ControlPadViewControllerRFIDTagScannedNotification, object: nil)
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // popover size
        self.preferredContentSize = CGSize(width: 400.0, height: 120.0)
        
        // Do any additional setup after loading the view.
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Clear", style: .Plain, target: self, action: "clearButtonTapped:")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "saveButtonTapped:")
        
        // start listening for scans
        self.scanStateWaitingForScan()
        
        // register for scan notifications
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "tagScannedNotificationReceived:",
            name: ControlPadViewControllerRFIDTagScannedNotification,
            object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Methods (Private)

    func tagScannedNotificationReceived(note: NSNotification) {
        // extract the scanned tag
        self.scannedTag = note.userInfo?[ControlPadScannedTagKey] as? String
        
        if let tag = self.scannedTag {
            println("The scanned RFID code is: \(tag)")
            
            // check if the tag is already associated with a player
            let fetchRequest = NSFetchRequest(entityName: "Player")
            fetchRequest.predicate = NSPredicate(format: "tagID == %@", tag)
            
            // execute the request
            var error: NSError? = nil
            let results = self.managedObjectContext.executeFetchRequest(fetchRequest, error: &error) as! [Player]
            
            if results.isEmpty {
                // no match
                self.scanStateSuccessfulWithTag(tag);
            }
            else {
                // there is a match
                let player = results.first!
                
                // clear out the currently stored tag
                self.scannedTag = nil
                
                // a player is already associated with this tag
                self.scanStateFailedWithExistingPlayer(player)
            }
        }
    }
    
    // MARK: - Methods (Scan States)
    
    func scanStateSuccessfulWithTag(tag: String) {
        self.view.backgroundColor = kGreenColor
        self.informationLabel.text = "The scanned tag is \n \(tag)"
        
        // disable the save button
        self.navigationItem.rightBarButtonItem?.enabled = true;
    }
    
    func scanStateFailedWithExistingPlayer(player: Player) {
        self.view.backgroundColor = kRedColor
        
        if let editingPlayer = self.player where editingPlayer == player {
            // this tag is already associated with this player
            self.informationLabel.text = "This tag is already associated with your profile."
        }
        else {
            // this tag is already associated with another player
            if let firstName = player.firstName, let lastName = player.lastName {
                self.informationLabel.text = "This tag is already associated with:\n" + "\(firstName)" + " " + "\(lastName)"
            }
            else {
                self.informationLabel.text = "This tag is already associated with an existing player."
            }
        }
        
        // disable the save button
        self.navigationItem.rightBarButtonItem?.enabled = false;
    }
    
    func scanStateWaitingForScan() {
        self.view.backgroundColor = kBlueColor
        self.informationLabel.text = "Scan an RFID tag..."
        
        // disable the save button
        self.navigationItem.rightBarButtonItem?.enabled = false;
    }
    
    // MARK: - Selectors
    
    func clearButtonTapped(sender: UIBarButtonItem) {
        // clear the tag by passing back nil
        self.delegate?.tagScanViewController(self, didSelectTag: nil)
    }
    
    func saveButtonTapped(sender: UIBarButtonItem) {
        if let tag = self.scannedTag {
            self.delegate?.tagScanViewController(self, didSelectTag: tag)
        }
        else {
            self.delegate?.tagScanViewControllerDidCancel(self)
        }
    }

}
