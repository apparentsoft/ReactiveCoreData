//
//  NSManagedObject+RACFetch.m
//  ReactiveCoreData
//
//  Created by Jacob Gorban on 25/04/2013.
//  Copyright (c) 2013 Apparent Software. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import "NSManagedObject+RACFetch.h"
#import "NSManagedObjectContext+ReactiveCoreData.h"

@implementation NSManagedObject (RACFetch)

+ (RACSignal *)findAll;
{
    return [RACSignal createSignal:^RACDisposable *(id <RACSubscriber> subscriber) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:self.entityName];
        [subscriber sendNext:fetchRequest];
        [subscriber sendCompleted];
        return nil;
    }];
}

+ (NSString *)entityName;
{
    return NSStringFromClass(self);
}

+ (instancetype)insert;
{
    return [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:[NSManagedObjectContext currentMoc]];
}


@end
