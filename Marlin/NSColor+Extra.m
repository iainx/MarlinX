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
        return [NSColor colorWithCalibratedRed:173.0 / 255.0
                                         green:178.0 / 255.0
                                          blue:187.0 / 255.0
                                         alpha:1.0];
    }
}

+ (NSColor *)marlinVoid
{
    static NSColor *marlinVoid = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        marlinVoid = [NSColor colorWithCalibratedRed:54.57 / 255.0
                                               green:55.59 / 255.0
                                                blue:57.63 / 255.0
                                               alpha:1.0];
    });
    
    return marlinVoid;
}

+ (NSColor *)marlinAsh
{
    static NSColor *marlinAsh = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        marlinAsh = [NSColor colorWithCalibratedRed:100.0/255.0
                                              green:100.0/255.0
                                               blue:100.0/255.0
                                              alpha:1.0];
    });
    
    return marlinAsh;
}

+ (NSColor *)marlinBlind
{
    static NSColor *marlinBlind = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        marlinBlind = [NSColor colorWithCalibratedRed:157.0/255.0
                                                green:157.0/255.0
                                                 blue:157.0/255.0
                                                alpha:1.0];
    });
    
    return marlinBlind;
}

+ (NSColor *)marlinBloodRed
{
    static NSColor *marlinBloodRed = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        marlinBloodRed = [NSColor colorWithCalibratedRed:190.0/255.0
                                                   green:38.0/255.0
                                                    blue:51.0/255.0
                                                   alpha:1.0];
    });
    
    return marlinBloodRed;
}

+ (NSColor *)marlinPigMeat
{
    static NSColor *marlinPigMeat = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        marlinPigMeat = [NSColor colorWithCalibratedRed:224.0/255.0
                                                  green:111.0/255.0
                                                   blue:139.0/255.0
                                                  alpha:1.0];
    });
    
    return marlinPigMeat;
}

+ (NSColor *)marlinOldPoop
{
    static NSColor *marlinOldPoop = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        marlinOldPoop = [NSColor colorWithCalibratedRed:73.0/255.0
                                                  green:60.0/255.0
                                                   blue:43.0/255.0
                                                  alpha:1.0];
    });
    
    return marlinOldPoop;
}

+ (NSColor *)marlinNewPoop
{
    static NSColor *marlinNewPoop = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        marlinNewPoop = [NSColor colorWithCalibratedRed:164.0/255.0
                                                  green:100.0/255.0
                                                   blue:34.0/255.0
                                                  alpha:1.0];
    });
    
    return marlinNewPoop;
}

+ (NSColor *)marlinBlaze
{
    static NSColor *marlinBlaze = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        marlinBlaze = [NSColor colorWithCalibratedRed:235.0/255.0
                                                green:137.0/255.0
                                                 blue:49.0/255.0
                                                alpha:1.0];
    });
    
    return marlinBlaze;
}

+ (NSColor *)marlinZornSkin
{
    static NSColor *marlinZornSkin = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        marlinZornSkin = [NSColor colorWithCalibratedRed:127.5/255.0
                                                   green:127.5/255.0
                                                    blue:51/255.0
                                                   alpha:1.0];
    });
    
    return marlinZornSkin;
}

+ (NSColor *)marlinShadeGreen
{
    static NSColor *marlinShadeGreen = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        marlinShadeGreen = [NSColor colorWithCalibratedRed:47.0/255.0
                                                     green:72.0/255.0
                                                      blue:78.0/255.0
                                                     alpha:1.0];
    });
    
    return marlinShadeGreen;
}

+ (NSColor *)marlinLeafGreen
{
    static NSColor *marlinLeafGreen = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        marlinLeafGreen = [NSColor colorWithCalibratedRed:68.0/255.0
                                                    green:137.0/255.0
                                                     blue:26.0/255.0
                                                    alpha:1.0];
    });
    
    return marlinLeafGreen;
}

+ (NSColor *)marlinSlimeGreen
{
    static NSColor *marlinSlimeGreen = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        marlinSlimeGreen = [NSColor colorWithCalibratedRed:163.0/255.0
                                                     green:206.0/255.0
                                                      blue:39.0/255.0
                                                     alpha:1.0];
    });
    
    return marlinSlimeGreen;
}

+ (NSColor *)marlinNightBlue
{
    static NSColor *marlinNightBlue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        marlinNightBlue = [NSColor colorWithCalibratedRed:51.0/255.0
                                                    green:51.0/255.0
                                                     blue:153.0/255.0
                                                    alpha:1.0];
    });
    
    return marlinNightBlue;
}

+ (NSColor *)marlinSeaBlue
{
    static NSColor *marlinSeaBlue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        marlinSeaBlue = [NSColor colorWithCalibratedRed:0.0/255.0
                                                  green:87.0/255.0
                                                   blue:132.0/255.0
                                                  alpha:1.0];
    });
    
    return marlinSeaBlue;
}

+ (NSColor *)marlinSkyBlue
{
    static NSColor *marlinSkyBlue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        marlinSkyBlue = [NSColor colorWithCalibratedRed:49.0/255.0
                                                  green:162.0/255.0
                                                   blue:242.0/255.0
                                                  alpha:1.0];
    });
    
    return marlinSkyBlue;
}

+ (NSColor *)marlinCloudBlue
{
    static NSColor *marlinCloudBlue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        marlinCloudBlue = [NSColor colorWithCalibratedRed:178.0/255.0
                                                    green:220.0/255.0
                                                     blue:239.0/255.0
                                                    alpha:1.0];
    });
    
    return marlinCloudBlue;
}

@end
