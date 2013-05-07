//
//  RACSignal+ReactiveCoreData.m
//  ReactiveCoreData
//
//  Created by Jacob Gorban on 25/04/2013.
//  Copyright (c) 2013 Apparent Software. All rights reserved.
//

#import "RACSignal+ReactiveCoreData.h"
#import "NSManagedObjectContext+ReactiveCoreData.h"

@interface RACSignal ()

- (NSArray *)convertToSignals:(NSArray *)args;
@end

@implementation RACSignal (ReactiveCoreData)
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
    NSArray *signals = [self convertToSignals:args];
    return [[[self combineLatestWith:[RACSignal combineLatest:signals]]
        reduceEach:^(NSFetchRequest *req, RACTuple *arguments) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:format argumentArray:[arguments allObjects]];
            req.predicate = predicate;
            return req;
        }] setNameWithFormat:@"[%@] -where:%@ args:%@", self.name, format, args];
}

- (RACSignal *)convertToSignal:(id)valueOrSignal;
{
    if ([valueOrSignal isKindOfClass:[RACStream class]])
        return valueOrSignal;
    return [RACSignal return:valueOrSignal];
}

- (NSArray *)convertToSignals:(NSArray *)args;
{
    NSMutableArray *signals = [NSMutableArray arrayWithCapacity:[args count]];
    for (id arg in args) {
        [signals addObject:[self convertToSignal:arg]];
    }
    return [signals copy];
}

- (instancetype)where:(id)key contains:(id)valueOrSignal options:(NSString *)optionsOrNil;
{
    NSParameterAssert(valueOrSignal);
    NSParameterAssert(key);
    return [[self convertToSignal:valueOrSignal]
        flattenMap:^(NSString *filter) {
            if ([filter length] > 0) {
                NSString *whereClause;
                if (optionsOrNil) {
                    whereClause = [NSString stringWithFormat:@"%%K CONTAINS[%@] %%@", optionsOrNil];
                }
                else {
                    whereClause = @"%K CONTAINS %@";
                }
                return [self where:whereClause args:@[key, filter]];
            }
            else
                return self;
        }];
}

- (instancetype)limit:(id)limitOrSignal;
{
    RACSignal *limitSignal = [self convertToSignal:limitOrSignal];
    return [[[self combineLatestWith:limitSignal]
        reduceEach:^(NSFetchRequest *req, NSNumber *limit) {
            req.fetchLimit = limit.unsignedIntegerValue;
            return req;
        }] setNameWithFormat:@"[%@] -limit:%@", self.name, limitOrSignal ];
}

- (instancetype)IDResultType;
{
    return [[self map:^id(NSFetchRequest *fetchRequest) {
        fetchRequest.resultType = NSManagedObjectIDResultType;
        return fetchRequest;
    }] setNameWithFormat:@"[%@] -IDResultType", self.name];
}

- (RACSignal *)sortBy:(id)sortOrSignal;
{
    RACSignal *sortSignal = [self convertToSignal:sortOrSignal];
    return [[[self combineLatestWith:sortSignal]
        reduceEach:^(NSFetchRequest *fetchRequest, id sortValue) {
            if ([sortValue isKindOfClass:[NSSortDescriptor class]]) {
                sortValue = @[sortValue];
            }
            else if ([sortValue isKindOfClass:[NSString class]]) {
                NSAssert([sortValue length] > 0, @"Key to sort by can't be empty");
                BOOL ascending = ([sortValue characterAtIndex:0] != '-');
                NSString *key = ascending ? sortValue : [sortValue substringFromIndex:1];
                sortValue = @[ [NSSortDescriptor sortDescriptorWithKey:key ascending:ascending] ];
            }
            fetchRequest.sortDescriptors = sortValue;
            return fetchRequest;
        }] setNameWithFormat:@"[%@] -sortBy:%@", self.name, sortOrSignal];
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

- (RACSignal *)performInBackgroundContext:(void(^)(NSManagedObjectContext *))block;
{
    return [[self performInBackgroundContext]
        doNext:^(id x) {
            block([NSManagedObjectContext currentContext]);
        }];
}

- (RACSignal *)fetchWithTrigger:(RACSignal *)triggerSignal;
{
    return [[[self combineLatestWith:triggerSignal]
        map:^(RACTuple *tuple) {
            return [tuple first];
        }]
        fetch];
}

#pragma mark - Operations starting a new NSFetchRequest signal
- (RACSignal *)findAll:(NSString *)entityName;
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    return [RACSignal return:fetchRequest];
}

- (RACSignal *)findOne:(NSString *)entityName;
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    fetchRequest.fetchLimit = 1;
    return [RACSignal return:fetchRequest];
}

- (RACSignal *)objectIDsToObjects;
{
    return [self map:^id(NSArray *objectIDs) {
        NSManagedObjectContext *context = [NSManagedObjectContext currentContext];
        NSMutableArray *objects = [NSMutableArray arrayWithCapacity:[objectIDs count]];
        for (NSManagedObjectID *objectID in objectIDs) {
            [objects addObject:[context objectWithID:objectID]];
        }
        return objects;
    }];
}

@end
