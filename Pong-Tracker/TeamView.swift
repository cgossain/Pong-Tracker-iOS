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
    let containerView = UIView()
    let centeringView = UIView()
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
    
    // MARK: - Initialization
    
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
        self.addSubview(headerView)
        
        // configure content view
        self.addSubview(containerView)
        
        containerView.addSubview(centeringView)
        
        // increment button
        centeringView.addSubview(incrementButton)
        
        // decrement button
        centeringView.addSubview(decrementButton)
        
        // configure content view
        centeringView.addSubview(scoreLabel)
        
        // configure content view
        centeringView.addSubview(nameLabel)
        
        // configure content view
        self.addSubview(playerAvatarView)
        
        // configure view UI
        self.configureViewElements()
    }
    
    func configureViewElements() {
        // configure the decrement button
        self.decrementButton.contentEdgeInsets = UIEdgeInsetsMake(-5, 0, 0, 0)
        self.decrementButton.tintColor = UIColor.whiteColor()
        self.decrementButton.layer.cornerRadius = 22
        self.decrementButton.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        self.decrementButton.titleLabel?.font = UIFont.systemFontOfSize(32)
        self.decrementButton.setTitle("-", forState: .Normal)
        
        // configure the increment button
        self.incrementButton.contentEdgeInsets = UIEdgeInsetsMake(-5, 0, 0, 0)
        self.incrementButton.tintColor = UIColor.whiteColor()
        self.incrementButton.layer.cornerRadius = 22
        self.incrementButton.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        self.incrementButton.titleLabel?.font = UIFont.systemFontOfSize(32)
        self.incrementButton.setTitle("+", forState: .Normal)
        
        // configure the score label
        self.scoreLabel.font = UIFont.systemFontOfSize(100.0)
        self.scoreLabel.textColor = UIColor.whiteColor()
        self.scoreLabel.text = "0"
        
        // configure the name label
        self.nameLabel.font = UIFont.systemFontOfSize(48.0)
        self.nameLabel.textColor = UIColor.whiteColor()
        self.nameLabel.text = "John Doe"
        self.nameLabel.textAlignment = .Center
        
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
            
            self.containerView.layer.borderColor = UIColor.redColor().CGColor
            self.containerView.layer.borderWidth = 1.0
            
            self.centeringView.layer.borderColor = UIColor.purpleColor().CGColor
            self.centeringView.layer.borderWidth = 1.0
        }
    }
    
    // MARK: - Constraints
    
    override func updateConstraints() {
        self.decrementButton.mas_remakeConstraints { make in
            make.leading.equalTo()(self.centeringView).with().offset()(60);
            make.centerY.equalTo()(self.scoreLabel)
            make.width.mas_equalTo()(44)
            make.height.mas_equalTo()(44)
        }
        
        self.scoreLabel.mas_remakeConstraints { make in
            make.top.equalTo()(self.centeringView)
            make.bottom.equalTo()(self.nameLabel.mas_top)
            make.centerX.equalTo()(self.centeringView)
        }
        
        self.incrementButton.mas_remakeConstraints { make in
            make.trailing.equalTo()(self.centeringView).with().offset()(-60);
            make.centerY.equalTo()(self.scoreLabel)
            make.width.mas_equalTo()(44)
            make.height.mas_equalTo()(44)
        }
        
        self.nameLabel.mas_remakeConstraints { make in
            make.leading.equalTo()(self.centeringView)
            make.trailing.equalTo()(self.centeringView)
            make.bottom.equalTo()(self.centeringView)
        }
        
        self.headerView.mas_remakeConstraints { make in
            make.leading.equalTo()(self)
            make.top.equalTo()(self)
            make.trailing.equalTo()(self)
            make.height.equalTo()(80)
        }
        
        self.containerView.mas_remakeConstraints { make in
            make.leading.equalTo()(self)
            make.top.equalTo()(self.headerView.mas_bottom)
            make.trailing.equalTo()(self)
            make.bottom.equalTo()(self.playerAvatarView.mas_top)
        }
        
        self.centeringView.mas_remakeConstraints { make in
            make.leading.equalTo()(self.containerView)
            make.trailing.equalTo()(self.containerView)
            make.centerY.equalTo()(self.containerView)
        }
        
        self.playerAvatarView.mas_remakeConstraints { make in
            make.top.equalTo()(self.containerView.mas_bottom)
            make.bottom.equalTo()(self)
            make.centerX.equalTo()(self)
        }
        
        super.updateConstraints()
    }
    
    // MARK: - Methods (Public)
    
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
    
    // MARK: - Methods (Private)
    
    private func setTeamInfoShown(shown: Bool) {
        if shown {
            self.containerView.alpha = 1.0
            self.playerAvatarView.alpha = 1.0
            self.selectPlayerButton.alpha = 0.0;
        }
        else {
            self.containerView.alpha = 0.0
            self.playerAvatarView.alpha = 0.0
            self.selectPlayerButton.alpha = 1.0;
        }
    }
    
    // MARK: - KVO
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
            if keyPath == "isServing" {
                let isServing = self.team?.isServing ?? false
                let changed = self.headerView.isServing != isServing
                
                // speak
                if isServing && changed {
                    SpeechHelper.sharedSpeechHelper.utterServingTeam(self.team!)
                }
                self.headerView.isServing = isServing
            }
            else if keyPath == "hasMatchPoint" {
                let isMatchPoint = self.team?.hasMatchPoint ?? false
                let changed = self.headerView.isMatchPoint != isMatchPoint
                
                // speak
                if isMatchPoint && changed {
                    SpeechHelper.sharedSpeechHelper.utterMatchPointTeam(self.team!)
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
