//
//  RootView.swift
//  Pong-Tracker
//
//  Created by Christian R. Gossain on 2015-05-04.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

class RootView: UIView {
    
    let topContentContainerView = UIView()
    let firstTeamContentView = UIView()
    let secondTeamContentView = UIView()
    let controlPadContentView = UIView()
    
    // keep track of the constraints added by this view
    var rootLayoutConstraints: [AnyObject] = []
    
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
        // configure content view
        topContentContainerView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(topContentContainerView)
        
        // configure content view
        firstTeamContentView.setTranslatesAutoresizingMaskIntoConstraints(false)
        topContentContainerView.addSubview(firstTeamContentView)
        
        // configure content view
        secondTeamContentView.setTranslatesAutoresizingMaskIntoConstraints(false)
        topContentContainerView.addSubview(secondTeamContentView)
        
        // configure content view
        controlPadContentView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(controlPadContentView)
        
        // background colors
        self.configureBackgroundColors()
        
        // constraints
        self.setNeedsUpdateConstraints()
    }
    
    func configureBackgroundColors() {
        
        self.firstTeamContentView.backgroundColor = UIColor.redColor()
        self.secondTeamContentView.backgroundColor = UIColor.blueColor()
        self.controlPadContentView.backgroundColor = UIColor.orangeColor()
        
    }
    
    override func updateConstraints() {
        // remove any existing constraints
        if self.rootLayoutConstraints.count > 0 {
            self.removeConstraints(self.rootLayoutConstraints)
            self.rootLayoutConstraints.removeAll(keepCapacity: false)
        }
        
        // group all the content view into an array
        let views = ["topContainer" : self.topContentContainerView, "firstTeam" : self.firstTeamContentView, "secondTeam" : self.secondTeamContentView, "controlPad" : self.controlPadContentView]
        let metrics = ["teamContentWidth" : (self.bounds.size.width / 2.0)]
        
        // configure the various constraints
        let teamLTR = NSLayoutConstraint.constraintsWithVisualFormat("|-0-[firstTeam(teamContentWidth)]-0-[secondTeam(teamContentWidth)]-0-|", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: metrics, views: views)
        
        let firstTeamTTB = NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[firstTeam]-0-|", options: nil, metrics: nil, views: views)
        
        let secondTeamTTB = NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[secondTeam]-0-|", options: nil, metrics: nil, views: views)
        
        let topContainerLTR = NSLayoutConstraint.constraintsWithVisualFormat("|-0-[topContainer]-0-|", options: nil, metrics: nil, views: views)
        
        let controlPadLTR = NSLayoutConstraint.constraintsWithVisualFormat("|-0-[controlPad]-0-|", options: nil, metrics: nil, views: views)
        
        let containerTTB = NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[topContainer]-0-[controlPad(200)]-0-|", options: nil, metrics: nil, views: views)
        
        // add the constraitns to the tracking array
        self.rootLayoutConstraints += teamLTR
        self.rootLayoutConstraints += firstTeamTTB
        self.rootLayoutConstraints += secondTeamTTB
        self.rootLayoutConstraints += topContainerLTR
        self.rootLayoutConstraints += controlPadLTR
        self.rootLayoutConstraints += containerTTB
        
        // add the constaints
        self.addConstraints(self.rootLayoutConstraints)
        
        // call the super implementation
        super.updateConstraints()
    }

}
