//
//  MLNSample+Operations.m
//  Marlin
//
//  Created by iain on 13/03/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNSampleChannel.h"
#import "MLNSample+Operations.h"

@implementation MLNSample (Operations)

- (void)deleteRange:(NSRange)range
{
    for (MLNSampleChannel *channel in [self channelData]) {
        [channel deleteRange:range];
    }
    
    [self setNumberOfFrames:[self numberOfFrames] - range.length];
    
    if ([self delegate]) {
        if ([[self delegate] respondsToSelector:@selector(sampleDataDidChangeInRange:)]) {
            [[self delegate] sampleDataDidChangeInRange:range];
        }
    }
}

- (NSArray *)copyRange:(NSRange)range
{
    NSMutableArray *channels = [NSMutableArray arrayWithCapacity:[self numberOfChannels]];
    
    for (MLNSampleChannel *channel in [self channelData]) {
        MLNSampleChannel *channelCopy = [channel copyChannelInRange:range];
        
        [channels addObject:channelCopy];
    }
    
    return channels;
}

- (BOOL)canInsertChannels:(NSArray *)channels
{
    if ([channels count] == [self numberOfChannels]) {
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
}
@end
