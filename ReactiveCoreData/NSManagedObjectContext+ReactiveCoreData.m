//
//  NSManagedObjectContext+ReactiveCoreData.m
//  ReactiveCoreData
//
//  Created by Jacob Gorban on 25/04/2013.
//  Copyright (c) 2013 Apparent Software. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import "NSManagedObjectContext+ReactiveCoreData.h"

@implementation NSManagedObjectContext (ReactiveCoreData)

- (RACSignal *)executeRequest:(NSFetchRequest *)request
{
    return [RACSignal createSignal:^RACDisposable *(id <RACSubscriber> subscriber) {
        NSError *error = nil;
        NSArray *result = [self executeFetchRequest:request error:&error];
        if (error) {
            [subscriber sendError:error];
            return nil;
        }
        [subscriber sendNext:result];
        [subscriber sendCompleted];
        return nil;
    }];
}

@end
