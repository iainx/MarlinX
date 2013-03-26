//
//  MLNSampleView.h
//  Marlin
//
//  Created by iain on 31/01/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MLNSampleViewDelegate.h"
#import "MLNSampleDelegate.h"

@class MLNSample;
@interface MLNSampleView : NSView <MLNSampleDelegate>

@property (readwrite, nonatomic, strong) MLNSample *sample;
@property (readwrite, nonatomic) NSUInteger framesPerPixel; // framesPerPoint in this retina age?
@property (readwrite, weak) id<MLNSampleViewDelegate> delegate;
@property (readonly) BOOL hasSelection;
@property (readonly) NSRange selection;

- (void)clearSelection;

- (void)dumpCacheImage;

@end
