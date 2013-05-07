//
//  NSManagedObject+ReactiveCoreData.m
//  ReactiveCoreData
//
//  Created by Jacob Gorban on 25/04/2013.
//  Copyright (c) 2013 Apparent Software. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import "NSManagedObject+ReactiveCoreData.h"
#import "NSManagedObjectContext+ReactiveCoreData.h"
#import "RACSignal+ReactiveCoreData.h"

@implementation NSManagedObject (ReactiveCoreData)

+ (RACSignal *)findAll;
{
    return [RACSignal createSignal:^RACDisposable *(id <RACSubscriber> subscriber) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:self.entityName];
        [subscriber sendNext:fetchRequest];
        [subscriber sendCompleted];
        return nil;
    }];
}

+ (RACSignal *)findOne;
{
    return [[self findAll]
        map:^id(NSFetchRequest *req) {
            req.fetchLimit = 1;
            return req;
        }];
}


+ (NSString *)entityName;
{
    return NSStringFromClass(self);
}

+ (instancetype)insert;
{
    return [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:[NSManagedObjectContext currentContext]];
}

+ (instancetype)insert:(void (^)(id obj))configBlock;
{
    id object = [self insert];
    configBlock(object);
    return object;
}

@end
