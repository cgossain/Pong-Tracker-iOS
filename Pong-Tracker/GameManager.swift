//
//  GameManager.swift
//  Pong-Tracker
//
//  Created by Christian Gossain on 2015-05-31.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

let kParticleIOAccessToken = "YOUR_ACCESS_TOKEN"
let kUndoInterval = 1.0

class GameManager {
    
    /// Returns the singleton instance of the Game Manager.
    static let sharedGameManager = GameManager()
    
    var currentGame: StandardGame?
    var eventSource: EventSource?
    
    var lastTeam0ScoreTime = NSDate.timeIntervalSinceReferenceDate()
    var lastTeam1ScoreTime = NSDate.timeIntervalSinceReferenceDate()
    
    var playerEditInProgress = false;
    
    // MARK: Methods (Private)
    
    func addTeam0(team: Team) {
        if currentGame == nil {
            currentGame = StandardGame()
            currentGame?.delegate = self
        }
        
        // pass message along to game
        currentGame?.addTeam0(team)
    }
    
    func addTeam1(team: Team) {
        if currentGame == nil {
            currentGame = StandardGame()
            currentGame?.delegate = self
        }
        
        // pass message along to game
        currentGame?.addTeam1(team)
    }
    
    func registerScoredServerSentEvents() {
        let scoredEventURL = "https://api.particle.io/v1/devices/events/scored" + "?access_token=" + kParticleIOAccessToken
        
        // create an event source that point to the particle.io device
        self.eventSource = EventSource.eventSourceWithURL(NSURL(string: scoredEventURL)) as? EventSource
        
        // listen to the scored events
        self.eventSource?.addEventListener("scored", handler: { (event: Event!) -> Void in
            var error: NSError?
            let data = event.data.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!
            
            var jsonError: NSError?
            let json = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &jsonError) as? NSDictionary
            
            if let player = json?["data"] as? String {
                
                println("Player \(player) scored")
                
                if player == "1" {
                    // team 0 pressed button
                    let t = NSDate.timeIntervalSinceReferenceDate()
                    
                    // if the new score is within the undo interval seconds, subtract a point
                    if t - self.lastTeam0ScoreTime <= kUndoInterval {
                        // subtract a point
                        self.currentGame?.team0Scored(1)
                    }
                    else {
                        // add a point
                        self.currentGame?.team0Scored(1)
                    }
                    
                    // update the last score time
                    self.lastTeam0ScoreTime = t
                }
                else if player == "2" {
                    // team 1 pressed button
                    let t = NSDate.timeIntervalSinceReferenceDate()
                    
                    // if the new score is within the undo interval seconds, subtract a point
                    if t - self.lastTeam1ScoreTime <= kUndoInterval {
                        // subtract a point
                        self.currentGame?.team1Scored(1)
                    }
                    else {
                        // add a point
                        self.currentGame?.team1Scored(1)
                    }
                    
                    // update the last score time
                    self.lastTeam1ScoreTime = t
                }
                
            }
            
            println("\(event.event): \(event.data)")
        })
    }
    
    // MARK:
    
    func rfidEvents() {
        let eventURL = "http://54.164.134.82:9000/register"
        let source: AnyObject! = EventSource.eventSourceWithURL(NSURL(string: eventURL))
        
        // listen to the scored events
        source.addEventListener("USER", handler: { (event: Event!) -> Void in
            println("The scanned RFID code is: \(event.data)")
        })
        
        source.addEventListener("STATUS", handler: { (event: Event!) -> Void in
            println("The RFID reader is online!")
        })
    }
}

extension GameManager: StandardGameDelegate {
    
    func gameIsReady() {
        // listen for scored events
        self.registerScoredServerSentEvents()
    }
    
    func gameDidEnd() {
        // unregister for scored events
        self.eventSource?.close()
        
        // clear the source
        self.eventSource = nil
    }
    
}
