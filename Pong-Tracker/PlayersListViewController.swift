//
//  PlayersListViewController.swift
//  Pong-Tracker
//
//  Created by Christian Gossain on 2015-07-05.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

protocol PlayersListViewControllerDelegate {
    func playersListViewControllerDoneButtonTapped(controller: PlayersListViewController)
    func playersListViewController(controller: PlayersListViewController, didSelectTeam team: Team)
}

let kPlayerListCellIdentifier = "PlayerListCell"

class PlayersListViewController: UITableViewController {
    
    var delegate: PlayersListViewControllerDelegate?
    var eventSource: EventSource?
    var managedObjectContext: NSManagedObjectContext {
        return GSCoreDataManager.sharedManager().managedObjectContext
    }
    
    // MARK: View Lifecycle
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch (segue.identifier, segue.destinationViewController) {
        case let (identifier, vc as EditPlayerViewController) where identifier == "CreateNewPlayer":
            vc.delegate = self
        case let (identifier, vc as EditPlayerViewController) where identifier == "EditPlayer":
            vc.delegate = self
            
            if let cell = sender as? UITableViewCell {
                if let indexPath = self.tableView.indexPathForCell(cell) {
                    vc.player = self.fetchedResultsController.objectAtIndexPath(indexPath) as? Player
                }
            }
        default:
            break
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true
        
        // row heights
        self.tableView.estimatedRowHeight = 60.0 + 16.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Methods (Private)
    
    func configureCell(cell: AvatarTableViewCell, atIndexPath indexPath: NSIndexPath) {
        let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Player
        
        // update the avatar
        cell.avatarView.player = object
        
        // display the player name
        let firstName = object.firstName ?? ""
        let lastName = object.lastName ?? ""
        let space = (count(firstName) > 0 && count(lastName) > 0) ? " " : ""
        
        // update the player name
        cell.titleLabel.text = firstName + space + lastName
    }
    
    func didSelectPlayer(player: Player) {
        // wrap the player in a team object
        let team = Team(name: "Team", playerOne: player, playerTwo: nil)
        
        // notify the delegate
        self.delegate?.playersListViewController(self, didSelectTeam: team)
    }
    
    // MARK: Actions
    
    @IBAction func doneButtonTapped(sender: AnyObject) {
        self.delegate?.playersListViewControllerDoneButtonTapped(self)
    }

    // MARK: - UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kPlayerListCellIdentifier, forIndexPath: indexPath) as! AvatarTableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Players"
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Player
        
        // select the player
        self.didSelectPlayer(object)
    }
    
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest(entityName: "Player")
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        let sortDescriptors = [NSSortDescriptor(key: "lastName", ascending: true)]
        fetchRequest.sortDescriptors = sortDescriptors
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        var error: NSError? = nil
        if !_fetchedResultsController!.performFetch(&error) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            println("Unresolved error \(error), \(error!.userInfo)")
//            abort()
        }
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController? = nil

}

extension PlayersListViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            self.configureCell(tableView.cellForRowAtIndexPath(indexPath!) as! AvatarTableViewCell, atIndexPath: indexPath!)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
    
}

extension PlayersListViewController: EditPlayerViewControllerDelegate {
    
    func editPlayerViewControllerDidFinish(controller: EditPlayerViewController) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
}
