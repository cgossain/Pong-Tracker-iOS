//
//  AvatarView.swift
//  Pong-Tracker
//
//  Created by Christian Gossain on 2015-07-05.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

enum AvatarViewSize {
    case Small
    case Large
}

class AvatarView: UIControl {
    
    var player: Player? {
        willSet {
            if let p = player {
                // remove observers from the existing player
                p.removeObserver(self, forKeyPath: "firstName")
                p.removeObserver(self, forKeyPath: "lastName")
                p.removeObserver(self, forKeyPath: "picture")
            }
        }
        didSet {
            if let p = player {
                // add observers to the new player
                p.addObserver(self, forKeyPath: "firstName", options: nil, context: nil)
                p.addObserver(self, forKeyPath: "lastName", options: nil, context: nil)
                p.addObserver(self, forKeyPath: "picture", options: nil, context: nil)
            }
            
            // update the label
            self.updateAvatar()
        }
    }
    
    let initialsLabel = UILabel()
    let imageView = UIImageView()
    let avatarViewSize: AvatarViewSize?
    
    // MARK: KVO
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if keyPath == "firstName" || keyPath == "lastName" || keyPath == "picture" {
            self.updateAvatar()
        }
        else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    // MARK: - Initialization
    
    init(size: AvatarViewSize) {
        avatarViewSize = size
        super.init(frame: CGRectZero)
        self.commonInit()
    }

    required init(coder aDecoder: NSCoder) {
        avatarViewSize = AvatarViewSize.Small // default to small
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    func commonInit() {
        // do not increase in size
        self.setContentHuggingPriority(1000, forAxis: UILayoutConstraintAxis.Horizontal)
        self.setContentHuggingPriority(1000, forAxis: UILayoutConstraintAxis.Vertical)
        
        self.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
        self.clipsToBounds = true
        
        if self.avatarViewSize == .Small {
            self.layer.cornerRadius = CGFloat(self.desiredDiameter()/2.0)
        }
        
        self.addSubview(initialsLabel)
        self.initialsLabel.textColor = UIColor.whiteColor()
        
        self.addSubview(imageView)
        
        self.setupConstraint()
    }
    
    deinit {
        if let p = self.player {
            // remove observers from the existing player
            p.removeObserver(self, forKeyPath: "firstName")
            p.removeObserver(self, forKeyPath: "lastName")
            p.removeObserver(self, forKeyPath: "picture")
        }
    }
    
    // MARK: Constraints
    
    func setupConstraint() {
        // initials label
        self.initialsLabel.mas_makeConstraints { make in
            make.center.equalTo()(self)
        }
        
        // image view
        self.imageView.mas_makeConstraints { make in
            make.edges.equalTo()(self)
        }
    }
    
    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: self.desiredDiameter(), height: self.desiredDiameter())
    }
    
    // MARK: - Methods (Private)
    
    func updateAvatar() {
        if let p = self.player {
            if let i = p.picture {
                self.imageView.hidden = false
                self.initialsLabel.hidden = true
                
                // extract the image
                self.imageView.image = UIImage(data: i)
            }
            else {
                self.imageView.hidden = true
                self.initialsLabel.hidden = false
                
                // extract the first initial
                let firstName = p.valueForKey("firstName") as? String ?? ""
                var firstInitial = ""
                if count(firstName) > 0 {
                    firstInitial = firstName.substringWithRange(Range<String.Index>(start: firstName.startIndex, end: advance(firstName.startIndex, 1)))
                }
                // extract the last initial
                let lastName = p.valueForKey("lastName") as? String ?? ""
                var lastInitial = ""
                if count(lastName) > 0 {
                    lastInitial = lastName.substringWithRange(Range<String.Index>(start: lastName.startIndex, end: advance(lastName.startIndex, 1)))
                }
                
                // set the initials
                self.initialsLabel.text = firstInitial + lastInitial
            }
        }
        else {
            self.imageView.image = nil
            self.initialsLabel.text = ""
        }
    }
    
    func desiredDiameter() -> Double {
        if self.avatarViewSize == .Large {
            return 220.0
        }
        return 60.0
    }

}
