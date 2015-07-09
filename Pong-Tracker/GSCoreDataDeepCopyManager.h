//
//  GSCoreDataDeepCopyManager.h
//  ProTracker Plus
//
//  Created by Christian R. Gossain on 2014-12-14.
//  Copyright (c) 2014 Gossain Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface GSCoreDataDeepCopyManager : NSObject

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel;

/**
 Adds an attribute to be excluded from migration, for the specified entity.
 @attention All exclusions accross all entities must be set before running the migration. Otherwise relationships traversed while migrating a specific entity, may not have proper exclusions configured at that point.
 */
- (void)excludeAttribute:(NSString *)attribute inEntityWithName:(NSString *)entityName;

/**
 Migrates all objects in the source context to the destination context.
 @param entityName The name of the entity objects to migrate.
 @param sourceContext The source managed object context from which to copy objects.
 @param destinationContext The destination managed object context to which object should be copied.
 @param error An error reference. This reference will be set if an error occurs during migration.
 @return Returns YES if the migration was successful, NO otherwise. If migration was not successful, the error object will be set and will contain more information.
 */
- (BOOL)migrateEntityWithName:(NSString *)entityName
            fromSourceContext:(NSManagedObjectContext *)sourceContext
         toDestinationContext:(NSManagedObjectContext *)destinationContext
                        error:(NSError **)error;

@end
