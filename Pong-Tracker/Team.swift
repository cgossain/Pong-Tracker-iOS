//
//  Team.swift
//  Pong-Tracker
//
//  Created by Christian R. Gossain on 2015-05-05.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

class Team: NSObject {
    var playerOne: Player
    var playerTwo: Player?
    
    var name: String
    var isServing = false {
        willSet {
            self.willChangeValueForKey("isServing")
        }
        didSet {
            self.didChangeValueForKey("isServing")
        }
    }
    
    var currentScore = 0 {
        willSet {
            self.willChangeValueForKey("currentScore")
        }
        didSet {
            self.didChangeValueForKey("currentScore")
        }
    }
    
    init(name: String, playerOne: Player, playerTwo: Player?) {
        self.name = name
        self.playerOne = playerOne
        self.playerTwo = playerTwo
    }
}
