//
//  GameViewController.swift
//  Pong-Tracker
//
//  Created by Christian R. Gossain on 2015-05-03.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

class GameViewController: UIViewController, TeamViewControllerDelegate, ControlPadViewControllerDelegate {
    
    weak var teamOneViewController: TeamViewController?
    weak var teamTwoViewController: TeamViewController?
    weak var controlPadViewController: ControlPadViewController?
    
    // MARK: View Lifecycle
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch (segue.identifier, segue.destinationViewController) {
            
        case let (identifier, destinationVC as TeamViewController) where identifier == "teamOne_Embed":
            teamOneViewController = destinationVC
            teamOneViewController?.delegate = self
            
        case let (identifier, destinationVC as TeamViewController) where identifier == "teamTwo_Embed":
            teamTwoViewController = destinationVC
            teamTwoViewController?.delegate = self
            
        case let (identifier, destinationVC as ControlPadViewController) where identifier == "controlPad_Embed":
            controlPadViewController = destinationVC
            controlPadViewController?.delegate = self
            
        default:
            break   // no default behaviour
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - TeamViewControllerDelegate
    
    func teamNumberForTeamViewController(controller: TeamViewController) -> TeamNumber {
        if controller == teamOneViewController {
            return .Zero
        }
        else if controller == teamTwoViewController {
            return .One
        }
        else {
            return .Unspecified
        }
    }
    
    func teamViewController(teamViewController: TeamViewController, didSelectTeam team: Team) {
        // add the team to the game manager
        if teamViewController == self.teamOneViewController {
            // add team 0
            
            // validate that this not the same player as team 1
            if team.playerOne != GameManager.sharedGameManager.currentGame?.team1?.playerOne {
                GameManager.sharedGameManager.addTeam0(team)
            }
        }
        else if teamViewController == self.teamTwoViewController {
            // add team 0
            
            // validate that this not the same player as team 0
            if team.playerOne != GameManager.sharedGameManager.currentGame?.team0?.playerOne {
                GameManager.sharedGameManager.addTeam1(team)
            }
        }
    }
    
    // MARK: - ControlPadViewControllerDelegate
    
    func controlPadViewController(controller: ControlPadViewController, didSelectTeam team: Team) {
        // add the team
        if GameManager.sharedGameManager.currentGame?.team0 == nil {
            // add team 0
            GameManager.sharedGameManager.addTeam0(team)
        }
        else if GameManager.sharedGameManager.currentGame?.team1 == nil {
            // add team 1
            
            // validate that this is a different player from team 0
            if team.playerOne != GameManager.sharedGameManager.currentGame?.team0?.playerOne {
                GameManager.sharedGameManager.addTeam1(team)
            }
        }
    }
}
