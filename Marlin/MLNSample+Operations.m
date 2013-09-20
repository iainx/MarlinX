//
//  MLNSample+Operations.m
//  Marlin
//
//  Created by iain on 13/03/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNPasteboardSampleData.h"
#import "MLNSampleChannel.h"
#import "MLNSample+Operations.h"
#import "Constants.h"

@implementation MLNSample (Operations)

- (void)postChangeInRangeNotification:(NSRange)range
{
    NSDictionary *userInfo = @{@"range": [NSValue valueWithRange:range]};
    NSNotification *note = [NSNotification notificationWithName:kMLNSampleDataDidChangeInRange
                                                         object:self
                                                       userInfo:userInfo];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotification:note];
}

- (void)deleteRange:(NSRange)range
{
    if (![self containsRange:range]) {
        DDLogVerbose(@"Contains range failed");
        return;
    }
    
    for (MLNSampleChannel *channel in [self channelData]) {
        [channel deleteRange:range];
    }
    
    [self setNumberOfFrames:[self numberOfFrames] - range.length];
    
    [self postChangeInRangeNotification:range];
}

- (NSArray *)copyRange:(NSRange)range
{
    if (![self containsRange:range]) {
        return nil;
    }
    
    NSMutableArray *channels = [NSMutableArray arrayWithCapacity:[self numberOfChannels]];
    
    for (MLNSampleChannel *channel in [self channelData]) {
        MLNSampleChannel *channelCopy = [channel copyChannelInRange:range];
        
        [channels addObject:channelCopy];
    }
    
    return channels;
}

- (BOOL)canInsertChannels:(NSArray *)channels
               sampleRate:(NSUInteger)sampleRate
{
    if ([channels count] == [self numberOfChannels] &&
        [self sampleRate] == sampleRate) {
        return YES;
    } else {
        return NO;
    }
}

- (void)insertChannels:(NSArray *)channels
               atFrame:(NSUInteger)frame
{
    if ([channels count] != [self numberOfChannels]) {
        return;
    }
    
    for (NSUInteger i = 0; i < [self numberOfChannels]; i++) {
        MLNSampleChannel *destChannel = [self channelData][i];
        MLNSampleChannel *srcChannel = channels[i];
        
        [destChannel insertChannel:srcChannel atFrame:frame];
    }
    
    MLNSampleChannel *aChannel = [self channelData][0];
    [self setNumberOfFrames:[aChannel numberOfFrames]];
    
    [self postChangeInRangeNotification:NSMakeRange(frame, [aChannel numberOfFrames] - frame)];
}

- (void)cropRange:(NSRange)range
{
    if (![self containsRange:range]) {
        return;
    }
    
    NSRange testRange = NSMakeRange(0, 2);
    DDLogVerbose(@"Range: %@, %lu", NSStringFromRange(testRange), NSMaxRange(testRange));
    
    NSRange startRange = NSMakeRange(0, range.location);
    NSRange endRange = NSMakeRange(NSMaxRange(range), [self numberOfFrames] - NSMaxRange(range));
    
    DDLogVerbose(@"Deleting %@ and %@", NSStringFromRange(startRange), NSStringFromRange(endRange));
    
    [self deleteRange:endRange];
    
    DDLogVerbose(@"After deleting %@ -> %lu frames left", NSStringFromRange(endRange), [self numberOfFrames]);
    [self deleteRange:startRange];
    
    DDLogVerbose(@"After deleting %@ -> %lu frames left", NSStringFromRange(startRange), [self numberOfFrames]);
}
@end
