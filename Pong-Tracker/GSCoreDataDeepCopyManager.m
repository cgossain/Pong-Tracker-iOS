//
//  GSCoreDataDeepCopyManager.m
//  ProTracker Plus
//
//  Created by Christian R. Gossain on 2014-12-14.
//  Copyright (c) 2014 Gossain Software LLC. All rights reserved.
//

#import "GSCoreDataDeepCopyManager.h"

@interface GSCoreDataDeepCopyManager ()
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSManagedObjectContext *sourceContext;
@property (nonatomic, strong) NSManagedObjectContext *destinationContext;

@property (nonatomic, strong) NSMutableDictionary *migratedIDsKeyedBySourceID;
@property (nonatomic, strong) NSMutableArray *sourceObjectIDsOfUnsavedCounterparts;
@property (nonatomic, strong) NSMutableDictionary *excludedAttributesKeyedByEntityName;
@end

@implementation GSCoreDataDeepCopyManager

#pragma mark - Initilization

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel {
    
    self = [self init];
    if (self) {
        _managedObjectModel = managedObjectModel;
        _migratedIDsKeyedBySourceID = [NSMutableDictionary dictionaryWithCapacity:500];
        _sourceObjectIDsOfUnsavedCounterparts = [NSMutableArray arrayWithCapacity:500];
        _excludedAttributesKeyedByEntityName = [NSMutableDictionary dictionary];
    }
    return self;
    
}

#pragma mark - Pre-Migration

- (void)excludeAttribute:(NSString *)attribute inEntityWithName:(NSString *)entityName {
    
    // grab the existing set associated with the entity, or create a new one if there is no set
    NSMutableSet *excludedAttributesSet = self.excludedAttributesKeyedByEntityName[entityName];
    if (!excludedAttributesSet) {
        excludedAttributesSet = [NSMutableSet set];
    }
    
    // add the attribute to the set associated with the specified entity
    [excludedAttributesSet addObject:attribute];
    
    // store the set in the dictionnary
    self.excludedAttributesKeyedByEntityName[entityName] = excludedAttributesSet;
    
}

#pragma mark - Migration

- (BOOL)migrateEntityWithName:(NSString *)entityName
            fromSourceContext:(NSManagedObjectContext *)sourceContext
         toDestinationContext:(NSManagedObjectContext *)destinationContext
                        error:(NSError *__autoreleasing *)error {
    
    NSUInteger batchSize = 15;
    
    self.sourceContext = sourceContext;
    self.destinationContext = destinationContext;
    
    NSEntityDescription *entity = [self.managedObjectModel.entitiesByName objectForKey:entityName];
    
    NSFetchRequest *fetch = [[NSFetchRequest alloc] initWithEntityName:entityName];
    fetch.fetchBatchSize = batchSize;
    fetch.relationshipKeyPathsForPrefetching = entity.relationshipsByName.allKeys;
    
    NSArray *sourceManagedObjects = [sourceContext executeFetchRequest:fetch error:error];
    if (!sourceManagedObjects) {
        return NO;
    }
    
    __block BOOL success = YES;
    
    [sourceManagedObjects enumerateObjectsUsingBlock:^(NSManagedObject *rootManagedObject, NSUInteger idx, BOOL *stop) {
        
        @autoreleasepool {
            
            // migrate the root managed object from the source context to the destination context
            [self migrateRootManagedObject:rootManagedObject];
            
            // save each time the end of the batch is reached
            if ((idx % fetch.fetchBatchSize) == 0) {
                if (![self save:error]) {
                    success = NO;
                    *stop = YES;
                };
            }
            
        }
        
    }];
    
    // check if saving in the loop failed
    if (!success) {
        return NO;
    }
    
    // save once more
    return [self save:error];
    
}

- (NSManagedObject *)migrateRootManagedObject:(NSManagedObject *)rootManagedObject {
    
    if (!rootManagedObject) {
        return nil;
    }
    
    NSManagedObjectID *destinationObjectID = [self.migratedIDsKeyedBySourceID objectForKey:rootManagedObject.objectID];
    
    if (destinationObjectID) {
        return [self.destinationContext objectWithID:destinationObjectID]; // the object has alredy been migrated
    }
    
    NSManagedObject *destinationManagedObject;
    
    @autoreleasepool {
        
        NSEntityDescription *entityDescription = rootManagedObject.entity;
        
        // insert a new object in the destination context
        destinationManagedObject = [NSEntityDescription insertNewObjectForEntityForName:entityDescription.name
                                                                 inManagedObjectContext:self.destinationContext];
        
        // keep track of the migrated object
        [self.migratedIDsKeyedBySourceID setObject:destinationManagedObject.objectID forKey:rootManagedObject.objectID];
        [self.sourceObjectIDsOfUnsavedCounterparts addObject:rootManagedObject.objectID];
        
        // copy the attributes from the source object to the destination object
        NSSet *exclusions = self.excludedAttributesKeyedByEntityName[entityDescription.name];
        NSArray *attributeKeys = entityDescription.attributesByName.allKeys;
        for (NSString *attributeKey in attributeKeys) {
            if ([exclusions containsObject:attributeKey]) {
                continue; // skip this attribute
            }
            [destinationManagedObject setPrimitiveValue:[rootManagedObject primitiveValueForKey:attributeKey] forKey:attributeKey];
        }
        
        // recursively copy the source object relationships to the destination object
        for (NSRelationshipDescription *relationshipDescription in entityDescription.relationshipsByName.allValues) {
            
            NSString *relationshipName = relationshipDescription.name;
            
            id destinationRelationshipValue;
            
            // determine the relationship type and handle accordingly
            if (relationshipDescription.isToMany) {
                
                destinationRelationshipValue = [[destinationManagedObject primitiveValueForKey:relationshipName] mutableCopy]; // should be an NSSet of managed objects or nil
                
                for (NSManagedObject *sourceRelationshipValue in [rootManagedObject primitiveValueForKey:relationshipName]) {
                    NSManagedObject *destinationObject = [self migrateRootManagedObject:sourceRelationshipValue];
                    [destinationRelationshipValue addObject:destinationObject];
                }
                
            }
            else {
                NSManagedObject *sourceRelationshipValue = [rootManagedObject primitiveValueForKey:relationshipName]; // should be the managed object or nil
                destinationRelationshipValue = (sourceRelationshipValue ? [self migrateRootManagedObject:sourceRelationshipValue] : nil);
            }
            [destinationManagedObject setPrimitiveValue:destinationRelationshipValue forKey:relationshipName];
            
        }
        
    }
    
    return destinationManagedObject;
    
}

#pragma mark - Saving

- (BOOL)save:(NSError **)error {
    
    BOOL success = [self saveDestinationContext:error];
    
    [self.destinationContext reset];
    
    return success;
    
}

- (BOOL)saveDestinationContext:(NSError **)error {
    
    // get the unsaved objects
    NSMutableArray *unsavedObjects = [NSMutableArray arrayWithCapacity:self.sourceObjectIDsOfUnsavedCounterparts.count];
    
    for (NSManagedObjectID *sourceManagedObjectID in self.sourceObjectIDsOfUnsavedCounterparts) {
        NSManagedObject *unsavedManagedObject = [self.destinationContext objectWithID:[self.migratedIDsKeyedBySourceID objectForKey:sourceManagedObjectID]];
        [unsavedObjects addObject:unsavedManagedObject];
    }
    
    // obtain permanent IDs
    if (![self.destinationContext obtainPermanentIDsForObjects:unsavedObjects error:error]) {
        return NO;
    }
    
    // map the permanent IDs back to the dictionary
    NSEnumerator *unsavedObjectsEnumerator = [unsavedObjects objectEnumerator];
    for (NSManagedObjectID *sourceObjectID in self.sourceObjectIDsOfUnsavedCounterparts) {
        NSManagedObject *unsavedObject = [unsavedObjectsEnumerator nextObject];
        [self.migratedIDsKeyedBySourceID setObject:unsavedObject.objectID forKey:sourceObjectID];
    }
    
    // clear out the array of unsaved object IDs
    [self.sourceObjectIDsOfUnsavedCounterparts removeAllObjects];
    
    // save the context
    if ([self.destinationContext hasChanges]) {
        return [self.destinationContext save:error];
    }
    return YES;
    
}

@end
