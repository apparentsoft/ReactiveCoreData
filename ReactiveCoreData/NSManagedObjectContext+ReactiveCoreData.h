//
//  NSManagedObjectContext+ReactiveCoreData.h
//  ReactiveCoreData
//
//  Created by Jacob Gorban on 25/04/2013.
//  Copyright (c) 2013 Apparent Software. All rights reserved.
//

#import <CoreData/CoreData.h>

@class RACSignal;

static NSString const *kRCDCurrentManagedObjectContext;
static NSString const *kRCDMainManagedObjectContext;

@interface NSManagedObjectContext (ReactiveCoreData)

// sends the NSManagedObjectContextDidSaveNotification notification when the context is merged into
// This is for the main context, sends on the main thread
@property (readonly, nonatomic) RACSignal *rcd_merged;

// sends the NSManagedObjectContextDidSaveNotification notification when the context is saved
@property (readonly, nonatomic) RACSignal *rcd_saved;

// Returns a signal that sends result of executing a fetch request (or sends error)
- (RACSignal *)executeRequest:(NSFetchRequest *)request;

// Returns a signal that sends result of executing a count of the fetch request (or sends error)
- (RACSignal *)countRequest:(NSFetchRequest *)request;

// Creates a new context based on the current context
+ (NSManagedObjectContext *)context;

// Set self as current context and starts a signal
//
// Passes self as signal's value
// This is needed when you have contexts per-document
// and need to perform operations in a specific context
// Probably only works well on the main thread
- (RACSignal *)perform;

// Sets `moc` as the current context for the main scheduler and sets it as current context
// This is mostly needed for shoebox-type apps
+ (void)setMainContext:(NSManagedObjectContext *)moc;

// Returns the context registered with current RACScheduler
+ (NSManagedObjectContext *)currentContext;

// Attaches self to the current scheduler
- (void)attachToCurrentScheduler;

// returns the context that self merges into
- (NSManagedObjectContext *)mainContext;

// Convenience method for shoebox contexts to start perform in the background right away
- (RACSignal *)performInBackground;

// Actually creates a new child context for the passed main context
+ (NSManagedObjectContext *)contextWithMainContext:(NSManagedObjectContext *)mainContext;
@end
