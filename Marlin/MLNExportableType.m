//
//  MLNExportableType.m
//  Marlin
//
//  Created by iain on 19/09/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNExportableType.h"

@implementation MLNExportableType

- (id)initWithName:(NSString *)name
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _name = name;
    
    return self;
}

- (id)init
{
    self = [self initWithName:@"No Name"];
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"MLNExportableType: %@", _name];
}

@end
