//
//  GSCoreDataDeduplicationManager.h
//  ProTracker Plus
//
//  Created by Christian R. Gossain on 2014-09-30.
//  Copyright (c) 2014 Gossain Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@protocol GSCoreDataDeduplicator <NSObject>

/**
 Asks the delegate for an array of unique attributes for a particular entity; the first object specifies the primary key to be used for determining uniqueness. Any subsequent objects are used to further refine the determination of uniqueness for NSManagedObjects with duplicate values.
 @param entityName The name of the entity for which unique attributes are being requested.
 @return An array of strings representing the attributes to use to identify duplicate objects. Return nil to prevent any deduplication of the specified entity.
 */
- (NSArray *)uniqueAttributesForEntityName:(NSString *)entityName;

/**
 Asks the delegate which of the objects in the @em duplicates array should be kept.
 @param duplicates An array of duplicate managed objects that were found.
 @param entityName The entity name of the duplicate objects.
 @return One of the NSManagedObjects from the @em duplicates array. The object returned is the managed object that will be kept; all other duplicates are deleted. Returning nil will leave all duplicates intact.
 @note The managed object context is saved if it contains changes after each call to this method.
 */
- (NSManagedObject *)managedObjectToKeepFromDuplicates:(NSArray *)duplicates forEntityName:(NSString *)entityName;

@end

@interface GSCoreDataDeduplicationManager : NSObject

/**
 Registers an object that conforms to the @em GSCoreDataDeduplicator protocol to be used as the deduplicator object. Deduplicator objects must implement the @em GSCoreDataDeduplicator protocol; This protocol allows the deduplication manager to determine which NSManagedObjects are duplicates. It also allows the deduplicator object to decide which of the duplicate objects should be kept.
 @Warning A deduplicator object must be provided in order for the manager to know how to deduplicate your data model.
 */
- (void)registerDeduplicator:(id <GSCoreDataDeduplicator> )deduplicator;

/**
 A deduplicator class must be registered before using this method. The managed object context is saved each time duplicates are deleted.
 */
- (void)deDuplicateEntityWithName:(NSString *)entityName inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 Brute force deduplication of the entire core data store. The managed object context is saved each time duplicates are deleted.
 */
- (void)deDuplicateObjectsInManagedObjectContext:(NSManagedObjectContext *)context;

@end
