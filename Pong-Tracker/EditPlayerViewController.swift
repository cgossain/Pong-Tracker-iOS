//
//  EditPlayerViewController.swift
//  Pong-Tracker
//
//  Created by Christian Gossain on 2015-06-30.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

let kAvatarCellIdentifier = "com.pong-tracker.avatarcell"
let kPlayerCellIdentifier = "com.pong-tracker.playercell"

protocol EditPlayerViewControllerDelegate {
    func editPlayerViewControllerDidFinish(controller: EditPlayerViewController)
}

class EditPlayerViewController: UITableViewController {
    
    var delegate: EditPlayerViewControllerDelegate?
    var player: Player?
    var managedObjectContext: NSManagedObjectContext { return GSCoreDataManager.sharedManager().managedObjectContext }
    var isCreatingNewPlayer = true
    
    // MARK: - View Lifecycle
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch (segue.identifier, segue.destinationViewController) {
        case let (identifier, vc as UINavigationController) where identifier == "ScanTag":
            if let viewController = vc.topViewController as? TagScanViewController {
                viewController.delegate = self
                viewController.player = self.player
            }
        default:
            break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // register cell
        self.tableView.registerClass(AvatarTableViewCell.self, forCellReuseIdentifier: kAvatarCellIdentifier)
        self.tableView.registerClass(TextFieldTableViewCell.self, forCellReuseIdentifier: kPlayerCellIdentifier)
        
        self.tableView.estimatedRowHeight = 60.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        // bar button items
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelBarButtonItemTapped:")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "saveBarButtonItemTapped:")
        
        if self.player == nil {
            // create a new player
            self.isCreatingNewPlayer = true
        }
        else {
            // editing an existing player
            self.isCreatingNewPlayer = false
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // if there is no player, create a new one
        if self.player == nil {
            self.player = Player.createInManagedObjectContext(self.managedObjectContext)
            
            // reload the table (configures binds cells to the player)
            self.tableView.reloadData()
        }
        
        // update buttons
        self.updateButtonStates()
    }
    
    // MARK: - Methods (Private)
    
    func updateButtonStates() {
        if let firstName = self.player?.firstName, let lastName = self.player?.lastName where !firstName.isEmpty && !lastName.isEmpty {
            // first name and last name are be required
            self.navigationItem.rightBarButtonItem?.enabled = true;
        }
        else {
            self.navigationItem.rightBarButtonItem?.enabled = false;
        }
    }
    
    func deletePlayer() {
        if let p = self.player {
            // delete the player
            self.managedObjectContext.deleteObject(p);
            
            // save the change
            GSCoreDataManager.sharedManager().saveContext()
        }
        
        // notify the delegate
        self.delegate?.editPlayerViewControllerDidFinish(self)
    }
    
    // MARK: - Selectors
    
    func cancelBarButtonItemTapped(sender: UIBarButtonItem) {
        // cancel the player creation/editing
        if let p = self.player {
            if self.isCreatingNewPlayer {
                // delete the created player
                self.managedObjectContext.deleteObject(p);
            }
            else {
                // reset the object
                self.managedObjectContext.refreshObject(p, mergeChanges: false)
            }
        }
        
        
        // notify the delegate
        self.delegate?.editPlayerViewControllerDidFinish(self)
    }
    
    func saveBarButtonItemTapped(sender: UIBarButtonItem) {
        // save the changes
        GSCoreDataManager.sharedManager().saveContext()
        
        // notify the delegate
        self.delegate?.editPlayerViewControllerDidFinish(self)
    }
    
}

extension EditPlayerViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if self.isCreatingNewPlayer {
            // exlcude the delete section
            return 3
        }
        else {
            return 4;
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            let avatarCell = cell as! AvatarTableViewCell
            
            avatarCell.titleLabel.text = "Add Profile Picture"
            avatarCell.avatarView.player = self.player
        }
        else if indexPath.section == 1 {
            let textFieldCell = cell as! TextFieldTableViewCell
            
            if indexPath.row == 0 {
                textFieldCell.titleLabel.text = "First Name"
                textFieldCell.detailTextField.placeholder = "required"
                textFieldCell.detailTextField.text = self.player?.firstName
                textFieldCell.detailTextField.returnKeyType = .Next
                textFieldCell.textFieldChangedHandler = { text in
                    self.player?.firstName = text
                    
                    // update buttons
                    self.updateButtonStates()
                }
                textFieldCell.textFieldReturnKeyHandler = { [unowned self] in
                    // go to the next text field
                    let nextCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 1)) as! TextFieldTableViewCell
                    let nextTextField = nextCell.detailTextField
                    
                    // make the text field the first responder
                    nextTextField.becomeFirstResponder()
                }
            }
            else if indexPath.row == 1 {
                textFieldCell.titleLabel.text = "Last Name"
                textFieldCell.detailTextField.placeholder = "required"
                textFieldCell.detailTextField.text = self.player?.lastName
                textFieldCell.detailTextField.returnKeyType = .Done
                textFieldCell.textFieldChangedHandler = { text in
                    self.player?.lastName = text
                    
                    // update buttons
                    self.updateButtonStates()
                }
                textFieldCell.textFieldReturnKeyHandler = { [unowned self] in
                    // dismiss the keyboard
                    self.view.endEditing(true)
                }
            }
        }
        else if indexPath.section == 2 {
            if indexPath.row == 0 {
                cell.textLabel!.text = "RFID Tag"
                cell.detailTextLabel?.text = self.player?.tagID ?? "tap to scan a tag"
            }
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section == 2 && indexPath.row == 0 {
            // scan tag cell
            // dismiss the keyboard if shown
            self.view.endEditing(true)
        }
        else if indexPath.section == 3 && indexPath.row == 0 && !self.isCreatingNewPlayer {
            // delete player cell was selected
            // the delete button only applies when editing a player
            
            // confirm deletion
            let alert = UIAlertController(title: "Delete Player", message: "This player will be permenantly deleted. This action cannot be undone.", preferredStyle: .Alert);
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: { action in
                self.deletePlayer()
            }))
            
            // show the alert
            self.presentViewController(alert, animated: true, completion: nil);
        }
    }
}

extension EditPlayerViewController: TagScanViewControllerDelegate {
    
    // MARK: - TagScanViewControllerDelegate
    
    func tagScanViewController(controller: TagScanViewController, didSelectTag tag: String?) {
        self.dismissViewControllerAnimated(true, completion: nil)
        
        // update the cell
        let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 2))!
        cell.detailTextLabel!.text = tag ?? "tap to scan a tag"
        
        // update the player model
        self.player?.tagID = tag
    }
    
    func tagScanViewControllerDidCancel(controller: TagScanViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
