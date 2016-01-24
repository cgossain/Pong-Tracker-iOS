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
    case PreDefined
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
                p.addObserver(self, forKeyPath: "firstName", options: [], context: nil)
                p.addObserver(self, forKeyPath: "lastName", options: [], context: nil)
                p.addObserver(self, forKeyPath: "picture", options: [], context: nil)
            }
            
            // update the label
            self.updateAvatar()
        }
    }
    
    let initialsLabel = UILabel()
    let imageView = UIImageView()
    let avatarViewSize: AvatarViewSize?
    
    // MARK: KVO
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "firstName" || keyPath == "lastName" || keyPath == "picture" {
            self.updateAvatar()
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    // MARK: - Initialization
    
    init(size: AvatarViewSize) {
        avatarViewSize = size
        super.init(frame: CGRectZero)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        avatarViewSize = AvatarViewSize.PreDefined
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    func commonInit() {
        self.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
        self.clipsToBounds = true
        
        if self.avatarViewSize == .Small {
            self.layer.cornerRadius = CGFloat(self.desiredDiameter() / 2.0)
        }
        
        self.addSubview(initialsLabel)
        initialsLabel.textColor = UIColor.whiteColor()
        
        self.addSubview(imageView)
        imageView.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        imageView.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Vertical)
        
        imageView.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        imageView.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Vertical)
        
        imageView.layer.borderColor = UIColor.greenColor().CGColor
        imageView.layer.borderWidth = 1.0
        
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
        initialsLabel.mas_makeConstraints { make in
            make.center.equalTo()(self)
        }
        
        // image view
        imageView.mas_makeConstraints { make in
            make.edges.equalTo()(self)
            
            if self.avatarViewSize != .PreDefined {
                make.width.equalTo()(self.desiredDiameter())
                make.height.equalTo()(self.desiredDiameter())
            }
        }
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
                if firstName.characters.count > 0 {
                    let index: String.Index = firstName.startIndex.advancedBy(1)
                    firstInitial = firstName.substringToIndex(index)
                }
                // extract the last initial
                let lastName = p.valueForKey("lastName") as? String ?? ""
                var lastInitial = ""
                if lastName.characters.count > 0 {
                    let index: String.Index = lastName.startIndex.advancedBy(1)
                    lastInitial = lastName.substringToIndex(index)
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
