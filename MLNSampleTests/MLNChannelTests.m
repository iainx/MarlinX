//
//  MLNChannelTests.m
//  Marlin
//
//  Created by iain on 17/04/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNChannelTests.h"
#import "MLNSampleChannel.h"

@implementation MLNChannelTests {
    MLNSampleChannel *_channel;
}

static const NSUInteger BUFFER_FRAME_SIZE = 44100;

- (MLNSampleChannel *)createChannel
{
    MLNSampleChannel *channel = [[MLNSampleChannel alloc] init];
    [channel setChannelName:@"Test channel"];
    
    float *buffer = malloc(BUFFER_FRAME_SIZE * sizeof(float));
    
    // Fill all the frames with dummy data
    for (int i = 0; i < BUFFER_FRAME_SIZE; i++) {
        buffer[i] = (float)i;
    }
    
    [channel addData:buffer withLength:BUFFER_FRAME_SIZE * sizeof(float)];
    
    return channel;
}

- (void)setUp
{
    _channel = [[MLNSampleChannel alloc] init];
    [_channel setChannelName:@"Test channel"];
}

- (void)tearDown
{
    _channel = nil;
}

- (void)testAddBlocks
{
    MLNSampleBlock *block1, *block2;
    
    block1 = MLNSampleBlockCreateBlock(NULL, BUFFER_FRAME_SIZE * sizeof(float), 0, NULL, 0, 0);
    block2 = MLNSampleBlockCreateBlock(NULL, BUFFER_FRAME_SIZE * sizeof(float), 0, NULL, 0, 0);
    
    STAssertTrue([_channel firstBlock] == NULL, @"[_channel firstBlock] != NULL");
    
    [_channel addBlock:block1];
    
    STAssertTrue([_channel firstBlock] == block1, @"[_channel firstBlock] != block1");
    STAssertTrue([_channel lastBlock] == block1, @"[_channel lastBlock] != block1");
    STAssertEquals([_channel numberOfFrames], BUFFER_FRAME_SIZE, @"[_channel numberOfFrames != %lu: %lu", BUFFER_FRAME_SIZE, [_channel numberOfFrames]);
    
    [_channel addBlock:block2];
    
    STAssertTrue([_channel lastBlock] == block2, @"[_channel lastBlock != block2");
    STAssertEquals([_channel numberOfFrames], BUFFER_FRAME_SIZE * 2, @"[_channel numberOfFrames != %lu: %lu", BUFFER_FRAME_SIZE * 2, [_channel numberOfFrames]);
    
    STAssertEquals(block2->startFrame, BUFFER_FRAME_SIZE, @"block2->startFrame != %lu: %lu", BUFFER_FRAME_SIZE, block2->startFrame);
}

- (void)testRemoveBlocks
{
    MLNSampleBlock *block1, *block2;
    
    block1 = MLNSampleBlockCreateBlock(NULL, BUFFER_FRAME_SIZE * sizeof(float), 0, NULL, 0, 0);
    block2 = MLNSampleBlockCreateBlock(NULL, BUFFER_FRAME_SIZE * sizeof(float), 0, NULL, 0, 0);
    
    // We know addBlocks works if the previous test passed
    [_channel addBlock:block1];
    [_channel addBlock:block2];

    [_channel removeBlock:block1];
    
    STAssertTrue([_channel firstBlock] == block2, @"[_channel firstBlock] != block2");
    STAssertEquals([_channel numberOfFrames], BUFFER_FRAME_SIZE, @"[_channel numberOfFrames] != %lu: %lu", BUFFER_FRAME_SIZE, [_channel numberOfFrames]);
    STAssertEquals(block2->startFrame, (NSUInteger)0, @"block2->startFrame != 0: %lu", block2->startFrame);
    
    // Check the removed blocks have been unlinked
    STAssertTrue(block1->nextBlock == NULL, @"block1->nextBlock != NULL");
    STAssertTrue(block2->previousBlock == NULL, @"block2->previousBlock != NULL");
    
    [_channel removeBlock:block2];
    
    STAssertTrue([_channel firstBlock] == NULL, @"[_channel firstBlock] != NULL");
    STAssertTrue([_channel lastBlock] == NULL, @"[_channel lastBlock] != NULL");
    STAssertEquals([_channel numberOfFrames], (NSUInteger)0, @"[_channel numberOfFrames] != 0: %lu", [_channel numberOfFrames]);
    
    MLNSampleBlockFree(block1);
    MLNSampleBlockFree(block2);
}

- (void)testDeleteMiddleRegion
{
    MLNSampleBlock *block;
    
    _channel = [self createChannel];
    
    [_channel deleteRange:NSMakeRange(100, 100)];
    
    // We should now have 2 blocks [0 -> 99] & [100 -> 43999]
    STAssertEquals([_channel count], (NSUInteger)2, @"[_channel count] != 2: %lu", [_channel count]);
    
    block = [_channel firstBlock];
    STAssertEquals(block->startFrame, (NSUInteger)0, @"block->startFrame != 0: %lu", block->startFrame);
    STAssertEquals(block->numberOfFrames, (NSUInteger)100, @"block->numberOfFrames != 100: %lu", block->numberOfFrames);
    
    block = block->nextBlock;
    STAssertFalse(block == NULL, @"block == NULL");
    STAssertEquals(block->startFrame, (NSUInteger)100, @"block->startFrame != 100: %lu", block->startFrame);
    STAssertEquals(block->numberOfFrames, (NSUInteger)43900, @"block->numberOfFrames != 43900: %lu", block->numberOfFrames);
}

- (void)testDeleteStart
{
    MLNSampleBlock *block;

    _channel = [self createChannel];
    
    [_channel deleteRange:NSMakeRange(0, 100)];
    
    STAssertEquals([_channel count], (NSUInteger)1, @"[_channel count] != 1: %lu", [_channel count]);
    block = [_channel firstBlock];
    
    STAssertFalse(block == NULL, @"block == NULL");
    STAssertEquals(block->startFrame, (NSUInteger)0, @"block->startFrame != 0: %lu", block->startFrame);
    STAssertEquals(block->numberOfFrames, (NSUInteger)BUFFER_FRAME_SIZE - 100, @"block->numberOfFrames != 44000: %lu", block->numberOfFrames);
}

- (void)testDeleteEnd
{
    MLNSampleBlock *block;
    
    _channel = [self createChannel];
    
    [_channel deleteRange:NSMakeRange(44000, 100)];
    
    STAssertEquals([_channel count], (NSUInteger)1, @"[_channel count] != 1: %lu", [_channel count]);
    block = [_channel firstBlock];
    
    STAssertFalse(block == NULL, @"block == NULL");
    STAssertEquals(block->startFrame, (NSUInteger)0, @"block->startFrame != 0: %lu", block->startFrame);
    STAssertEquals(block->numberOfFrames, (NSUInteger)BUFFER_FRAME_SIZE - 100, @"block->numberOfFrames != 44000: %lu", block->numberOfFrames);
}

- (void)testDeleteAll
{
    _channel = [self createChannel];
    
    [_channel deleteRange:NSMakeRange(0, BUFFER_FRAME_SIZE)];
    
    STAssertEquals([_channel count], (NSUInteger)0, @"[_channel count] != 0: %lu", [_channel count]);
    STAssertEquals([_channel numberOfFrames], (NSUInteger)0, @"[_channel numberOfFrames] != 0: %lu", [_channel numberOfFrames]);
    STAssertTrue([_channel firstBlock] == NULL, @"[_channel firstBlock] != NULL");
    STAssertTrue([_channel lastBlock] == NULL, @"[_channel lastBlock] != NULL");
}

- (void)testDeleteInvalidLocation
{
    _channel = [self createChannel];
    STAssertThrows([_channel deleteRange:NSMakeRange(276824, 100)], nil);
}

- (void)testDeleteInvalidLength
{
    _channel = [self createChannel];
    STAssertThrows([_channel deleteRange:NSMakeRange(100, 124124123)], nil);
}

- (void)testCopyChannel
{
    NSUInteger startFrame, endFrame, numberOfFrames;
    MLNSampleChannel *channelCopy;
    
    _channel = [self createChannel];
    startFrame = rand() % [_channel numberOfFrames];
    endFrame = startFrame + (rand() % ([_channel numberOfFrames] - startFrame));
    numberOfFrames = (endFrame - startFrame) + 1;
    
    channelCopy = [_channel copyChannelInRange:NSMakeRange(startFrame, numberOfFrames)];
    
    STAssertNotNil(channelCopy, @"channelCopy is nil");
    STAssertEquals([channelCopy numberOfFrames], numberOfFrames, @"[channelCopy numberOfFrames] != %lu: %lu", numberOfFrames, [channelCopy numberOfFrames]);
}
@end
