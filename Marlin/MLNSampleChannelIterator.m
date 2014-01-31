//
//  MLNSampleChannelIterator.m
//  Marlin
//
//  Created by iain on 26/12/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNSampleChannelIterator.h"
#import "MLNSampleChannel.h"

struct MLNSampleChannelCIterator {
    NSUInteger framePosition;
    NSUInteger cachePointPosition;
    MLNSampleBlock *currentBlock;
    BOOL isRaw;
};

@implementation MLNSampleChannelIterator {
    MLNSampleChannelCIterator *_cIter;
}

MLNSampleChannelCIterator *MLNSampleChannelIteratorNew(MLNSampleChannel *channel,
                                                       NSUInteger frame,
                                                       BOOL isRaw)
{
    MLNSampleChannelCIterator *cIter = malloc(sizeof(MLNSampleChannelCIterator));
    cIter->currentBlock = [channel sampleBlockForFrame:frame];
    cIter->framePosition = (frame - cIter->currentBlock->startFrame);
    cIter->cachePointPosition = (cIter->framePosition / MLNSampleChannelFramesPerCachePoint());
    cIter->isRaw = isRaw;
    
    return cIter;
}

void MLNSampleChannelIteratorFree(MLNSampleChannelCIterator *cIter)
{
    free (cIter);
}

- (id)initWithChannel:(MLNSampleChannel *)channel
              atFrame:(NSUInteger)frame
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _cIter = MLNSampleChannelIteratorNew(channel, frame, NO);
    return self;
}

- (id)initRawIteratorWithChannel:(MLNSampleChannel *)channel
                         atFrame:(NSUInteger)frame
{
    self = [self initWithChannel:channel atFrame:frame];
    if (!self) {
        return nil;
    }
    
    _cIter->isRaw = YES;
    
    return self;
}

- (void)dealloc
{
    MLNSampleChannelIteratorFree(_cIter);
}

void MLNSampleChannelIteratorResetToFrame(MLNSampleChannelCIterator *cIter,
                                          MLNSampleChannel *channel,
                                          NSUInteger frame)
{
    cIter->currentBlock = [channel sampleBlockForFrame:frame];
    cIter->framePosition = (frame - cIter->currentBlock->startFrame);
    cIter->cachePointPosition = (cIter->framePosition / MLNSampleChannelFramesPerCachePoint());
}

- (void)resetToFrame:(NSUInteger)frame
           inChannel:(MLNSampleChannel *)channel
{
    MLNSampleChannelIteratorResetToFrame(_cIter, channel, frame);
}

BOOL MLNSampleChannelIteratorHasMoreData(MLNSampleChannelCIterator *iter)
{
    return (iter->currentBlock != NULL);
}

BOOL MLNSampleChannelIteratorNextFrameData(MLNSampleChannelCIterator *iter,
                                           float *value)
{
    if (iter->currentBlock == NULL) {
        DDLogCError(@"Requesting frame from dead iterator");
        *value = 0.0;
        return NO;
    }
    
    *value = MLNSampleBlockDataAtFrame(iter->currentBlock, iter->framePosition);
    
    iter->framePosition++;
    iter->cachePointPosition = iter->framePosition / MLNSampleChannelFramesPerCachePoint();
    
    if (iter->framePosition >= iter->currentBlock->numberOfFrames) {
        iter->currentBlock = iter->currentBlock->nextBlock;
        iter->framePosition = 0;
        iter->cachePointPosition = 0;
    }
    
    if (iter->currentBlock) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)nextFrameData:(float *)value
{
    return MLNSampleChannelIteratorNextFrameData(_cIter, value);
}

BOOL MLNSampleChannelIteratorPreviousFrameData(MLNSampleChannelCIterator *iter,
                                               float *value)
{
    if (iter->currentBlock == NULL) {
        DDLogCError(@"Requesting frame from dead iterator");
        *value = 0.0;
        return NO;
    }
    
    *value = MLNSampleBlockDataAtFrame(iter->currentBlock, iter->framePosition);
    
    if (iter->framePosition == 0) {
        iter->currentBlock = iter->currentBlock->previousBlock;
        
        if (iter->currentBlock == NULL) {
            return NO;
        }
        iter->framePosition = iter->currentBlock->numberOfFrames;
    } else {
        iter->framePosition--;
    }
    
    iter->cachePointPosition = iter->framePosition / MLNSampleChannelFramesPerCachePoint();
    
    if (iter->currentBlock) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)previousFrameData:(float *)value
{
    return MLNSampleChannelIteratorPreviousFrameData(_cIter, value);
}

BOOL MLNSampleChannelIteratorNextCachePointData(MLNSampleChannelCIterator *iter,
                                                MLNSampleCachePoint *cachePoint)
{
    if (iter->currentBlock == NULL) {
        DDLogCError(@"Requesting cachepoint from dead iterator");
        cachePoint->avgMaxValue = 0.0;
        cachePoint->avgMinValue = 0.0;
        cachePoint->maxValue = 0.0;
        cachePoint->minValue = 0.0;
        
        return NO;
    }
    
    MLNSampleCachePoint cp;
    MLNSampleBlockCachePointAtFrame(iter->currentBlock, &cp, iter->cachePointPosition);
    
    cachePoint->minValue = cp.minValue;
    cachePoint->maxValue = cp.maxValue;
    cachePoint->avgMinValue = cp.avgMinValue;
    cachePoint->avgMaxValue = cp.avgMaxValue;
    
    iter->cachePointPosition++;
    iter->framePosition = iter->cachePointPosition * MLNSampleChannelFramesPerCachePoint();
    
    if (iter->framePosition >= iter->currentBlock->numberOfFrames) {
        iter->currentBlock = iter->currentBlock->nextBlock;
        iter->framePosition = 0;
        iter->cachePointPosition = 0;
    }
    
    if (iter->currentBlock) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)nextCachePointData:(MLNSampleCachePoint *)cachePoint
{
    return MLNSampleChannelIteratorNextCachePointData(_cIter, cachePoint);
}

- (NSUInteger)fillBufferWithData:(float *)buffer
                   ofFrameLength:(NSUInteger)frameLength
{
    NSUInteger framesAdded = 0;
    NSUInteger framesToAdd = frameLength;
    BOOL moreData = MLNSampleChannelIteratorHasMoreData(_cIter);
    
    while (framesToAdd && moreData) {
        float value;
        
        // FIXME: We could speed this up with a memcpy when the current block is a pure block
        moreData = MLNSampleChannelIteratorNextFrameData(_cIter, &value);
        buffer[framesAdded] = value;
        framesAdded++;
        framesToAdd--;
    }
    
    return framesAdded;
}

NSUInteger MLNSampleChannelIteratorGetPosition(MLNSampleChannelCIterator *cIter)
{
    return cIter->framePosition + cIter->currentBlock->startFrame;
}

void MLNSampleChannelIteratorPeekFrame(MLNSampleChannelCIterator *cIter, float *frame)
{
    *frame = MLNSampleBlockDataAtFrame(cIter->currentBlock, cIter->framePosition);
}

- (float)peekFrame
{
    float frame;
    
    MLNSampleChannelIteratorPeekFrame(_cIter, &frame);
    return frame;
}

BOOL MLNSampleChannelIteratorPeekNextFrame(MLNSampleChannelCIterator *cIter, float *frame)
{
    if (cIter->framePosition < (cIter->currentBlock->numberOfFrames - 2)) {
        *frame = MLNSampleBlockDataAtFrame(cIter->currentBlock, cIter->framePosition + 1);
        return YES;
    }
    
    MLNSampleBlock *nextBlock = cIter->currentBlock->nextBlock;
    if (nextBlock == NULL) {
        return NO;
    }
    
    *frame = MLNSampleBlockDataAtFrame(nextBlock, 0);
    return YES;
}

- (BOOL)peekNextFrame:(float *)frame
{
    return MLNSampleChannelIteratorPeekNextFrame(_cIter, frame);
}

BOOL MLNSampleChannelIteratorPeekPreviousFrame(MLNSampleChannelCIterator *cIter, float *frame)
{
    if (cIter->framePosition > 1) {
        *frame = MLNSampleBlockDataAtFrame(cIter->currentBlock, cIter->framePosition - 1);
        return YES;
    }
    
    MLNSampleBlock *previousBlock = cIter->currentBlock->previousBlock;
    if (previousBlock == NULL) {
        return NO;
    }
    
    *frame = MLNSampleBlockDataAtFrame(previousBlock, previousBlock->numberOfFrames - 1);
    return YES;
}

- (BOOL)peekPreviousFrame:(float *)frame
{
    return MLNSampleChannelIteratorPeekPreviousFrame(_cIter, frame);
}

BOOL MLNSampleChannelIteratorFindNextZeroCrossing(MLNSampleChannelCIterator *cIter,
                                                  NSUInteger *nextZeroCrossing)
{
    BOOL moreData;
    float prevValue, nextValue;
    
    MLNSampleChannelIteratorPeekFrame(cIter, &prevValue);
    while (moreData) {
        moreData = MLNSampleChannelIteratorNextFrameData(cIter, &nextValue);
        
        if (prevValue < 0 && nextValue >= 0) {
            *nextZeroCrossing = nextValue;
            return YES;
        }
        
        prevValue = nextValue;
    }
    
    return NO;
}

- (BOOL)findNextZeroCrossing:(NSUInteger *)nextZeroCrossing
{
    return MLNSampleChannelIteratorFindNextZeroCrossing(_cIter, nextZeroCrossing);
}


BOOL MLNSampleChannelIteratorFindPreviousZeroCrossing(MLNSampleChannelCIterator *cIter,
                                                      NSUInteger *previousZeroCrossing)
{
    BOOL moreData;
    float prevValue, nextValue;
    
    MLNSampleChannelIteratorPeekFrame(cIter, &nextValue);
    while (moreData) {
        moreData = MLNSampleChannelIteratorPreviousFrameData(cIter, &prevValue);
        
        if (prevValue <= 0 && nextValue > 0) {
            *previousZeroCrossing = prevValue;
            return YES;
        }
        
        nextValue = prevValue;
    }
    
    return NO;
}

- (BOOL)findPreviousZeroCrossing:(NSUInteger *)previousZeroCrossing
{
    return MLNSampleChannelIteratorFindPreviousZeroCrossing(_cIter, previousZeroCrossing);
}
@end
