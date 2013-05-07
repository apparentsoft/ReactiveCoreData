//
//  NSManagedObject+ReactiveCoreData.h
//  ReactiveCoreData
//
//  Created by Jacob Gorban on 25/04/2013.
//  Copyright (c) 2013 Apparent Software. All rights reserved.
//

#import <CoreData/CoreData.h>

@class RACSignal;

@interface NSManagedObject (ReactiveCoreData)

// Creates a signal that sends an NSFetchRequest for specified entity
+ (RACSignal *)findAll;

// Creates a signal that sends a NSFetchRequest with fetchLimit of 1
//
// In the end, fetch will return only one object instead of arrays for such requests
+ (RACSignal *)findOne;

// returns Entity name string
//
// By default returns class name string (which works well for XCode generated subclasses)
// mogenerator also defines such a method in its private subclass interface, so it'll override this one
+ (NSString*)entityName;

// Inserts a new object in the current context and returns it
+ (instancetype)insert;

// Convenience method that for faster insertion with values
//
// Inserts a new object and passes it to the config block
// Return the newly configured object
+ (instancetype)insert:(void (^)(id))configBlock;
@end
