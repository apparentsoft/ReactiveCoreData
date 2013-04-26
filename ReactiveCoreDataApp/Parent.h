//
//  Parent.h
//  ReactiveCoreData
//
//  Created by Jacob Gorban on 26/04/2013.
//  Copyright (c) 2013 Apparent Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Parent;

@interface Parent : NSManagedObject

@property (nonatomic) int32_t age;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *children;
@property (nonatomic, retain) Parent *spouse;

+ (NSString*)entityName;
@end

@interface Parent (CoreDataGeneratedAccessors)

- (void)addChildrenObject:(NSManagedObject *)value;
- (void)removeChildrenObject:(NSManagedObject *)value;
- (void)addChildren:(NSSet *)values;
- (void)removeChildren:(NSSet *)values;

@end
