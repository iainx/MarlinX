//
//  MLNSampleView.h
//  Marlin
//
//  Created by iain on 31/01/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MLNSampleViewDelegate.h"
#import "MLNMarkerHandlerDelegate.h"

@class MLNSample;
@interface MLNSampleView : NSView <MLNMarkerHandlerDelegate>

@property (readwrite, nonatomic, strong) MLNSample *sample;
@property (readwrite, nonatomic) NSUInteger framesPerPixel; // framesPerPoint in this retina age?
@property (readonly) NSRange visibleRange;
@property (readwrite, weak) id<MLNSampleViewDelegate> delegate;
@property (readonly) BOOL hasSelection;
@property (readwrite) NSRange selection;
@property (readwrite, strong) NSArray *selectionActions;
@property (readonly) NSUInteger cursorFramePosition;

- (void)zoomIn;
- (void)zoomOut;
- (void)zoomToFit;
- (void)zoomToNormal;

- (void)clearSelection;

- (void)moveCursorTo:(NSUInteger)cursorFrame;
- (void)centreOnCursor;

- (void)requestNewVisibleRange:(NSRange)newVisibleRange;

- (void)stopTimers;
- (void)resetTimers;
- (void)dumpCacheImage;

- (NSRect)calculateGutterRect:(NSUInteger)gutterNumber;

- (NSUInteger)convertPointToFrame:(NSPoint)point;
- (NSPoint)convertFrameToPoint:(NSUInteger)frame;

@end
