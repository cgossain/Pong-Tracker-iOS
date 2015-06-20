//
//  Game.swift
//  Pong-Tracker
//
//  Created by Christian R. Gossain on 2015-05-05.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

let Team0JoinedGameNotification = "com.pong-tracker.team0JoinedGame.notification"
let Team1JoinedGameNotification = "com.pong-tracker.team1JoinedGame.notification"

let GameDidSwapTeamsNotification = "com.pong-tracker.gamedidswapteamsnotification"
let GameDidBeginNotification = "com.pong-tracker.gamedidbeginnotification"
let GameDidEndNotification = "com.pong-tracker.gamedidendnotification"

let Team0IsServingNotification = "com.pong-tracker.team0servingnotification"
let Team1IsServingNotification = "com.pong-tracker.team1servingnotification"

let Team0MatchPointNotification = "com.pong-tracker.team0matchpointnotification"
let Team1MatchPointNotification = "com.pong-tracker.team1matchpointnotification"

let NoMatchPointNotification = "com.pong-tracker.nomatchpointnotification"

let Team0WonGameNotification = "com.pong-tracker.team0wongamenotification"
let Team1WonGameNotification = "com.pong-tracker.team1wongamenotification"

protocol PingPongGame {
    var maxScore: Int { get }
    var serviceSwitchInterval: Int { get }
    var leadRequiredToWin: Int { get }
}

class StandardGame: PingPongGame {
    // game rules
    var maxScore: Int { return 11 }
    var serviceSwitchInterval: Int { return 2 }
    var leadRequiredToWin: Int { return 2 }
    
    // teams
    var teams = [Team]()
    var team0: Team? {
        if teams.count > 0 {
            return teams[0]
        }
        return nil
    }
    var team1: Team? {
        if teams.count > 1 {
            return teams[1]
        }
        return nil
    }
    
    var startingTeam: Team?
    
    var isGameReady: Bool { return teams.count == 2 } // the game is ready if both teams have joined
    var isGameInProgress: Bool { return startingTeam != nil }
    
    // MARK: Methods
    
    func addTeam(team: Team) {
        if teams.count == 0 {
            // add team 0
            teams.append(team)
            
            // post notification
            NSNotificationCenter.defaultCenter().postNotificationName(Team0JoinedGameNotification, object: nil)
        }
        else if teams.count == 1 {
            // add team 1
            teams.append(team)
            
            // post notification
            NSNotificationCenter.defaultCenter().postNotificationName(Team1JoinedGameNotification, object: nil)
        }
    }
    
    func swapTeams() {
        // if both teams have joined the game, but the game has not yet started, we can swap the team positions
        if isGameReady && !isGameInProgress {
            let pendingTeam0 = self.team1
            let pendingTeam1 = self.team0
            
            // remove existing teams
            teams.removeAll(keepCapacity: true)
            
            // swap team positions in the array
            teams.append(pendingTeam0!)
            teams.append(pendingTeam1!)
            
            // post notification
            NSNotificationCenter.defaultCenter().postNotificationName(GameDidSwapTeamsNotification, object: nil)
        }
    }
    
    /// Begins the game with the provided team serving first
    func startGameWithTeam(team: Team) {
        // mark the starting team
        self.startingTeam = team
        
        // post notification
        NSNotificationCenter.defaultCenter().postNotificationName(GameDidBeginNotification, object: nil)
    }
    
    func endAndSaveGame() {
        
        // post notification
        NSNotificationCenter.defaultCenter().postNotificationName(GameDidEndNotification, object: nil)
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
                NSNotificationCenter.defaultCenter().postNotificationName(Team0WonGameNotification, object: nil)

                // someone won, so no need to post anymore notifications after this point
                somebodyWon = true
            }
            else if (team1Score >= maxScore) && ((team1Score - team0Score) >= leadRequiredToWin) {
                // team 1 won the game
                // post notification
                NSNotificationCenter.defaultCenter().postNotificationName(Team1WonGameNotification, object: nil)

                // someone won, so no need to post anymore notifications after this point
                somebodyWon = true
            }
            
            // if nobody won, is it match point for someone and who's serve is it
            if !somebodyWon {
            	// does somwone have the match point?
	            if (team0Score >= (maxScore - 1)) && ((team0Score - team1Score) >= (leadRequiredToWin - 1)) {
	                // team 0 has a game point
	                // post notification
	                NSNotificationCenter.defaultCenter().postNotificationName(Team0MatchPointNotification, object: nil)
	                
	            }
	            else if (team1Score >= (maxScore - 1)) && ((team1Score - team0Score) >= (leadRequiredToWin - 1)) {
	                // team 1 has a game point
	                // post notification
	                NSNotificationCenter.defaultCenter().postNotificationName(Team1MatchPointNotification, object: nil)
	            }
                else {
                    // nobody has a match point
                    // post notification
                    NSNotificationCenter.defaultCenter().postNotificationName(NoMatchPointNotification, object: nil)
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
			            NSNotificationCenter.defaultCenter().postNotificationName(Team0IsServingNotification, object: nil)
	            	}
	            	else {
	                	NSNotificationCenter.defaultCenter().postNotificationName(Team1IsServingNotification, object: nil)
	            	}
	            }
	            else {
	                if firstTeamIsServing {
			            NSNotificationCenter.defaultCenter().postNotificationName(Team1IsServingNotification, object: nil)
	            	}
	            	else {
	                	NSNotificationCenter.defaultCenter().postNotificationName(Team0IsServingNotification, object: nil)
	            	}
	            }
            }
        }
    }
    
    func team0Scored(points: Int) {
        if !self.isGameInProgress {
        	// start the game
        	self.startGameWithTeam(team0!)
        }
        
        // update the score
        self.team0?.currentScore += points
        
        // update game
        self.updateGameState()
    }
    
    func team1Scored(points: Int) {
	    if !self.isGameInProgress {
        	// start the game
        	self.startGameWithTeam(team1!)
        }

        // update the score
        self.team1?.currentScore += points
        
        // update game
        self.updateGameState()
    }
}
