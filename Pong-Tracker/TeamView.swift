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
    let playerAvatarView = AvatarView(size: .Large)
    let incrementButton: UIButton = UIButton.buttonWithType(.System) as! UIButton
    let decrementButton: UIButton = UIButton.buttonWithType(.System) as! UIButton
    
    var team: Team? {
        willSet (newTeam) {
            // remove current observers
            if let currentTeam = team {
                currentTeam.removeObserver(self, forKeyPath: "isServing")
                currentTeam.removeObserver(self, forKeyPath: "hasMatchPoint")
                currentTeam.removeObserver(self, forKeyPath: "currentScore")
            }
        }
        didSet {
            // update the view accordingly
            if let aTeam = team {
                // load in the data
                nameLabel.text = (aTeam.playerOne.firstName ?? "") + " " + (aTeam.playerOne.lastName ?? "")
                
//                // set the avatar view
//                if let picture = aTeam.playerOne.picture {
//                    playeyAvatarView.hidden = false
//                }
//                else {
//                    playeyAvatarView.hidden = true
//                }
                
                // pass the player to the avatar
                playerAvatarView.player = aTeam.playerOne
                
                // observe some properties
                aTeam.addObserver(self, forKeyPath: "isServing", options: NSKeyValueObservingOptions.Initial, context: nil)
                aTeam.addObserver(self, forKeyPath: "hasMatchPoint", options: NSKeyValueObservingOptions.Initial, context: nil)
                aTeam.addObserver(self, forKeyPath: "currentScore", options: NSKeyValueObservingOptions.Initial, context: nil)
                
                // show team info
                self.setTeamInfoShown(true);
            }
            else {
                // hide team info
                self.setTeamInfoShown(false);
            }
            
            // reset the header
            self.headerView.isServing = false
            self.headerView.isMatchPoint = false
            self.scoreLabel.text = "0"
        }
    }
    
    @IBOutlet weak var selectPlayerButton: UIButton!
    
    // keep track of the constraints added by this view
    var rootLayoutConstraints = [AnyObject]()
    
    // MARK: Initialization
    
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
    
    deinit {
        self.team = nil
    }
    
    func commonInit() {
        self.backgroundColor = kBlueColor
        
        // configure content view
        headerView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(headerView)
        
        // configure content view
        topContainerView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(topContainerView)
        
        // increment button
        topContainerView.addSubview(incrementButton)
        
        // decrement button
        topContainerView.addSubview(decrementButton)
        
        // configure content view
        scoreLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        topContainerView.addSubview(scoreLabel)
        
        // configure content view
        nameLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        topContainerView.addSubview(nameLabel)
        
        // configure content view
        playerAvatarView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(playerAvatarView)
        
        // configure view UI
        self.configureViewElements()
        
        // constraints
        self.updateConstraints()
    }
    
    func configureViewElements() {
        // configure the decrement button
        self.decrementButton.contentEdgeInsets = UIEdgeInsetsMake(-5, 0, 0, 0)
        self.decrementButton.tintColor = UIColor.whiteColor()
        self.decrementButton.layer.cornerRadius = 22
        self.decrementButton.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        self.decrementButton.titleLabel?.font = UIFont.systemFontOfSize(32)
        self.decrementButton.setTitle("-", forState: .Normal)
        self.decrementButton.mas_makeConstraints { make in
            make.leading.equalTo()(self.topContainerView).with().offset()(60);
            make.centerY.equalTo()(self.scoreLabel)
            make.width.mas_equalTo()(44)
            make.height.mas_equalTo()(44)
        }
        
        // configure the increment button
        self.incrementButton.contentEdgeInsets = UIEdgeInsetsMake(-5, 0, 0, 0)
        self.incrementButton.tintColor = UIColor.whiteColor()
        self.incrementButton.layer.cornerRadius = 22
        self.incrementButton.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        self.incrementButton.titleLabel?.font = UIFont.systemFontOfSize(32)
        self.incrementButton.setTitle("+", forState: .Normal)
        self.incrementButton.mas_makeConstraints { make in
            make.trailing.equalTo()(self.topContainerView).with().offset()(-60);
            make.centerY.equalTo()(self.scoreLabel)
            make.width.mas_equalTo()(44)
            make.height.mas_equalTo()(44)
        }
        
        // configure the score label
        self.scoreLabel.font = UIFont.systemFontOfSize(100.0)
        self.scoreLabel.textColor = UIColor.whiteColor()
        self.scoreLabel.text = "0"
        
        // configure the name label
        self.nameLabel.font = UIFont.systemFontOfSize(24.0)
        self.nameLabel.textColor = UIColor.whiteColor()
        self.nameLabel.text = "John Doe"
        
        // debug layout
        if debugLayout {
            self.scoreLabel.layer.borderColor = UIColor.greenColor().CGColor
            self.scoreLabel.layer.borderWidth = 1.0
            
            self.nameLabel.layer.borderColor = UIColor.greenColor().CGColor
            self.nameLabel.layer.borderWidth = 1.0
            
            self.playerAvatarView.layer.borderColor = UIColor.greenColor().CGColor
            self.playerAvatarView.layer.borderWidth = 1.0
            
            self.selectPlayerButton?.layer.borderColor = UIColor.greenColor().CGColor
            self.selectPlayerButton?.layer.borderWidth = 1.0
            
            self.topContainerView.layer.borderColor = UIColor.redColor().CGColor
            self.topContainerView.layer.borderWidth = 1.0
        }
    }
    
    // MARK: Constraints
    
    override func updateConstraints() {
        // remove any existing constraints
        if self.rootLayoutConstraints.count > 0 {
            self.removeConstraints(self.rootLayoutConstraints)
            self.rootLayoutConstraints.removeAll(keepCapacity: false)
        }
        
        // group all the content view into an array
        let views = ["headerView" : self.headerView, "topContainer" : self.topContainerView, "score" : self.scoreLabel, "name" : self.nameLabel, "avatar" : self.playerAvatarView]
        
        // configure the various constraints
        let headerViewLTR = NSLayoutConstraint.constraintsWithVisualFormat("|-0-[headerView]-0-|", options: nil, metrics: nil, views: views)
        let topContainerLTR = NSLayoutConstraint.constraintsWithVisualFormat("|-0-[topContainer]-0-|", options: nil, metrics: nil, views: views)
        
        let scoreLabelCenterY = NSLayoutConstraint(
            item: self.scoreLabel,
            attribute: NSLayoutAttribute.CenterY,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self.topContainerView,
            attribute: NSLayoutAttribute.CenterY,
            multiplier: 1.0,
            constant: 0.0
        )
        
        let scoreLabelCenterX = NSLayoutConstraint(
            item: self.scoreLabel,
            attribute: NSLayoutAttribute.CenterX,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self.topContainerView,
            attribute: NSLayoutAttribute.CenterX,
            multiplier: 1.0,
            constant: 0.0
        )
        
        let topContainerTTB = NSLayoutConstraint.constraintsWithVisualFormat("V:[score]-0-[name]", options: NSLayoutFormatOptions.AlignAllCenterX, metrics: nil, views: views)
        let verticalTTB = NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[headerView(80)]-0-[topContainer]-40-[avatar]-0-|", options: NSLayoutFormatOptions.AlignAllCenterX, metrics: nil, views: views)
        
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
    
    // MARK: Methods (Public)
    
    func setTeamInfoShown(shown: Bool, animated: Bool) {
        if animated {
            UIView.animateWithDuration(0.1,
                delay: 0.0,
                options: UIViewAnimationOptions.CurveEaseInOut,
                animations: { () -> Void in
                    self.setTeamInfoShown(shown)
                },
                completion: nil)
        }
        else {
            self.setTeamInfoShown(shown);
        }
    }
    
    // MARK: Methods (Private)
    
    private func setTeamInfoShown(shown: Bool) {
        if shown {
            self.topContainerView.alpha = 1.0
            self.playerAvatarView.alpha = 1.0
            self.selectPlayerButton.alpha = 0.0;
        }
        else {
            self.topContainerView.alpha = 0.0
            self.playerAvatarView.alpha = 0.0
            self.selectPlayerButton.alpha = 1.0;
        }
    }
    
    // MARK: KVO
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
            if keyPath == "isServing" {
                var isServing = false
                
                if let aTeam = self.team {
                    isServing = aTeam.isServing
                }
                self.headerView.isServing = isServing
            }
            else if keyPath == "hasMatchPoint" {
                var isMatchPoint = false
                
                if let aTeam = self.team {
                    isMatchPoint = aTeam.hasMatchPoint
                }
                self.headerView.isMatchPoint = isMatchPoint
            }
            else if keyPath == "currentScore" {
                var score = 0
                
                if let aTeam = self.team {
                    score = aTeam.currentScore
                }
                self.scoreLabel.text = String(score)
            }
            else {
                super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            }
    }

}
