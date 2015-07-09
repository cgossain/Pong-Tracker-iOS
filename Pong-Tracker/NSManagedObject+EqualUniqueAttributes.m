//
//  NSManagedObject+EqualUniqueAttributes.m
//  ProTracker Plus
//
//  Created by Christian R. Gossain on 2014-10-05.
//  Copyright (c) 2014 Gossain Software LLC. All rights reserved.
//

#import "NSManagedObject+EqualUniqueAttributes.h"

@implementation NSManagedObject (EqualUniqueAttributes)

- (BOOL)isEqualToManagedObject:(NSManagedObject *)toManagedObject forUniqueAttributes:(NSArray *)uniqueAttributes {
    
    __block BOOL isEqual = NO;
    
    NSLog(@"----------Checking Equality of Managed Object Named: %@ ----------", self.entity.name);
    
    [uniqueAttributes enumerateObjectsUsingBlock:^(NSString *uniqueAttributeName, NSUInteger idx, BOOL *stop) {
        
        NSLog(@">>> Comparing unique attribute: %@", uniqueAttributeName);
        
        BOOL objectsAreEqual = [[self valueForKey:uniqueAttributeName] isEqual:[toManagedObject valueForKey:uniqueAttributeName]];
        
        NSLog(@">>> Is << %@ >> equal to << %@ >>? %@", [self valueForKey:uniqueAttributeName], [toManagedObject valueForKey:uniqueAttributeName], (objectsAreEqual ? @"YES" :  @"NO"));
        
        if (idx == 0) {
            isEqual = objectsAreEqual;
        }
        else {
            isEqual = isEqual && objectsAreEqual;
        }
        
        *stop = !isEqual;
        
    }];
    
    NSLog(@"------------------------------------------------------------------");
    
    return isEqual;
    
}

@end