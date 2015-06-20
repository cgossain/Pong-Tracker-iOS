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
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.autorepeat = true
        
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
}
