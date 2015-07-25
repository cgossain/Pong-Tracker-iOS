//
//  ControlPadViewController.swift
//  Pong-Tracker
//
//  Created by Christian R. Gossain on 2015-05-04.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

let kParticleIOAccessToken = "YOUR_ACCESS_TOKEN"
let kParticleIODeviceID = "YOUR_DEVICE_ID"
let kScoreLimitInterval = 1.0

let ControlPadViewControllerRFIDTagScannedNotification = "com.controlpadviewcontroller.tagscannednotification"

let ControlPadScannedTagKey = "ControlPadScannedTagKey"

protocol ControlPadViewControllerDelegate {
    func controlPadViewController(controller: ControlPadViewController, didSelectTeam team: Team)
}

class ControlPadViewController: UIViewController {
    
    @IBOutlet weak var rfidReaderStatusIndicator: StatusIndicator!
    @IBOutlet weak var tableStatusIndicator: StatusIndicator!
    
    var delegate: ControlPadViewControllerDelegate?
    var rfidEventSource: EventSource?
    var particleCoreEventSource: EventSource?
    var managedObjectContext: NSManagedObjectContext { return GSCoreDataManager.sharedManager().managedObjectContext }
    
    var lastTeam0ScoreTime = NSDate.timeIntervalSinceReferenceDate()
    var lastTeam1ScoreTime = NSDate.timeIntervalSinceReferenceDate()
    
    // MARK: Initialization
    
    deinit {
        // close the event source connections
        rfidEventSource?.close()
        particleCoreEventSource?.close()
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: Storyboard
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier where identifier == "WinningTeam" {
            // set self as the delegate
            if let navigationViewController = segue.destinationViewController as? UINavigationController {
                if let winningViewController = navigationViewController.topViewController as? WinningTeamViewController {
                    winningViewController.delegate = self
                    winningViewController.winningTeam = sender as? Team
                }
            }
        }
    }
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.registerForSentEvents()
        
        // listen to win notifications
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "team0WonGameNotificationFired:",
            name: Team0WonGameNotification,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "team1WonGameNotificationFired:",
            name: Team1WonGameNotification,
            object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Actions
    
    @IBAction func swapButtonTapped(sender: AnyObject) {
        // swap teams
        GameManager.sharedGameManager.currentGame?.swapTeams()
    }
    
    @IBAction func restartButtonTapped(sender: AnyObject) {
        // restart game
        GameManager.sharedGameManager.currentGame?.restartGame()
    }

    @IBAction func rematchButtonTapped(sender: AnyObject) {
        // restart game
        GameManager.sharedGameManager.currentGame?.rematchGame()
    }
    
    @IBAction func endGameButttonTapped(sender: AnyObject) {
        // end current game
        GameManager.sharedGameManager.currentGame?.endGame()
    }
    
    // MARK: Notifications
    
    func team0WonGameNotificationFired(note: NSNotification) {
        let info = note.userInfo as? [String : AnyObject]
        let team = info?["team"] as? Team
        
        self.presentWinningViewControllerWithTeam(team)
    }
    
    func team1WonGameNotificationFired(note: NSNotification) {
        let info = note.userInfo as? [String : AnyObject]
        let team = info?["team"] as? Team
        
        self.presentWinningViewControllerWithTeam(team)
    }
    
    // MARK: Methods (Private)
    
    func presentWinningViewControllerWithTeam(team: Team?) {
        // create the controller
        let winningViewController = self.storyboard?.instantiateViewControllerWithIdentifier("WinningTeamViewController") as? WinningTeamViewController
        
        // configure
        winningViewController?.delegate = self
        winningViewController?.winningTeam = team
        
        // present
        self.presentViewController(winningViewController!, animated: true, completion: nil)
    }
    
    func registerForSentEvents() {
        let rfidEventURL = "http://someeventsourceurl"
        rfidEventSource = EventSource.eventSourceWithURL(NSURL(string: rfidEventURL)) as? EventSource
        
        // listen for the status event
        rfidEventSource?.addEventListener("STATUS", handler: {[unowned self] (event: Event!) -> Void in
            self.rfidReaderStatusIndicator.isOnline = true
        })
        
        // listen for tag scans
        rfidEventSource?.addEventListener("USER", handler: {[unowned self] (event: Event!) -> Void in
            self.didScanTag(event.data.uppercaseString)
        })
        
        // particle.io online event
        let particleEventURL = "https://api.particle.io/v1/devices/events" + "?access_token=" + kParticleIOAccessToken
        particleCoreEventSource = EventSource.eventSourceWithURL(NSURL(string: particleEventURL)) as? EventSource
        
        particleCoreEventSource?.addEventListener("ping", handler: {[unowned self] (event: Event!) -> Void in
            self.tableStatusIndicator.isOnline = true
        })
        
        // listen to the scored events
        particleCoreEventSource?.addEventListener("scored", handler: { (event: Event!) -> Void in
            var error: NSError?
            let data = event.data.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!
            
            var jsonError: NSError?
            let json = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &jsonError) as? NSDictionary
            
            if let player = json?["data"] as? String {
                
                println("Player \(player) scored")
                
                if player == "1" {
                    // team 0 pressed button
                    let t = NSDate.timeIntervalSinceReferenceDate()
                    
                    // limit 1 point per interval
                    if t - self.lastTeam0ScoreTime > kScoreLimitInterval {
                        // add a point
                        GameManager.sharedGameManager.currentGame?.team0Scored(1)
                        
                        // update the last score time
                        self.lastTeam0ScoreTime = t
                    }
                }
                else if player == "2" {
                    // team 1 pressed button
                    let t = NSDate.timeIntervalSinceReferenceDate()
                    
                    // limit 1 point per interval
                    if t - self.lastTeam1ScoreTime > kScoreLimitInterval {
                        // add a point
                        GameManager.sharedGameManager.currentGame?.team1Scored(1)
                        
                        // update the last score time
                        self.lastTeam1ScoreTime = t
                    }
                }
            }
        })
    }
    
    func didScanTag(tag: String) {
        println("The scanned RFID code is: \(tag)")
        
        // add the player if not editing a player (we could be associating a tag with a player)
        if !GameManager.sharedGameManager.playerEditInProgress {
            // check if the tag is already associated with a player
            let fetchRequest = NSFetchRequest(entityName: "Player")
            fetchRequest.predicate = NSPredicate(format: "tagID == %@", tag)
            
            // execute the request
            var error: NSError? = nil
            let results = self.managedObjectContext.executeFetchRequest(fetchRequest, error: &error) as! [Player]
            
            if !results.isEmpty {
                // there is a match
                let player = results.first!
                
                // wrap the player in a team object
                let team = Team(name: "Team", playerOne: player, playerTwo: nil)
                
                // notify the delegate
                self.delegate?.controlPadViewController(self, didSelectTeam: team)
            }
        }
        
        // post a notification with the scanned tag
        NSNotificationCenter.defaultCenter().postNotificationName(
            ControlPadViewControllerRFIDTagScannedNotification,
            object: self,
            userInfo: [ControlPadScannedTagKey : tag])
    }
}

extension ControlPadViewController: WinningTeamViewControllerDelegate {
    func winningTeamViewControllerDidFinish(controller: WinningTeamViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}