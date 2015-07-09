//
//  Game.swift
//  Pong-Tracker
//
//  Created by Christian R. Gossain on 2015-05-05.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

// team joined
let Team0JoinedGameNotification = "com.pong-tracker.team0JoinedGame.notification"
let Team1JoinedGameNotification = "com.pong-tracker.team1JoinedGame.notification"

// game lifecycle
let GameDidSwapTeamsNotification = "com.pong-tracker.gamedidswapteamsnotification"
let GameDidRestartNotification = "com.pong-tracker.gamedidrestartnotification"
let GameDidEndNotification = "com.pong-tracker.gamedidendnotification"

// team won
let Team0WonGameNotification = "com.pong-tracker.team0wongamenotification"
let Team1WonGameNotification = "com.pong-tracker.team1wongamenotification"

protocol PingPongGame {
    var maxScore: Int { get }
    var serviceSwitchInterval: Int { get }
    var leadRequiredToWin: Int { get }
}

protocol StandardGameDelegate {
    func gameIsReady(); // enough players have joined to start the game
    func gameDidEnd();
}

class StandardGame: PingPongGame {
    // game rules
    var maxScore: Int { return 11 }
    var serviceSwitchInterval: Int { return 2 }
    var leadRequiredToWin: Int { return 2 }
    
    // delegate
    var delegate: StandardGameDelegate?
    
    // teams
    var team0: Team?
    var team1: Team?
    
    var isGameReady: Bool { return ((team0 != nil) && (team1 != nil)) } // the game is ready if both teams have joined
    var isGameInProgress: Bool { return startingTeam != nil }
    
    var startingTeam: Team?
    
    // MARK: Methods
    
    func addTeam0(team: Team) {
        // set the team
        self.team0 = team;
        
        // post notification
        NSNotificationCenter.defaultCenter().postNotificationName(Team0JoinedGameNotification, object: nil)
        
        // notify delegate if game is ready
        if self.isGameReady {
            self.delegate?.gameIsReady()
        }
    }
    
    func addTeam1(team: Team) {
        // set the team
        self.team1 = team;
        
        // post notification
        NSNotificationCenter.defaultCenter().postNotificationName(Team1JoinedGameNotification, object: nil)
        
        // notify delegate if game is ready
        if self.isGameReady {
            self.delegate?.gameIsReady()
        }
    }
    
    func swapTeams() {
        // if both teams have joined the game, but the game has not yet started, we can swap the team positions
        if isGameReady && !isGameInProgress {
            let pendingTeam0 = self.team1
            let pendingTeam1 = self.team0
            
            // swap the teams
            self.team0 = pendingTeam0!
            self.team1 = pendingTeam1!
            
            // post notification
            NSNotificationCenter.defaultCenter().postNotificationName(GameDidSwapTeamsNotification, object: nil)
        }
    }
    
    /// Begins the game with the provided team serving first
    func startGameWithTeam(team: Team) {
        // mark the starting team
        self.startingTeam = team
    }
    
    func restartGame() {
        // keep same teams; but clear starting team
        self.startingTeam = nil
        
        // reset team properties
        self.team0?.currentScore = 0
        self.team1?.currentScore = 0

        self.team0?.isServing = false
	    self.team1?.isServing = false

	    self.team0?.hasMatchPoint = false
	    self.team1?.hasMatchPoint = false
        
        // post notification
        NSNotificationCenter.defaultCenter().postNotificationName(GameDidRestartNotification, object: nil)
    }
    
    func rematchGame() {
        
    }
    
    func endGame() {
        // mark the starting team
        self.startingTeam = nil
        
        // clear the existing teams
        self.team0 = nil
        self.team1 = nil
        
        // post notification
        NSNotificationCenter.defaultCenter().postNotificationName(GameDidEndNotification, object: nil)
        
        // notify delegate
        self.delegate?.gameDidEnd()
    }
    
    func endAndSaveGame() {
        // mark the starting team
        self.startingTeam = nil
        
        // clear the existing teams
        self.team0 = nil
        self.team1 = nil
        
        // post notification
        NSNotificationCenter.defaultCenter().postNotificationName(GameDidEndNotification, object: nil)
        
        // notify delegate
        self.delegate?.gameDidEnd()
    }
    
    /// MARK: Methods (Scoring)
    
    func updateGameState() {
        if self.isGameInProgress {
            
            let team0Score = self.team0?.currentScore ?? 0
            let team1Score = self.team1?.currentScore ?? 0
            var somebodyWon = false
            
            // did somebody win
            if (team0Score >= maxScore) && ((team0Score - team1Score) >= leadRequiredToWin) {
                // team 0 won the game
                // post notification
                NSNotificationCenter.defaultCenter().postNotificationName(Team0WonGameNotification, object: nil, userInfo: ["team" : self.team0!])
                
                // someone won, so no need to post anymore notifications after this point
                somebodyWon = true
            }
            else if (team1Score >= maxScore) && ((team1Score - team0Score) >= leadRequiredToWin) {
                // team 1 won the game
                // post notification
                NSNotificationCenter.defaultCenter().postNotificationName(Team1WonGameNotification, object: nil, userInfo: ["team" : self.team1!])
                
                // someone won, so no need to post anymore notifications after this point
                somebodyWon = true
            }
            
            // if nobody won, is it match point for someone and who's serve is it
            if somebodyWon {
                // end the game
                // keep the same player but restart and swap the teams
                self.restartGame()
                self.swapTeams()
            }
            else {
                // does somwone have the match point?
                if (team0Score >= (maxScore - 1)) && ((team0Score - team1Score) >= (leadRequiredToWin - 1)) {
                    // team 0 has match point
                    self.team0?.hasMatchPoint = true
                    self.team1?.hasMatchPoint = false
                }
                else if (team1Score >= (maxScore - 1)) && ((team1Score - team0Score) >= (leadRequiredToWin - 1)) {
                    // team 1 has a game point
                    self.team0?.hasMatchPoint = false
                    self.team1?.hasMatchPoint = true
                }
                else {
                    // nobody has a match point
                    self.team0?.hasMatchPoint = false
                    self.team1?.hasMatchPoint = false
                }
                
                // who is serving
                let totalScore = team0Score + team1Score
                let threshold = maxScore - leadRequiredToWin
                var firstTeamIsServing = true
                
                if (team0Score > threshold && team1Score > threshold) {
                    let hyperThresholdMultiple = (totalScore - 2*(threshold + 1));
                    
                    // switch every 1 serve
                    if hyperThresholdMultiple % 2 == 0 {
                        // even; first team is serving
                        firstTeamIsServing = true
                    }
                    else {
                        // odd; second team is serving
                        firstTeamIsServing = false
                    }
                }
                else {
                    let multiple = totalScore/serviceSwitchInterval
                    
                    // switch every "defined" number of serves (i.e. serviceSwitchInterval)
                    if multiple % 2 == 0 {
                        // even; first team is serving
                        firstTeamIsServing = true
                    }
                    else {
                        // odd; second team serving
                        firstTeamIsServing = false
                    }
                }
                
                // post notification
                if startingTeam == team0 {
                    if firstTeamIsServing {
                        self.team0?.isServing = true
                        self.team1?.isServing = false
                    }
                    else {
                        self.team0?.isServing = false
                        self.team1?.isServing = true
                    }
                }
                else {
                    if firstTeamIsServing {
                        self.team0?.isServing = false
                        self.team1?.isServing = true
                    }
                    else {
                        self.team0?.isServing = true
                        self.team1?.isServing = false
                    }
                }
            }
        }
    }
    
    func team0Scored(points: Int) {
        // only proceed if the game is ready
        if self.isGameReady {
            if !self.isGameInProgress {
                // start the game
                self.startGameWithTeam(team0!)
            }
            else {
                // update the score
                self.team0?.currentScore += points
            }
            
            // update game
            self.updateGameState()
        }
    }
    
    func team1Scored(points: Int) {
        // only proceed if the game is ready
        if self.isGameReady {
            if !self.isGameInProgress {
                // start the game
                self.startGameWithTeam(team1!)
            }
            else {
                // update the score
                self.team1?.currentScore += points
            }
            
            // update game
            self.updateGameState()
        }
    }
}
