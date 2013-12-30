//
//  MLNSampleBlock.m
//  Marlin
//
//  Created by iain on 02/02/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNSampleChannel.h"
#import "MLNSampleBlock.h"
#import "MLNMMapRegion.h"

#pragma mark - Lifetime

MLNSampleBlock *
MLNSampleBlockCreateBlock (MLNMapRegion *region,
                           size_t byteLength,
                           off_t offset,
                           MLNMapRegion *cacheRegion,
                           size_t cacheByteLength,
                           off_t cacheByteOffset)
{
    MLNSampleBlock *block;
    
    block = malloc(sizeof(MLNSampleBlock));
    
    block->region = region;
    MLNMapRegionRetain(region);
    
    block->sampleByteLength = byteLength;
    block->byteOffset = offset;
    
    block->cacheRegion = cacheRegion;
    MLNMapRegionRetain(cacheRegion);
    
    block->cacheByteLength = cacheByteLength;
    block->cacheByteOffset = cacheByteOffset;
    
    block->numberOfFrames = byteLength / sizeof (float);
    block->startFrame = 0;
    
    block->nextBlock = NULL;
    block->previousBlock = NULL;
    
    block->reversed = NO;
    
    return block;
}

void
MLNSampleBlockFree (MLNSampleBlock *block)
{
    if (block == NULL) {
        return;
    }

    MLNMapRegionRelease(block->region);
    MLNMapRegionRelease(block->cacheRegion);
    
    free(block);
}

#pragma mark - Data access
const float *
MLNSampleBlockSampleData (MLNSampleBlock *block)
{
    if (block == NULL) {
        return NULL;
    }
    
    return (block->region->dataRegion + block->byteOffset);
}

const MLNSampleCachePoint *
MLNSampleBlockSampleCacheData (MLNSampleBlock *block)
{
    if (block == NULL) {
        return NULL;
    }
    
    return (block->cacheRegion->dataRegion + block->cacheByteOffset);
}

MLNSampleBlock *
MLNSampleBlockListLastBlock(MLNSampleBlock *blockList)
{
    while (blockList) {
        NSCAssert(blockList->nextBlock != blockList, @"Internal consistency failed");
        
        if (blockList->nextBlock == NULL) {
            return blockList;
        }
        blockList = blockList->nextBlock;
    }
    
    // Shouldn't get here
    return NULL;
}

NSUInteger
MLNSampleBlockLastFrame(MLNSampleBlock *block)
{
    if (block == NULL) {
        // FIXME: Can I raise exceptions from C?
        //[NSException raise:@"MLNSampleBlockLastFrame" format:@"MLNSampleBlockLastFrame: block is NULL"];
        return 0;
    }
    return (block->startFrame + block->numberOfFrames) - 1;
}

/**
 * MLNSampleBlockSplitBlockAtFrame:
 *
 * Splits @block into block_a and block_b.
 * block_a: [block->startFrame --> splitFrame - 1]
 * block_b: [splitFrame --> block->startFrame + block->numberOfFrames]
 *
 * block is turned into block_a, and block_b is returned
 * Returns: NULL on invalid @splitframe, or @block if @splitframe == block->startFrame
 */
MLNSampleBlock *
MLNSampleBlockSplitBlockAtFrame (MLNSampleBlock *block,
                                 NSUInteger splitFrame)
{
    MLNSampleBlock *newBlock;
    NSUInteger realSplitFrame;
    NSUInteger numberFramesInSelf;
    NSUInteger numberFramesInOther;
    NSUInteger otherStart;
    NSUInteger numberOfCachePoints;
    NSUInteger numberOfCachePointsInSelf;
    NSUInteger numberOfCachePointsInOther;
    
    if (block == NULL) {
        return NULL;
    }
    
    if (!FRAME_IN_BLOCK(block, splitFrame)) {
        return NULL;
    }
    
    DDLogCVerbose(@"Splitting block at %lu", splitFrame);
    if (block->reversed) {
        realSplitFrame = ((MLNSampleBlockLastFrame(block) + 1) - splitFrame) + block->startFrame;
    } else {
        realSplitFrame = splitFrame;
    }
    DDLogCVerbose(@"Real split frame: %lu", realSplitFrame);
    MLNSampleBlockDumpBlock(block);
    
    numberFramesInSelf = realSplitFrame - block->startFrame;
    numberFramesInOther = block->numberOfFrames - numberFramesInSelf;
    otherStart = block->startFrame + numberFramesInSelf;
    
    DDLogCVerbose(@"Number frames in self: %lu", numberFramesInSelf);
    DDLogCVerbose(@"Number frames in new block: %lu", numberFramesInOther);
    DDLogCVerbose(@"Other start: %lu", otherStart);
    
    numberOfCachePoints = block->cacheByteLength / sizeof(MLNSampleCachePoint);
    
    DDLogCVerbose(@"Total cache points: %lu", numberOfCachePoints);
    
    numberOfCachePointsInSelf = numberFramesInSelf / MLNSampleChannelFramesPerCachePoint();
    if (numberFramesInSelf % MLNSampleChannelFramesPerCachePoint() != 0) {
        numberOfCachePointsInSelf++;
    }
    
    numberOfCachePointsInOther = numberOfCachePoints - numberOfCachePointsInSelf;
    
    DDLogCVerbose(@"number cache points in self: %lu", numberOfCachePointsInSelf);
    DDLogCVerbose(@"number cache points in other: %lu", numberOfCachePointsInOther);
    if (realSplitFrame == block->startFrame) {
        DDLogCVerbose(@"Split frame == _startFrame, returning self");
        
        // FIXME: Do blocks need to be ref-counted?
        return block;
    }
    
    newBlock = MLNSampleBlockCreateBlock(block->region,
                                         numberFramesInOther * sizeof(float),
                                         block->byteOffset + numberFramesInSelf * sizeof(float),
                                         block->cacheRegion,
                                         numberOfCachePointsInOther * sizeof(MLNSampleCachePoint),
                                         block->cacheByteOffset + (numberOfCachePointsInSelf * sizeof(MLNSampleCachePoint)));
    newBlock->startFrame = otherStart;
    newBlock->reversed = block->reversed;
    
    block->numberOfFrames = numberFramesInSelf;
    block->sampleByteLength = block->numberOfFrames * sizeof(float);
    block->cacheByteLength = numberOfCachePointsInSelf * sizeof(MLNSampleCachePoint);
    
    if (block->reversed) {
        MLNSampleBlockPrependBlock(block, newBlock);
    } else {
        MLNSampleBlockAppendBlock(block, newBlock);
    }
    
    MLNSampleBlockDumpBlock(newBlock);
    
    return newBlock;
}

MLNSampleBlock *
MLNSampleBlockCopy (MLNSampleBlock *block,
                    NSUInteger startFrame,
                    NSUInteger endFrame)
{
    MLNSampleBlock *copyBlock;
    size_t copyByteLength;
    off_t copyOffset;
    off_t copyCacheOffset;
    NSUInteger framesToCopy;
    NSUInteger frameOffset;
    NSUInteger copyNumberOfCachePoints;
    
    if (block == NULL) {
        return NULL;
    }
    
    if (!FRAME_IN_BLOCK(block, startFrame) || !FRAME_IN_BLOCK(block, endFrame)) {
        return NULL;
    }
    
    if (startFrame == block->startFrame && endFrame == MLNSampleBlockLastFrame(block)) {
        copyBlock = MLNSampleBlockCreateBlock(block->region, block->sampleByteLength, block->byteOffset,
                                              block->cacheRegion, block->cacheByteLength, block->cacheByteOffset);
        
        copyBlock->startFrame = startFrame;
        return copyBlock;
    }
    
    framesToCopy = (endFrame - startFrame) + 1;
    
    frameOffset = (startFrame - block->startFrame);
    copyOffset = block->byteOffset + (frameOffset * sizeof(float));
    //copyNumberOfFrames = (block->numberOfFrames - frameOffset);
    
    copyByteLength = framesToCopy * sizeof(float);
    
    copyNumberOfCachePoints = framesToCopy / 256;
    if (framesToCopy % 256 != 0) {
        copyNumberOfCachePoints++;
    }
    
    copyCacheOffset = (block->cacheByteLength - (copyNumberOfCachePoints * sizeof(MLNSampleCachePoint)));
    
    copyBlock = MLNSampleBlockCreateBlock(block->region, copyByteLength, copyOffset,
                                          block->cacheRegion,
                                          copyNumberOfCachePoints * sizeof(MLNSampleCachePoint),
                                          block->cacheByteOffset + copyCacheOffset);
    copyBlock->startFrame = startFrame;
    
    return copyBlock;
}

/**
 * MLNSampleBlockCopyList:
 *
 * Copies all the blocks in the list
 */
MLNSampleBlock *
MLNSampleBlockListCopy(MLNSampleBlock *blockList)
{
    MLNSampleBlock *copyList, *copyBlock, *previousBlock;
    
    copyBlock = MLNSampleBlockCopy(blockList, blockList->startFrame, MLNSampleBlockLastFrame(blockList));
    copyList = copyBlock;
    previousBlock = copyBlock;
    
    blockList = blockList->nextBlock;
    while (blockList) {
        NSCAssert(blockList->nextBlock != blockList, @"Internal consistency failed");
        
        copyBlock = MLNSampleBlockCopy(blockList, blockList->startFrame, MLNSampleBlockLastFrame(blockList));
        
        MLNSampleBlockAppendBlock(previousBlock, copyBlock);
        
        previousBlock = copyBlock;
        blockList = blockList->nextBlock;
    }
    
    return copyList;
}

#pragma mark - List operations
/**
 * MLNSampleBlockAppendBlock:
 *
 * Inserts @otherBlock between @block and @block->nextBlock
 */
// This is badly named: It should be insert
void
MLNSampleBlockAppendBlock (MLNSampleBlock *block,
                           MLNSampleBlock *otherBlock)
{
    MLNSampleBlock *nb;
    
    if (block == NULL) {
        return;
    }
    
    if (otherBlock == NULL) {
        return;
    }
    
    nb = block->nextBlock;
    
    block->nextBlock = otherBlock;
    
    if (nb) {
        nb->previousBlock = otherBlock;
    }
    
    otherBlock->nextBlock = nb;
    otherBlock->previousBlock = block;
}

/**
 * MLNSampleBlockPrependBlock:
 *
 * Inserts @otherBlock between @block and @block->previousBlock
 */
void
MLNSampleBlockPrependBlock (MLNSampleBlock *block,
                            MLNSampleBlock *otherBlock)
{
    MLNSampleBlock *pb;
    
    if (block == NULL) {
        return;
    }
    
    if (otherBlock == NULL) {
        return;
    }
    
    pb = block->previousBlock;
    
    block->previousBlock = otherBlock;
    
    if (pb) {
        pb->nextBlock = otherBlock;
    }
    
    otherBlock->nextBlock = block;
    otherBlock->previousBlock = pb;
}

/**
 * MLNSampleBlockRemoveFromList:
 *
 * Removes @block from the list, linking @block->previousBlock and @block->nextBlock
 */
void
MLNSampleBlockRemoveFromList (MLNSampleBlock *block)
{
    if (block == NULL) {
        return;
    }
    
    if (block->previousBlock) {
        block->previousBlock->nextBlock = block->nextBlock;
    }

    if (block->nextBlock) {
        block->nextBlock->previousBlock = block->previousBlock;
    }

    block->previousBlock = NULL;
    block->nextBlock = NULL;
}

/**
 * MLNSampleBlockRemoveBlocksFromList:
 *
 * Unlinks all the blocks between @startBlock and @endBlock from the list
 * in one operation
 */
void
MLNSampleBlockRemoveBlocksFromList (MLNSampleBlock *startBlock,
                                    MLNSampleBlock *endBlock)
{
    if (startBlock == NULL || endBlock == NULL) {
        return;
    }
    
    if (startBlock->previousBlock) {
        startBlock->previousBlock->nextBlock = endBlock->nextBlock;
    }
    
    if (endBlock->nextBlock) {
        endBlock->nextBlock->previousBlock = startBlock->previousBlock;
    }

    /* Decouple the blocks from the main list */
    startBlock->previousBlock = NULL;
    endBlock->nextBlock = NULL;
}

NSUInteger
MLNSampleBlockListNumberOfFrames (MLNSampleBlock *startBlock)
{
    NSUInteger count = startBlock->numberOfFrames;
    MLNSampleBlock *block;
    
    block = startBlock->nextBlock;
    while (block) {
        count += block->numberOfFrames;
        block = block->nextBlock;
    }
    
    return count;
}

/**
 * MLNSampleBlockInsertList:
 *
 * Inserts @blockList after @block
 */
void
MLNSampleBlockInsertList(MLNSampleBlock *block,
                         MLNSampleBlock *blockList)
{
    MLNSampleBlock *lastListBlock = MLNSampleBlockListLastBlock(blockList);
    MLNSampleBlock *nextBlock;
    
    nextBlock = block->nextBlock;
    if (nextBlock) {
        nextBlock->previousBlock = lastListBlock;
    }
    
    lastListBlock->nextBlock = nextBlock;
    
    block->nextBlock = blockList;
    blockList->previousBlock = block;
}

void
MLNSampleBlockListReverse(MLNSampleBlock *first,
                          MLNSampleBlock *last)
{
    MLNSampleBlock *block, *nextBlock;
    
    DDLogCVerbose(@"Reversing %p -> %p", first, last);
    block = first;

    while (block != last && block) {
        DDLogCVerbose(@"***Before***");
        MLNSampleBlockDumpBlock(block);
        
        nextBlock = block->nextBlock;
        
        block->nextBlock = block->previousBlock;
        block->previousBlock = nextBlock;

        block->reversed = !block->reversed;
        
        DDLogCVerbose(@"***After***");
        MLNSampleBlockDumpBlock(block);
        
        block = nextBlock;
    }
    
    DDLogCVerbose(@"***Before (final) ***");
    MLNSampleBlockDumpBlock(block);
    
    nextBlock = block->nextBlock;
    block->nextBlock = block->previousBlock;
    block->previousBlock = nextBlock;
    
    block->reversed = !block->reversed;
    
    DDLogCVerbose(@"***After (final) ***");
    MLNSampleBlockDumpBlock(block);
}

#pragma mark - Debugging
void
MLNSampleBlockDumpBlock (MLNSampleBlock *block)
{
    if (block == NULL) {
        return;
    }
    
    DDLogCInfo(@"[%p] - [%p] - [%p]", block->previousBlock, block, block->nextBlock);
    DDLogCInfo(@"   Region: %p - (offset: %llu)", block->region, block->byteOffset);
    DDLogCInfo(@"   Direction: %@", block->reversed ? @"Reversed":@"Normal");
    DDLogCInfo(@"   %lu bytes", block->sampleByteLength);
    DDLogCInfo(@"   %lu cache", block->cacheByteLength);
    DDLogCInfo(@"   %lu -> %lu", block->startFrame, MLNSampleBlockLastFrame(block));
}

void
MLNSampleBlockListDump (MLNSampleBlock *block)
{
    while (block) {
        MLNSampleBlockDumpBlock(block);
        block = block->nextBlock;
    }
}
