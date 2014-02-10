//
//  MLNDurationFormatter.m
//  Marlin
//
//  Created by iain on 10/02/2014.
//  Copyright (c) 2014 iain. All rights reserved.
//

#import "MLNDurationFormatter.h"

@implementation MLNDurationFormatter


- (NSString *)stringForObjectValue:(id)obj
{
    if (![obj isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    
    NSNumber *number = (NSNumber *)obj;
    float frames = [number floatValue];
    
    float seconds = frames / (float)_sampleRate;
    NSUInteger hours = (NSUInteger)seconds / 3600;
    float secondsLeft = seconds - (hours * 3600);
    NSUInteger mins = (NSUInteger)secondsLeft / 60;
    secondsLeft = secondsLeft - (mins * 60);
    
    NSString *result = [NSString stringWithFormat:@"%lu:%lu:%.3f", hours, mins, secondsLeft];
    
    return result;
}

- (BOOL)getObjectValue:(out __autoreleasing id *)obj
             forString:(NSString *)string
      errorDescription:(out NSString *__autoreleasing *)error
{
    NSArray *components = [string componentsSeparatedByString:@":"];
    float seconds = 0;
    NSUInteger mins = 0, hours = 0;
    
    NSString *secondsComponent, *minsComponent, *hoursComponent;
    switch ([components count]) {
        case 1:
            secondsComponent = components[0];
            break;
            
        case 2:
            secondsComponent = components[1];
            minsComponent = components[0];
            break;
            
        case 3:
            secondsComponent = components[2];
            minsComponent = components[1];
            hoursComponent = components[0];
            break;
            
        default:
        case 0:
            if (error) {
                *error = NSLocalizedString(@"Couldn't convert to time", @"Error converting");
            }
            return NO;
    }
    
    seconds = [secondsComponent floatValue];
    mins = [minsComponent integerValue];
    hours = [hoursComponent integerValue];
    
    float floatResult = (hours * 3600) + (mins * 60) + seconds;
    
    if (_ignoreUpdate == NO) {
        floatResult *= _sampleRate;
    }
    
    if (obj) {
        *obj = [NSNumber numberWithFloat:floatResult];
    }
    
    return YES;
}

@end
