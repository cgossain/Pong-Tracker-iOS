//
//  StatusIndicator.swift
//  Pong-Tracker
//
//  Created by Christian Gossain on 2015-06-23.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

let kResetTimeInterval = 30.0 // the RFID reader and Particle board trigger at 15 second intervals

class StatusIndicator: UIView {
    
    var isOnline: Bool = false {
        didSet {
            if isOnline {
                // invalidate the timer if it exists
                self.timer?.invalidate()
                
                // schedule/reshedule a timer to reset the indicator back to "offline"
                self.timer = NSTimer.scheduledTimerWithTimeInterval(kResetTimeInterval, target: self, selector: "resetTimerFired:", userInfo: nil, repeats: true)
                
                // update the background color
                self.backgroundColor = UIColor.greenColor()
            }
            else {
                // invalidate the reset timer
                self.timer?.invalidate()
                
                // update the background color
                self.backgroundColor = UIColor.redColor()
            }
        }
    }
    var timer: NSTimer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    func commonInit() {
        self.layer.cornerRadius = 20.0/2.0
        self.isOnline = false
    }
    
    // MARK: Constraints
    
    override func intrinsicContentSize() -> CGSize {
        return CGSizeMake(20, 20)
    }
    
    // MARK: Methods (Private)
    
    func resetTimerFired(timer: NSTimer) {
        // reset back to the offline status
        self.isOnline = false
    }
}