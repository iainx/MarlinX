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
#import "MLNMarker.h"
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

- (void)removeMarker:(MLNMarker *)marker
         undoManager:(NSUndoManager *)undoManager
{
    MLNArrayController *ac = [self markerController];
    [ac removeObject:marker];
    
    [[undoManager prepareWithInvocationTarget:self] addMarker:marker
                                                  undoManager:undoManager];
}

- (void)addMarker:(MLNMarker *)marker
      undoManager:(NSUndoManager *)undoManager
{
    [[self markerController] addObject:marker];
    
    [[undoManager prepareWithInvocationTarget:self] removeMarker:marker
                                                     undoManager:undoManager];
}

- (void)moveMarker:(MLNMarker *)marker
         fromFrame:(NSNumber *)fromFrame
           toFrame:(NSNumber *)toFrame
       undoManager:(NSUndoManager *)undoManager
{
    [[undoManager prepareWithInvocationTarget:self] moveMarker:marker
                                                     fromFrame:toFrame
                                                       toFrame:fromFrame
                                                   undoManager:undoManager];
    [marker setFrame:toFrame];
}

- (void)removeMarkersForRange:(NSRange)range
                  undoManager:(NSUndoManager *)undoManager
{
    NSArray *markers = [[self markerController] arrangedObjects];
    
    for (MLNMarker *marker in markers) {
        NSUInteger frame = [[marker frame] unsignedIntegerValue];
        
        if (NSLocationInRange(frame, range)) {
            [self removeMarker:marker undoManager:undoManager];
        } else if (frame > NSMaxRange(range)) {
            [self moveMarker:marker
                   fromFrame:[marker frame]
                     toFrame:@(frame - range.length)
                 undoManager:undoManager];
        }
    }
}

- (void)moveMarkersForRange:(NSRange)range
                undoManager:(NSUndoManager *)undoManager
{
    NSArray *markers = [[self markerController] arrangedObjects];
    
    for (MLNMarker *marker in markers) {
        NSUInteger frame = [[marker frame] unsignedIntegerValue];
        if (frame > range.location) {
            [self moveMarker:marker
                   fromFrame:[marker frame]
                     toFrame:@(frame + range.length)
                 undoManager:undoManager];
        }
    }
}

// In all these methods:
// We only want the markers to be moved when the undo manager isn't doing anything
// because the marker move registers itself with the undo manager, and otherwise
// it will be executed twice.

- (BOOL)deleteRange:(NSRange)range
        undoManager:(NSUndoManager *)undoManager
{
    if (![self containsRange:range]) {
        return NO;
    }
    
    if (![undoManager isUndoing] && ![undoManager isRedoing]) {
        [self removeMarkersForRange:range
                        undoManager:undoManager];
    }
    
    NSMutableArray *deletedBlocks = [NSMutableArray arrayWithCapacity:[self numberOfChannels]];
    
    for (MLNSampleChannel *channel in [self channelData]) {
        MLNSampleBlock *blockList = [channel deleteRange:range];
        [deletedBlocks addObject:[NSValue valueWithPointer:blockList]];
    }
    
    [self setNumberOfFrames:[self numberOfFrames] - range.length];
    
    [self postChangeInRangeNotification:range];
    
    [[undoManager prepareWithInvocationTarget:self] insertBlocks:deletedBlocks
                                                         atFrame:range.location
                                                 withUndoManager:undoManager];
    
    return YES;
}

- (void)insertBlocks:(NSArray *)blockArray
             atFrame:(NSUInteger)frame
     withUndoManager:(NSUndoManager *)undoManager
{
    NSUInteger channelNumber = 0;
    
    NSValue *value = blockArray[0];
    NSUInteger extraFrames = MLNSampleBlockListNumberOfFrames([value pointerValue]);

    NSRange changedRange = NSMakeRange(frame, extraFrames);
    if (![undoManager isUndoing] && ![undoManager isRedoing]) {
        [self moveMarkersForRange:changedRange undoManager:undoManager];
    }
    
    for (MLNSampleChannel *channel in [self channelData]) {
        NSValue *blockListValue = blockArray[channelNumber];
        MLNSampleBlock *blockList = [blockListValue pointerValue];
        [channel insertBlockList:blockList atFrame:frame];
        channelNumber++;
    }

    [[undoManager prepareWithInvocationTarget:self] deleteRange:changedRange
                                                    undoManager:undoManager];

    [self setNumberOfFrames:[self numberOfFrames] + extraFrames];

    [self postChangeInRangeNotification:changedRange];
}

- (NSArray *)copyRange:(NSRange)range
             withError:(NSError **)error
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

- (BOOL)insertChannels:(NSArray *)channels
               atFrame:(NSUInteger)frame
             withUndoManager:(NSUndoManager *)undoManager
{
    if ([channels count] != [self numberOfChannels]) {
        return NO;
    }
    
    NSMutableArray *channelBlocks = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < [self numberOfChannels]; i++) {
        MLNSampleChannel *srcChannel = channels[i];
        
        channelBlocks[i] = [NSValue valueWithPointer:[srcChannel firstBlock]];
    }

    [self insertBlocks:channelBlocks atFrame:frame withUndoManager:undoManager];
    return YES;
}

- (BOOL)cropRange:(NSRange)range
  withUndoManager:(NSUndoManager *)undoManager
{
    if (![self containsRange:range]) {
        return NO;
    }
    
    NSRange startRange = NSMakeRange(0, range.location);
    NSRange endRange = NSMakeRange(NSMaxRange(range), [self numberOfFrames] - NSMaxRange(range));
    
    [undoManager beginUndoGrouping];
    [self deleteRange:endRange undoManager:undoManager];
    [self deleteRange:startRange undoManager:undoManager];
    [undoManager endUndoGrouping];
    
    return YES;
}

- (void)insertSilenceAtFrame:(NSUInteger)frame
              numberOfFrames:(NSUInteger)numberOfFrames
                 undoManager:(NSUndoManager *)undoManager
{
    NSRange changedRange = NSMakeRange(frame, numberOfFrames);
    
    if (![undoManager isUndoing] && ![undoManager isRedoing]) {
        [self moveMarkersForRange:changedRange
                      undoManager:undoManager];
    }
    for (MLNSampleChannel *channel in [self channelData]) {
        [channel insertSilenceAtFrame:frame frameDuration:numberOfFrames];
    }
    
    [self setNumberOfFrames:[self numberOfFrames] + numberOfFrames];
    
    [self postChangeInRangeNotification:changedRange];

    changedRange = NSMakeRange(frame, numberOfFrames);
    [[undoManager prepareWithInvocationTarget:self] deleteRange:changedRange
                                                    undoManager:undoManager];
}

- (void)clearRange:(NSRange)clearRange
   withUndoManager:(NSUndoManager *)undoManager
{
    if (![self containsRange:clearRange]) {
        return;
    }
    
    [undoManager beginUndoGrouping];
    [self deleteRange:clearRange undoManager:undoManager];
    [self insertSilenceAtFrame:clearRange.location numberOfFrames:clearRange.length undoManager:undoManager];
    [undoManager endUndoGrouping];
}

- (void)dumpDataInRange:(NSRange)range
{
    for (MLNSampleChannel *channel in [self channelData]) {
        NSData *dump = [channel dumpChannelRange:range];

        [dump writeToFile:[NSString stringWithFormat:@"/Users/iain/Marlin Test/dump-%@.dump", [channel channelName]]
               atomically:YES];                           
    }
}
@end
