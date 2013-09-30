//
//  MLNSampleChannel.h
//  Marlin
//
//  Created by iain on 06/02/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLNSampleBlock.h"

@interface MLNSampleChannel : NSObject

@property (readwrite) MLNSampleBlock *firstBlock;
@property (readwrite) MLNSampleBlock *lastBlock;
@property (readwrite, copy) NSString *channelName;

@property (readonly) NSUInteger count; // Block count
@property (readonly) NSUInteger numberOfFrames;

+ (int)framesPerCachePoint;

- (id)initWithDataFile:(MLNCacheFile *)dataFile
             cacheFile:(MLNCacheFile *)cacheFile;

- (MLNSampleBlock *)sampleBlockForFrame:(NSUInteger)frame;

- (MLNSampleChannel *)copyChannelInRange:(NSRange)range;

- (BOOL)addData:(float *)data
     withLength:(size_t)byteLength;
- (size_t)fillBuffer:(float *)data
       withLength:(size_t)byteLength
        fromFrame:(NSUInteger)frame;

- (void)addBlock:(MLNSampleBlock *)block;
- (void)removeBlock:(MLNSampleBlock *)block;

- (MLNSampleBlock *)deleteRange:(NSRange)range;

- (BOOL)insertChannel:(MLNSampleChannel *)channel
              atFrame:(NSUInteger)frame;
- (void)insertBlockList:(MLNSampleBlock *)blockList
                atFrame:(NSUInteger)frame;

- (void)dumpChannel:(BOOL)withBlocks;
@end
