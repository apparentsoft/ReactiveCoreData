//
//  RACManagedObjectFetchSpecs.m
//  ReactiveCoreData
//
//  Created by Jacob Gorban on 25/04/2013.
//  Copyright (c) 2013 Apparent Software. All rights reserved.
//

#import <Specta.h>
#define EXP_SHORTHAND
#import <Expecta.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "NSManagedObject+RACFetch.h"
#import "NSManagedObjectContext+ReactiveCoreData.h"
#import "Parent.h"
#import "RACSignal+RCDFetch.h"

NSManagedObjectContext * contextForTest()
{
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[NSManagedObjectModel mergedModelFromBundles:nil]];
    NSError *error = nil;
    NSPersistentStore *persistentStore = [psc addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
    if (!persistentStore) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    NSManagedObjectContext *ctx = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
    [ctx setPersistentStoreCoordinator:psc];
    [ctx setUndoManager:nil];
    [NSManagedObjectContext setMainContext:ctx];
    [ctx save:NULL];
    return ctx;
}

SpecBegin(RACMagagedObjectFetch)

__block NSManagedObjectContext *ctx = nil;
__block BOOL completed = NO;

beforeEach(^{
    ctx = contextForTest();
    completed = NO;
});

afterEach(^{
    ctx = nil;
    [NSManagedObjectContext setMainContext:nil];
});

describe(@"NSManagedObject", ^{
    __block BOOL executed;

    beforeEach(^{
        executed = NO;
    });

    it(@"creates a fetch request signal", ^{
        RACSignal *signal = Parent.findAll;
        [signal subscribeNext:^(NSFetchRequest *req) {
            expect(req).toNot.beNil();
            expect(req.entityName).to.equal(@"Parent");
            executed = YES;
        }];
        expect(executed).to.beTruthy();
    });

    it(@"inserts into context", ^{
        Parent *parent = [Parent insert];
        expect(parent).toNot.beNil();
        expect(parent.managedObjectContext).to.equal(ctx);
    });
});

describe(@"RACSignal", ^{
    it(@"counts results", ^{
        [Parent insert];
        expect([[[Parent findAll] count] first]).to.equal(@1);
    });

    it(@"fetches results", ^{
        Parent *p1 = [Parent insert];
        Parent *p2 = [Parent insert];
        NSArray *result = [[[Parent findAll] fetch] first];
        expect(result).to.contain(p1);
        expect(result).to.contain(p2);
    });
});

describe(@"FetchRequest operations:", ^{
    __block Parent *Joe;
    __block Parent *Jane;
    beforeEach(^{
        Joe = [Parent insert];
        Jane = [Parent insert];
        Joe.name = @"Joe";
        Jane.name = @"Jane";
        Joe.age = 40;
        Jane.age = 35;
    });

    it(@"where for property constant value", ^{
        NSArray *result = [[[Parent.findAll where:@"name" equals:@"Jane"] fetch] first];
        expect(result).to.equal(@[Jane]);
    });

    it(@"where for property signal", ^{
        RACSubject *nameSignal = [RACSubject subject];
        __block id final_result;
        [[[[Parent.findAll where:@"name == %@" args:@[nameSignal]] fetch] collect]
            subscribeNext:^(id x) {
                final_result = x;
            }];

        [nameSignal sendNext:@"Jane"];
        [nameSignal sendNext:@"Joe"];
        [nameSignal sendCompleted];

        NSArray *exp = @[@[Jane], @[Joe]];
        expect(final_result).to.equal(exp);
    });

    it(@"sends complete", ^{
        [[Parent.findAll fetch]
            subscribeNext:^(id x) {
            }
            completed:^{
                completed = YES;
            }];
        expect(completed).to.beTruthy();
    });

    it(@"handles predicates for constants", ^{
        NSArray *result = [[[Parent.findAll where:@"name == %@" args:@[@"Jane"]] fetch] first];
        expect(result).to.equal(@[Jane]);
    });

    context(@"check limits", ^{
        beforeEach(^{
            for (NSUInteger i=0; i<50; i++) {
                [Parent insert];
            }
        });

        it(@"number limits", ^{
            [[[Parent.findAll limit:@10] fetch]
                subscribeNext:^(id x) {
                    expect(x).to.haveCountOf(10);
                    completed = YES;
                }];
            expect(completed).to.beTruthy();
        });

        it(@"limit signals", ^{
            RACSubject *limitSignal = [RACSubject subject];
            __block NSArray *final_result;
            [[[[Parent.findAll limit:limitSignal] fetch] collect]
                subscribeNext:^(id x) {
                    final_result = x;
                }];
            [limitSignal sendNext:@10];
            [limitSignal sendNext:@30];
            [limitSignal sendCompleted];
            expect(final_result).to.haveCountOf(2);
            expect(final_result[0]).to.haveCountOf(10);
            expect(final_result[1]).to.haveCountOf(30);
        });
    });


});

describe(@"Cross-Thread functionality", ^{
    it(@"Creates a new background context", ^{
        [[[RACSignal empty]
            deliverOn:[RACScheduler scheduler]]
            subscribeCompleted:^{
                NSManagedObjectContext *moc = [NSManagedObjectContext currentMoc];
                expect(moc).toNot.equal(ctx);
                completed = YES;
            }];
        expect(completed).will.beTruthy();
    });

    it(@"Merges changes from background context", ^AsyncBlock{
        [[[[[[RACSignal return:@"empty"]
            deliverOn:[RACScheduler scheduler]]
            doNext:^(id _){
                Parent *dad = [Parent insert];
                dad.name = @"Dad";
            }]
            saveMoc]
            deliverOn:RACScheduler.mainThreadScheduler]
            subscribeNext:^(id _){
                [[[Parent findAll] fetch]
                    subscribeNext:^(NSArray *result) {
                        expect([[result lastObject] name]).to.equal(@"Dad");
                        completed = YES;
                        done();
                    }];
            }];
        expect(completed).will.beTruthy();
    });

    it(@"Has a signal that posts after a merge", ^AsyncBlock{
        __block BOOL local_completed = NO;
        id d1 = [[[[[RACSignal return:@"empty"]
            deliverOn:[RACScheduler scheduler]]
            doNext:^(id _){
                [Parent insert];
            }]
            saveMoc]
            subscribeNext:^(id x) {
            }];
        id d2 = [ctx.rcd_merged subscribeNext:^(NSNotification *note){
            local_completed = YES;
            expect([note userInfo][NSInsertedObjectsKey]).to.haveCountOf(1);
            NSLog(@"DONE2");
            done();
        }];
        expect(local_completed).will.beTruthy();
        expect(d1).toNot.beNil();
        expect(d2).toNot.beNil();
        NSLog(@"End2");
    });
});

SpecEnd

