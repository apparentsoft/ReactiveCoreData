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
    return [[self flattenMap:^RACStream *(NSFetchRequest *req) {
        if (req.fetchLimit == 1) {
            return [[moc executeRequest:req] map:^id(id value) {
                return [value lastObject];
            }];
        }
        else {
            return [moc executeRequest:req];
        }
    }]  setNameWithFormat:@"[%@] -fetchInMOC:%@", self.name, moc];
}

- (instancetype)countInMOC:(NSManagedObjectContext *)moc;
{
    return [[self flattenMap:^RACStream *(NSFetchRequest *req) {
        return [moc countRequest:req];
    }]  setNameWithFormat:@"[%@] -countInMOC:%@", self.name, moc];
}

- (instancetype)fetch;
{

    NSManagedObjectContext *currentMoc = [NSManagedObjectContext currentContext];
    return [self fetchInMOC:currentMoc];
}

- (instancetype)count;
{
    return [self countInMOC:[NSManagedObjectContext currentContext]];
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
    return [[[self combineLatestWith:[RACSignal combineLatest:signals]]
        reduceEach:^(NSFetchRequest *req, RACTuple *arguments) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:format argumentArray:[arguments allObjects]];
            req.predicate = predicate;
            return req;
        }] setNameWithFormat:@"[%@] -where:%@ args:%@", self.name, format, args];
}

- (instancetype)limit:(id)limitOrSignal;
{
    RACSignal *limitSignal = [limitOrSignal isKindOfClass:[RACStream class]] ? limitOrSignal : [RACSignal return:limitOrSignal];
    return [[[self combineLatestWith:limitSignal]
        reduceEach:^(NSFetchRequest *req, NSNumber *limit) {
            req.fetchLimit = limit.unsignedIntegerValue;
            return req;
        }] setNameWithFormat:@"[%@] -limit:%@", self.name, limitOrSignal ];
}

- (instancetype)saveMoc;
{
    return [[RACSignal createSignal:^RACDisposable *(id <RACSubscriber> subscriber) {
        return [self
            subscribeNext:^(id x) {
                NSError *error = nil;
                BOOL success = [[NSManagedObjectContext currentContext] save:&error];
                if (!success) {
                    [subscriber sendError:error];
                }
                else {
                    [subscriber sendNext:x];
                }
            }
            error:^(NSError *error) {
                [subscriber sendError:error];
            }
            completed:^{
                [subscriber sendCompleted];
            }];
    }] setNameWithFormat:@"[%@] -saveMoc", self.name];
}

- (RACSignal *)performInContext:(NSManagedObjectContext *)context
{
    [context attachToCurrentScheduler];
    return self;
}

- (RACSignal *)performInBackgroundContext;
{
    RACScheduler *scheduler = [RACScheduler schedulerWithPriority:RACSchedulerPriorityDefault name:@"com.ReactiveCoreData.background"];
    NSManagedObjectContext *currentContext = [NSManagedObjectContext currentContext];
//    NSLog(@"PERFORM IN BACKGROUND: current MOC: %@", currentContext);
    return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
        return [self subscribeNext:^(id x) {
            [scheduler schedule:^{
                NSManagedObjectContext *childContext = [NSManagedObjectContext currentContext];
//                NSLog(@"PERFORM IN BACKGROUND: Child MOC: %@", childContext);
                if (!childContext) {
                    childContext = [NSManagedObjectContext contextWithMainContext:currentContext];
                }
                [childContext attachToCurrentScheduler];
                [subscriber sendNext:x];
            }];
        } error:^(NSError *error) {
            [scheduler schedule:^{
                [subscriber sendError:error];
            }];
        } completed:^{
            [scheduler schedule:^{
                [subscriber sendCompleted];
            }];
        }];
    }] setNameWithFormat:@"[%@] -performInBackgroundContext", self.name];
}
@end
