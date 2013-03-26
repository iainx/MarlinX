//
//  MLNSample+Drawing.h
//  Marlin
//
//  Created by iain on 08/03/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNSample.h"

@interface MLNSample (Drawing)

- (void)drawWaveformInContext:(CGContextRef)context
                channelNumber:(NSUInteger)channelNumber
                         rect:(NSRect)scaledBounds
           withFramesPerPixel:(NSUInteger)framesPerPixel;

@end
