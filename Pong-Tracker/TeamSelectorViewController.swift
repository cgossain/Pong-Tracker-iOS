//
//  TeamSelectorViewController.swift
//  Pong-Tracker
//
//  Created by Christian Gossain on 2015-05-25.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

protocol TeamSelectorViewControllerDelegate {
    func teamSelector(teamSelector: TeamSelectorViewController, didSelectTeam team: Team)
}

class TeamSelectorViewController: UIViewController {
    
    var delegate: TeamSelectorViewControllerDelegate?
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Selectors

    @IBAction func teamOneButtonTapped(sender: AnyObject) {
        
//        let player = Player(firstName: "John", lastName: "Smith")
//        let team = Team(name: "Team One", playerOne: player, playerTwo: nil)
//        
//        delegate?.teamSelector(self, didSelectTeam: team)
    }
    
    @IBAction func teamTwoButtonTapped(sender: AnyObject) {
        
//        let player = Player(firstName: "Jane", lastName: "Smith")
//        let team = Team(name: "Team Two", playerOne: player, playerTwo: nil)
//        
//        delegate?.teamSelector(self, didSelectTeam: team)
    }
}
