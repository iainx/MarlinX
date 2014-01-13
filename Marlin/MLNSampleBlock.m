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

void
MLNSampleBlockFree (MLNSampleBlock *block)
{
    if (block == NULL) {
        return;
    }

    block->methods->freeBlock(block);
}

#pragma mark - Data access
float
MLNSampleBlockDataAtFrame(MLNSampleBlock *block,
                          NSUInteger frame)
{
    if (block == NULL) {
        return 0.0;
    }
    
    return block->methods->dataAtFrame(block, frame);
}

void
MLNSampleBlockCachePointAtFrame(MLNSampleBlock *block,
                                MLNSampleCachePoint *cachePoint,
                                NSUInteger frame)
{
    if (block == NULL) {
        return;
    }
    
    block->methods->cachePointAtFrame(block, cachePoint, frame);
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

void
MLNSampleBlockSplitBlockAtFrame (MLNSampleBlock *block,
                                 NSUInteger splitFrame,
                                 MLNSampleBlock **firstBlock,
                                 MLNSampleBlock **secondBlock)
{
    if (block == NULL) {
        return;
    }
    
    block->methods->splitAtFrame (block, splitFrame, firstBlock, secondBlock);
}

MLNSampleBlock *
MLNSampleBlockCopy (MLNSampleBlock *block,
                    NSUInteger startFrame,
                    NSUInteger endFrame)
{
    if (block == NULL) {
        return NULL;
    }
    
    return block->methods->copyBlock (block, startFrame, endFrame);
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
    
    block = first;

    while (block != last && block) {
        nextBlock = block->nextBlock;
        
        block->nextBlock = block->previousBlock;
        block->previousBlock = nextBlock;

        block->reversed = !block->reversed;
        
        block = nextBlock;
    }
    
    NSCAssert(block != NULL, @"");
    
    nextBlock = block->nextBlock;
    block->nextBlock = block->previousBlock;
    block->previousBlock = nextBlock;
    
    block->reversed = !block->reversed;
}

void
MLNSampleBlockListFree(MLNSampleBlock *blockList)
{
    MLNSampleBlock *block;

    block = blockList;
    
    while (block) {
        MLNSampleBlock *nextBlock = block->nextBlock;
        MLNSampleBlockFree(block);
        block = nextBlock;
    }
}

#pragma mark - Debugging
void
MLNSampleBlockDumpBlock (MLNSampleBlock *block)
{
    if (block == NULL) {
        return;
    }
    
    DDLogCInfo(@"[%p] - [%p] - [%p]", block->previousBlock, block, block->nextBlock);
    //DDLogCInfo(@"   Region: %p - (offset: %llu)", block->region, block->byteOffset);
    DDLogCInfo(@"   Direction: %@", block->reversed ? @"Reversed":@"Normal");
    //DDLogCInfo(@"   %lu bytes", block->sampleByteLength);
    //DDLogCInfo(@"   %lu cache", block->cacheByteLength);
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
