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

class TeamViewController: UIViewController {
    
    var delegate: TeamViewControllerDelegate?
    var teamView: TeamView {
        get {
            return self.view as! TeamView
        }
    }
    var teamNumber: TeamNumber {
        return delegate?.teamNumberForTeamViewController(self) ?? .Unspecified
    }
    
    // MARK: - Initialization
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - View Lifecycle
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch (segue.identifier, segue.destinationViewController) {
        case let (identifier, vc as UINavigationController) where identifier == "TeamOneSelector":
            if let teamSelectorVC = vc.topViewController as? PlayersListViewController {
                teamSelectorVC.delegate = self
                
                GameManager.sharedGameManager.playerEditInProgress = true
            }
        case let (identifier, vc as UINavigationController) where identifier == "TeamTwoSelector":
            if let teamSelectorVC = vc.topViewController as? PlayersListViewController {
                teamSelectorVC.delegate = self
                
                GameManager.sharedGameManager.playerEditInProgress = true
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
        
        // button target actions
        self.teamView.decrementButton.addTarget(self, action: "decrementButtonTapped:", forControlEvents: .TouchUpInside)
        self.teamView.incrementButton.addTarget(self, action: "incrementButtonTapped:", forControlEvents: .TouchUpInside)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Actions
    
    func decrementButtonTapped(sender: UIButton) {
        if self.teamNumber == .Zero {
            GameManager.sharedGameManager.currentGame?.team0Scored(-1)
        }
        else if self.teamNumber == .One {
            GameManager.sharedGameManager.currentGame?.team1Scored(-1)
        }
    }
    
    func incrementButtonTapped(sender: UIButton) {
        if self.teamNumber == .Zero {
            GameManager.sharedGameManager.currentGame?.team0Scored(1)
        }
        else if self.teamNumber == .One {
            GameManager.sharedGameManager.currentGame?.team1Scored(1)
        }
    }
    
    // MARK: - Methods (Public)
    
    func clear() {
        // hide the team 
        teamView.setTeamInfoShown(false, animated: true);
    }
    
    // MARK: - Methods (Private)
    
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
}

extension TeamViewController: PlayersListViewControllerDelegate {
    
    // MARK: - PlayersListViewControllerDelegate
    
    func playersListViewControllerDoneButtonTapped(controller: PlayersListViewController) {
        GameManager.sharedGameManager.playerEditInProgress = false
        
        // dismiss the view controller
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func playersListViewController(controller: PlayersListViewController, didSelectTeam team: Team) {
        GameManager.sharedGameManager.playerEditInProgress = false
        
        // dismiss the view controller
        self.dismissViewControllerAnimated(true, completion: nil)
        
        // notify the delegate
        delegate?.teamViewController(self, didSelectTeam: team)
    }
    
}
