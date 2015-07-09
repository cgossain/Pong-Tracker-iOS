//
//  Player.swift
//  
//
//  Created by Christian Gossain on 2015-07-05.
//
//

import Foundation
import CoreData

class Player: NSManagedObject {

    @NSManaged var firstName: String?
    @NSManaged var lastName: String?
    @NSManaged var tagID: String?
    
    class func createInManagedObjectContext(moc: NSManagedObjectContext) -> Player {
        let newItem = NSEntityDescription.insertNewObjectForEntityForName("Player", inManagedObjectContext: moc) as! Pong_Tracker.Player
        
        return newItem
    }

}
