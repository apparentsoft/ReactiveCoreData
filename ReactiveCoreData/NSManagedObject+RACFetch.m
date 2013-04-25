//
//  NSManagedObject+RACFetch.m
//  ReactiveCoreData
//
//  Created by Jacob Gorban on 25/04/2013.
//  Copyright (c) 2013 Apparent Software. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import "NSManagedObject+RACFetch.h"

@implementation NSManagedObject (RACFetch)

+ (RACSignal *)fetchEntity:(NSString *)entityName;
{
    return [RACSignal createSignal:^RACDisposable *(id <RACSubscriber> subscriber) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
        [subscriber sendNext:fetchRequest];
        [subscriber sendCompleted];
        return nil;
    }];
}

@end
