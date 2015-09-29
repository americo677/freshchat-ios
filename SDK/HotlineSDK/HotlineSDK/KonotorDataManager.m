//
//  KonotorDataManager.m
//  Konotor
//
//  Created by Vignesh G on 15/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//
#import "KonotorDataManager.h"
#import "HLMacros.h"

NSString * const DataManagerDidSaveNotification = @"DataManagerDidSaveNotification";
NSString * const DataManagerDidSaveFailedNotification = @"DataManagerDidSaveFailedNotification";

@interface KonotorDataManager ()

- (NSString*)sharedDocumentsPath;

@end

@implementation KonotorDataManager

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize mainObjectContext = _mainObjectContext;
@synthesize objectModel = _objectModel;

NSString * const kDataManagerBundleName = @"KonotorModels";
NSString * const kDataManagerModelName = @"KonotorModel";
NSString * const kDataManagerSQLiteName = @"Konotor.sqlite";

+ (KonotorDataManager*)sharedInstance {
	static dispatch_once_t pred;
	static KonotorDataManager *sharedInstance = nil;
    
	dispatch_once(&pred, ^{ sharedInstance = [[self alloc] init]; });
	return sharedInstance;
}

- (void)dealloc {
	[self save];
}

- (NSManagedObjectModel*)objectModel {
	if (_objectModel)
		return _objectModel;
    
	NSBundle *bundle = [NSBundle mainBundle];
	if (kDataManagerBundleName)
    {
        
        
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"KonotorModels" ofType:@"bundle"];
		bundle = [NSBundle bundleWithPath:bundlePath];
	}
	NSString *modelPath = [bundle pathForResource:kDataManagerModelName ofType:@"momd"];
	_objectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:modelPath]];
    
	return _objectModel;
}

- (NSPersistentStoreCoordinator*)persistentStoreCoordinator {
	if (_persistentStoreCoordinator)
		return _persistentStoreCoordinator;
    
	// Get the paths to the SQLite file
	NSString *storePath = [[self sharedDocumentsPath] stringByAppendingPathComponent:kDataManagerSQLiteName];
	NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    
	// Define the Core Data version migration options
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                             nil];
    
    
	// Attempt to load the persistent store
	NSError *error = nil;
    
	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.objectModel];
	if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:options
                                                           error:&error]) {
		//NSLog(@"Fatal error while creating persistent store: %@", error);
		abort();
	}
    
	return _persistentStoreCoordinator;
}

- (NSManagedObjectContext*)mainObjectContext {
	if (_mainObjectContext)
		return _mainObjectContext;
    
	// Create the main context only on the main thread
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(mainObjectContext)
                               withObject:nil
                            waitUntilDone:YES];
		return _mainObjectContext;
	}
    
	_mainObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	[_mainObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    [_mainObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];

    
	return _mainObjectContext;
}

- (BOOL)save {
	if (![self.mainObjectContext hasChanges])
		return YES;
    
	NSError *error = nil;
	if (![self.mainObjectContext save:&error]) {
		//NSLog(@"[Konotor] Error while saving: %@\n%@", [error localizedDescription], [error userInfo]);
		[[NSNotificationCenter defaultCenter] postNotificationName:DataManagerDidSaveFailedNotification
                                                            object:error];
		return NO;
	}
    
	[[NSNotificationCenter defaultCenter] postNotificationName:DataManagerDidSaveNotification object:nil];
	return YES;
}

- (NSString*)sharedDocumentsPath {
	static NSString *SharedDocumentsPath = nil;
	if (SharedDocumentsPath)
		return SharedDocumentsPath;
    
	// Compose a path to the <Library>/Database directory
	NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	SharedDocumentsPath = [libraryPath stringByAppendingPathComponent:@"Database"];
    
	// Ensure the database directory exists
	NSFileManager *manager = [NSFileManager defaultManager];
	BOOL isDirectory;
	if (![manager fileExistsAtPath:SharedDocumentsPath isDirectory:&isDirectory] || !isDirectory) {
		NSError *error = nil;
		NSDictionary *attr = [NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                         forKey:NSFileProtectionKey];
		[manager createDirectoryAtPath:SharedDocumentsPath
		   withIntermediateDirectories:YES
                            attributes:attr
                                 error:&error];
		if (error)
			NSLog(@"Error creating directory path: %@", [error localizedDescription]);
	}
    
	return SharedDocumentsPath;
}

- (NSManagedObjectContext*)managedObjectContext {
	NSManagedObjectContext *ctx = [[NSManagedObjectContext alloc] init];
	[ctx setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    
	return ctx;
}

-(void)deleteAllSolutions{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_CATEGORY_ENTITY];
    [self.mainObjectContext performBlockAndWait:^{
        NSArray *results = [self.mainObjectContext executeFetchRequest:request error:nil];
        for (int i=0; i<[results count]; i++) {
            id entry = results[i];
            [self.mainObjectContext deleteObject:entry];
        }
        [self save];
    }];
}

@end