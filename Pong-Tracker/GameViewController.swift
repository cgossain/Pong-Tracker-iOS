//
//  GameViewController.swift
//  Pong-Tracker
//
//  Created by Christian R. Gossain on 2015-05-03.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

class GameViewController: UIViewController, TeamViewControllerDelegate {
    
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
            
        default:
            // no default behaviour
            break
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: TeamViewControllerDelegate
    
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
        GameManager.sharedGameManager.addTeam(team)
    }
}
