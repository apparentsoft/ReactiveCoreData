//
//  RACSignal+RCDFetch.m
//  ReactiveCoreData
//
//  Created by Jacob Gorban on 25/04/2013.
//  Copyright (c) 2013 Apparent Software. All rights reserved.
//

#import "RACSignal+RCDFetch.h"
#import "NSManagedObjectContext+ReactiveCoreData.h"

@implementation RACSignal (RCDFetch)
- (RACSignal *)executeFetchInMOC:(NSManagedObjectContext *)ctx;
{
    return [self flattenMap:^RACStream *(NSFetchRequest *req) {
        return [ctx executeRequest:req];
    }];
}
@end
