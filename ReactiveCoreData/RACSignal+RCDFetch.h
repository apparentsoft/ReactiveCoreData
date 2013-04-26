//
//  RACSignal+RCDFetch.h
//  ReactiveCoreData
//
//  Created by Jacob Gorban on 25/04/2013.
//  Copyright (c) 2013 Apparent Software. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>

@interface RACSignal (RCDFetch)

// Execute the NSFetchRequest that's sent in next, in specified context
- (RACSignal *)fetchInMOC:(NSManagedObjectContext *)moc;

@end
