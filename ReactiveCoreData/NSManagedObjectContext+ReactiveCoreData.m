//
//  NSManagedObjectContext+ReactiveCoreData.m
//  ReactiveCoreData
//
//  Created by Jacob Gorban on 25/04/2013.
//  Copyright (c) 2013 Apparent Software. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/NSNotificationCenter+RACSupport.h>
#import <objc/runtime.h>
#import "NSManagedObjectContext+ReactiveCoreData.h"
#import "RACSignal+ReactiveCoreData.h"

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
    return [self contextWithMainContext:[self currentContext]];
}

+ (NSManagedObjectContext *)mainMoc;
{
    return [self contextForScheduler:[RACScheduler mainThreadScheduler]];
}

- (void)rcd_mergeChanges:(NSNotification *)note;
{
    NSManagedObjectContext *mainContext = [self mainContext];
    NSAssert(mainContext, @"no main context");
    [mainContext performSelector:@selector(mergeChangesFromContextDidSaveNotification:) onThread:[NSThread mainThread] withObject:note waitUntilDone:YES];
    [((RACSubject *) mainContext.rcd_merged) sendNext:note];
}

+ (void)setCurrentContext:(NSManagedObjectContext *)moc;
{
    [moc attachToCurrentScheduler];
}

+ (void)setMainContext:(NSManagedObjectContext *)moc;
{
    RACScheduler *scheduler = [RACScheduler mainThreadScheduler];
    objc_setAssociatedObject(scheduler, (__bridge void *)kRCDCurrentManagedObjectContext, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self setCurrentContext:moc];
}

+ (NSManagedObjectContext *)currentContext;
{
    return [self contextForScheduler:[RACScheduler currentScheduler]];
}

+ (NSManagedObjectContext *)contextForScheduler:(RACScheduler *)scheduler;
{
    NSManagedObjectContext *schedulerContext = objc_getAssociatedObject(scheduler, (__bridge void *)kRCDCurrentManagedObjectContext);
    return schedulerContext;
}

- (RACSignal *)rcd_merged;
{
    RACSubject *merged = objc_getAssociatedObject(self, _cmd);
    if (!merged) {
        merged = [RACSubject subject];
        objc_setAssociatedObject(self, _cmd, merged, OBJC_ASSOCIATION_RETAIN);
        [self.rac_deallocDisposable addDisposable:[RACDisposable disposableWithBlock:^{
            [merged sendCompleted];
        }]];
    }
    return merged;
}

- (RACSignal *)rcd_saved;
{
    RACSignal *saved = objc_getAssociatedObject(self, _cmd);
    if (!saved) {
        saved = [[NSNotificationCenter defaultCenter] rac_addObserverForName:NSManagedObjectContextDidSaveNotification object:self];
        objc_setAssociatedObject(self, _cmd, saved, OBJC_ASSOCIATION_RETAIN);
    }
    return saved;
}

- (NSManagedObjectContext *)mainContext
{
    return self.userInfo[kRCDMainManagedObjectContext];
}

+ (NSManagedObjectContext *)contextWithMainContext:(NSManagedObjectContext *)mainContext;
{
    NSParameterAssert(mainContext);
    NSManagedObjectContext *moc = [[self alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
    moc.userInfo[kRCDMainManagedObjectContext] = mainContext;
    moc.persistentStoreCoordinator = mainContext.persistentStoreCoordinator;

    [NSNotificationCenter.defaultCenter addObserver:moc selector:@selector(rcd_mergeChanges:) name:NSManagedObjectContextDidSaveNotification object:moc];
    [moc.rac_deallocDisposable addDisposable:[RACDisposable disposableWithBlock:^{
        [NSNotificationCenter.defaultCenter removeObserver:moc name:NSManagedObjectContextDidSaveNotification object:moc];
    }]];

    return moc;
}


- (RACSignal *)perform;
{
    NSManagedObjectContext *oldContext = [NSManagedObjectContext currentContext];
    [NSManagedObjectContext setCurrentContext:self];
    return [RACSignal createSignal:^RACDisposable *(id <RACSubscriber> subscriber) {
        [subscriber sendNext:self];
        [subscriber sendCompleted];
        [NSManagedObjectContext setCurrentContext:oldContext];
        return nil;
    }];
}

- (void)attachToCurrentScheduler;
{
    RACScheduler *scheduler = [RACScheduler currentScheduler];
    objc_setAssociatedObject(scheduler, (__bridge void *)kRCDCurrentManagedObjectContext, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (RACSignal *)performInBackground;
{
    return [[self perform] performInBackgroundContext];
}
@end
