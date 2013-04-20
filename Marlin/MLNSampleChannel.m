//
//  MLNSampleChannel.m
//  Marlin
//
//  Created by iain on 06/02/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNApplicationDelegate.h"
#import "MLNSampleChannel.h"
#import "MLNSampleBlock.h"
#import "MLNMMapRegion.h"

@implementation MLNSampleChannel { 
    MLNCacheFile *_dataFd;
    MLNCacheFile *_cacheFd;
    BOOL _debugFinding;
}

- (id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    // _dataFd is the file that we write the channel's raw data to
    // _cacheFd is the file that we write the channel's cached data to.
    MLNApplicationDelegate *appDelegate = [NSApp delegate];
    _dataFd = [appDelegate createNewCacheFileWithExtension:@"data"];
    _cacheFd = [appDelegate createNewCacheFileWithExtension:@"cachedata"];
    
    return self;
}

- (void)dealloc
{
    MLNSampleBlock *block;
    
    block = _firstBlock;
    while (block) {
        MLNSampleBlock *oldBlock = block;
        
        block = block->nextBlock;
        MLNSampleBlockFree(oldBlock);
    }
    
    MLNApplicationDelegate *appDelegate = [NSApp delegate];
    [appDelegate removeCacheFile:_dataFd];
    [appDelegate removeCacheFile:_cacheFd];
}

#pragma mark - Cache generation

#define SAMPLES_PER_CACHE_POINT 256

+ (int)framesPerCachePoint
{
    return SAMPLES_PER_CACHE_POINT;
}

// We turn bytes into SampleCachePoints by taking every 256 (SAMPLES_PER_CACHE_POINT) samples
// minimaxing them, and collecting the average values above and below 0
- (MLNSampleCachePoint *)createCacheDataFromBytes:(float *)bytes
                                           length:(size_t)byteLength
                                      cacheLength:(size_t *)cacheByteLength
{
    NSUInteger sampleLength = (byteLength / sizeof(float));
    
    UInt32 numberOFCachePoints = ((UInt32)sampleLength / SAMPLES_PER_CACHE_POINT);
    if (sampleLength % SAMPLES_PER_CACHE_POINT != 0) {
        // There will be one cachepoint which doesn't represent the full number of samples.
        numberOFCachePoints++;
    }
    
    size_t dataSize = numberOFCachePoints * sizeof(MLNSampleCachePoint);
    MLNSampleCachePoint *cacheData = (MLNSampleCachePoint *)malloc(dataSize);
    
    if (cacheData == NULL) {
        // FIXME Should return error
        return NULL;
    }
    
    NSUInteger samplesRemaining = sampleLength;
    NSUInteger samplePositionInBuffer = 0;
    NSUInteger positionInCachePoint = 0;
    
    while (samplesRemaining) {
        float minValue = 0.0, maxValue = 0.0;
        float sumBelowZero = 0.0, sumAboveZero = 0.0;
        int aboveCount = 0, belowCount = 0;
        int i;
        
        // Gather at most SAMPLES_PER_CACHE_POINT samples
        // But don't exceed the number of samples in the buffer
        for (i = 0; i < SAMPLES_PER_CACHE_POINT && samplePositionInBuffer < sampleLength; i++) {
            float value = bytes[samplePositionInBuffer];
            
            minValue = MIN(minValue, value);
            maxValue = MAX(maxValue, value);
            if (value < 0.0) {
                sumBelowZero += value;
                belowCount++;
            } else {
                sumAboveZero += value;
                aboveCount++;
            }
            
            samplePositionInBuffer++;
            samplesRemaining--;
        }
        
        cacheData[positionInCachePoint].minValue = minValue;
        cacheData[positionInCachePoint].maxValue = maxValue;
        if (belowCount == 0) {
            cacheData[positionInCachePoint].avgMinValue = 0.0;
        } else {
            cacheData[positionInCachePoint].avgMinValue = sumBelowZero / belowCount;
        }
        
        if (aboveCount == 0) {
            cacheData[positionInCachePoint].avgMaxValue = 0.0;
        } else {
            cacheData[positionInCachePoint].avgMaxValue = sumAboveZero / aboveCount;
        }
        positionInCachePoint++;
    }
    
    *cacheByteLength = dataSize;
    return cacheData;
}

#pragma mark - Data operations

- (BOOL)addData:(float *)data
     withLength:(size_t)byteLength
{
    size_t cacheByteLength = 0;
    
    MLNSampleCachePoint *cacheData = [self createCacheDataFromBytes:data
                                                             length:byteLength
                                                        cacheLength:&cacheByteLength];
    
    // Create a region for the new data
    MLNMapRegion *region = MLNMapRegionCreateRegion(_dataFd, data, byteLength);
    MLNMapRegion *cacheRegion = MLNMapRegionCreateRegion(_cacheFd, cacheData, cacheByteLength);
    
    // Free cacheData because we're using an mmapped file for it now
    // FIXME: We could keep this around as a buffer so we don't fragment memory so much?
    free(cacheData);
    
    // Our new block is the whole of the new region we've created
    MLNSampleBlock *block = MLNSampleBlockCreateBlock(region, byteLength, 0,
                                                      cacheRegion, cacheByteLength, 0);
    [self addBlock:block];
    
    return YES;
}

#pragma mark - Block list manipulation

- (void)updateBlockCount
{
    MLNSampleBlock *block = _firstBlock;
    NSUInteger count = 0;
    NSUInteger blockCount = 0;
    
    while (block) {
        block->startFrame = count;
        count += block->numberOfFrames;
        
        block = block->nextBlock;
        blockCount++;
    }
    
    _numberOfFrames = count;
    _count = blockCount;
}

- (void)addBlock:(MLNSampleBlock *)block
{
    if (block == NULL) {
        return;
    }
    
    if (_firstBlock == NULL) {
        _firstBlock = block;
        _lastBlock = block;
        _count = 1;
        
        _numberOfFrames = block->numberOfFrames;
        block->startFrame = 0;
        return;
    }
    
    MLNSampleBlockAppendBlock(_lastBlock, block);
    _lastBlock = block;
    _count++;
    
    block->startFrame = _numberOfFrames;
    _numberOfFrames += block->numberOfFrames;
}

- (void)removeBlock:(MLNSampleBlock *)block
{
    if (_firstBlock == block && _lastBlock == block) {
        _firstBlock = nil;
        _lastBlock = nil;
        _count = 0;
        _numberOfFrames = 0;
        return;
    }
    
    if (_lastBlock == block) {
        _lastBlock = _lastBlock->previousBlock;
    }
    
    if (_firstBlock == block) {
        _firstBlock = block->nextBlock;
    }
    
    _numberOfFrames -= block->numberOfFrames;
    
    MLNSampleBlockRemoveFromList(block);
    _count--;
    
    // FIXME: We could optimise this to start from the block we've just moved
    [self updateBlockCount];
}

- (MLNSampleBlock *)sampleBlockForFrame:(NSUInteger)frame
{
    if (frame > _numberOfFrames - 1) {
        return nil;
    }
    
    MLNSampleBlock *block = _firstBlock;
    NSUInteger lastFrame = 0;
    while (block) {
        lastFrame += block->numberOfFrames;
        if (_debugFinding)
            DDLogVerbose(@"Checking %p: %lu for %lu", block, lastFrame, frame);

        if (frame <= lastFrame - 1) {
            if (_debugFinding)
                DDLogVerbose(@"Found in %p", block);
            return block;
        }
        
        block = block->nextBlock;
    }
    
    return nil;
}

#pragma mark - Sample manipulation

- (void)deleteRange:(NSRange)range
{
    NSUInteger lastFrame = NSMaxRange(range) - 1;
    MLNSampleBlock *firstBlock, *lastBlock;
    
    DDLogVerbose(@"Deleting from %lu -> %lu", range.location, lastFrame);
    
    // Find first block
    firstBlock = [self sampleBlockForFrame:range.location];
    if (firstBlock == nil) {
        [NSException raise:@"MLNSampleChannel" format:@"deleteRange has no first block"];
        return;
    }
    
    DDLogVerbose(@"   firstBlock: %p", firstBlock);
    
    // Split first & last blocks
    if (range.location != firstBlock->startFrame) {
        MLNSampleBlock *newBlock = MLNSampleBlockSplitBlockAtFrame(firstBlock, range.location);
        firstBlock = newBlock;
    }
    
    // Find last block
    lastBlock = [self sampleBlockForFrame:lastFrame];
    if (lastBlock == nil) {
        [NSException raise:@"MLNSampleChannel" format:@"deleteRange last frame out of range: %@", NSStringFromRange(range)];
        return;
    }
    
    DDLogVerbose(@"   lastBlock: %p", lastBlock);
    
    if (lastFrame != MLNSampleBlockLastFrame(lastBlock)) {
        // Split the last block on the next frame
        // Don't need to care about the next
        MLNSampleBlockSplitBlockAtFrame(lastBlock, NSMaxRange(range));
    }
    
    if (_firstBlock == firstBlock) {
        _firstBlock = lastBlock->nextBlock;
    }
    
    if (_lastBlock == lastBlock) {
        _lastBlock = firstBlock->previousBlock;
    }
    DDLogVerbose(@"Need to remove blocks from %p -> %p", firstBlock, lastBlock);
    MLNSampleBlockRemoveBlocksFromList(firstBlock, lastBlock);

    [self updateBlockCount];
    
    [self dumpChannel];
}

#pragma mark - Debugging

- (void)dumpChannel
{
    //int count = 0;
    DDLogInfo(@"[%p] - %@ - %lu: (%lu)", self, _channelName, _count, _numberOfFrames);

    /*
    MLNSampleBlock *b = _firstBlock;
    while (b) {
        DDLogInfo(@"Block number %d", count);
        count++;
        
        //[b dumpBlock];
        b = b->nextBlock;
    }
     */
}
@end
