//
//  Player.swift
//  Pong-Tracker
//
//  Created by Christian R. Gossain on 2015-05-05.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

class Player {
    var firstName: String
    var lastName: String
    
    /// The RFID tag
    var playerID: String?
    
    init(firstName: String, lastName: String) {
        self.firstName = firstName
        self.lastName = lastName
    }
}
