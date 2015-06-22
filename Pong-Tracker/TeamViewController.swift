//
//  TeamViewController.swift
//  Pong-Tracker
//
//  Created by Christian R. Gossain on 2015-05-04.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

enum TeamNumber {
    case Zero
    case One
    case Unspecified
}

protocol TeamViewControllerDelegate {
    func teamViewController(controller: TeamViewController, didSelectTeam team: Team)
    func teamNumberForTeamViewController(controller: TeamViewController) -> TeamNumber
}

class TeamViewController: UIViewController, TeamSelectorViewControllerDelegate {
    
    var delegate: TeamViewControllerDelegate?
    var teamView: TeamView {
        get {
            return self.view as! TeamView
        }
    }
    var teamNumber: TeamNumber {
        return delegate?.teamNumberForTeamViewController(self) ?? .Unspecified
    }
    
    // MARK: Initialization
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: View Lifecycle
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch (segue.identifier, segue.destinationViewController) {
        case let (identifier, destinationVC as UINavigationController) where identifier == "TeamOneSelector":
            if let teamSelectorVC = destinationVC.topViewController as? TeamSelectorViewController {
                teamSelectorVC.delegate = self
            }
        case let (identifier, destinationVC as UINavigationController) where identifier == "TeamTwoSelector":
            if let teamSelectorVC = destinationVC.topViewController as? TeamSelectorViewController {
                teamSelectorVC.delegate = self
            }
        default:
            break
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initial UI state
        teamView.setTeamInfoShown(false, animated: false)
        
        // register for notifications
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "gameSwappedTeamsNotification",
            name: GameDidSwapTeamsNotification,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "gameDidEndNotification",
            name: GameDidEndNotification,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "gameDidRestartNotification",
            name: GameDidRestartNotification,
            object: nil)
        
        // team specific notifications
        if self.teamNumber == .Zero {
            NSNotificationCenter.defaultCenter().addObserver(
                self,
                selector: "teamJoinedGameNotification",
                name: Team0JoinedGameNotification,
                object: nil)
        }
        else if self.teamNumber == .One {
            NSNotificationCenter.defaultCenter().addObserver(
                self,
                selector: "teamJoinedGameNotification",
                name: Team1JoinedGameNotification,
                object: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Methods (Public)
    
    func clear() {
        // hide the team 
        teamView.setTeamInfoShown(false, animated: true);
    }
    
    // MARK: Methods (Private)
    
    func gameSwappedTeamsNotification() {
        // update the view with team information
        self.reloadTeam()
    }
    
    func gameDidRestartNotification() {
        self.teamView.headerView.isServing = false
        self.teamView.headerView.isMatchPoint = false
    }
    
    func gameDidEndNotification() {
        // clear out the team view
        self.teamView.team = nil
    }
    
    func teamJoinedGameNotification() {
        // update the view with team information
        self.reloadTeam()
    }
    
    func reloadTeam() {
        if self.teamNumber == .Zero {
            self.teamView.team = GameManager.sharedGameManager.currentGame?.team0
        }
        else if self.teamNumber == .One {
            self.teamView.team = GameManager.sharedGameManager.currentGame?.team1
        }
    }
    
    // MARK: TeamSelectorViewControllerDelegate
    
    func teamSelector(teamSelector: TeamSelectorViewController, didSelectTeam team: Team) {
        // dismiss the team selector view controller
        self.dismissViewControllerAnimated(true) { () -> Void in NSLog("DISMISSED TEAM SELECTOR VIEW CONTROLLER") }
        
        // notify the delegate
        delegate?.teamViewController(self, didSelectTeam: team)
    }

}
