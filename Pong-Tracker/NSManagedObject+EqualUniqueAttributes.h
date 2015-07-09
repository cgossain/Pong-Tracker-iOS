//
//  NSManagedObject+EqualUniqueAttributes.h
//  ProTracker Plus
//
//  Created by Christian R. Gossain on 2014-10-05.
//  Copyright (c) 2014 Gossain Software LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (EqualUniqueAttributes)

- (BOOL)isEqualToManagedObject:(NSManagedObject *)toManagedObject forUniqueAttributes:(NSArray *)uniqueAttributes;

@end