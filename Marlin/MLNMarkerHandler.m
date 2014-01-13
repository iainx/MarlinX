//
//  MLNMarkerHandler.m
//  Marlin
//
//  Created by iain on 26/11/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNMarkerHandler.h"
#import "MLNMarker.h"
#import "MLNSampleView.h"
#import "MLNSample.h"

@implementation MLNMarkerHandler {
    MLNMarker *_marker;
    MLNSampleView *_sampleView;
    NSMutableArray *_trackingAreas;
}

static void *markerContext = &markerContext;

- (id)initForMarker:(MLNMarker *)marker
              owner:(MLNSampleView *)sampleView;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _marker = marker;
    [_marker addObserver:self
              forKeyPath:@"frame"
                 options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                 context:markerContext];
    
    _sampleView = sampleView;
    
    _trackingAreas = [[NSMutableArray alloc] init];
    
    [self addTrackingAreas];
    
    return self;
}

- (void)dealloc
{
    
    [self removeTrackingAreas];
    [_marker removeObserver:self forKeyPath:@"frame" context:markerContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context != markerContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    if ([keyPath isEqualToString:@"frame"]) {
        [self removeTrackingAreas];
        [self addTrackingAreas];
        
        [_sampleView handler:self didMoveMarker:_marker from:0];
    }
}

- (void)addTrackingAreas
{
    NSPoint markerPoint = [_sampleView convertFrameToPoint:[[_marker frame] unsignedIntegerValue]];
    NSUInteger numberOfChannels = [[_sampleView sample] numberOfChannels];
    
    int firstChannel = (numberOfChannels == 1) ? 0 : 1;
    for (NSUInteger channel = firstChannel; channel < numberOfChannels; channel++) {
        NSRect gutterRect = [_sampleView calculateGutterRect:channel];
        
        gutterRect.origin.x = markerPoint.x - 4;
        gutterRect.size.width = 9;
        
        NSTrackingArea *area = [self trackingAreaForRect:gutterRect];
        [_sampleView addTrackingArea:area];
    }
}

- (void)removeTrackingAreas
{
    for (NSTrackingArea *area in _trackingAreas) {
        [_sampleView removeTrackingArea:area];
    }
    
    [_trackingAreas removeAllObjects];
}

- (NSTrackingArea *)trackingAreaForRect:(NSRect)rect
{
    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:rect
                                                        options:NSTrackingMouseEnteredAndExited | NSTrackingCursorUpdate | NSTrackingActiveInKeyWindow | NSTrackingAssumeInside
                                                          owner:self
                                                       userInfo:nil];
    [_trackingAreas addObject:area];
    
    return area;
}

- (NSArray *)trackingAreas
{
    return (NSArray *)_trackingAreas;
}

- (void)mouseEntered:(NSEvent *)event
{
    if (_delegate) {
        [_delegate handler:self didEnterMarker:_marker];
    }
}

- (void)mouseExited:(NSEvent *)event
{
    if (_delegate) {
        [_delegate handler:self didLeaveMarker:_marker];
    }
}

- (void)mouseMoved:(NSEvent *)event
{
    DDLogVerbose(@"Mouse Moved Marker %@", _marker);
}

- (void)cursorUpdate:(NSEvent *)event
{
    DDLogVerbose(@"Cursor Changed %@", _marker);
}
@end
