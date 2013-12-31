//
//  MLNSampleChannelIterator.h
//  Marlin
//
//  Created by iain on 26/12/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLNSampleBlock.h"

@class MLNSampleChannel;

typedef struct MLNSampleChannelCIterator MLNSampleChannelCIterator;

@interface MLNSampleChannelIterator : NSObject
- (id)initWithChannel:(MLNSampleChannel *)channel atFrame:(NSUInteger)frame;
- (id)initRawIteratorWithChannel:(MLNSampleChannel *)channel
                         atFrame:(NSUInteger)frame;

- (BOOL)nextFrameData:(float *)value;
- (BOOL)nextCachePointData:(MLNSampleCachePoint *)cachePoint;
- (NSUInteger)fillBufferWithData:(float *)buffer ofFrameLength:(NSUInteger)frameLength;

// C API
MLNSampleChannelCIterator *MLNSampleChannelIteratorNew(MLNSampleChannel *channel,
                                                       NSUInteger frame,
                                                       BOOL isRaw);
void MLNSampleChannelIteratorFree(MLNSampleChannelCIterator *cIter);
BOOL MLNSampleChannelIteratorHasMoreData(MLNSampleChannelCIterator *iter);
BOOL MLNSampleChannelIteratorNextCachePointData(MLNSampleChannelCIterator *iter,
                                                MLNSampleCachePoint *cachePoint);
BOOL MLNSampleChannelIteratorNextFrameData(MLNSampleChannelCIterator *iter,
                                           float *value);
@end
