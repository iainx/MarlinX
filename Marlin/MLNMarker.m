//
//  MLNMarker.m
//  Marlin
//
//  Created by iain on 13/11/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNMarker.h"

@implementation MLNMarker

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: %lu", _name, [_frame unsignedIntegerValue]];
}
@end
