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
- (instancetype)fetchInMOC:(NSManagedObjectContext *)moc;
{
    return [self flattenMap:^RACStream *(NSFetchRequest *req) {
        return [moc executeRequest:req];
    }];
}

- (instancetype)countInMOC:(NSManagedObjectContext *)moc;
{
    return [self flattenMap:^RACStream *(NSFetchRequest *req) {
        return [moc countRequest:req];
    }];
}

- (instancetype)fetch;
{
    return [self fetchInMOC:[NSManagedObjectContext currentMoc]];
}

- (instancetype)count;
{
    return [self countInMOC:[NSManagedObjectContext currentMoc]];
}

#pragma mark - Operations modifying NSFetchRequest
- (instancetype)where:(id)key equals:(id)value;
{
    return [self where:@"%K == %@" args:@[key, value]];
}

- (instancetype)where:(NSString *)format args:(NSArray *)args;
{
    NSMutableArray *signals = [NSMutableArray arrayWithCapacity:[args count]];
    for (id arg in args) {
        if ([arg isKindOfClass:[RACStream class]])
            [signals addObject:arg];
        else
            [signals addObject:[RACSignal return:arg]];
    }
    return [[self combineLatestWith:[RACSignal combineLatest:signals]]
        reduceEach:^(NSFetchRequest *req, RACTuple *arguments) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:format argumentArray:[arguments allObjects]];
            req.predicate = predicate;
            return req;
        }];
}
@end
