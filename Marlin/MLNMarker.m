//
//  MLNMarker.m
//  Marlin
//
//  Created by iain on 13/11/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNMarker.h"

@implementation MLNMarker

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    [self setName:[aDecoder decodeObjectForKey:@"name"]];
    [self setFrame:[aDecoder decodeObjectForKey:@"frame"]];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeObject:_frame forKey:@"frame"];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: %lu", _name, [_frame unsignedIntegerValue]];
}
@end
