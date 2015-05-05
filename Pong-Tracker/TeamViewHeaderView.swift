//
//  TeamViewHeaderView.swift
//  Pong-Tracker
//
//  Created by Christian R. Gossain on 2015-05-04.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

class TeamViewHeaderView: UIView {

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

}
