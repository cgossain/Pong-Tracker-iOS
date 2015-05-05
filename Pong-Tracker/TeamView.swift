//
//  TeamView.swift
//  Pong-Tracker
//
//  Created by Christian R. Gossain on 2015-05-04.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

let debugLayout = false

class TeamView: UIView {
    
    let headerView = TeamViewHeaderView()
    let scoreLabel = UILabel()
    let nameLabel = UILabel()
    let topContainerView = UIView()
    let playerImageView = UIImageView()
    
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
        headerView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(headerView)
        
        // configure content view
        topContainerView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(topContainerView)
        
        // configure content view
        scoreLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        topContainerView.addSubview(scoreLabel)
        
        // configure content view
        nameLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        topContainerView.addSubview(nameLabel)
        
        // configure content view
        playerImageView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(playerImageView)
        
        // configure view UI
        self.configureViewElements()
        
        // constraints
        self.setNeedsUpdateConstraints()
    }
    
    func configureViewElements() {
        // configure the header view
        
        // configure the score label
        self.scoreLabel.font = UIFont.systemFontOfSize(100.0)
        self.scoreLabel.textColor = UIColor.whiteColor()
        self.scoreLabel.text = "99"
        
        // configure the name label
        self.nameLabel.font = UIFont.systemFontOfSize(24.0)
        self.nameLabel.textColor = UIColor.whiteColor()
        self.nameLabel.text = "John Doe"
        
        // configure the player image view
        self.playerImageView.contentMode = UIViewContentMode.ScaleAspectFit
        self.playerImageView.image = UIImage(named: "ash")
        
        // debug layout
        if debugLayout {
            self.scoreLabel.layer.borderColor = UIColor.greenColor().CGColor
            self.scoreLabel.layer.borderWidth = 1.0
            
            self.nameLabel.layer.borderColor = UIColor.greenColor().CGColor
            self.nameLabel.layer.borderWidth = 1.0
            
            self.playerImageView.layer.borderColor = UIColor.greenColor().CGColor
            self.playerImageView.layer.borderWidth = 1.0
        }
    }
    
    override func updateConstraints() {
        // remove any existing constraints
        if self.rootLayoutConstraints.count > 0 {
            self.removeConstraints(self.rootLayoutConstraints)
            self.rootLayoutConstraints.removeAll(keepCapacity: false)
        }
        
        // group all the content view into an array
        let views = ["headerView" : self.headerView, "topContainer" : self.topContainerView, "score" : self.scoreLabel, "name" : self.nameLabel, "image" : self.playerImageView]
        
        // configure the various constraints
        let headerViewLTR = NSLayoutConstraint.constraintsWithVisualFormat("|-0-[headerView]-0-|", options: nil, metrics: nil, views: views)
        let topContainerLTR = NSLayoutConstraint.constraintsWithVisualFormat("|-0-[topContainer]-0-|", options: nil, metrics: nil, views: views)
        let scoreLabelCenterY = NSLayoutConstraint(item: self.scoreLabel, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self.topContainerView, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0)
        let scoreLabelCenterX = NSLayoutConstraint(item: self.scoreLabel, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.topContainerView, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0)
        let topContainerTTB = NSLayoutConstraint.constraintsWithVisualFormat("V:[score]-0-[name]", options: NSLayoutFormatOptions.AlignAllCenterX, metrics: nil, views: views)
        let verticalTTB = NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[headerView(80)]-0-[topContainer]-0-[image(200)]-0-|", options: NSLayoutFormatOptions.AlignAllCenterX, metrics: nil, views: views)
        
        // add the constraitns to the tracking array
        self.rootLayoutConstraints += headerViewLTR
        self.rootLayoutConstraints += topContainerLTR
        self.rootLayoutConstraints += [scoreLabelCenterY, scoreLabelCenterX]
        self.rootLayoutConstraints += topContainerTTB
        self.rootLayoutConstraints += verticalTTB
        
        // add the constaints
        self.addConstraints(self.rootLayoutConstraints)
        
        // call the super implementation
        super.updateConstraints()
    }

}