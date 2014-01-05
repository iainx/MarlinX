//
//  MLNSampleBlock.h
//  Marlin
//
//  Created by iain on 02/02/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLNMMapRegion.h"

#ifndef __MLNSAMPLEBLOCK_H
#define __MLNSAMPLEBLOCK_H

typedef struct _MLNSampleCachePoint {
    float minValue;
    float maxValue;
    float avgMinValue;
    float avgMaxValue;
} MLNSampleCachePoint;

typedef struct _MLNSampleBlockMethods MLNSampleBlockMethods;

typedef struct _MLNSampleBlock {
    struct _MLNSampleBlock *nextBlock;
    struct _MLNSampleBlock *previousBlock;

    MLNSampleBlockMethods *methods;
    
    NSUInteger numberOfFrames;
    NSUInteger startFrame;

    BOOL reversed;
} MLNSampleBlock;

typedef void (*MLNSampleBlockFreeFunction)(MLNSampleBlock *block);
typedef MLNSampleBlock *(*MLNSampleBlockCopyFunction)(MLNSampleBlock *block,
                                                      NSUInteger startFrame,
                                                      NSUInteger endFrame);
typedef void (*MLNSampleBlockSplitBlockAtFrameFunction)(MLNSampleBlock *block,
                                                        NSUInteger splitFrame,
                                                        MLNSampleBlock **firstBlock,
                                                        MLNSampleBlock **secondBlock);
typedef float (*MLNSampleBlockDataAtFrameFunction)(MLNSampleBlock *block, NSUInteger frame);
typedef void (*MLNSampleBlockCachePointAtFrameFunction)(MLNSampleBlock *block, MLNSampleCachePoint *cachePoint, NSUInteger frame);

struct _MLNSampleBlockMethods {
    MLNSampleBlockFreeFunction freeBlock;
    MLNSampleBlockCopyFunction copyBlock;
    MLNSampleBlockSplitBlockAtFrameFunction splitAtFrame;
    
    MLNSampleBlockDataAtFrameFunction dataAtFrame;
    MLNSampleBlockCachePointAtFrameFunction cachePointAtFrame;
};

#define FRAME_IN_BLOCK(b, f) (((f) >= (b)->startFrame) && ((f) < (b)->startFrame + (b)->numberOfFrames))

void MLNSampleBlockFree (MLNSampleBlock *block);

float MLNSampleBlockDataAtFrame(MLNSampleBlock *block,
                                NSUInteger frame);
void MLNSampleBlockCachePointAtFrame(MLNSampleBlock *block,
                                     MLNSampleCachePoint *cachePoint,
                                     NSUInteger frame);

void MLNSampleBlockSplitBlockAtFrame(MLNSampleBlock *block,
                                     NSUInteger splitFrame,
                                     MLNSampleBlock **firstBlock,
                                     MLNSampleBlock **secondBlock);
MLNSampleBlock *MLNSampleBlockCopy (MLNSampleBlock *block,
                                    NSUInteger startFrame,
                                    NSUInteger endFrame);
MLNSampleBlock *MLNSampleBlockListCopy(MLNSampleBlock *blockList);

void MLNSampleBlockAppendBlock (MLNSampleBlock *block,
                                MLNSampleBlock *otherBlock);
void MLNSampleBlockPrependBlock (MLNSampleBlock *block,
                                 MLNSampleBlock *otherBlock);
void MLNSampleBlockRemoveFromList (MLNSampleBlock *block);
void MLNSampleBlockRemoveBlocksFromList (MLNSampleBlock *startBlock,
                                         MLNSampleBlock *endBlock);

NSUInteger MLNSampleBlockLastFrame(MLNSampleBlock *block);

MLNSampleBlock *MLNSampleBlockListLastBlock(MLNSampleBlock *blockList);
NSUInteger MLNSampleBlockListNumberOfFrames(MLNSampleBlock *blockList);

void MLNSampleBlockInsertList(MLNSampleBlock *block,
                              MLNSampleBlock *blockList);

void MLNSampleBlockListReverse(MLNSampleBlock *start, MLNSampleBlock *last);

void MLNSampleBlockDumpBlock (MLNSampleBlock *block);
void MLNSampleBlockListDump (MLNSampleBlock *block);

#endif
