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
    
    const float *data = MLNSampleBlockSampleData(block);
    
    STAssertFalse(data == NULL, @"Sample data is NULL");
    
    for (int i = 0; i < BUFFER_FRAME_SIZE; i++) {
        float d = data[i];
        
        STAssertEquals(d, (float)i, @"Frame %d is %f: Expected %f", i, d, (float)i);
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
        const float *data = MLNSampleBlockSampleData(block);
        for (int i = 0; i < block->numberOfFrames; i++, j++) {
            float d = data[i];
    
            STAssertEquals(d, (float)j, @"Frame %d is %f: Expected %f", i, d, (float)i);
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
    
    // Crop is just 2 channel deletes, so if the channel tests passed then we just need to check the number of frames
    STAssertEquals([_testSample numberOfFrames], length, @"Range is %@", NSStringFromRange(range));
}

- (void)testCropRangeUndo
{
    NSUndoManager *undo = [[NSUndoManager alloc] init];
    NSUInteger start = rand() % [_testSample numberOfFrames];
    NSUInteger length = rand() % ([_testSample numberOfFrames] - start);
    
    NSRange range = NSMakeRange(start, length);
    
    [_testSample cropRange:range withUndoManager:undo];
    
    [undo undo];
    
    MLNSampleChannel *channel = [_testSample channelData][0];
    MLNSampleBlock *block = [channel firstBlock];
    
    NSUInteger j = 0;
    NSUInteger numberOfBlocks = 0;
    
    while (block) {
        const float *data = MLNSampleBlockSampleData(block);
        for (int i = 0; i < block->numberOfFrames; i++, j++) {
            float d = data[i];
            
            STAssertEquals(d, (float)j, @"Frame %d is %f: Expected %f", i, d, (float)i);
        }
        
        block = block->nextBlock;
        numberOfBlocks++;
    }
    
    STAssertEquals(numberOfBlocks, (NSUInteger)3, @"");
    STAssertEquals([_testSample numberOfFrames], (NSUInteger)44100, @"");
}

- (void)testInsertSilence
{
    [_testSample insertSilenceAtFrame:100 numberOfFrames:100 undoManager:nil];
    
    STAssertEquals([_testSample numberOfFrames], (NSUInteger)44200, @"");
}
@end
