//
//  MLNSecondsFormatter.m
//  Marlin
//
//  Created by iain on 09/02/2014.
//  Copyright (c) 2014 iain. All rights reserved.
//

#import "MLNSecondsFormatter.h"

@implementation MLNSecondsFormatter

- (NSString *)stringForObjectValue:(id)obj
{
    if (![obj isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    
    NSNumber *number = (NSNumber *)obj;
    float frames = [number floatValue];
    
    NSString *result = [NSString stringWithFormat:@"%f", frames / (float)_sampleRate];

    return result;
}

- (BOOL)getObjectValue:(out __autoreleasing id *)obj
             forString:(NSString *)string
      errorDescription:(out NSString *__autoreleasing *)error
{
    float floatResult;
    NSScanner *scanner;
    BOOL returnValue = NO;
    
    scanner = [NSScanner scannerWithString:string];
    if ([scanner scanFloat:&floatResult] && ([scanner isAtEnd])) {
        returnValue = YES;
        if (obj) {
            if (_ignoreUpdate == NO) {
                floatResult *= _sampleRate;
            }
            *obj = [NSNumber numberWithFloat:floatResult];
        }
    } else {
        if (error)
            *error = NSLocalizedString(@"Couldn’t convert  to float", @"Error converting");
    }
    return returnValue;
}

- (BOOL)isPartialStringValid:(NSString *)partialString
            newEditingString:(NSString *__autoreleasing *)newString
            errorDescription:(NSString *__autoreleasing *)error
{
    return YES;
}
@end
