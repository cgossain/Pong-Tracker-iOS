//
//  AvatarTableViewCell.swift
//  Pong-Tracker
//
//  Created by Christian Gossain on 2015-07-05.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

class AvatarTableViewCell: UITableViewCell {
    
    let avatarView = AvatarView(size: .Small)
    let titleLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    func commonInit() {
        // avatar view
        self.contentView.addSubview(avatarView)
        
        // title label
        self.contentView.addSubview(titleLabel)
        titleLabel.setContentHuggingPriority((UILayoutPriorityFittingSizeLevel - 10), forAxis: .Horizontal)
        titleLabel.textAlignment = .Left
        
        // constraints
        self.setupConstraints()
    }
    
    // MARK: Constraints
    
    func setupConstraints() {
        // avatar view
        avatarView.mas_makeConstraints { make in
            make.top.equalTo()(self.contentView.mas_top).with().offset()(8)
            make.bottom.equalTo()(self.contentView.mas_bottom).with().offset()(-8)
            make.leading.equalTo()(self.contentView.mas_leading).with().offset()(15)
        }
        
        // title label
        titleLabel.mas_makeConstraints { make in
            make.leading.equalTo()(self.avatarView.mas_trailing).with().offset()(15)
            make.centerY.equalTo()(self.contentView)
        }
    }
}
