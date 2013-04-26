//
//  NSManagedObjectContext+ReactiveCoreData.m
//  ReactiveCoreData
//
//  Created by Jacob Gorban on 25/04/2013.
//  Copyright (c) 2013 Apparent Software. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACSignal.h>
#import "NSManagedObjectContext+ReactiveCoreData.h"

static NSString const *kRCDCurrentManagedObjectContext = @"kRCDCurrentManagedObjectContext";
static NSString const *kRCDMainManagedObjectContext = @"kRCDMainManagedObjectContext";

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

+ (NSManagedObjectContext *)context;
{
    NSManagedObjectContext *moc = [[self alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
    // TODO: connect to persistent store
    return moc;
}

+ (void)setMainContext:(NSManagedObjectContext *)moc;
{
    [NSThread mainThread].threadDictionary[kRCDMainManagedObjectContext] = moc;
    [NSThread mainThread].threadDictionary[kRCDCurrentManagedObjectContext] = moc;
}

+ (NSManagedObjectContext *)currentMoc;
{
    NSMutableDictionary *threadDictionary = [NSThread.currentThread threadDictionary];
    NSManagedObjectContext *moc = threadDictionary[kRCDCurrentManagedObjectContext];
    if (!moc) {
        moc = [NSManagedObjectContext context];
        threadDictionary[kRCDCurrentManagedObjectContext] = moc;
    }
    return moc;
}


@end
