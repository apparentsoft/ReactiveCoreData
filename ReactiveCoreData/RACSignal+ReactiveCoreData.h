//
//  RACSignal+ReactiveCoreData.h
//  ReactiveCoreData
//
//  Created by Jacob Gorban on 25/04/2013.
//  Copyright (c) 2013 Apparent Software. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>

@interface RACSignal (ReactiveCoreData)

// Execute the NSFetchRequest that's sent in next, in specified context
//
// If the fetch request fetchLimit is set to 1, the signal will carry the object itself
// if fetchLimit != 1, then the signal will carry the resulting array
- (RACSignal *)fetchInMOC:(NSManagedObjectContext *)moc;

// Returns signal with the count of results that would've returned in `fetchInMOC:`
- (RACSignal *)countInMOC:(NSManagedObjectContext *)moc;

// Returns a signal that contains the NSArray of the fetch result in current NSManagedObjectContext
- (RACSignal *)fetch;

// Returns a signal that contains the count of results of the fetch request in current NSManagedObjectContext
- (RACSignal *)count;

// Modifies NSFetchRequest to set predicate
- (RACSignal *)where:(id)predicateOrSignal;

// Returns a signal with NSFetchRequest's predicate modified according to format and its arguments
//
// The format is passed to NSPredicate as is
// The arguments can be either signals or objects that can be returned in signals
// Any new value in any of the argument signals will result in update of the fetch request
// and possible execution of the request, if there's a `fetch` later.
// This brings the predicates into the reactive world
- (RACSignal *)where:(NSString *)format args:(NSArray *)args;

// A convenience method for a common predicate case
//
// Create a "%K == %@" predicate with key and value as arguments
- (RACSignal *)where:(id)key equals:(id)value;

// A convenience method for a common predicate case
//
// Creates a "%K CONTAINS[options] %@" predicate with key and value as arguments and adds it to the fetch request
// The key may be a signal
// If the `contains` parameter value is an empty string, it won't add the predicate, instead passing the fetch request as is
// This is useful when the using it to filter text from the search field, which can be empty
// `options` parameter is an optional string like `@"cd"` that can be added after CONTAINS inside brackets.
// For example, passing @"cd" for `options` will result in a CONTAINS[cd] predicate
- (RACSignal *)where:(id)key contains:(id)valueOrSignal options:(NSString *)optionsOrNil;

// Modifies the NSFetchRequest to set passed-in limit
- (RACSignal *)limit:(id)limitOrSignal;

// Modifies NSFetchRequest to set sortDescriptor
//
// The `sortOrSignal` parameter may be one of the following:
// - An NSSortDescriptor
// - An NSArray of NSSortDescriptors
// - An NSString of the key to be sorted in ascending order
// - An NSString of the key, prefixed by a minus (@"-key") to sort key in descending order
// - A RACSignal that sends any of the above values
- (RACSignal *)sortBy:(id)sortOrSignal;

// Modifies the NSFetchRequest. Sets resultType to NSManagedObjectIDResultType
- (RACSignal *)IDResultType;

// Saves current NSManagedObjectContext and waits for it to merge
//
// Send an error if couldn't save
// Passes next from previous subscriber on to the next one
- (RACSignal *)saveContext;

// Sets context as current context and return self
//
// Use it to start inserting document-based Core Data operations on the passed context
- (RACSignal *)performInContext:(NSManagedObjectContext *)context;

// Creates a new background scheduler and context.
//
// Sets the context as current for this scheduler and further chain runs on this scheduler
- (RACSignal *)performInBackgroundContext;

// Creates a new background scheduler and context and executes the passed-in block
//
// Sets the context as current for this scheduler and further chain runs on this scheduler
- (RACSignal *)performInBackgroundContext:(void (^)(NSManagedObjectContext *))block;

// Will rerun fetch when triggerSignal sends any next value
- (RACSignal *)fetchWithTrigger:(RACSignal *)triggerSignal;

// Will return a signal with a fetch request for the given entity name
//
// It disregards the value in the signal that it follows
- (RACSignal *)findAll:(NSString *)entityName;

// Similar to findAll but also sets fetchLimit to 1
- (RACSignal *)findOne:(NSString *)entityName;

// converts a signal of NSManagedObjectID array to array of these objects in current context
- (RACSignal *)objectIDsToObjects;

@end
