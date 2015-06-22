//
//  ControlPadViewController.swift
//  Pong-Tracker
//
//  Created by Christian R. Gossain on 2015-05-04.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

class ControlPadViewController: UIViewController {

    @IBOutlet weak var team0ScoreStepper: ScoreStepper! {
        didSet {
            team0ScoreStepper.valueChangedAction = { (diff: Double) in
                GameManager.sharedGameManager.currentGame?.team0Scored(Int(diff))
            }
        }
    }
    
    @IBOutlet weak var team1ScoreStepper: ScoreStepper! {
        didSet {
            team1ScoreStepper.valueChangedAction = { (diff: Double) in
                GameManager.sharedGameManager.currentGame?.team1Scored(Int(diff))
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func swapButtonTapped(sender: AnyObject) {
        // swap teams
        GameManager.sharedGameManager.swapTeams()
    }

    @IBAction func restartButtonTapped(sender: AnyObject) {
        // restart game
        GameManager.sharedGameManager.restartGame()
    }
    @IBAction func endGameButttonTapped(sender: AnyObject) {
        // end current game
        GameManager.sharedGameManager.endGame()
    }
}
