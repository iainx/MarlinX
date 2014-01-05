//
//  MLNBlockTests.m
//  Marlin
//
//  Created by iain on 17/04/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNBlockTests.h"
#import "MLNSampleBlockFile.h"
#import "MLNSampleChannel.h"

@implementation MLNBlockTests

static const NSUInteger BUFFER_FRAME_SIZE = 44100;

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testAppend
{
    MLNSampleBlock *block1, *block2, *block3;
    
    block1 = MLNSampleBlockFileCreateBlock(NULL, 0, 0, NULL, 0, 0);
    block2 = MLNSampleBlockFileCreateBlock(NULL, 0, 0, NULL, 0, 0);
    block3 = MLNSampleBlockFileCreateBlock(NULL, 0, 0, NULL, 0, 0);
    
    // Append block 2 to block 1
    MLNSampleBlockAppendBlock(block1, block2);
    
    STAssertFalse(block1->nextBlock == NULL, @"block1->nextBlock == NULL");
    STAssertTrue(block1->nextBlock == block2, @"block2->nextBlock != block2");
    STAssertFalse(block2->previousBlock == NULL, @"block2->previousBlock == NULL");
    STAssertTrue(block2->previousBlock == block1, @"block2->previousBlock != block2");
    
    // Append block 3 to block 1, inserting it before block 2
    MLNSampleBlockAppendBlock(block1, block3);
    
    // Check that block 3 is connected to block 1
    STAssertFalse(block1->nextBlock == NULL, @"block1->nextBlock == NULL");
    STAssertTrue(block1->nextBlock == block3, @"block1->nextBlock != block3");
    STAssertFalse(block3->previousBlock == NULL, @"block3->previouBlock == NULL");
    STAssertTrue(block3->previousBlock == block1, @"block3->previousBlock != block1");
    
    // Check that block 3 is connected to block 2
    STAssertFalse(block3->nextBlock == NULL, @"block3->nextBlock == NULL");
    STAssertTrue(block3->nextBlock == block2, @"block3->nextBlock != block2");
    STAssertFalse(block2->previousBlock == NULL, @"block2->previousBlock == NULL");
    STAssertTrue(block2->previousBlock == block3, @"block2->previousBlock != block2");
    
    MLNSampleBlockFree(block1);
    MLNSampleBlockFree(block2);
    MLNSampleBlockFree(block3);
}

- (void)testPrepend
{
    MLNSampleBlock *block1, *block2, *block3;
    
    block1 = MLNSampleBlockFileCreateBlock(NULL, 0, 0, NULL, 0, 0);
    block2 = MLNSampleBlockFileCreateBlock(NULL, 0, 0, NULL, 0, 0);
    block3 = MLNSampleBlockFileCreateBlock(NULL, 0, 0, NULL, 0, 0);
    
    // Prepend block 2 to block 1
    MLNSampleBlockPrependBlock(block1, block2);
    
    STAssertFalse(block1->previousBlock == NULL, @"block1->previousBlock == NULL");
    STAssertTrue(block1->previousBlock == block2, @"block1->previousBlock != block2");
    STAssertFalse(block2->nextBlock == NULL, @"block2->nextBlock == NULL");
    STAssertTrue(block2->nextBlock == block1, @"block2->nextBlock != block1");
    
    // Prepend block 3 to block 1, inserting it after block 2
    MLNSampleBlockPrependBlock(block1, block3);
    
    // Check that block 3 is connected to block 1
    STAssertFalse(block1->previousBlock == NULL, @"block1->previousBlock == NULL");
    STAssertTrue(block1->previousBlock == block3, @"block1->previousBlock != block3");
    STAssertFalse(block3->nextBlock == NULL, @"block3->nextBlock == NULL");
    STAssertTrue(block3->nextBlock == block1, @"block3->nextBlock != block1");
    
    // Check that block 3 is connected to block 2
    STAssertFalse(block3->previousBlock == NULL, @"block3->previousBlock == NULL");
    STAssertTrue(block3->previousBlock == block2, @"block3->previousBlock != block2");
    STAssertFalse(block2->nextBlock == NULL, @"block2->nextBlock == NULL");
    STAssertTrue(block2->nextBlock == block3, @"block2->nextBlock != block3");
    
    MLNSampleBlockFree(block1);
    MLNSampleBlockFree(block2);
    MLNSampleBlockFree(block3);
}

- (void)testRemove
{
    MLNSampleBlock *block1, *block2, *block3;
    
    block1 = MLNSampleBlockFileCreateBlock(NULL, 0, 0, NULL, 0, 0);
    block2 = MLNSampleBlockFileCreateBlock(NULL, 0, 0, NULL, 0, 0);
    block3 = MLNSampleBlockFileCreateBlock(NULL, 0, 0, NULL, 0, 0);

    // Make a list of block1->block2->block3
    // We know this works because the earlier append test succeeded
    MLNSampleBlockAppendBlock(block1, block2);
    MLNSampleBlockAppendBlock(block2, block3);

    // Remove block2
    MLNSampleBlockRemoveFromList(block2);
    
    // Check block2 is detached
    STAssertTrue(block2->previousBlock == NULL, @"block2->previousBlock != NULL");
    STAssertTrue(block2->nextBlock == NULL, @"block2->nextBlock != NULL");
    
    // Check block1 & block3 are connected
    STAssertFalse(block1->nextBlock == NULL, @"block1->nextBlock == NULL");
    STAssertTrue(block1->nextBlock == block3, @"block1->nextBlock != block3");
    STAssertFalse(block3->previousBlock == NULL, @"block3->previousBlock == NULL");
    STAssertTrue(block3->previousBlock == block1, @"block3->previousBlock != block1");
    
    // Remove block3
    MLNSampleBlockRemoveFromList(block3);
    
    // Check block3 is detached
    STAssertTrue(block3->previousBlock == NULL, @"block3->previousBlock != NULL");
    STAssertTrue(block3->nextBlock == NULL, @"block3->nextBlock != NULL");
    
    // Check block1 is detached
    STAssertTrue(block1->previousBlock == NULL, @"block3->previousBlock != NULL");
    STAssertTrue(block1->nextBlock == NULL, @"block3->nextBlock != NULL");

    MLNSampleBlockFree(block1);
    MLNSampleBlockFree(block2);
    MLNSampleBlockFree(block3);
}

- (void)testRemoveList
{
    MLNSampleBlock *block1, *block2, *block3, *block4;
    
    block1 = MLNSampleBlockFileCreateBlock(NULL, 0, 0, NULL, 0, 0);
    block2 = MLNSampleBlockFileCreateBlock(NULL, 0, 0, NULL, 0, 0);
    block3 = MLNSampleBlockFileCreateBlock(NULL, 0, 0, NULL, 0, 0);
    block4 = MLNSampleBlockFileCreateBlock(NULL, 0, 0, NULL, 0, 0);
    
    // Make a list of block1->block2->block3->4
    // We know this works because the earlier append test succeeded
    MLNSampleBlockAppendBlock(block1, block2);
    MLNSampleBlockAppendBlock(block2, block3);
    MLNSampleBlockAppendBlock(block3, block4);
    
    // Remove block2 & block3 from the list
    // This should leave us with 2 lists: block1->block4 & block2->block3
    MLNSampleBlockRemoveBlocksFromList(block2, block3);
    
    STAssertFalse(block1->nextBlock == NULL, @"block1->nextBlock == NULL");
    STAssertTrue(block1->nextBlock == block4, @"block1->nextBlock != block4");
    STAssertFalse(block4->previousBlock == NULL, @"block4->previousBlock == NULL");
    STAssertTrue(block4->previousBlock == block1, @"block4->previousBlock != block1");
    
    STAssertFalse(block2->nextBlock == NULL, @"block2->nextBlock == NULL");
    STAssertTrue(block2->nextBlock == block3, @"block2->nextBlock != block3");
    STAssertFalse(block3->previousBlock == NULL, @"block3->previousBlock == NULL");
    STAssertTrue(block3->previousBlock == block2, @"block3->previousBlock != block2");

    MLNSampleBlockFree(block1);
    MLNSampleBlockFree(block2);
    MLNSampleBlockFree(block3);
    MLNSampleBlockFree(block4);
}

- (MLNSampleChannel *)createChannel
{
    MLNSampleChannel *channel = [[MLNSampleChannel alloc] init];
    [channel setChannelName:@"Test channel"];
    
    float *buffer = malloc(BUFFER_FRAME_SIZE * sizeof(float));
    
    // Fill all the frames with dummy data
    for (int i = 0; i < BUFFER_FRAME_SIZE; i++) {
        buffer[i] = (float)i;
    }
    
    [channel addData:buffer withByteLength:BUFFER_FRAME_SIZE * sizeof(float)];
    
    return channel;
}

- (void)testSplitMiddleFrame
{
    MLNSampleChannel *channel = [self createChannel];
    MLNSampleBlock *block1, *block2;
    MLNSampleBlockFile *fileBlock;
    
    block1 = [channel firstBlock];
    MLNSampleBlockSplitBlockAtFrame(block1, 22050, &block1, &block2);
    
    STAssertFalse(block2 == NULL, @"block2 == NULL");
    
    fileBlock = (MLNSampleBlockFile *)block1;
    STAssertEquals(block1->startFrame, (NSUInteger)0, @"block1->startFrame != 0: Got %lu", block1->startFrame);
    STAssertEquals(block1->numberOfFrames, (NSUInteger)22050, @"block1->numberOfFrames != 22050: Got %lu", block1->numberOfFrames);
    STAssertEquals(fileBlock->sampleByteLength, (ssize_t)22050 * sizeof(float), @"block1->sampleByteLength != %lu: Got %lu",
                   22050 * sizeof(float), fileBlock->sampleByteLength);
    
    for (int i = 0; i < 22050; i++) {
        float value = MLNSampleBlockDataAtFrame(block1, i);
        STAssertEquals(value, (float)i, @"block1->data[%d] != %f: %f", i, (float)i, value);
    }
    
    fileBlock = (MLNSampleBlockFile *)block2;
    STAssertEquals(block2->startFrame, (NSUInteger)22050, @"block2->startFrame != 22050: Got %lu", block2->startFrame);
    STAssertEquals(block2->numberOfFrames, (NSUInteger)22050, @"block2->numberOfFrames != 22050: Got %lu", block2->numberOfFrames);
    STAssertEquals(fileBlock->sampleByteLength, (ssize_t)22050 * sizeof(float), @"block2->sampleByteLength != %lu: Got %lu",
                   22050 * sizeof(float), fileBlock->sampleByteLength);
    
    for (int i = 0; i < 22050; i++) {
        float value = MLNSampleBlockDataAtFrame(block2, i);
        STAssertEquals(value, (float)22050 + i, @"block1->data[%d] != %f: %f", i, (float)22050 + i, value);
    }
}

- (void)testSplitFirstFrame
{
    MLNSampleBlock *block1, *desiredBlock2, *block2;
    
    block1 = MLNSampleBlockFileCreateBlock(NULL, 44100 * sizeof(float), 0, NULL, (44100 / 256) * sizeof(MLNSampleCachePoint), 0);
    desiredBlock2 = block1;
    MLNSampleBlockSplitBlockAtFrame(block1, 0, &block1, &block2);
    
    STAssertEquals(block1, (MLNSampleBlock *)NULL, @"");
    STAssertTrue(block2 == desiredBlock2, @"block2 != desiredBlock2");
    
    MLNSampleBlockFree(block1);
}

- (void)testSplitLastFrame
{
    MLNSampleChannel *channel = [self createChannel];
    MLNSampleBlock *block1, *block2;
    MLNSampleBlockFile *fileBlock;
    
    block1 = [channel firstBlock];
    
    // Split final frame, result should be a single framed block
    MLNSampleBlockSplitBlockAtFrame(block1, 44099, &block1, &block2);
    
    STAssertFalse(block2 == NULL, @"block2 == NULL");
    
    fileBlock = (MLNSampleBlockFile *)block1;
    
    STAssertEquals(block1->startFrame, (NSUInteger)0, @"block1->startFrame != 0: Got %lu", block1->startFrame);
    STAssertEquals(block1->numberOfFrames, (NSUInteger)44099, @"block1->numberOfFrames != 44099: Got %lu", block1->numberOfFrames);
    STAssertEquals(fileBlock->sampleByteLength, (ssize_t)44099 * sizeof(float), @"block1->sampleByteLength != %lu: Got %lu",
                   44099 * sizeof(float), fileBlock->sampleByteLength);
    
    fileBlock = (MLNSampleBlockFile *)block2;
    
    STAssertEquals(block2->startFrame, (NSUInteger)44099, @"block2->startFrame != 22050: Got %lu", block2->startFrame);
    STAssertEquals(block2->numberOfFrames, (NSUInteger)1, @"block2->numberOfFrames != 22050: Got %lu", block2->numberOfFrames);
    STAssertEquals(fileBlock->sampleByteLength, (ssize_t)1 * sizeof(float), @"block2->sampleByteLength != %lu: Got %lu",
                   1 * sizeof(float), fileBlock->sampleByteLength);
}

- (void)testSplitInvalidFrame
{
    MLNSampleBlock *block1, *block2;
    
    block1 = MLNSampleBlockFileCreateBlock(NULL, 44100 * sizeof(float), 0, NULL, (44100 / 256) * sizeof(MLNSampleCachePoint), 0);
    MLNSampleBlockSplitBlockAtFrame(block1, 876235, &block1, &block2);
    
    STAssertTrue(block2 == NULL, @"block2 != NULL");
    
    MLNSampleBlockFree(block1);
}

- (void)testCopy
{
    MLNSampleChannel *channel = [self createChannel];
    MLNSampleBlock *block1, *block2;
    MLNSampleBlockFile *fileBlock;
    
    block1 = [channel firstBlock];
    
    block2 = MLNSampleBlockCopy(block1, 22050, MLNSampleBlockLastFrame(block1));

    STAssertFalse(block2 == NULL, @"block2 == NULL");
    
    fileBlock = (MLNSampleBlockFile *)block1;
    STAssertEquals(block1->startFrame, (NSUInteger)0, @"block1->startFrame != 0: Got %lu", block1->startFrame);
    STAssertEquals(block1->numberOfFrames, (NSUInteger)44100, @"block1->numberOfFrames != 44100: Got %lu", block1->numberOfFrames);
    STAssertEquals(fileBlock->sampleByteLength, (ssize_t)44100 * sizeof(float), @"block1->sampleByteLength != %lu: Got %lu",
                   44100 * sizeof(float), fileBlock->sampleByteLength);
    
    for (int i = 0; i < 44100; i++) {
        float value = MLNSampleBlockDataAtFrame(block1, i);
        STAssertEquals(value, (float)i, @"block1->data[%d] != %f: %f", i, (float)i, value);
    }
    
    fileBlock = (MLNSampleBlockFile *)block2;
    STAssertEquals(block2->startFrame, (NSUInteger)22050, @"block2->startFrame != 22050: Got %lu", block2->startFrame);
    STAssertEquals(block2->numberOfFrames, (NSUInteger)22050, @"block2->numberOfFrames != 22050: Got %lu", block2->numberOfFrames);
    STAssertEquals(fileBlock->sampleByteLength, (ssize_t)22050 * sizeof(float), @"block2->sampleByteLength != %lu: Got %lu",
                   22050 * sizeof(float), fileBlock->sampleByteLength);
    
    for (int i = 0; i < 22050; i++) {
        float value = MLNSampleBlockDataAtFrame(block2, i);
        STAssertEquals(value, (float)22050 + i, @"block1->data[%d] != %f: %f", i, (float)22050 + i, value);
    }

    // Don't need to free block1 because it is owned by the channel
    MLNSampleBlockFree(block2);
}

- (void)testCopyEnd
{
    MLNSampleChannel *channel = [self createChannel];
    MLNSampleBlock *block1, *block2;
    MLNSampleBlockFile *fileBlock;
    
    block1 = [channel firstBlock];
    
    block2 = MLNSampleBlockCopy(block1, 0, 22049);
    
    STAssertFalse(block2 == NULL, @"block2 == NULL");
    
    fileBlock = (MLNSampleBlockFile *)block2;
    STAssertEquals(block2->startFrame, (NSUInteger)0, @"block2->startFrame != 0: Got %lu", block2->startFrame);
    STAssertEquals(block2->numberOfFrames, (NSUInteger)22050, @"block2->numberOfFrames != 22050: Got %lu", block2->numberOfFrames);
    STAssertEquals(fileBlock->sampleByteLength, (ssize_t)22050 * sizeof(float), @"block2->sampleByteLength != %lu: Got %lu",
                   22050 * sizeof(float), fileBlock->sampleByteLength);
    
    for (int i = 0; i < 22050; i++) {
        float value = MLNSampleBlockDataAtFrame(block2, i);
        STAssertEquals(value, (float)i, @"block2->data[%lu] != %f: %f", i, (float)i, value);
    }
}

- (void)testCopyMiddle
{
    NSUInteger startFrame, endFrame, numberOfFrames;
    
    MLNSampleChannel *channel = [self createChannel];
    MLNSampleBlock *block1, *block2;
    MLNSampleBlockFile *fileBlock;
    
    block1 = [channel firstBlock];
    
    startFrame = rand();
    endFrame = startFrame + (rand() % (block1->numberOfFrames - startFrame));
    numberOfFrames = (endFrame - startFrame) + 1;
    
    block2 = MLNSampleBlockCopy(block1, startFrame, endFrame);
    
    STAssertFalse(block2 == NULL, @"block2 == NULL");
    
    fileBlock = (MLNSampleBlockFile *)block2;
    
    STAssertEquals(block2->startFrame, startFrame, @"block2->startFrame != %lu: Got %lu", startFrame, block2->startFrame);
    STAssertEquals(block2->numberOfFrames, numberOfFrames, @"block2->numberOfFrames != %lu: Got %lu", numberOfFrames, block2->numberOfFrames);
    STAssertEquals(fileBlock->sampleByteLength, (ssize_t)numberOfFrames * sizeof(float), @"block2->sampleByteLength != %lu: Got %lu",
                   numberOfFrames * sizeof(float), fileBlock->sampleByteLength);
    
    for (int i = 0; i < numberOfFrames; i++) {
        float value = MLNSampleBlockDataAtFrame(block2, i);
        STAssertEquals(value, (float)i + startFrame, @"block2->data[%lu] != %f: %f", i, (float)i + startFrame, value);
    }
}

- (void)testCopyStart
{
    MLNSampleChannel *channel = [self createChannel];
    MLNSampleBlock *block1, *block2;
    MLNSampleBlockFile *fileBlock;
    
    block1 = [channel firstBlock];
    
    block2 = MLNSampleBlockCopy(block1, 0, MLNSampleBlockLastFrame(block1));
    
    STAssertFalse(block2 == NULL, @"block2 == NULL");
    
    fileBlock = (MLNSampleBlockFile *)block1;
    STAssertEquals(block1->startFrame, (NSUInteger)0, @"block1->startFrame != 0: Got %lu", block1->startFrame);
    STAssertEquals(block1->numberOfFrames, (NSUInteger)44100, @"block1->numberOfFrames != 44100: Got %lu", block1->numberOfFrames);
    STAssertEquals(fileBlock->sampleByteLength, (ssize_t)44100 * sizeof(float), @"block1->sampleByteLength != %lu: Got %lu",
                   44100 * sizeof(float), fileBlock->sampleByteLength);
    
    for (int i = 0; i < 44100; i++) {
        float value = MLNSampleBlockDataAtFrame(block1, i);
        STAssertEquals(value, (float)i, @"block1->data[%d] != %f: %f", i, (float)i, value);
    }
    
    fileBlock = (MLNSampleBlockFile *)block2;
    STAssertEquals(block2->startFrame, (NSUInteger)0, @"block2->startFrame != 22050: Got %lu", block2->startFrame);
    STAssertEquals(block2->numberOfFrames, (NSUInteger)44100, @"block2->numberOfFrames != 22050: Got %lu", block2->numberOfFrames);
    STAssertEquals(fileBlock->sampleByteLength, (ssize_t)44100 * sizeof(float), @"block2->sampleByteLength != %lu: Got %lu",
                   44100 * sizeof(float), fileBlock->sampleByteLength);
    
    for (int i = 0; i < 44100; i++) {
        float value = MLNSampleBlockDataAtFrame(block2, i);
        STAssertEquals(value, (float)i, @"block1->data[%d] != %f: %f", i, (float)i, value);
    }

    // Do not need to free block1 as it is owned by the channel
    MLNSampleBlockFree(block2);
}

- (void)testCopyInvalidFrame
{
    MLNSampleBlock *block1, *block2;
    
    block1 = MLNSampleBlockFileCreateBlock(NULL, 44100 * sizeof(float), 0, NULL, (44100 / 256) * sizeof(MLNSampleCachePoint), 0);
    block2 = MLNSampleBlockCopy(block1, 876235, MLNSampleBlockLastFrame(block1));
    
    STAssertTrue(block2 == NULL, @"block2 != NULL");
    
    MLNSampleBlockFree(block1);
}

- (void)testCopyBlockList
{
    MLNSampleChannel *channel = [self createChannel];
    MLNSampleBlock *blockList = [channel firstBlock];
    MLNSampleBlock *copyList;
    MLNSampleBlock *block, *copyBlock;
    
    for (NSUInteger split = 34100; split > 4100; split -= 10000) {
        MLNSampleBlockSplitBlockAtFrame(blockList, split, NULL, NULL);
    }
    
    copyList = MLNSampleBlockListCopy(blockList);
    
    NSUInteger blockCount = 0, copyCount = 0;
    block = blockList;
    while (block) {
        block = block->nextBlock;
        blockCount++;
    }
    
    copyBlock = copyList;
    while (copyBlock) {
        copyBlock = copyBlock->nextBlock;
        copyCount++;
    }
    
    STAssertEquals(blockCount, copyCount, @"blockCount != copyCount: %lu != %lu", blockCount, copyCount);

    block = blockList;
    copyBlock = copyList;
    
    // Check all the blocks are equal
    while (block && copyBlock) {
        STAssertEquals(block->startFrame, copyBlock->startFrame, @"block->startFrame != copyBlock->startFrame: %lu != %lu", block->startFrame, copyBlock->startFrame);
        STAssertEquals(block->numberOfFrames, copyBlock->numberOfFrames, @"block->numberOfFrames != copyBlock->numberOfFrames: %lu != %lu", block->numberOfFrames, copyBlock->numberOfFrames);
        
        NSUInteger k;
        
        for (k = 0; k < block->numberOfFrames; k++) {
            float value, copyValue;
            
            value = MLNSampleBlockDataAtFrame(block, k);
            copyValue = MLNSampleBlockDataAtFrame(copyBlock, k);
            
            STAssertEquals(value, copyValue, @"data[%lu] != copyData[%lu]: %f != %f", k, k, value, copyValue);
        }
        block = block->nextBlock;
        copyBlock = copyBlock->nextBlock;
    }
}
@end
