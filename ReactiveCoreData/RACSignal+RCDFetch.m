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
- (RACSignal *)fetchInMOC:(NSManagedObjectContext *)moc;
{
    return [self flattenMap:^RACStream *(NSFetchRequest *req) {
        return [moc executeRequest:req];
    }];
}

- (RACSignal *)countInMOC:(NSManagedObjectContext *)moc;
{
    return [self flattenMap:^RACStream *(NSFetchRequest *req) {
        return [moc countRequest:req];
    }];
}

- (RACSignal *)fetch;
{
    return [self fetchInMOC:[NSManagedObjectContext currentMoc]];
}

- (RACSignal *)count;
{
    return [self countInMOC:[NSManagedObjectContext currentMoc]];
}

@end
