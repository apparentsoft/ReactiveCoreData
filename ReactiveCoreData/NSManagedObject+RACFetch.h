//
//  NSManagedObject+RACFetch.h
//  ReactiveCoreData
//
//  Created by Jacob Gorban on 25/04/2013.
//  Copyright (c) 2013 Apparent Software. All rights reserved.
//

#import <CoreData/CoreData.h>

@class RACSignal;

@interface NSManagedObject (RACFetch)

// Creates a signal that sends an NSFetchRequest for specified entity
+ (RACSignal *)findAll;

// returns Entity name string
//
// By default returns class name string (which works well for XCode generated subclasses)
// mogenerator also defines such a method in its private subclass interface, so it'll override this one
+ (NSString*)entityName;
+ (instancetype)insert;
@end
