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

// Returns a signal that sends result of executing a fetch request (or sends error)
- (RACSignal *)executeRequest:(NSFetchRequest *)request;
+ (NSManagedObjectContext *)context;
+ (void)setMainContext:(NSManagedObjectContext *)moc;
+ (NSManagedObjectContext *)currentMoc;
@end
