//
//  GameManager.swift
//  Pong-Tracker
//
//  Created by Christian Gossain on 2015-05-31.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

class GameManager: NSObject {
    
    /// Returns the singleton instance of the Game Manager.
    static let sharedGameManager = GameManager()
    
    var currentGame: StandardGame?
    
    // MARK: Methods
    
    func addTeam(team: Team) {
        if currentGame == nil {
            currentGame = StandardGame()
        }
        
        // pass message along to game
        currentGame?.addTeam(team)
    }
    
    /// Ends the current game without saving
    func endGame() {
        // pass message along to game
        
    }
    
    /// Restart the current game
    func restartGame() {
        // pass message along to game
        
    }
    
    func swapTeams() {
        // pass message along to game
        currentGame?.swapTeams()
    }
}
