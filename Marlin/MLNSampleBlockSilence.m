//
//  MLNSampleBlockSilence.m
//  Marlin
//
//  Created by iain on 08/02/2014.
//  Copyright (c) 2014 iain. All rights reserved.
//

#import "MLNSampleBlockSilence.h"

static void MLNSampleBlockSilenceFree (MLNSampleBlock *block);
static MLNSampleBlock *MLNSampleBlockSilenceCopy (MLNSampleBlock *block,
                                                  NSUInteger startFrame,
                                                  NSUInteger endFrame);
static void MLNSampleBlockSilenceSplitBlockAtFrame (MLNSampleBlock *block,
                                                    NSUInteger splitFrame,
                                                    MLNSampleBlock **firstBlock,
                                                    MLNSampleBlock **secondBlock);
static float MLNSampleBlockSilenceDataAtFrame(MLNSampleBlock *block,
                                              NSUInteger frame);
static void MLNSampleBlockSilenceCachePointAtFrame(MLNSampleBlock *block,
                                                   MLNSampleCachePoint *cachePoint,
                                                   NSUInteger frame);

static MLNSampleBlockMethods methods = {
    MLNSampleBlockSilenceFree,
    MLNSampleBlockSilenceCopy,
    MLNSampleBlockSilenceSplitBlockAtFrame,
    MLNSampleBlockSilenceDataAtFrame,
    MLNSampleBlockSilenceCachePointAtFrame,
};

MLNSampleBlock *
MLNSampleBlockSilenceCreateBlock(NSUInteger numberOfFrames)
{
    MLNSampleBlockSilence *block = malloc(sizeof(MLNSampleBlockSilence));
    
    block->parentBlock.methods = &methods;
    block->parentBlock.numberOfFrames = numberOfFrames;
    block->parentBlock.startFrame = 0;
    
    block->parentBlock.nextBlock = NULL;
    block->parentBlock.previousBlock = NULL;
    
    block->parentBlock.reversed = NO;
    
    return (MLNSampleBlock *)block;
}

static void MLNSampleBlockSilenceFree (MLNSampleBlock *block)
{
    free(block);
}

static MLNSampleBlock *MLNSampleBlockSilenceCopy (MLNSampleBlock *block,
                                                  NSUInteger startFrame,
                                                  NSUInteger endFrame)
{
    NSUInteger numberOfFrames = (endFrame - startFrame) + 1;
    return MLNSampleBlockSilenceCreateBlock(numberOfFrames);
}

static void MLNSampleBlockSilenceSplitBlockAtFrame (MLNSampleBlock *block,
                                                    NSUInteger splitFrame,
                                                    MLNSampleBlock **firstBlock,
                                                    MLNSampleBlock **secondBlock)
{
    NSUInteger framesInBlock, framesInOther;
    MLNSampleBlock *newBlock;
    
    framesInBlock = splitFrame - block->startFrame;
    framesInOther = block->numberOfFrames - splitFrame;
    
    block->numberOfFrames = framesInBlock;
    
    newBlock = MLNSampleBlockSilenceCreateBlock(framesInOther);
    newBlock->startFrame = splitFrame;
    
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
}

static float MLNSampleBlockSilenceDataAtFrame(MLNSampleBlock *block,
                                              NSUInteger frame)
{
    return 0.0;
}

static void MLNSampleBlockSilenceCachePointAtFrame(MLNSampleBlock *block,
                                                   MLNSampleCachePoint *cachePoint,
                                                   NSUInteger frame)
{
    cachePoint->minValue = 0.0;
    cachePoint->maxValue = 0.0;
    cachePoint->avgMinValue = 0.0;
    cachePoint->avgMaxValue = 0.0;
}