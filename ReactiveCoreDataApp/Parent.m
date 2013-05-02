//
//  Parent.m
//  ReactiveCoreData
//
//  Created by Jacob Gorban on 26/04/2013.
//  Copyright (c) 2013 Apparent Software. All rights reserved.
//

#import "Parent.h"

@implementation Parent

@dynamic age;
@dynamic name;
@dynamic children;
@dynamic spouse;

+ (NSString *)entityName;
{
    return @"Parent";
}


@end
