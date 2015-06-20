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
        
//        let Team0IsServingNotification = "com.pong-tracker.team0servingnotification"
//        let Team1IsServingNotification = "com.pong-tracker.team1servingnotification"
//        
//        let Team0MatchPointNotification = "com.pong-tracker.team0matchpointnotification"
//        let Team1MatchPointNotification = "com.pong-tracker.team1matchpointnotification"
//        
//        let MatchPointLostNotification = "com.pong-tracker.matchpointlostnotification"
//        
//        let Team0WonGameNotification = "com.pong-tracker.team0wongamenotification"
//        let Team1WonGameNotification = "com.pong-tracker.team1wongamenotification"
        
        // register for notifications
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "gameSwappedTeamsNotification",
            name: GameDidSwapTeamsNotification,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "team0IsServingNotification",
            name: Team0IsServingNotification,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "team1IsServingNotification",
            name: Team1IsServingNotification,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "team0HasMatchPointNotification",
            name: Team0MatchPointNotification,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "team1HasMatchPointNotification",
            name: Team1MatchPointNotification,
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
        
        // clear match point notification
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "noMatchPointNotification",
            name: NoMatchPointNotification,
            object: nil)
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
    
    func teamJoinedGameNotification() {
        // update the view with team information
        self.reloadTeam()
    }
    
    func team0IsServingNotification() {
        if self.teamNumber == .Zero {
            self.teamView.headerView.isServing = true
        }
        else if self.teamNumber == .One {
            self.teamView.headerView.isServing = false
        }
    }
    
    func team1IsServingNotification() {
        if self.teamNumber == .Zero {
            self.teamView.headerView.isServing = false
        }
        else if self.teamNumber == .One {
            self.teamView.headerView.isServing = true
        }
    }
    
    func team0HasMatchPointNotification() {
        // update the view with team information
        if self.teamNumber == .Zero {
            self.teamView.headerView.isMatchPoint = true
        }
        else if self.teamNumber == .One {
            self.teamView.headerView.isMatchPoint = false
        }
    }
    
    func team1HasMatchPointNotification() {
        // update the view with team information
        if self.teamNumber == .Zero {
            self.teamView.headerView.isMatchPoint = false
        }
        else if self.teamNumber == .One {
            self.teamView.headerView.isMatchPoint = true
        }
    }
    
    func noMatchPointNotification() {
        // update the view with team information
        self.teamView.headerView.isMatchPoint = false
    }
    
    func gameSwappedTeamsNotification() {
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
