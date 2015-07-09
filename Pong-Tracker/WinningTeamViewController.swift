//
//  WinningTeamViewController.swift
//  Pong-Tracker
//
//  Created by Christian Gossain on 2015-06-26.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

protocol WinningTeamViewControllerDelegate {
    func winningTeamViewControllerDidFinish(controller: WinningTeamViewController)
}

let kDismissTimerInterval = 5.0

class WinningTeamViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBAction func doneButtonTapped(sender: UIBarButtonItem) {
        self.dismiss()
    }
    
    var delegate: WinningTeamViewControllerDelegate?
    var winningTeam: Team?
    var dismissTimer: NSTimer?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        // configure the default presentation
        self.modalPresentationStyle = UIModalPresentationStyle.Custom
        self.transitioningDelegate = self
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // configure the default presentation
        self.modalPresentationStyle = UIModalPresentationStyle.Custom
        self.transitioningDelegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set the title label
        if let team = self.winningTeam {
            self.titleLabel.text = team.playerOne.firstName! + " " + team.playerOne.lastName! + " Won!"
        }
        
        // start a timer to dismiss the controller
        self.dismissTimer = NSTimer.scheduledTimerWithTimeInterval(
            kDismissTimerInterval,
            target: self,
            selector: "dismissTimerFired:",
            userInfo: nil,
            repeats: false)
    }
    
    // MARK: Selectors
    
    func dismissTimerFired(timer: NSTimer) {
        self.dismiss()
    }
    
    // MARK: Private
    
    func dismiss() {
        self.delegate?.winningTeamViewControllerDidFinish(self)
    }
}

extension WinningTeamViewController: UIViewControllerTransitioningDelegate {
    
    func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController!, sourceViewController source: UIViewController) -> UIPresentationController? {
        return TransientPresentationController(presentedViewController: presented, presentingViewController: presenting)
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented == self {
            return PopPresentationAnimator(presenting: true)
        }
        return nil
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed == self {
            return PopPresentationAnimator(presenting: false)
        }
        return nil
    }
    
}
