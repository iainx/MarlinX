//
//  MLNSampleTests.m
//  MLNSampleTests
//
//  Created by iain on 15/04/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNSampleTests.h"

#import "MLNSampleBlock.h"
#import "MLNSampleChannel.h"
#import "MLNSampleChannelIterator.h"
#import "MLNSample.h"
#import "MLNSample+Operations.h"

@implementation MLNSampleTests {
    MLNSample *_testSample;
    MLNSample *_testStereoSample;
}

static const NSUInteger BUFFER_FRAME_SIZE = 44100;

- (MLNSampleChannel *)makeChannelWithName:(NSString *)name
{
    MLNSampleChannel *channel = [[MLNSampleChannel alloc] init];
    [channel setChannelName:name];
    
    float *buffer = malloc(BUFFER_FRAME_SIZE * sizeof(float));
    
    // Fill all the frames with dummy data
    for (int i = 0; i < BUFFER_FRAME_SIZE; i++) {
        buffer[i] = (float)i;
    }
    
    [channel addData:buffer withByteLength:BUFFER_FRAME_SIZE * sizeof(float)];
    
    return channel;
}

- (void)setUp
{
    srand((unsigned int)time(NULL));
    
    [super setUp];
    
    NSMutableArray *channels = [NSMutableArray array];
    
    [channels addObject:[self makeChannelWithName:@"Test Channel - Mono"]];
    
    _testSample = [[MLNSample alloc] initWithChannels:channels];
    
    
    channels = [NSMutableArray arrayWithCapacity:2];
    [channels addObject:[self makeChannelWithName:@"Test Channel - Left"]];
    [channels addObject:[self makeChannelWithName:@"Test Channel - Right"]];
    
    _testStereoSample = [[MLNSample alloc] initWithChannels:channels];
}

- (void)tearDown
{
    _testSample = nil;
    _testStereoSample = nil;
    [super tearDown];
}

- (void)testData
{
    STAssertEquals([_testSample numberOfFrames], (NSUInteger)44100, nil);
    
    MLNSampleChannel *channel = [_testSample channelData][0];
    
    STAssertNotNil(channel, @"Channel is nil");
    
    MLNSampleBlock *block = [channel firstBlock];
    
    STAssertFalse(block == NULL, @"Block is NULL");
    
    NSUInteger numberOfFrames = block->numberOfFrames;
    
    STAssertEquals(numberOfFrames, BUFFER_FRAME_SIZE, @"Number of frames are different: Expected %d, got %d", BUFFER_FRAME_SIZE, numberOfFrames);
    
    for (int i = 0; i < BUFFER_FRAME_SIZE; i++) {
        float value = MLNSampleBlockDataAtFrame(block, i);
        
        STAssertEquals(value, (float)i, @"Frame %d is %f: Expected %f", i, value, (float)i);
    }
}

- (void)testDeleteRange
{
    [_testSample deleteRange:NSMakeRange(100, 100) undoManager:nil];
    
    // If the Channel tests have passed then the only thing this needs to test is that the sample has the correct number of frames
    STAssertEquals([_testSample numberOfFrames], (NSUInteger)44000, @"[_testSample numberOfFrames != 44000: %lu", [_testSample numberOfFrames]);
}

- (void)testDeleteRangeUndo
{
    NSUndoManager *undo = [[NSUndoManager alloc] init];
    
    [_testSample deleteRange:NSMakeRange(100, 100) undoManager:undo];
    
    STAssertTrue([undo canUndo], @"");
    
    [undo undo];
    
    STAssertFalse([undo canUndo], @"");
    
    STAssertEquals([_testSample numberOfFrames], (NSUInteger)44100, @"");
    
    MLNSampleChannel *channel = [_testSample channelData][0];
    MLNSampleBlock *block = [channel firstBlock];
    
    NSUInteger j = 0;
    
    while (block) {
        for (int i = 0; i < block->numberOfFrames; i++, j++) {
            float value = MLNSampleBlockDataAtFrame(block, i);
    
            STAssertEquals(value, (float)j, @"Frame %d is %f: Expected %f", i, value, (float)j);
        }
        
        block = block->nextBlock;
    }
}

- (void)testInsertInvalid
{
    
}

- (void)testCropRange
{
    NSUInteger start = rand() % [_testSample numberOfFrames];
    NSUInteger length = rand() % ([_testSample numberOfFrames] - start);
    
    NSRange range = NSMakeRange(start, length);
    
    [_testSample cropRange:range withUndoManager:nil];
    
    STAssertEquals([_testSample numberOfFrames], length, @"Range is %@", NSStringFromRange(range));
}

- (void)testCropRangeUndo
{
    NSUndoManager *undo = [[NSUndoManager alloc] init];
    NSUInteger start = rand() % [_testSample numberOfFrames];
    NSUInteger length = rand() % ([_testSample numberOfFrames] - start);
    
    NSRange range = NSMakeRange(start, length);
    
    [_testSample cropRange:range withUndoManager:undo];
    
    MLNSampleChannel *channel = [_testSample channelData][0];
    MLNSampleBlock *block = [channel firstBlock];
    
    STAssertFalse(block == NULL, @"");
    [undo undo];
    
    NSUInteger numberOfBlocks = 0;
    block = [channel firstBlock];
    while (block) {
        block = block->nextBlock;
        numberOfBlocks++;
    }
    STAssertEquals(numberOfBlocks, (NSUInteger)3, @"");
    STAssertEquals([_testSample numberOfFrames], (NSUInteger)44100, @"");

    block = [channel firstBlock];
    STAssertEquals(block->startFrame, (NSUInteger)0, @"");
    STAssertEquals(block->numberOfFrames, (NSUInteger)start, @"");
    
    for (int i = 0; i < block->numberOfFrames; i++) {
        float value = MLNSampleBlockDataAtFrame(block, i);
        STAssertEquals(value, (float)i, @"");
    }
    
    MLNSampleBlock *block2 = block->nextBlock;
    STAssertFalse(block2 == NULL, @"");
    
    STAssertEquals(block2->previousBlock, block, @"");
    STAssertEquals(block2->startFrame, start, @"");
    STAssertEquals(block2->numberOfFrames, length, @"");
    
    for (int i = 0; i < block->numberOfFrames; i++) {
        float value = MLNSampleBlockDataAtFrame(block2, i);
        STAssertEquals(value, (float)i + block2->startFrame, @"");
    }
    
    MLNSampleBlock *block3 = block2->nextBlock;
    
    STAssertFalse(block3 == NULL, @"");
    
    STAssertEquals(block3->previousBlock, block2, @"");
    STAssertEquals(block3->startFrame, start + length, @"");
    STAssertEquals(block3->numberOfFrames, 44100 - block3->startFrame, @"");
    
    STAssertEquals([channel lastBlock], block3, @"");
    
    for (int i = 0; i < block3->numberOfFrames; i++) {
        float value = MLNSampleBlockDataAtFrame(block3, i);
        STAssertEquals(value, (float)i + block3->startFrame, @"");
    }
}

- (void)checkSilenceInRange:(NSRange)range
{
    MLNSampleChannelIterator *iter;
    MLNSampleChannel *channel = [_testSample channelData][0];
    
    NSLog(@"number of frames in channel: %lu", [channel numberOfFrames]);
    NSUInteger i;
    
    iter = [[MLNSampleChannelIterator alloc] initWithChannel:channel atFrame:0];
    BOOL moreData = YES;
    
    i = 0;
    while (moreData) {
        float value;
        moreData = [iter nextFrameData:&value];
        
        if (NSLocationInRange(i, range)) {
            STAssertEquals(value, (float)0, @"at %lu (%@)", i, NSStringFromRange(range));
        } else if (i < range.location) {
            STAssertEquals(value, (float)i, @"at %lu (%@)", i, NSStringFromRange(range));
        } else {
            STAssertEquals(value, (float)i - range.length, @"at %lu (%@)", i, NSStringFromRange(range));
        }
        
        i++;
    }
}

- (void)testInsertSilence
{
    NSUInteger frame = rand() % [_testSample numberOfFrames];
    NSUInteger numberOfFrames = rand() % 44100;
    NSUInteger expectedNumberOfFrames = [_testSample numberOfFrames] + numberOfFrames;
    
    [_testSample insertSilenceAtFrame:frame numberOfFrames:numberOfFrames undoManager:nil];
    
    STAssertEquals([_testSample numberOfFrames], (NSUInteger)expectedNumberOfFrames, @"");
    
    [self checkSilenceInRange:NSMakeRange(frame, numberOfFrames)];
}

- (void)testInsertSilenceStart
{
    NSUInteger numberOfFrames = rand() % 44100;
    NSUInteger expectedNumberOfFrames = [_testSample numberOfFrames] + numberOfFrames;
    
    [_testSample insertSilenceAtFrame:0 numberOfFrames:numberOfFrames undoManager:nil];
    
    STAssertEquals([_testSample numberOfFrames], expectedNumberOfFrames, @"");
    
    [self checkSilenceInRange:NSMakeRange(0, numberOfFrames)];
}

- (void)testInsertSilenceEnd
{
    NSUInteger numberOfFrames = rand() % 44100;
    NSUInteger expectedNumberOfFrames = [_testSample numberOfFrames] + numberOfFrames;
    
    [_testSample insertSilenceAtFrame:[_testSample numberOfFrames] numberOfFrames:numberOfFrames undoManager:nil];
    
    STAssertEquals([_testSample numberOfFrames], expectedNumberOfFrames, @"");

    [self checkSilenceInRange:NSMakeRange(44100, numberOfFrames)];
}

- (void)testInsertSilenceUndo
{
    NSUndoManager *undo = [[NSUndoManager alloc] init];

    NSUInteger frame = rand() % [_testSample numberOfFrames];
    NSUInteger numberOfFrames = rand() % 44100;
    NSUInteger expectedNumberOfFrames = [_testSample numberOfFrames] + numberOfFrames;
    
    [_testSample insertSilenceAtFrame:frame numberOfFrames:numberOfFrames undoManager:undo];
    
    STAssertEquals([_testSample numberOfFrames], (NSUInteger)expectedNumberOfFrames, @"");
    
    [undo undo];
    
    STAssertEquals([_testSample numberOfFrames], (NSUInteger)44100, @"");
}

- (void)testClearRange
{
    NSUInteger start = rand() % [_testSample numberOfFrames];
    NSUInteger length = rand() % ([_testSample numberOfFrames] - start);
    NSRange range = NSMakeRange(start, length);
    
    [_testSample clearRange:range withUndoManager:nil];
    
    STAssertEquals([_testSample numberOfFrames], (NSUInteger)44100, @"");
}

- (void)testClearRangeStart
{
    NSUInteger length = rand() % [_testSample numberOfFrames];
    NSUInteger start = 0;
    NSRange range = NSMakeRange(start, length);
    
    [_testSample clearRange:range withUndoManager:nil];
    
    STAssertEquals([_testSample numberOfFrames], (NSUInteger)44100, @"");
}

- (void)testClearRangeEnd
{
    NSUInteger length = rand() % [_testSample numberOfFrames];
    NSUInteger start = [_testSample numberOfFrames] - length;
    NSRange range = NSMakeRange(start, length);
    
    [_testSample clearRange:range withUndoManager:nil];
    
    STAssertEquals([_testSample numberOfFrames], (NSUInteger)44100, @"");
}

- (void)testClearAll
{
    NSRange range = NSMakeRange(0, [_testSample numberOfFrames]);
    
    [_testSample clearRange:range withUndoManager:nil];
    
    STAssertEquals([_testSample numberOfFrames], (NSUInteger)44100, @"");
}

- (void)testClearRangeUndo
{
    NSUndoManager *undo = [[NSUndoManager alloc] init];

    NSUInteger start = rand() % [_testSample numberOfFrames];
    NSUInteger length = rand() % ([_testSample numberOfFrames] - start);
    NSRange range = NSMakeRange(start, length);
    
    [_testSample clearRange:range withUndoManager:undo];
    
    STAssertEquals([_testSample numberOfFrames], (NSUInteger)44100, @"");
    
    [undo undo];
    
    STAssertEquals([_testSample numberOfFrames], (NSUInteger)44100, @"");
}
@end
