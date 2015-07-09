//
//  GSCoreDataManager.h
//  ProTracker Plus
//
//  Created by Christian Gossain on 2014-08-03.
//  Copyright (c) 2014 Gossain Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "GSCoreDataDeduplicationManager.h"

extern NSString * const GSCoreDataManagerStoresWillChangedNotification; // interaction with core data should be disabled here
extern NSString * const GSCoreDataManagerStoreContentsDidChangeNotification; // either the store has changed or ubiquitious content has been imported

typedef NS_ENUM(NSInteger, GSCoreDataManagerBackingStore) {
    GSCoreDataManagerBackingStoreLocal = 1,
    GSCoreDataManagerBackingStoreCloud = 2
};

typedef NS_ENUM(NSInteger, GSCoreDataManagerConfirmation) {
    GSCoreDataManagerConfirmContinueWithMigration = 1,
    GSCoreDataManagerConfirmContinueWithoutMigration = 2,
    GSCoreDataManagerConfirmCancel = 3
};

extern NSString * const GSCoreDataManagerErrorDomain;

typedef NS_ENUM(NSInteger, GSCoreDataManagerErrorCode) {
    
    /// Migration Failure
    GSCoreDataManagerErrorCodeMigrationFailure           = 101,
    
};

typedef void (^GSConfirmationBlock)(GSCoreDataManagerConfirmation confirmation);
typedef void (^GSCompletionBlock)(GSCoreDataManagerConfirmation confirmation, NSError *error);

@class GSCoreDataManager;

@protocol GSCoreDataManagerDelegate <NSObject>
@optional
- (void)coreDataManagerConfirmMerge:(GSCoreDataManager *)manager
                          fromStore:(GSCoreDataManagerBackingStore)fromStore
                            toStore:(GSCoreDataManagerBackingStore)toStore
                  confirmationBlock:(GSConfirmationBlock)confirmationBlock;
@end

@interface GSCoreDataManager : NSObject

@property (readonly, nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (readonly, nonatomic, getter = isCloudEnabled) BOOL cloudEnabled;

/**
 Indicates whether iCloud is available for the current user.
 */
@property (readonly, nonatomic, getter = isCloudAvailable) BOOL cloudAvailable;

+ (GSCoreDataManager *)sharedManager;

#warning If no class provided, then make sure no crash
/// a class that conforms to the GSCoreDataDeduplicator protocol
- (void)registerDeduplicatorClass:(Class)deduplicatorClass;

- (void)startWithLocalStoreURL:(NSURL *)localStoreURL
                     modelName:(NSString *)modelName
             completionHandler:(void (^) (GSCoreDataManager *manager))completionHandler;

- (void)saveContext;

- (void)setCloudEnabled:(BOOL)cloudEnabled
               delegate:(id<GSCoreDataManagerDelegate>)delegate
      completionHandler:(GSCompletionBlock)completionHandler;

#pragma mark - HARD RESET

- (void)destroyAllCloudDataForThisApplication;

@end
