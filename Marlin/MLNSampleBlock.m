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
    block->sampleByteLength = byteLength;
    block->byteOffset = offset;
    
    block->cacheRegion = cacheRegion;
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
    
    free(block);
}

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
MLNSampleBlockLastFrame(MLNSampleBlock *block)
{
    if (block == NULL) {
        // FIXME: Can I raise exceptions from C?
        //[NSException raise:@"MLNSampleBlockLastFrame" format:@"MLNSampleBlockLastFrame: block is NULL"];
        return 0;
    }
    return (block->startFrame + block->numberOfFrames) - 1;
}

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
}
