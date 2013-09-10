//
//  MLNSample+Drawing.m
//  Marlin
//
//  Created by iain on 08/03/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNSample+Drawing.h"
#import "MLNSampleChannel.h"
#import "MLNSampleBlock.h"

@implementation MLNSample (Drawing)

- (NSUInteger)fillPointArray:(MLNSampleCachePoint *)pointArray
                      length:(NSUInteger)length
                 fromChannel:(MLNSampleChannel *)channel
            atFramesPerPixel:(int)fpp
                  startFrame:(NSUInteger)startFrame
{
    int framesPerCachePoint = [MLNSampleChannel framesPerCachePoint];
    MLNSampleBlock *block = [channel sampleBlockForFrame:startFrame];
    int i = 0;
    
    if (block == NULL) {
        DDLogError(@"Block is NULL for %lu", startFrame);
        return 0;
    }
    
    // If fpp is < framesPerCachePoint then we need to use the raw data, rather than the precalculated cache data
    // FIXME: These should be able to be consolidated because they're essentially the same thing
    // just using different data sources
    if (fpp < framesPerCachePoint) {
        const float *data = MLNSampleBlockSampleData(block);
        int cachePointsPerPixel = fpp;
        int j;
        NSUInteger posInData;
        
        posInData = (startFrame - block->startFrame);
        
        while (block && i < length) {
            CGFloat maxPoint = 0, minPoint = 0;
            CGFloat totalPositive = 0, totalNegative = 0;
            
            for (j = 0; j < cachePointsPerPixel; j++) {
                float value;
                
                if (posInData * sizeof(float) >= block->sampleByteLength) {
                    block = block->nextBlock;
                    
                    if (block == NULL) {
                        break;
                    }
                    
                    data = MLNSampleBlockSampleData(block);
                    assert(data);
                    
                    posInData = 0;
                }
                
                value = data[posInData];
                maxPoint = MAX(maxPoint, value);
                minPoint = MIN(minPoint, value);
                if (value > 0) {
                    totalPositive += value;
                } else {
                    totalNegative += value;
                }
                
                posInData++;
            }
            
            pointArray[i].maxValue = maxPoint;
            pointArray[i].minValue = minPoint;
            pointArray[i].avgMaxValue = totalPositive / j;
            pointArray[i].avgMinValue = totalNegative / j;
            
            i++;
        }
    } else {
        const MLNSampleCachePoint *cacheData;
        int j;
        int cachePointsPerPixel;
        NSUInteger posInCache;
        
        cacheData = MLNSampleBlockSampleCacheData(block);
        
        posInCache = (startFrame - block->startFrame) / framesPerCachePoint;
        //DDLogVerbose(@"Position in cache: %lu", posInCache);
        cachePointsPerPixel = fpp / framesPerCachePoint;
        
        // Go through the blocks getting the required number of CGPoints to fill the array
        while (block && i < length) {
            CGFloat maxPoint = 0, minPoint = 0;
            CGFloat totalBelowZero = 0, totalAboveZero = 0;
            
            // Each point in cacheData represents framesPerCachePoint frames
            // so if we want more than framesPerCachePoint frames per pixels
            // then we need to resample. fpp must be a multiple of framesPerCachePoint
            // for this to work.
            for (j = 0; j < cachePointsPerPixel; j++) {
                
                // If there are no more frames in the block then we need to
                // get the next block.
                //NSLog(@"Pos in cache: %lu: %lu -> %lu", posInCache, posInCache * sizeof(MLNSampleCachePoint), [cache length]);
                if (posInCache * sizeof(MLNSampleCachePoint) >= block->cacheByteLength) {
                    block = block->nextBlock;
                    
                    // If there are no more blocks, then we've finished
                    // and cannot draw anymore.
                    if (block == nil) {
                        // No more blocks
                        break;
                    }
                    cacheData = MLNSampleBlockSampleCacheData(block);
                    assert(cacheData);
                    
                    // Reset the position in the cache
                    posInCache = 0;
                }
                
                maxPoint = MAX(maxPoint, cacheData[posInCache].maxValue);
                minPoint = MIN(minPoint, cacheData[posInCache].minValue);
                totalAboveZero += cacheData[posInCache].avgMaxValue;
                totalBelowZero += cacheData[posInCache].avgMinValue;
                
                posInCache++;
            }
            
            pointArray[i].maxValue = maxPoint;
            pointArray[i].minValue = minPoint;
            
            // j will be the number of values that we actually added to the total, rather than cachePointsPerPixel
            // which is the value we wanted to add to the total
            pointArray[i].avgMaxValue = totalAboveZero / j;
            pointArray[i].avgMinValue = totalBelowZero / j;
            
            i++;
        }
    }
    
    return i;
}

// Draw the waveform for @channelNumber into the context whose size is defined by @scaledBounds
- (void)drawWaveformInContext:(CGContextRef)context
                channelNumber:(NSUInteger)channelNumber
                         rect:(NSRect)scaledBounds
           withFramesPerPixel:(NSUInteger)framesPerPixel
{
    NSArray *channelData;
    MLNSampleCachePoint *pointArray;
    
    // Scale bounds as we may be working on a retina display
    // And CGContext works in pixels, but bounds is in points.
    
    // NSRect scaledBounds = [self convertRectToBacking:bounds];
    
    // Add one to the width because if x is not on pixel boundaries
    // then we need to draw one more pixel.
    // Consider drawing from 0.5 with width 3, we need to draw the 0, 1, 2, and 3 pixels
    // which is 4.
    int numberOfPoints = scaledBounds.size.width + 1;
    
    channelData = [self channelData];
    
    // We need bounds.size.width points to draw
    pointArray = malloc(numberOfPoints * sizeof(MLNSampleCachePoint));
    assert(pointArray);
 
    /*
    NSUInteger channelCount = [channelData count];
    CGFloat totalGutterSpacing = ((channelCount - 1) == 0 ? 1 : channelCount - 1) * gutterSpacing;
    CGFloat boundsHeight = (scaledBounds.size.height + scaledBounds.origin.y) - totalGutterSpacing;
    CGFloat h = boundsHeight / (2 * [channelData count]);
    */
    //for (int c = 0; c < [channelData count]; c++) {
    MLNSampleChannel *channel = channelData[channelNumber];
    NSUInteger pixelsDrawn;
    CGFloat h = scaledBounds.size.height / 2;
    
    CGFloat x = (scaledBounds.origin.x < 0) ? 0: scaledBounds.origin.x;
    
    pixelsDrawn = [self fillPointArray:pointArray
                                length:numberOfPoints
                           fromChannel:channel
                      atFramesPerPixel:(int)framesPerPixel
                            startFrame:(int)x * framesPerPixel];
    
    //
    //CGFloat yoff = h + (channelCount - (c + 1)) * ((boundsHeight / 2) + gutterSpacing);
    
    CGContextSetLineWidth(context, 1.0);
    
    // For each point in the array, draw a line between max and min
    
    for (int i = 0; i < pixelsDrawn; i++) {
        CGFloat x = i;
        CGContextMoveToPoint(context, x + 0.5, (pointArray[i].maxValue * h) + h);
        CGContextAddLineToPoint(context, x + 0.5, (pointArray[i].minValue * h) + h);
    }
    CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextStrokePath(context);
  
    /*
     // Draw the average waveform as well
     for (int i = 0; i < pixelsDrawn; i++) {
     CGFloat x = origin.x + i + 0.5;
     CGContextMoveToPoint(context, x, (pointArray[i].avgMaxValue * h + yoff) + 0.5);
     CGContextAddLineToPoint(context, x, (pointArray[i].avgMinValue * h + yoff) + 0.5);
     }
     CGContextSetRGBStrokeColor(context, 0.4, 0.4, 0.4, 1.0);
     CGContextStrokePath(context);
     */
    
    free(pointArray);
}

@end
