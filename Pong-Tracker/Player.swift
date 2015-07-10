//
//  Player.swift
//  
//
//  Created by Christian Gossain on 2015-07-09.
//
//

import Foundation
import CoreData

class Player: NSManagedObject {

    @NSManaged var firstName: String?
    @NSManaged var lastName: String?
    @NSManaged var tagID: String?
    @NSManaged var picture: NSData?
    
    class func createInManagedObjectContext(moc: NSManagedObjectContext) -> Player {
        let newItem = NSEntityDescription.insertNewObjectForEntityForName("Player", inManagedObjectContext: moc) as! Player//Pong_Tracker.Player
        
        return newItem
    }

}
