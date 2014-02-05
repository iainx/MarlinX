//
//  MLNSample+Drawing.m
//  Marlin
//
//  Created by iain on 08/03/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNSample+Drawing.h"
#import "MLNSampleChannel.h"
#import "MLNSampleChannelIterator.h"
#import "MLNSampleBlock.h"

@implementation MLNSample (Drawing)

- (NSUInteger)fillPointArray:(MLNSampleCachePoint *)pointArray
                      length:(NSUInteger)length
                 fromChannel:(MLNSampleChannel *)channel
            atFramesPerPixel:(int)fpp
                  startFrame:(NSUInteger)startFrame
{
    MLNSampleChannelIterator *iter = [[MLNSampleChannelIterator alloc] initWithChannel:channel
                                                                               atFrame:startFrame];
    int framesPerCachePoint = [MLNSampleChannel framesPerCachePoint];
    int i = 0;
    int cachePointsPerPixel;
    
    BOOL moreData = YES;
    
    if (fpp < framesPerCachePoint) {
        cachePointsPerPixel = fpp;
    } else {
        cachePointsPerPixel = fpp / framesPerCachePoint;
    }
    
    while (moreData && i < length) {
        CGFloat maxPoint = 0, minPoint = 0;
        CGFloat totalAboveZero = 0, totalBelowZero = 0;
        int j;
        
        for (j = 0; j < cachePointsPerPixel && moreData; j++) {
            if (fpp < framesPerCachePoint) {
                float value;
                
                moreData = [iter frameDataAndAdvance:&value];
                
                maxPoint = MAX(maxPoint, value);
                minPoint = MIN(minPoint, value);
                if (value > 0) {
                    totalAboveZero += value;
                } else {
                    totalBelowZero += value;
                }
            } else {
                MLNSampleCachePoint cachePoint;
                
                moreData = [iter nextCachePointData:&cachePoint];
                
                maxPoint = MAX(maxPoint, cachePoint.maxValue);
                minPoint = MIN(minPoint, cachePoint.minValue);
                totalAboveZero += cachePoint.avgMaxValue;
                totalBelowZero += cachePoint.avgMinValue;
            }
        }
        
        pointArray[i].maxValue = maxPoint;
        pointArray[i].minValue = minPoint;
        pointArray[i].avgMaxValue = totalAboveZero / j;
        pointArray[i].avgMinValue = totalBelowZero / j;
        
        i++;
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
    
    scaledBounds.origin.x = floor(scaledBounds.origin.x);
    // Add one to the width because if x is not on pixel boundaries
    // then we need to draw one more pixel.
    // Consider drawing from 0.5 with width 3, we need to draw the 0, 1, 2, and 3 pixels
    // which is 4.
    int numberOfPoints = scaledBounds.size.width + 1;
    
    channelData = [self channelData];
    
    // We need bounds.size.width points to draw
    pointArray = malloc(numberOfPoints * sizeof(MLNSampleCachePoint));
    assert(pointArray);
 
    MLNSampleChannel *channel = channelData[channelNumber];
    NSUInteger pixelsDrawn;
    CGFloat h = scaledBounds.size.height / 2;
    
    CGFloat x = (scaledBounds.origin.x < 0) ? 0: scaledBounds.origin.x;
    
    pixelsDrawn = [self fillPointArray:pointArray
                                length:numberOfPoints
                           fromChannel:channel
                      atFramesPerPixel:(int)framesPerPixel
                            startFrame:(int)x * framesPerPixel];
    
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
