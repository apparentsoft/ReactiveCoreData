//
//  NSManagedObjectContext+ReactiveCoreData.m
//  ReactiveCoreData
//
//  Created by Jacob Gorban on 25/04/2013.
//  Copyright (c) 2013 Apparent Software. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <objc/runtime.h>
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

- (RACSignal *)countRequest:(NSFetchRequest *)request
{
    return [RACSignal createSignal:^RACDisposable *(id <RACSubscriber> subscriber) {
        NSError *error = nil;
        NSUInteger count = [self countForFetchRequest:request error:&error];
        if (error) {
            [subscriber sendError:error];
            return nil;
        }
        [subscriber sendNext:@(count)];
        [subscriber sendCompleted];
        return nil;
    }];
}

+ (NSManagedObjectContext *)context;
{
    NSManagedObjectContext *moc = [[self alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
    NSManagedObjectContext *mainContext = [self mainMoc];
    if (mainContext) {
        moc.persistentStoreCoordinator = mainContext.persistentStoreCoordinator;
    }
    return moc;
}

+ (NSManagedObjectContext *)mainMoc;
{
    return [NSThread mainThread].threadDictionary[kRCDMainManagedObjectContext];
}

- (void)rcd_mergeChanges:(NSNotification *)note;
{
    if (note.object == self) return;
    [self performSelector:@selector(mergeChangesFromContextDidSaveNotification:) onThread:[NSThread mainThread] withObject:note waitUntilDone:YES];
    [((RACSubject *) self.rcd_merged) sendNext:note];
}

+ (void)setMainContext:(NSManagedObjectContext *)moc;
{
    if ([self mainMoc]) {
        [[NSNotificationCenter defaultCenter] removeObserver:[self mainMoc] name:NSManagedObjectContextDidSaveNotification object:nil];
    }
    [NSThread mainThread].threadDictionary[kRCDMainManagedObjectContext] = moc;
    [NSThread mainThread].threadDictionary[kRCDCurrentManagedObjectContext] = moc;

    [[NSNotificationCenter defaultCenter] addObserver:moc selector:@selector(rcd_mergeChanges:) name:NSManagedObjectContextDidSaveNotification object:nil];
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

- (RACSignal *)rcd_merged;
{
    RACSubject *merged = objc_getAssociatedObject(self, _cmd);
    if (!merged) {
        merged = [RACSubject subject];
        objc_setAssociatedObject(self, _cmd, merged, OBJC_ASSOCIATION_RETAIN);
    }
    return merged;
}


@end
