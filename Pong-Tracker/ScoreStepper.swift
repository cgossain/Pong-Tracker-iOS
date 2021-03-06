//
//  ScoreStepper.swift
//  Pong-Tracker
//
//  Created by Christian Gossain on 2015-06-04.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

class ScoreStepper: UIStepper {
    var previousValue = 0.0
    var valueChangedAction: ((change: Double) -> Void)?
    var team: Team? {
        willSet {
            if let t = team {
                // disable
                //self.enabled = false
                
                // remove observers
                t.removeObserver(self, forKeyPath: "currentScore");
            }
        }
        didSet {
            if let t = team {
                // enable
                //self.enabled = true
                
                // remove observers
                t.addObserver(self, forKeyPath: "currentScore", options: [], context: nil)
            }
            else {
                //self.value = 0.0 // reset the value
            }
        }
    }
    
    deinit {
        self.team = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.autorepeat = false
        
        // add self as target
        self.addTarget(self, action: "stepperValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
    }
    
    func stepperValueChanged(sender: UIStepper) {
        let diff = sender.value - previousValue
        
        previousValue = sender.value
        
        if let action = valueChangedAction {
            action(change: diff)
        }
        
    }
    
    // MARK: - KVO
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "currentScore" {
            let currentScore = self.team?.currentScore
            
            self.value = Double(currentScore ?? 0)
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}
