//
//  NSColor+Extra.m
//  Marlin
//
//  Created by iain on 22/01/2014.
//  Copyright (c) 2014 iain. All rights reserved.
//

#import "NSColor+Extra.h"

@implementation NSColor (Extra)

+ (NSColor *)marlinBackgroundColor
{
    if ([NSColor respondsToSelector:@selector(underPageBackgroundColor)]) {
        return [NSColor underPageBackgroundColor];
    } else {
        return [NSColor colorWithCalibratedRed:173.0 / 256.0
                                         green:178.0 / 256.0
                                          blue:187.0 / 256.0
                                         alpha:1.0];
    }
}
@end
