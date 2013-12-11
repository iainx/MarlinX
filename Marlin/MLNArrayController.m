//
//  MLNArrayController.m
//  Marlin
//
//  Created by iain on 17/11/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNArrayController.h"
#import "Constants.h"

@implementation MLNArrayController

- (void)insertObject:(id)object atArrangedObjectIndex:(NSUInteger)index
{
    [super insertObject:object atArrangedObjectIndex:index];
    
    NSDictionary *userInfo = @{@"object": object, @"index": @(index)};
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:kMLNArrayControllerObjectAdded
                      object:self
                    userInfo:userInfo];
}

- (void)removeObject:(id)object
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    NSDictionary *userInfo = @{@"object":object};
    [nc postNotificationName:kMLNArrayControllerObjectRemoved
                      object:self
                    userInfo:userInfo];
    [super removeObject:object];
}

- (void)removeObjectAtArrangedObjectIndex:(NSUInteger)index
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    id object = [self content][index];
    
    NSDictionary *userInfo = @{@"object":object, @"index": @(index)};
    [nc postNotificationName:kMLNArrayControllerObjectRemoved
                      object:self
                    userInfo:userInfo];
    
    [super removeObjectAtArrangedObjectIndex:index];
}

@end
