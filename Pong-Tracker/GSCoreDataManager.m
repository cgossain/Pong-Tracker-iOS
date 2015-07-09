//
//  GSCoreDataManager.m
//  ProTracker Plus
//
//  Created by Christian Gossain on 2014-08-03.
//  Copyright (c) 2014 Gossain Software LLC. All rights reserved.
//

#import "GSCoreDataManager.h"
#import "GSCoreDataDeepCopyManager.h"

NSString * const GSCoreDataManagerStoresWillChangedNotification = @"com.gossainsoftware.GSCoreDataManagerStoresWillChangedNotification";
NSString * const GSCoreDataManagerStoreContentsDidChangeNotification = @"com.gossainsoftware.GSCoreDataManagerStoreContentsDidChangeNotification";

static NSString *kGSUbiquitousContentName = @"GSUbiquitousContent";

static NSString *kGSLocalStoreFilename = @"GSLocalStore.sqlite";
static NSString *kGSCloudStoreFilename = @"GSCloudStore.sqlite";

static NSString *kGSCloudEnabledUserDefaultsKey = @"GSCloudEnabledUserDefaultsKey";

NSString * const GSCoreDataManagerErrorDomain = @"GSCoreDataManagerErrorDomain";

@interface GSCoreDataManager ()

@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong) NSURL *managedObjectModelURL;
@property (nonatomic, strong) NSURL *localStoreURL;

@property (nonatomic, strong) NSPersistentStore *localStore;
@property (nonatomic, strong) NSPersistentStore *cloudStore;

// managed object context hiearchy
@property (nonatomic, strong) NSManagedObjectContext *backgroundSaveContext;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSManagedObjectContext *importContext;

// seeding
@property (nonatomic, strong) NSPersistentStoreCoordinator *seedPersistentStoreCoordinator;
@property (nonatomic, strong) NSPersistentStore *seedStore;
@property (nonatomic, strong) NSManagedObjectContext *seedContext;

// deduplication
@property (nonatomic, strong) Class deduplicatorClass;
@property (nonatomic, strong) GSCoreDataDeduplicationManager *deduplicationManager;

// observers
@property (nonatomic, strong) id storesWillChangeNotificationObserver;
@property (nonatomic, strong) id storesDidChangeNotificationObserver;
@property (nonatomic, strong) id didImportUbiquitousContentChangesNotificationObserver;

// cloud state management
@property (copy) GSCompletionBlock enableCloudCompletionHandler;

@property (nonatomic, weak) id <GSCoreDataManagerDelegate> delegate;

@end

@implementation GSCoreDataManager

#pragma mark - INITIALIZATION

+ (GSCoreDataManager *)sharedManager {
    
    static  GSCoreDataManager *sharedManager;
    static  dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (void)dealloc {
    [self deRegisterNotificationObservers];
}

#pragma mark - DEDUPLICATION

- (void)registerDeduplicatorClass:(Class)deduplicatorClass {
    self.deduplicatorClass = deduplicatorClass;
}

- (GSCoreDataDeduplicationManager *)deduplicationManager {
    if (!_deduplicationManager) {
        _deduplicationManager = [[GSCoreDataDeduplicationManager alloc] init];
        if (self.deduplicatorClass) {
            [_deduplicationManager registerDeduplicator:[self.deduplicatorClass new]];
        }
    }
    return _deduplicationManager;
}

#pragma mark - SETUP

- (void)startWithLocalStoreURL:(NSURL *)localStoreURL
                     modelName:(NSString *)modelName
             completionHandler:(void (^)(GSCoreDataManager *))completionHandler {
    
    // configure the local store URL
    _localStoreURL = localStoreURL;
    
    // initialize the model
    if (modelName) {
        _managedObjectModelURL = [[NSBundle mainBundle] URLForResource:modelName withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:_managedObjectModelURL];
    }
    else {
        _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    }
    
    // initialize the coordinators
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_managedObjectModel];
    _seedPersistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_managedObjectModel];
    
    // configure the managed object context hierarchy
    [self configureManagedObjectContextHierarchy];
    
    // observe store changes
    [self registerNotificationObservers];
    
    // load the backing store (i.e. local, or cloud)
    NSError *error;
//    if (self.isCloudEnabled) {
//        [self loadBackingStore:GSCoreDataManagerBackingStoreCloud
//                     withError:&error];
//    }
//    else {
//        [self loadBackingStore:GSCoreDataManagerBackingStoreLocal
//                     withError:&error];
//    }
    [self loadBackingStore:GSCoreDataManagerBackingStoreLocal
                 withError:&error];
    
    // call the completion handler
    if (completionHandler) {
        completionHandler(self);
    }
    
}

- (BOOL)loadBackingStore:(GSCoreDataManagerBackingStore)backingStore
               withError:(NSError **)error {
    
    // load the requested store
    if (GSCoreDataManagerBackingStoreCloud == backingStore) {
        
        if (!_cloudStore) {
            NSLog(@"** Attempting to load the CLOUD Store **");
            
            // we want the cloud store and it is not loaded; lets nuke the existing stack and load in the requested one
            [self nukeCoreDataStack];
            
            // load the cloud store
            _cloudStore = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                    configuration:nil
                                                                              URL:[self cloudStoreURL]
                                                                          options:[self cloudStoreOptions]
                                                                            error:error];
            
            if (!_cloudStore) {
                NSLog(@"FAILED to add cloud store. Error: %@", *error);
                return NO;
            }
            
            NSLog(@"SUCCESSFULLY added cloud store: %@", _cloudStore);
            return YES;
            
        }
        else {
            NSLog(@"** The CLOUD store is already loaded **");
            return YES;
        }
        
    }
    else if (GSCoreDataManagerBackingStoreLocal == backingStore) {
        
        if (!_localStore) {
            NSLog(@"** Attempting to load the LOCAL store **");
            
            // we want the local store and it is not loaded; lets nuke the existing stack and load in the requested one
            [self nukeCoreDataStack];
            
            // load the local store
            _localStore = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                    configuration:nil
                                                                              URL:[self localStoreURL]
                                                                          options:[self localStoreOptions]
                                                                            error:error];
            
            
            if (!_localStore) {
                NSLog(@"FAILED to add local store. Error: %@", *error);
                return NO;
            }
            
            NSLog(@"SUCCESSFULLY added local store: %@", _localStore);
            return YES;
            
        }
        else {
            NSLog(@"** The LOCAL store is already loaded **");
            return YES;
        }
        
    }
    
    // requested to load an unknown backing store
    NSLog(@"** Attempting to load an unknown backing store **");
    return NO;
    
}

- (void)transitionFromBackingStore:(GSCoreDataManagerBackingStore)fromStore
                    toBackingStore:(GSCoreDataManagerBackingStore)toStore
                  withConfirmation:(GSCoreDataManagerConfirmation)confirmation {
    
    BOOL success = NO;
    
    NSError *error;
    if (GSCoreDataManagerConfirmContinueWithMigration == confirmation) {
        if ((GSCoreDataManagerBackingStoreLocal == fromStore) && (GSCoreDataManagerBackingStoreCloud == toStore)) {
            // switch to the cloud store by migrating from the local store
            if ([self loadCloudStoreByMigratingFromLocalStoreWithError:&error]) {
                success = YES;
            }
        }
        else if ((GSCoreDataManagerBackingStoreCloud == fromStore) && (GSCoreDataManagerBackingStoreLocal == toStore)) {
            // switch to the local store by migrating from the cloud store
            // TODO: NEEDS IMPLEMENTATION
        }
    }
    else {
        // load the 'toStore' without migrating
        if ([self loadBackingStore:toStore withError:&error]) {
            success = YES;
        }
    }
    
    // notify that the store transition finished
    [self switchingToStore:toStore
                 succeeded:success
         mergeConfirmation:confirmation
                     error:error];
    
}

#pragma mark - PATHS

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSURL *)localStoreURL {
    if (!_localStoreURL) {
        _localStoreURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:kGSLocalStoreFilename];
    }
    return _localStoreURL;
}

- (NSURL *)cloudStoreURL {
    return [[self applicationDocumentsDirectory] URLByAppendingPathComponent:kGSCloudStoreFilename];
}

//- (NSURL *)applicationStoresDirectory {
//
//    NSURL *storesDirectory = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Stores"];
//
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//
//    if (![fileManager fileExistsAtPath:[storesDirectory path]]) {
//
//        NSError *error;
//
//        if ([fileManager createDirectoryAtURL:storesDirectory
//                  withIntermediateDirectories:YES
//                                   attributes:nil
//                                        error:&error]) {
//
//                NSLog(@"SUCCESSFULLY created Stores directory");
//
//        }
//        else {
//
//            NSLog(@"FAILED to create Stores directory: %@", error);
//
//        }
//
//    }
//    return storesDirectory;
//
//}

//- (NSURL *)ubiquityContainerURL {
//    return [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:self.ubiquityContainerIdentifier];
//}

//- (NSURL *)cloudStoreURL {
//    return [[self ubiquityContainerURL] URLByAppendingPathComponent:kCloudStoreFilename];
//}

#pragma mark - SAVING

- (void)saveContext {
    [self saveContextHierarchyWithReset:NO];
}

- (void)saveContextHierarchyWithReset:(BOOL)reset {
    
    __weak GSCoreDataManager *weakSelf = self;
    __block BOOL shouldReset = reset;
    
    // save the hierarchy in order, beginning with the main context; if the import context is used, it should take care of saving its content
    [self.managedObjectContext performBlockAndWait:^{
        GSCoreDataManager *strongSelf = weakSelf;
        if (strongSelf.managedObjectContext.hasChanges) {
            NSError *error;
            if (![strongSelf.managedObjectContext save:&error]) {
                NSLog(@"ERROR saving main context: %@", error);
            }
        }
        
        if (shouldReset) {
            [strongSelf.managedObjectContext reset];
        }
        
    }];
    
    [self.backgroundSaveContext performBlockAndWait:^{
        GSCoreDataManager *strongSelf = weakSelf;
        if (strongSelf.backgroundSaveContext.hasChanges) {
            NSError *error;
            if (![strongSelf.backgroundSaveContext save:&error]) {
                NSLog(@"ERROR saving background context: %@", error);
            }
        }
        
        if (shouldReset) {
            [strongSelf.backgroundSaveContext reset];
        }
        
    }];
    
}

- (void)saveEntireContextHierarchyWithReset:(BOOL)reset {
    
    __weak GSCoreDataManager *weakSelf = self;
    __block BOOL shouldReset = reset;
    
    // save the hierarchy in order, beginning with the main context; if the import context is used, it should take care of saving its content
    [self.importContext performBlockAndWait:^{
        GSCoreDataManager *strongSelf = weakSelf;
        if (strongSelf.importContext.hasChanges) {
            NSError *error;
            if (![strongSelf.importContext save:&error]) {
                NSLog(@"ERROR saving main context: %@", error);
            }
        }
        
        if (shouldReset) {
            [strongSelf.importContext reset];
        }
        
    }];
    
    [self.managedObjectContext performBlockAndWait:^{
        GSCoreDataManager *strongSelf = weakSelf;
        if (strongSelf.managedObjectContext.hasChanges) {
            NSError *error;
            if (![strongSelf.managedObjectContext save:&error]) {
                NSLog(@"ERROR saving main context: %@", error);
            }
        }
        
        if (shouldReset) {
            [strongSelf.managedObjectContext reset];
        }
        
    }];
    
    [self.backgroundSaveContext performBlockAndWait:^{
        GSCoreDataManager *strongSelf = weakSelf;
        if (strongSelf.backgroundSaveContext.hasChanges) {
            NSError *error;
            if (![strongSelf.backgroundSaveContext save:&error]) {
                NSLog(@"ERROR saving background context: %@", error);
            }
        }
        
        if (shouldReset) {
            [strongSelf.backgroundSaveContext reset];
        }
        
    }];
    
}

#pragma mark - CLOUD STATE MANAGEMENT

- (BOOL)isCloudAvailable {
    
    id token = [[NSFileManager defaultManager] ubiquityIdentityToken];
    
    if (token) {
        NSLog(@"** iCloud is SIGNED IN with token '%@' **", token);
        return YES;
    }
    
    NSLog(@"** iCloud is NOT SIGNED IN **");
    NSLog(@"--> Is iCloud Documents and Data enabled for a valid iCloud account on your Mac & iOS Device or iOS Simulator?");
    NSLog(@"--> Have you enabled the iCloud Capability in the Application Target?");
    NSLog(@"--> Is there a CODE_SIGN_ENTITLEMENTS Xcode warning that needs fixing? You may need to specifically choose a developer instead of using Automatic selection");
    NSLog(@"--> Are you using a Pre-iOS7 Simulator?");
    
    return NO;
    
}

- (BOOL)isCloudEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kGSCloudEnabledUserDefaultsKey];
}

- (void)setCloudEnabled:(BOOL)cloudEnabled delegate:(id<GSCoreDataManagerDelegate>)delegate completionHandler:(GSCompletionBlock)completionHandler {
    
    __block GSCoreDataManagerBackingStore fromStore = (cloudEnabled ? GSCoreDataManagerBackingStoreLocal : GSCoreDataManagerBackingStoreCloud);
    __block GSCoreDataManagerBackingStore toStore = (cloudEnabled ? GSCoreDataManagerBackingStoreCloud : GSCoreDataManagerBackingStoreLocal);
    
    // notify the delegate
    if ([delegate respondsToSelector:@selector(coreDataManagerConfirmMerge:fromStore:toStore:confirmationBlock:)]) {
        
        __weak GSCoreDataManager *weakSelf = self;
        
        // reference the delegate
        self.delegate = delegate;
        
        // keep a reference to the completion handler
        self.enableCloudCompletionHandler = [completionHandler copy];
        
        // notify the delegate
        [self.delegate coreDataManagerConfirmMerge:self
                                         fromStore:fromStore
                                           toStore:toStore
                                 confirmationBlock:^(GSCoreDataManagerConfirmation confirmation) {
                                     
                                     GSCoreDataManager *strongSelf = weakSelf;
                                     
                                     // if migration is confirmed, proceed with migration; if not, just switch to a new store
                                     if (GSCoreDataManagerConfirmContinueWithMigration == confirmation) {
                                         // transition with migration
                                         [strongSelf transitionFromBackingStore:fromStore toBackingStore:toStore withConfirmation:confirmation];
                                     }
                                     else if (GSCoreDataManagerConfirmContinueWithoutMigration == confirmation) {
                                         // transition without migration
                                         [strongSelf transitionFromBackingStore:fromStore toBackingStore:toStore withConfirmation:confirmation];
                                     }
                                     else if (GSCoreDataManagerConfirmCancel == confirmation) {
                                         // cancel the store transition
                                         
                                         // call the completion handler if one was provided
                                         if (strongSelf.enableCloudCompletionHandler) {
                                             strongSelf.enableCloudCompletionHandler(GSCoreDataManagerConfirmCancel, nil);
                                         }
                                         
                                         // cleanup
                                         strongSelf.delegate = nil;
                                         strongSelf.enableCloudCompletionHandler = nil;
                                     }
                                     
                                 }];
        
        
    }
    else {
        // transition without migration
        [self transitionFromBackingStore:fromStore toBackingStore:toStore withConfirmation:GSCoreDataManagerConfirmContinueWithoutMigration];
        
    }
    
}

- (void)switchingToStore:(GSCoreDataManagerBackingStore)toStore
               succeeded:(BOOL)succeeded
       mergeConfirmation:(GSCoreDataManagerConfirmation)confirmation
                   error:(NSError *)error {
    
    __weak GSCoreDataManager *weakSelf = self;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        GSCoreDataManager *strongSelf = weakSelf;
        
        if (succeeded) {
            // if the cloud store was loaded and/or migrated successfully, update the user defaults value
            [[NSUserDefaults standardUserDefaults] setBool:(GSCoreDataManagerBackingStoreCloud == toStore) forKey:kGSCloudEnabledUserDefaultsKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        // call the completion handler if one was provided
        if (strongSelf.enableCloudCompletionHandler) {
            strongSelf.enableCloudCompletionHandler(confirmation, (succeeded ? nil : error));
        }
        
        // cleanup
        strongSelf.delegate = nil;
        strongSelf.enableCloudCompletionHandler = nil;
        
    }];
    
}

#pragma mark - SEEDING

- (BOOL)unloadStore:(NSPersistentStore *)persistentStore {
    
    if (persistentStore) {
        NSPersistentStoreCoordinator *psc = persistentStore.persistentStoreCoordinator;
        if (psc) {
            NSError *error;
            if (![psc removePersistentStore:persistentStore error:&error]) {
                NSLog(@"ERROR removing store from the coordinator: %@", error);
                return NO; // error unloading store
            }
            else {
                persistentStore = nil;
                return YES; // store was sucessfully unloaded
            }
        }
        else {
            persistentStore = nil;
            return YES; // store was not associated with a persistent store coordinator
        }
    }
    return YES; // store is already unloaded
    
}

- (BOOL)loadLocalStoreAsSeedStore {
    
    if (![self unloadStore:_seedStore]) {
        NSLog(@"Failed to ensure _seedStore was removed prior to migration.");
        return NO;
    }
    
    if (![self unloadStore:_localStore]) {
        NSLog(@"Failed to ensure _localStore was removed prior to migration.");
        return NO;
    }
    
    NSError *error;
    _seedStore = [_seedPersistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                               configuration:nil
                                                                         URL:[self localStoreURL]
                                                                     options:[self seedStoreOptions]
                                                                       error:&error];
    if (!_seedStore) {
        NSLog(@"Failed to load Non-iCloud Store as Seed Store. Error: %@", error);
        return NO;
    }
    
    NSLog(@"Successfully loaded Non-iCloud Store as Seed Store: %@", _seedStore);
    return YES;
    
}

- (BOOL)loadCloudStoreByMigratingFromLocalStoreWithError:(NSError **)error {
    
    NSLog(@"** Attempting to migrate data from the LOCAL store to the CLOUD store **");
    
    // first load the iCloud store
    if ([self loadBackingStore:GSCoreDataManagerBackingStoreCloud withError:error]) {
        
        __block BOOL success = YES;
        
        // deregister for notifications while we are migrating
        [self deRegisterNotificationObservers];
        
        [self.seedContext performBlockAndWait:^{
            
            // make sure the local store is unloaded, and loaded as a read-only seed store
            if ([self loadLocalStoreAsSeedStore]) {
                
                GSCoreDataDeepCopyManager *migrator = [[GSCoreDataDeepCopyManager alloc] initWithManagedObjectModel:self.managedObjectModel];
                
                // migrate all entities to the import context
                for (NSEntityDescription *entityDescription in self.managedObjectModel.entities) {
                    success = [migrator migrateEntityWithName:entityDescription.name
                                            fromSourceContext:self.seedContext
                                         toDestinationContext:self.importContext
                                                        error:error];
                    
                }
                
                if (success) {
                    NSLog(@"** SUCCESSFULLY migrated data from LOCAL to CLOUD store");
                    
                    [self.importContext performBlockAndWait:^{
                        
                        // since migration was successful, we should deduplicate to prevent duplicate data
                        [self.deduplicationManager deDuplicateObjectsInManagedObjectContext:self.importContext];
                        
                        // post a notification (from the main thread) that the store content has changed
                        [self.managedObjectContext performBlock:^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:GSCoreDataManagerStoreContentsDidChangeNotification
                                                                                object:self
                                                                              userInfo:nil];
                        }];
                        
                    }];
                    
                }
                
                // unload the seed store
                [self unloadStore:_seedStore];
                
            }
            else {
                *error = [self migrationErrorWithFailureReason:@"Failed to load the local store as a seed store."];
                success = NO;
            }
            
        }];
        
        // register for notifications after successful migration
        [self registerNotificationObservers];
        
        return success;
        
    }
    
    return NO;
    
    
    
    
    
    
    
    
    
    
    
//    BOOL success = NO;
//    
//    // unregister the notification observers; this prevents controller from being notified to update their UI during migration
//    [self deRegisterNotificationObservers];
//    
//    // first load the local store as a read-only seed store
//    if ([self loadLocalStoreAsSeedStore]) {
//        _cloudStore = [_seedPersistentStoreCoordinator migratePersistentStore:_seedStore
//                                                                        toURL:[self cloudStoreURL]
//                                                                      options:[self cloudStoreOptions]
//                                                                     withType:NSSQLiteStoreType
//                                                                        error:error];
//        
//        // unload the read-only seed store
//        [self unloadStore:_seedStore];
//        
//        // since migration was successful, load in the cloud store
//        if (_cloudStore) {
//            if ([self loadBackingStore:GSCoreDataManagerBackingStoreCloud withError:error]) {
//                // mark the migration as successful
//                success = YES;
//                
//                // deduplicate the store
//                [self.deduplicationManager deDuplicateObjectsInManagedObjectContext:self.importContext];
//                
//                // post a notification that the store content has changed
//                [[NSNotificationCenter defaultCenter] postNotificationName:GSCoreDataManagerStoreContentsDidChangeNotification
//                                                                    object:self
//                                                                  userInfo:nil];
//            }
//        }
//    }
//    
//    if (!success && !error) {
//        // set a migration error, if no error was provided above
//        *error = [self migrationErrorWithFailureReason:@"Failed to load the local store as a seed store."];
//    }
//    
//    // register for notifications again before returning
//    [self registerNotificationObservers];
//    
//    return success;
}

#pragma mark - RESET

- (void)nukeCoreDataStack {
    
    // this method saves and resets each context in the hierarchy, ensuring any changes are saved to disk and cleared out of memory
    [self saveEntireContextHierarchyWithReset:YES];
    
    // remove all stores from the persistant coordinator
    [self removeAllStoresFromCoordinator:_persistentStoreCoordinator];
    
    // clear out the store references; calls to this reset method should be followed by a call to 'loadBackingStore'
    _localStore = nil;
    _cloudStore = nil;
    
}

- (void)removeAllStoresFromCoordinator:(NSPersistentStoreCoordinator*)psc {
    
    for (NSPersistentStore *store in psc.persistentStores) {
        NSError *error;
        if (![psc removePersistentStore:store error:&error]) {
            NSLog(@"Error removing persistent store: %@", error);
        }
    }
    
}

- (void)removeFileAtURL:(NSURL *)url {
    
    NSError *error;
    if (![[NSFileManager defaultManager] removeItemAtURL:url error:&error]) {
        NSLog(@"FAILED to delete '%@' from '%@'", url.lastPathComponent, url.URLByDeletingLastPathComponent);
    }
    else {
        NSLog(@"DELETED '%@'from '%@'", url.lastPathComponent, url.URLByDeletingLastPathComponent);
    }
    
}

#pragma mark - HELPERS

- (void)configureManagedObjectContextHierarchy {
    
    // configure the seed context
    _seedContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    [_seedContext performBlockAndWait:^{
        _seedContext.persistentStoreCoordinator = _seedPersistentStoreCoordinator;
        _seedContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    }];
    
    // configure a private queue context at the root of the hierarchy to allow saving data in the background
    _backgroundSaveContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    [_backgroundSaveContext performBlockAndWait:^{
        _backgroundSaveContext.persistentStoreCoordinator = _persistentStoreCoordinator;
        _backgroundSaveContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    }];
    
    // configure a main queue context that the application will interact with; this context is a child of the background context
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    
    [_managedObjectContext performBlockAndWait:^{
        _managedObjectContext.parentContext = _backgroundSaveContext;
        _managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    }];
    
    // configure a private queue context that will allow data to be imported in the background; this context is a child of the main queue context
    _importContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    [_importContext performBlockAndWait:^{
        _importContext.parentContext = _managedObjectContext;
        _importContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    }];
    
}

- (void)registerNotificationObservers {
    
    __weak GSCoreDataManager *weakSelf = self;
    
    // observe when the stores are about to change
    self.storesWillChangeNotificationObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:NSPersistentStoreCoordinatorStoresWillChangeNotification
                                                      object:_persistentStoreCoordinator
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      
                                                      NSLog(@"Stores Will Change Notification Received: %@", note);
                                                      
                                                      // save and reset the context hierarchy in the appropriate order before the underlying store changes
                                                      // this scenario could be the result of the user changing iCloud account in the device settings among other things
                                                      // so we save and reset the previous users data before moving to another user
                                                      
                                                      GSCoreDataManager *strongSelf = weakSelf;
                                                      
                                                      // save and reset context hierarchy
                                                      [strongSelf saveContextHierarchyWithReset:YES];
                                                      
                                                      // post a notification that the stores will change
                                                      [[NSNotificationCenter defaultCenter] postNotificationName:GSCoreDataManagerStoresWillChangedNotification
                                                                                                          object:strongSelf
                                                                                                        userInfo:nil];
                                                      
                                                  }];
    
    // observe when the stores do change
    self.storesDidChangeNotificationObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:NSPersistentStoreCoordinatorStoresDidChangeNotification
                                                      object:_persistentStoreCoordinator
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      
                                                      //NSLog(@"Stores Did Change Notification Received: %@", note);
                                                      
                                                      //NSNumber *transition = note.userInfo[NSPersistentStoreUbiquitousTransitionTypeKey];
                                                      
                                                      //NSLog(@"Transition Type: %@", transition);
                                                      
                                                      GSCoreDataManager *strongSelf = weakSelf;
                                                      
                                                      // post a notification that the store content has changed
                                                      [[NSNotificationCenter defaultCenter] postNotificationName:GSCoreDataManagerStoreContentsDidChangeNotification
                                                                                                          object:strongSelf
                                                                                                        userInfo:nil];
                                                      
                                                  }];
    
    // observe when content is imported from the cloud
    self.didImportUbiquitousContentChangesNotificationObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                      object:_persistentStoreCoordinator
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      
                                                      //NSLog(@"Did Import Ubiquitous Content: %@", note);
                                                      
                                                      GSCoreDataManager *strongSelf = weakSelf;
                                                      
                                                      // update the import context
                                                      [strongSelf.importContext performBlockAndWait:^{
                                                          [strongSelf.importContext mergeChangesFromContextDidSaveNotification:note];
                                                      }];
                                                      
                                                      // update the main context
                                                      [strongSelf.managedObjectContext performBlockAndWait:^{
                                                          [strongSelf.managedObjectContext mergeChangesFromContextDidSaveNotification:note];
                                                      }];
                                                      
                                                      // update the background save context
                                                      [strongSelf.backgroundSaveContext performBlockAndWait:^{
                                                          [strongSelf.backgroundSaveContext mergeChangesFromContextDidSaveNotification:note];
                                                      }];
                                                      
                                                      // deduplicate starting at the import context
                                                      [strongSelf.deduplicationManager deDuplicateObjectsInManagedObjectContext:strongSelf.importContext];
                                                      
                                                      // save and reset the hierarchy
                                                      [strongSelf saveContextHierarchyWithReset:YES];
                                                      
                                                      // post a notification that the store content has changed
                                                      [[NSNotificationCenter defaultCenter] postNotificationName:GSCoreDataManagerStoreContentsDidChangeNotification
                                                                                                          object:strongSelf
                                                                                                        userInfo:nil];
                                                      
                                                  }];
    
}

- (void)deRegisterNotificationObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self.storesWillChangeNotificationObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.storesDidChangeNotificationObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.didImportUbiquitousContentChangesNotificationObserver];
}

- (NSError *)migrationErrorWithFailureReason:(NSString *)reason {
    return [NSError errorWithDomain:GSCoreDataManagerErrorDomain
                               code:GSCoreDataManagerErrorCodeMigrationFailure
                           userInfo:@{NSLocalizedDescriptionKey:@"Migration Failed",
                                      NSLocalizedFailureReasonErrorKey:reason,
                                      NSLocalizedRecoverySuggestionErrorKey:@"Try again later."}];
}

#pragma mark - HELPERS (STORE OPTIONS)

- (NSDictionary *)localStoreOptions {
    return @{NSMigratePersistentStoresAutomaticallyOption : @YES,
             NSInferMappingModelAutomaticallyOption : @YES};
}

- (NSDictionary *)cloudStoreOptions {
    return @{NSMigratePersistentStoresAutomaticallyOption : @YES,
             NSInferMappingModelAutomaticallyOption : @YES,
             NSPersistentStoreUbiquitousContentNameKey : kGSUbiquitousContentName};
}

- (NSDictionary *)seedStoreOptions {
    return @{NSMigratePersistentStoresAutomaticallyOption : @YES,
             NSInferMappingModelAutomaticallyOption : @YES,
             NSReadOnlyPersistentStoreOption : @YES};
}

#pragma mark - HARD RESET

- (void)destroyAllCloudDataForThisApplication {
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[[_cloudStore URL] path]]) {
        NSLog(@"Skipped destroying iCloud content, _iCloudStore.URL is %@", [[_cloudStore URL] path]);
        return;
    }
    
    NSLog(@"\n\n\n\n\n **** Destroying ALL iCloud content for this application, this could take a while...  **** \n\n\n\n\n\n");
    
    [self removeAllStoresFromCoordinator:_persistentStoreCoordinator];
    
    _persistentStoreCoordinator = nil;
    
    NSDictionary *options = @{NSPersistentStoreUbiquitousContentNameKey:kGSUbiquitousContentName};
    
    NSError *error;
    if ([NSPersistentStoreCoordinator removeUbiquitousContentAndPersistentStoreAtURL:[self cloudStoreURL] options:options error:&error]) {
        
        // disable iCloud in the user defaults
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kGSCloudEnabledUserDefaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSLog(@"\n\n\n\n\n");
        NSLog(@"*        This application's iCloud content has been destroyed        *");
        NSLog(@"* On ALL devices, please delete any reference to this application in *");
        NSLog(@"*  Settings > iCloud > Storage & Backup > Manage Storage > Show All  *");
        NSLog(@"\n\n\n\n\n");
        
        abort();
        /*
         The application is force closed to ensure iCloud data is wiped cleanly.
         This method shouldn't be called in a production application.
         */
        
    }
    else {
        
        NSLog(@"\n\n FAILED to destroy iCloud content at URL: %@ Error:%@", [_cloudStore URL], error);
        
    }
    
}

@end
