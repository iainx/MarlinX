//
//  MLNSampleBlockFile.m
//  Marlin
//
//  Created by iain on 03/01/2014.
//  Copyright (c) 2014 iain. All rights reserved.
//

#import "MLNSampleBlockFile.h"
#import "MLNSampleChannel.h"

static void MLNSampleBlockFileFree (MLNSampleBlock *block);
static MLNSampleBlock *MLNSampleBlockFileCopy (MLNSampleBlock *block,
                                               NSUInteger startFrame,
                                               NSUInteger endFrame);
static void MLNSampleBlockFileSplitBlockAtFrame (MLNSampleBlock *block,
                                                 NSUInteger splitFrame,
                                                 MLNSampleBlock **firstBlock,
                                                 MLNSampleBlock **secondBlock);
static float MLNSampleBlockFileDataAtFrame(MLNSampleBlock *block,
                                           NSUInteger frame);
static void MLNSampleBlockFileCachePointAtFrame(MLNSampleBlock *block,
                                                MLNSampleCachePoint *cachePoint,
                                                NSUInteger frame);

static MLNSampleBlockMethods methods = {
    MLNSampleBlockFileFree,
    MLNSampleBlockFileCopy,
    MLNSampleBlockFileSplitBlockAtFrame,
    MLNSampleBlockFileDataAtFrame,
    MLNSampleBlockFileCachePointAtFrame,
};

MLNSampleBlock *
MLNSampleBlockFileCreateBlock(MLNMapRegion *region,
                              size_t byteLength,
                              off_t offset,
                              MLNMapRegion *cacheRegion,
                              size_t cacheByteLength,
                              off_t cacheByteOffset)
{
    MLNSampleBlockFile *block = malloc(sizeof(MLNSampleBlockFile));
    
    block->parentBlock.methods = &methods;
    
    block->region = region;
    MLNMapRegionRetain(region);
    
    block->sampleByteLength = byteLength;
    block->byteOffset = offset;
    
    block->cacheRegion = cacheRegion;
    MLNMapRegionRetain(cacheRegion);
    
    block->cacheByteLength = cacheByteLength;
    block->cacheByteOffset = cacheByteOffset;
    
    block->parentBlock.numberOfFrames = byteLength / sizeof (float);
    block->parentBlock.startFrame = 0;
    
    block->parentBlock.nextBlock = NULL;
    block->parentBlock.previousBlock = NULL;
    
    block->parentBlock.reversed = NO;
    
    return (MLNSampleBlock *)block;
}

static void
MLNSampleBlockFileFree (MLNSampleBlock *block)
{
    MLNSampleBlockFile *fileBlock = (MLNSampleBlockFile *)block;
    
    if (block == NULL) {
        return;
    }
    
    MLNMapRegionRelease(fileBlock->region);
    MLNMapRegionRelease(fileBlock->cacheRegion);
    
    free(block);
}

static MLNSampleBlock *
MLNSampleBlockFileCopy (MLNSampleBlock *block,
                        NSUInteger startFrame,
                        NSUInteger endFrame)
{
    MLNSampleBlockFile *copyBlock, *fileBlock;
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
    
    fileBlock = (MLNSampleBlockFile *)block;
    
    if (startFrame == block->startFrame && endFrame == MLNSampleBlockLastFrame(block)) {
        copyBlock = (MLNSampleBlockFile *)MLNSampleBlockFileCreateBlock(fileBlock->region, fileBlock->sampleByteLength, fileBlock->byteOffset,
                                                                        fileBlock->cacheRegion, fileBlock->cacheByteLength, fileBlock->cacheByteOffset);
        
        copyBlock->parentBlock.startFrame = startFrame;
        return (MLNSampleBlock *)copyBlock;
    }
    
    framesToCopy = (endFrame - startFrame) + 1;
    
    frameOffset = (startFrame - block->startFrame);
    copyOffset = fileBlock->byteOffset + (frameOffset * sizeof(float));    
    copyByteLength = framesToCopy * sizeof(float);
    
    copyNumberOfCachePoints = framesToCopy / 256;
    if (framesToCopy % 256 != 0) {
        copyNumberOfCachePoints++;
    }
    
    copyCacheOffset = (fileBlock->cacheByteLength - (copyNumberOfCachePoints * sizeof(MLNSampleCachePoint)));
    
    copyBlock = (MLNSampleBlockFile *)MLNSampleBlockFileCreateBlock(fileBlock->region, copyByteLength, copyOffset,
                                                                    fileBlock->cacheRegion,
                                                                    copyNumberOfCachePoints * sizeof(MLNSampleCachePoint),
                                                                    fileBlock->cacheByteOffset + copyCacheOffset);
    copyBlock->parentBlock.startFrame = startFrame;
    
    return (MLNSampleBlock *)copyBlock;
}

static void
MLNSampleBlockFileSplitBlockAtFrame (MLNSampleBlock *block,
                                     NSUInteger splitFrame,
                                     MLNSampleBlock **firstBlock,
                                     MLNSampleBlock **secondBlock)
{
    MLNSampleBlockFile *newBlock, *fileBlock;
    NSUInteger realSplitFrame;
    NSUInteger numberFramesInSelf;
    NSUInteger numberFramesInOther;
    NSUInteger otherStart;
    NSUInteger numberOfCachePoints;
    NSUInteger numberOfCachePointsInSelf;
    NSUInteger numberOfCachePointsInOther;
  
    if (block == NULL) {
        if (firstBlock) {
            *firstBlock = NULL;
        }
        
        if (secondBlock) {
            *secondBlock = NULL;
        }
        return;
    }
  
    if (!FRAME_IN_BLOCK(block, splitFrame)) {
        if (firstBlock) {
            *firstBlock = NULL;
        }
        
        if (secondBlock) {
            *secondBlock = NULL;
        }

        return;
    }
  
    fileBlock = (MLNSampleBlockFile *)block;
    
    if (block->reversed) {
        realSplitFrame = ((MLNSampleBlockLastFrame(block) + 1) - splitFrame) + block->startFrame;
    } else {
        realSplitFrame = splitFrame;
    }
  
    numberFramesInSelf = realSplitFrame - block->startFrame;
    numberFramesInOther = block->numberOfFrames - numberFramesInSelf;
    otherStart = block->startFrame + numberFramesInSelf;
  
    numberOfCachePoints = fileBlock->cacheByteLength / sizeof(MLNSampleCachePoint);
  
    numberOfCachePointsInSelf = numberFramesInSelf / MLNSampleChannelFramesPerCachePoint();
    if (numberFramesInSelf % MLNSampleChannelFramesPerCachePoint() != 0) {
        numberOfCachePointsInSelf++;
    }
  
    numberOfCachePointsInOther = numberOfCachePoints - numberOfCachePointsInSelf;
  
    if (realSplitFrame == block->startFrame) {
        if (firstBlock) {
            *firstBlock = block->previousBlock;
        }
        
        if (secondBlock) {
            *secondBlock = block;
        }
        return;
    }
  
    newBlock = (MLNSampleBlockFile *)MLNSampleBlockFileCreateBlock(fileBlock->region,
                                                                   numberFramesInOther * sizeof(float),
                                                                   fileBlock->byteOffset + numberFramesInSelf * sizeof(float),
                                                                   fileBlock->cacheRegion,
                                                                   numberOfCachePointsInOther * sizeof(MLNSampleCachePoint),
                                                                   fileBlock->cacheByteOffset + (numberOfCachePointsInSelf * sizeof(MLNSampleCachePoint)));
    newBlock->parentBlock.startFrame = otherStart;
    newBlock->parentBlock.reversed = block->reversed;
  
    block->numberOfFrames = numberFramesInSelf;
    fileBlock->sampleByteLength = block->numberOfFrames * sizeof(float);
    fileBlock->cacheByteLength = numberOfCachePointsInSelf * sizeof(MLNSampleCachePoint);
  
    if (block->reversed) {
        MLNSampleBlockPrependBlock(block, (MLNSampleBlock *)newBlock);
        
        if (firstBlock) {
            *firstBlock = (MLNSampleBlock *)newBlock;
        }
        
        if (secondBlock) {
            *secondBlock = block;
        }
    } else {
        MLNSampleBlockAppendBlock(block, (MLNSampleBlock *)newBlock);
        if (firstBlock) {
            *firstBlock = block;
        }
        
        if (secondBlock) {
            *secondBlock = (MLNSampleBlock *)newBlock;
        }
    }
  
    MLNSampleBlockDumpBlock((MLNSampleBlock *)newBlock);
}

static float
MLNSampleBlockFileDataAtFrame(MLNSampleBlock *block,
                              NSUInteger frame)
{
    MLNSampleBlockFile *fileBlock;
    float *data;
    
    if (block == NULL) {
        return 0.0;
    }
    
    fileBlock = (MLNSampleBlockFile *)block;
    
    data = (float *)(fileBlock->region->dataRegion + fileBlock->byteOffset);
    return data[frame];
}

static void
MLNSampleBlockFileCachePointAtFrame(MLNSampleBlock *block,
                                    MLNSampleCachePoint *cachePoint,
                                    NSUInteger frame)
{
    MLNSampleBlockFile *fileBlock;
    MLNSampleCachePoint *cachePointData, *cp;
    if (block == NULL) {
        return;
    }
    
    fileBlock = (MLNSampleBlockFile *)block;
    cachePointData = (MLNSampleCachePoint *)(fileBlock->cacheRegion->dataRegion + fileBlock->cacheByteOffset);
    cp = cachePointData + frame;
    cachePoint->avgMaxValue = cp->avgMaxValue;
    cachePoint->avgMinValue = cp->avgMinValue;
    cachePoint->maxValue = cp->maxValue;
    cachePoint->minValue = cp->minValue;
}