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
    
    numberFramesInSelf = splitFrame - block->startFrame;
    numberFramesInOther = block->numberOfFrames - numberFramesInSelf;
    otherStart = block->startFrame + numberFramesInSelf;
    
    numberOfCachePoints = block->cacheByteLength / sizeof(MLNSampleCachePoint);
    
    // FIXME: Don't make this a magic number!
    numberOfCachePointsInSelf = numberFramesInSelf / 256;
    if (numberFramesInSelf % 256 != 0) {
        numberOfCachePointsInSelf++;
    }
    
    numberOfCachePointsInOther = numberOfCachePoints - numberOfCachePointsInSelf;
    
    if (splitFrame == block->startFrame) {
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
    
    block->numberOfFrames = numberFramesInSelf;
    block->sampleByteLength = block->numberOfFrames * sizeof(float);
    block->cacheByteLength = numberOfCachePointsInSelf * sizeof(MLNSampleCachePoint);
    
    MLNSampleBlockAppendBlock(block, newBlock);
    
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

#pragma mark - Debugging
void
MLNSampleBlockDumpBlock (MLNSampleBlock *block)
{
    if (block == NULL) {
        return;
    }
    
    DDLogCInfo(@"[%p] - [%p] - [%p]", block->previousBlock, block, block->nextBlock);
    DDLogCInfo(@"   Region: %p - (offset: %llu)", block->region, block->byteOffset);
    DDLogCInfo(@"   %lu bytes", block->sampleByteLength);
    DDLogCInfo(@"   %lu cache", block->cacheByteLength);
    DDLogCInfo(@"   %lu -> %lu", block->startFrame, MLNSampleBlockLastFrame(block));
}
