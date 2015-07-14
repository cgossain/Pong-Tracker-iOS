//
//  GameManager.swift
//  Pong-Tracker
//
//  Created by Christian Gossain on 2015-05-31.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

class GameManager {
    
    /// Returns the singleton instance of the Game Manager.
    static let sharedGameManager = GameManager()
    
    var currentGame: Game?
    var playerEditInProgress = false;
    
    // MARK: Methods (Private)
    
    func addTeam0(team: Team) {
        if currentGame == nil {
            currentGame = Game()
            currentGame?.delegate = self
        }
        
        // pass message along to game
        currentGame?.addTeam0(team)
    }
    
    func addTeam1(team: Team) {
        if currentGame == nil {
            currentGame = Game()
            currentGame?.delegate = self
        }
        
        // pass message along to game
        currentGame?.addTeam1(team)
    }
}

extension GameManager: GameDelegate {
    
    // MARK: - GameDelegate
    
    func gameDidEnd() {
        // clear the game
        currentGame = nil
    }
}