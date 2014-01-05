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
    
    if (iter->currentBlock->reversed && iter->isRaw == NO) {
        NSUInteger realFramePosition = iter->currentBlock->numberOfFrames - iter->framePosition;
        *value = MLNSampleBlockDataAtFrame(iter->currentBlock, realFramePosition);
    } else {
        *value = MLNSampleBlockDataAtFrame(iter->currentBlock, iter->framePosition);
    }
    
    iter->framePosition++;
    iter->cachePointPosition = iter->framePosition / MLNSampleChannelFramesPerCachePoint();
    
    if (iter->framePosition >= iter->currentBlock->numberOfFrames) {
        fprintf(stderr, "iter->framePosition: %lu -- numberOfFrames: %lu\n", iter->framePosition, iter->currentBlock->numberOfFrames);
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

BOOL MLNSampleChannelIteratorNextCachePointData(MLNSampleChannelCIterator *iter,
                                                MLNSampleCachePoint *cachePoint)
{
    //const MLNSampleCachePoint *cacheData;
    
    if (iter->currentBlock == NULL) {
        DDLogCError(@"Requesting cachepoint from dead iterator");
        cachePoint->avgMaxValue = 0.0;
        cachePoint->avgMinValue = 0.0;
        cachePoint->maxValue = 0.0;
        cachePoint->minValue = 0.0;
        
        return NO;
    }
    
    //cacheData = MLNSampleBlockSampleCacheData(iter->currentBlock);
    
    MLNSampleCachePoint cp;
    
    if (iter->currentBlock->reversed && iter->isRaw == NO) {
        // FIXME: I feel like this needs to be tested as whether it is correct
        NSUInteger realCachePointPosition = (iter->currentBlock->numberOfFrames / MLNSampleChannelFramesPerCachePoint()) - iter->cachePointPosition;
        //cp = cacheData[realCachePointPosition];
        MLNSampleBlockCachePointAtFrame(iter->currentBlock, &cp, realCachePointPosition);
    } else {
        //cp = cacheData[iter->cachePointPosition];
        MLNSampleBlockCachePointAtFrame(iter->currentBlock, &cp, iter->cachePointPosition);
    }
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
@end
