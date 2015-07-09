//
//  GSCoreDataDeduplicationManager.m
//  ProTracker Plus
//
//  Created by Christian R. Gossain on 2014-09-30.
//  Copyright (c) 2014 Gossain Software LLC. All rights reserved.
//

#import "GSCoreDataDeduplicationManager.h"
#import "NSManagedObject+EqualUniqueAttributes.h"

@interface GSCoreDataDeduplicationManager ()
@property (nonatomic, strong) id <GSCoreDataDeduplicator> deduplicator;
@end

@implementation GSCoreDataDeduplicationManager

- (void)registerDeduplicator:(id<GSCoreDataDeduplicator>)deduplicator {
    self.deduplicator = deduplicator;
}

- (void)deDuplicateEntityWithName:(NSString *)entityName inManagedObjectContext:(NSManagedObjectContext *)context {
    
    // perform deduplication on the context's thread, asynchronously; ideally the context should be an import context with private queue concurrency
    [context performBlockAndWait:^{
        
        @autoreleasepool {
            
            NSLog(@"***********************************************************************");
            
            NSLog(@">>> Will begin deduplicating entity named: '%@'", entityName);
            
            // get the unique attributes for the specified entity from the deduplicator
            NSArray *uniqueAttributes = [self.deduplicator uniqueAttributesForEntityName:entityName];
            
            if (uniqueAttributes.count < 1) {
                NSLog(@">>> No unique attributes for entity named: %@. Will not deduplicate.", entityName);
                return; // if no primary unique attribute is provided, no deduplication will occur for the entity
            }
            
            // get information on duplicate items
            NSArray *duplicates = [self duplicatesForEntityWithName:entityName
                                              usingUniqueAttributes:uniqueAttributes
                                             inManagedObjectContext:context];
            
            if (duplicates.count > 0) {
                NSLog(@">>> Found the following duplicates:\n%@", duplicates);
            }
            else {
                NSLog(@">>> No duplicates found.");
                return; // if no duplicates were found, there's no need to continue
            }
            
            // create a fetch request to get all managed objects with duplicates for the current entity
            NSFetchRequest *fetchRequest = [self fetchRequestForEntityName:entityName
                                                       forUniqueAttributes:uniqueAttributes
                                                           usingDuplicates:duplicates];
            
            NSError *error;
            NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
            
            NSManagedObject *previousManagedObject;
            NSMutableArray *duplicateObjects = [NSMutableArray array];
            
            NSUInteger lastIndex = results.count - 1;
            NSUInteger idx = 0;
            
            for (NSManagedObject *managedObject in results) {
                
                if (previousManagedObject) {
                    // deletion logic
                    if (![managedObject isEqualToManagedObject:previousManagedObject forUniqueAttributes:uniqueAttributes] || idx == lastIndex) {
                        // this is the cuttoff for the current set of duplicates; either we've reached the end of the results array, of the next object is a different duplicate
                        
                        if (idx == lastIndex) {
                            [duplicateObjects addObject:managedObject];
                        }
                        
                        // ask the deduplicator what to do with the collected duplicates
                        NSManagedObject *keep = [self.deduplicator managedObjectToKeepFromDuplicates:duplicateObjects forEntityName:entityName];
                        
                        // make sure the 'keep' object that is returned is one of the duplicates; to prevent all duplicates from being accidentally deleted
                        BOOL isValidObject = [duplicateObjects containsObject:keep];
                        
                        if (isValidObject) {
                            
                            NSLog(@">>> Will keep managed object:\n%@", keep);
                            
                            // remove the object that we want to keep
                            [duplicateObjects removeObject:keep];
                            
                            // delete the rest of the objects in the duplicate objects array
                            [duplicateObjects enumerateObjectsUsingBlock:^(NSManagedObject *obj, NSUInteger idx, BOOL *stop) {
                                NSLog(@">>> Will delete duplicate managed object:\n%@", obj);
                                [context deleteObject:obj];
                            }];
                            
                            [duplicateObjects removeAllObjects];
                            
                            // save the context
                            [self saveManagedObjectContext:context];
                            [context refreshObject:keep mergeChanges:NO];
                            
                        }
                        else {
                            NSLog(@">>> Keep object is NOT a valid managed object!");
                            
                            // if nil or the object returned is not a managed object, don't delete any of the duplicates
                            [duplicateObjects removeAllObjects];
                            
                            // save the context, if changes were made
                            [self saveManagedObjectContext:context];
                        }
                        
                    }
                    
                }
                previousManagedObject = managedObject;
                
                if (idx != lastIndex) {
                    [duplicateObjects addObject:managedObject];
                }
                
                idx++;
                
            }
            
            NSLog(@">>> Finished deduplicating entity named: '%@'", entityName);
        }

    }];
    
}

- (void)deDuplicateObjectsInManagedObjectContext:(NSManagedObjectContext *)context {
    
    NSDictionary *allEntities = [[context.persistentStoreCoordinator managedObjectModel] entitiesByName];
    
    for (NSString *entityName in allEntities) {
        [self deDuplicateEntityWithName:entityName inManagedObjectContext:context];
    }
    
}

#pragma mark - DeDuplication Helpers

/**
 Returns an array containing NSDictionary objects representing the value of the unique attribute that was determined to be a duplicate.
 The array returned by this method, contains dictionary with information about each set of duplicates that were found for the specified entity.

 The format of each dictionary is:
 @code
 -------------------------------------
 ----- * Key * ------:--- * Value * --
 -------------------------------------
 uniqueAttributeName : attribute value
 count               : # of duplicates
 -------------------------------------
*/
- (NSArray *)duplicatesForEntityWithName:(NSString *)entityName
                   usingUniqueAttributes:(NSArray *)uniqueAttributes
                  inManagedObjectContext:(NSManagedObjectContext *)context {
    
    if (uniqueAttributes.count < 1) {
        NSLog(@"Must provide at least one unique attribute name");
        return nil;
    }
    
    NSError *error;
    
    __block NSMutableArray *propertiesToFetch = [NSMutableArray array];
    __block NSMutableArray *propertiesToGroupBy = [NSMutableArray array];
    
    __block NSDictionary *allEntities = [[context.persistentStoreCoordinator managedObjectModel] entitiesByName];
    
    // get the unique attributes
    [uniqueAttributes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSString *uniqueAttributeName = (NSString *)obj;
        
        if (idx == 0) {
            // get the primary unique attribute
            NSAttributeDescription *primaryUniqueAttribute = [[[allEntities objectForKey:entityName] propertiesByName] objectForKey:uniqueAttributeName];
            
            // create the count expression to fetch entities with duplicate unique attributes
            NSExpressionDescription *primaryCountExpression = [[NSExpressionDescription alloc] init];
            [primaryCountExpression setName:@"count"];
            [primaryCountExpression setExpression:[NSExpression expressionWithFormat:@"count:(%K)", uniqueAttributeName]];
            [primaryCountExpression setExpressionResultType:NSInteger64AttributeType];
            
            // add the primary attribute as a property to fetch
            [propertiesToFetch addObject:primaryUniqueAttribute];
            [propertiesToFetch addObject:primaryCountExpression];
            
            // add the primary attribute as a property to group by
            [propertiesToGroupBy addObject:primaryUniqueAttribute];
            
        }
        else {
            
            // aditional attributes are taken as secondary attributes to 'group by'
            NSAttributeDescription *secondaryUniqueAttribute = [[[allEntities objectForKey:entityName] propertiesByName] objectForKey:uniqueAttributeName];
            
            // add the secondary attribute as a property to fetch
            [propertiesToFetch addObject:secondaryUniqueAttribute];
            
            // add the secondary attribute as a property to group by
            [propertiesToGroupBy addObject:secondaryUniqueAttribute];
            
        }
        
    }];
    
    // create a fetch request to find the duplicate objects
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    [fetchRequest setIncludesPendingChanges:NO];
    [fetchRequest setFetchBatchSize:100];
    [fetchRequest setPropertiesToFetch:propertiesToFetch];
    [fetchRequest setPropertiesToGroupBy:propertiesToGroupBy];
    [fetchRequest setResultType:NSDictionaryResultType];
    
    // execute the fetch request
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    
    if (error) {
        NSLog(@"Fetch Error: %@", error);
        return nil;
    }
    
    return [results filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"count > 1"]];
    
}

- (NSFetchRequest *)fetchRequestForEntityName:(NSString *)entityName forUniqueAttributes:(NSArray *)uniqueAttributes usingDuplicates:(NSArray *)duplicates {
    
    // FETCH DUPLICATE OBJECTS
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    
    [fetchRequest setSortDescriptors:[self sortDescriptorsForUniqueAttributes:uniqueAttributes]];
    [fetchRequest setFetchBatchSize:100];
    [fetchRequest setIncludesPendingChanges:NO];
    
    __block NSMutableArray *subPredicates = [NSMutableArray array];
    
    [uniqueAttributes enumerateObjectsUsingBlock:^(NSString *uniqueAttributeName, NSUInteger idx, BOOL *stop) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K IN (%@.%K)", uniqueAttributeName, duplicates, uniqueAttributeName];
        [subPredicates addObject:predicate];
    }];
    
    NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
    
    [fetchRequest setPredicate:compoundPredicate];
    
    return fetchRequest;
    
}

- (NSArray *)sortDescriptorsForUniqueAttributes:(NSArray *)uniqueAttributes {
    
    __block NSMutableArray *descriptors = [NSMutableArray array];
    
    [uniqueAttributes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [descriptors addObject:[NSSortDescriptor sortDescriptorWithKey:(NSString *)obj ascending:YES]];
    }];
    
    return descriptors;
    
}

#pragma mark - Saving

- (void)saveManagedObjectContext:(NSManagedObjectContext *)context {
    
    [context performBlockAndWait:^{
        // save the given context if it has changes
        if (context.hasChanges) {
            NSError *error;
            if (![context save:&error]) {
                NSLog(@"ERROR saving: %@", error);
            }
        }
    }];
    
}

@end
