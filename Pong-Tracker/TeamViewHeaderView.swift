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
    let titleLabel = UILabel()
    
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
        // background color
        self.backgroundColor = UIColor.darkGrayColor().colorWithAlphaComponent(0.8)
        
        // label style
        titleLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(titleLabel)
        
        titleLabel.font = UIFont.systemFontOfSize(28.0)
        titleLabel.textColor = UIColor.whiteColor()
        
        // center the label in x and y
        self.addConstraint(NSLayoutConstraint(item: titleLabel, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0));
        self.addConstraint(NSLayoutConstraint(item: titleLabel, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0));
        
    }
    
    func updateHeader() {
        if isServing && isMatchPoint {
            // begin w/ serving
            self.showingServing = true
            
            // update state
            self.setIndicatorState(.Serving)
            
            // alternate banners
            self.timer?.invalidate()
            self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "timerFired", userInfo: nil, repeats: true)
        }
        else if isServing {
            // update state
            self.setIndicatorState(.Serving)
            
            self.timer?.invalidate()
            self.timer = nil
        }
        else if isMatchPoint {
            // update state
            self.setIndicatorState(.MatchPoint)
            
            self.timer?.invalidate()
            self.timer = nil
        }
        else {
            // update state
            self.setIndicatorState(.Resting)
        }
    }
    
    func timerFired() {
        if self.showingServing {
            self.showingServing = false
            
            // switch to match point
            self.setIndicatorState(.MatchPoint)
        }
        else {
            self.showingServing = true
            
            // switch to serving
            self.setIndicatorState(.Serving)
        }
    }
    
    // MARK: Methods (Private)
    
    enum HeaderViewState {
        case Resting
        case Serving
        case MatchPoint
    }
    
    func setIndicatorState(state: HeaderViewState) -> Void {
        switch state {
            
        case .Resting:
            // show match point
            self.backgroundColor = self.restingColor()
            
            // text
            self.titleLabel.text = ""
            
        case .Serving:
            // show serving
            self.backgroundColor = self.servingColor()
            
            // text
            self.titleLabel.text = "Serving"
            
        case .MatchPoint:
            // show match point
            self.backgroundColor = self.matchPointColor()
            
            // text
            self.titleLabel.text = "Match Point"
        }
    }
    
    // MARK: Helpers
    
    func restingColor() -> UIColor {
        return UIColor.darkGrayColor().colorWithAlphaComponent(0.8)
    }
    
    func servingColor() -> UIColor {
        return UIColor.greenColor().colorWithAlphaComponent(1.0)
    }
    
    func matchPointColor() -> UIColor {
        return UIColor.orangeColor().colorWithAlphaComponent(1.0)
    }

}
