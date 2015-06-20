//
//  TeamViewHeaderView.swift
//  Pong-Tracker
//
//  Created by Christian R. Gossain on 2015-05-04.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

class TeamViewHeaderView: UIView {
    
    var timer: NSTimer?
    
    var isServing: Bool = false {
        didSet {
            self.updateHeader()
        }
    }
    
    var isMatchPoint: Bool = false {
        didSet {
            self.updateHeader()
        }
    }
    
    var showingServing: Bool = false;

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // perform common init
        self.commonInit()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // perform common init
        self.commonInit()
    }
    
    func commonInit() {
        self.backgroundColor = UIColor.darkGrayColor().colorWithAlphaComponent(0.8)
    }
    
    func updateHeader() {
        if isServing && isMatchPoint {
            // serving
            self.backgroundColor = self.servingColor()
            self.showingServing = true
            
            // alternate banners
            self.timer?.invalidate()
            self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "timerFired", userInfo: nil, repeats: true)
        }
        else if isServing {
            self.backgroundColor = self.servingColor()
            self.timer?.invalidate()
            self.timer = nil
        }
        else if isMatchPoint {
            self.backgroundColor = self.matchPointColor()
            self.timer?.invalidate()
            self.timer = nil
        }
        else {
            self.backgroundColor = self.restingColor()
        }
    }
    
    func timerFired() {
        if self.showingServing {
            // show match point
            self.backgroundColor = self.matchPointColor()
            self.showingServing = false
        }
        else {
            // show serving
            self.backgroundColor = self.servingColor()
            self.showingServing = true
        }
    }
    
    // MARK: Helpers
    
    func restingColor() -> UIColor {
        return UIColor.darkGrayColor().colorWithAlphaComponent(0.8)
    }
    
    func servingColor() -> UIColor {
        return UIColor.greenColor().colorWithAlphaComponent(0.8)
    }
    
    func matchPointColor() -> UIColor {
        return UIColor.orangeColor().colorWithAlphaComponent(0.8)
    }

}
