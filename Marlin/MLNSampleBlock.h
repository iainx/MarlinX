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

typedef struct _MLNSampleBlock {
    struct _MLNSampleBlock *nextBlock;
    struct _MLNSampleBlock *previousBlock;

    size_t sampleByteLength;
    size_t cacheByteLength;
    
    NSUInteger numberOfFrames;
    NSUInteger startFrame;
    
    MLNMapRegion *region;
    off_t byteOffset; // Byte offset into [_region dataRegion]
    
    MLNMapRegion *cacheRegion;
    off_t cacheByteOffset;
} MLNSampleBlock;

#define FRAME_IN_BLOCK(b, f) (((f) >= (b)->startFrame) && ((f) < (b)->startFrame + (b)->numberOfFrames))

MLNSampleBlock *MLNSampleBlockCreateBlock(MLNMapRegion *region,
                                          size_t byteLength,
                                          off_t offset,
                                          MLNMapRegion *cacheRegion,
                                          size_t cacheByteLength,
                                          off_t cacheByteOffset);
void MLNSampleBlockFree (MLNSampleBlock *block);

const float *MLNSampleBlockSampleData (MLNSampleBlock *block);
const MLNSampleCachePoint *MLNSampleBlockSampleCacheData (MLNSampleBlock *block);

MLNSampleBlock *MLNSampleBlockSplitBlockAtFrame(MLNSampleBlock *block,
                                                NSUInteger splitFrame);
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
void MLNSampleBlockDumpBlock (MLNSampleBlock *block);
void MLNSampleBlockListDump (MLNSampleBlock *block);

#endif
