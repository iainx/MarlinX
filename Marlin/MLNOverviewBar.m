//
//  MLNOverviewBar.m
//  Marlin
//
//  Created by iain on 02/04/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNOverviewBar.h"
#import "MLNSample.h"
#import "MLNSample+Drawing.h"
#import "Constants.h"

typedef enum {
    DragRegionNone,
    DragRegionStart,
    DragRegionEnd,
} DragRegion;

@implementation MLNOverviewBar {
    NSSize _cachedSize;
    NSMutableArray *_channelMasks;
    NSRange _selection;
    NSRange _visibleFrameRange;
    NSRect _visiblePixelRect;
    NSUInteger _framesPerPixel;
    
    NSTrackingArea *_trackingArea;
    
    NSPoint _mouseDownPoint;
    DragRegion _dragRegion;
    BOOL _dragged;
    
    NSColor *_darkBG;
}

@synthesize sample = _sample;

static void *sampleContext = &sampleContext;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    _cachedSize = NSZeroSize;
    _channelMasks = [[NSMutableArray alloc] init];
    
    [self setContentCompressionResistancePriority:NSLayoutPriorityRequired
                                   forOrientation:NSLayoutConstraintOrientationVertical];
    [self setContentHuggingPriority:NSLayoutPriorityRequired
                     forOrientation:NSLayoutConstraintOrientationVertical];
    
    _trackingArea = [[NSTrackingArea alloc] initWithRect:frame
                                                 options:NSTrackingCursorUpdate | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow |NSTrackingInVisibleRect
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
    
    return self;
}

#pragma mark - Layout

- (NSSize)intrinsicContentSize
{
    CGFloat height;
    
    if ([_sample numberOfChannels] < 3) {
        height = 36;
    } else {
        height = 12 * [_sample numberOfChannels];
    }
    
    return NSMakeSize(NSViewNoInstrinsicMetric, height + 9);
}

- (void)viewWillDraw
{
    if (NSEqualSizes(_cachedSize, [self frame].size)) {
        return;
    }

    [self createChannelMasks];
    _cachedSize = [self frame].size;
}

- (void)drawRect:(NSRect)dirtyRect
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    NSRect bounds = [self bounds];
    NSRect channelRect = bounds;
    CGFloat channelHeight = (bounds.size.height - 9) / [_sample numberOfChannels];
    
    channelRect.size.height = (channelHeight - 1);
    if (_darkBG == nil) {
        _darkBG = [NSColor colorWithCalibratedRed:0.214 green:0.218 blue:0.226 alpha:1.0];
    }
    
    [[NSColor underPageBackgroundColor] setFill];
    NSRectFill(dirtyRect);
    
    NSRect borderRect = NSZeroRect;
    if (_visibleFrameRange.length != 0) {
        borderRect = _visiblePixelRect;
    }
    
    for (int channel = 0; channel < [_sample numberOfChannels]; channel++) {
        channelRect.origin.y = ((bounds.size.height - 5) - (channelHeight * (channel + 1))) + 1;
        
        // Draw the background
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:channelRect
                                                             xRadius:4 yRadius:4];
        [_darkBG set];
        [path fill];
    }

    NSBezierPath *selectionPath = nil;
    if (_selection.length != 0) {
        NSRect selectionRect = [self selectionToRect:_selection];
        
        selectionRect.origin.x += 0.5;
        selectionRect.origin.y += 4.5;
        selectionRect.size.width -= 1;
        selectionRect.size.height -= 9;
        
        selectionPath = [NSBezierPath bezierPathWithRoundedRect:selectionRect xRadius:2.0 yRadius:2.0];
        NSColor *selectionBackgroundColour = [NSColor colorWithCalibratedRed:0.2 green:0.2 blue:0.6 alpha:0.75];
        [selectionBackgroundColour setFill];
        
        [selectionPath fill];
    }
    
    for (int channel = 0; channel < [_sample numberOfChannels]; channel++) {
        channelRect.origin.y = ((bounds.size.height - 5) - (channelHeight * (channel + 1))) + 1;
        
        // Draw the sample mask
        CGContextSaveGState(context);
        CGImageRef channelMask = (CGImageRef)CFBridgingRetain([_channelMasks objectAtIndex:channel]);
        
        CGContextClipToMask(context, channelRect, channelMask);
    
        [[NSColor darkGrayColor] setFill];
        NSRectFill(channelRect);
        
        if (NSEqualRects(borderRect, NSZeroRect) == NO) {
            NSColor *waveformColour = [NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.2 alpha:1.0];
            [waveformColour setFill];
            
            NSRectFill(borderRect);
        }
        CGImageRelease(channelMask);
        CGContextRestoreGState(context);
    }
    
    if (selectionPath) {
        [[NSColor blackColor] setStroke];
        [selectionPath stroke];
    }
    
    if (_visibleFrameRange.length != 0) {
        [[NSColor colorWithCalibratedRed:0.1 green:0.12 blue:0.15 alpha:1.0] set];
        NSBezierPath *borderPath = [NSBezierPath bezierPathWithRoundedRect:borderRect xRadius:2.0 yRadius:2.0];
        [borderPath setLineWidth:1.0];
        [borderPath stroke];
    }
}

- (CGContextRef)newMaskContextForRect:(NSRect)scaledRect
{
    CGContextRef maskContext;
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray();
    
    maskContext = CGBitmapContextCreate(NULL,
                                        scaledRect.size.width,
                                        scaledRect.size.height,
                                        8,
                                        scaledRect.size.width,
                                        colorspace,
                                        0);
    CGColorSpaceRelease(colorspace);
    
    return maskContext;
}

- (void)createChannelMasks
{
    NSRect channelRect = [self convertRectToBacking:[self bounds]];
    
    channelRect.size.height /= [_sample numberOfChannels];
    //channelRect = NSInsetRect(channelRect, 0, 1);
    
    [_channelMasks removeAllObjects];
    for (int channel = 0; channel < [_sample numberOfChannels]; channel++) {
        CGContextRef maskContext = [self newMaskContextForRect:channelRect];
        CGImageRef channelMask;
        
        [_sample drawWaveformInContext:maskContext
                         channelNumber:channel
                                  rect:channelRect
                    withFramesPerPixel:_framesPerPixel];
        channelMask = CGBitmapContextCreateImage(maskContext);
        
        [_channelMasks addObject:CFBridgingRelease(channelMask)];
        CGContextRelease(maskContext);
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context != sampleContext) {
        return;
    }
    
    if ([keyPath isEqualToString:@"numberOfChannels"]) {
        [self createChannelMasks];
        [self invalidateIntrinsicContentSize];
        [self setNeedsDisplay:YES];
        return;
    }
    
    if ([keyPath isEqualToString:@"loaded"]) {
        NSSize scaledSize = [self convertSizeToBacking:[self bounds].size];
        _framesPerPixel = [_sample numberOfFrames] / scaledSize.width;
        
        [self createChannelMasks];
        [self invalidateIntrinsicContentSize];
        [self setNeedsDisplay:YES];
        return;
    }
}

- (NSRect)selectionToRect:(NSRange)selection
{
    NSRect rect = [self bounds];
    NSRect selectionRect = NSZeroRect;
    
    selectionRect.origin.x = selection.location / _framesPerPixel;
    selectionRect.size.width = (NSMaxRange(selection) / _framesPerPixel) - selectionRect.origin.x;
    
    selectionRect = [self convertRectFromBacking:selectionRect];
    
    rect.origin.x = selectionRect.origin.x;
    rect.size.width = selectionRect.size.width;
    
    return rect;
}

- (NSRect)visibleRangeToRect:(NSRange)visibleRange
{
    if (_framesPerPixel == 0) {
        return NSZeroRect;
    }
    
    NSRect visibleRect = NSZeroRect;
    visibleRect.origin.x = visibleRange.location / _framesPerPixel;
    visibleRect.size.width = (NSMaxRange(visibleRange) / _framesPerPixel) - visibleRect.origin.x;
    NSRect scaledRect = [self convertRectFromBacking:visibleRect];
    
    NSRect borderRect = NSMakeRect(scaledRect.origin.x, 2.5, scaledRect.size.width, [self bounds].size.height - 5);
    
    if (NSMaxX(borderRect) > NSMaxX([self bounds])) {
        borderRect.size.width = ([self bounds].size.width - borderRect.origin.x) - 1;
    }
    
    return borderRect;
}

#pragma mark - Event handling

- (BOOL)pointInVisibleEdges:(NSPoint)point
{
    NSRect visibleRect = [self visibleRangeToRect:_visibleFrameRange];
    
    return ((point.x >= visibleRect.origin.x - 3 && point.x <= visibleRect.origin.x + 3) ||
            (point.x >= NSMaxX(visibleRect) - 3 && point.x <= NSMaxX(visibleRect) + 3));
}

- (void)mouseDown:(NSEvent *)theEvent
{
    _mouseDownPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    if (_mouseDownPoint.x >= _visiblePixelRect.origin.x - 3 && _mouseDownPoint.x <= _visiblePixelRect.origin.x + 3) {
        _dragRegion = DragRegionStart;
    } else if (_mouseDownPoint.x >= NSMaxX(_visiblePixelRect) - 3 && _mouseDownPoint.x <= NSMaxX(_visiblePixelRect) + 3) {
        _dragRegion = DragRegionEnd;
    } else {
        _dragRegion = DragRegionNone;
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if (_dragRegion == DragRegionNone) {
        NSPoint scaledPoint = [self convertPointToBacking:_mouseDownPoint];
        NSUInteger selectedFrame = _framesPerPixel * (NSInteger)scaledPoint.x;
    
        [_delegate overviewBar:self didSelectFrame:selectedFrame];
    }
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    if (_dragRegion == DragRegionNone) {
        return;
    }
    
    NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    if (_dragRegion == DragRegionEnd) {
        if (mouseLoc.x <= (_visiblePixelRect.origin.x)) {
            mouseLoc.x = _visiblePixelRect.origin.x + 1;
        }
    } else if (_dragRegion == DragRegionStart) {
        if (mouseLoc.x >= NSMaxX(_visiblePixelRect)) {
            mouseLoc.x = NSMaxX(_visiblePixelRect) - 1;
        }
    }
    
    NSUInteger newFrameLocation;
    NSUInteger newFrameLength;
    
    NSSize visibleRectSize = NSMakeSize(_visiblePixelRect.origin.x - mouseLoc.x, 0);
    NSSize scaledRectSize = [self convertSizeToBacking:visibleRectSize];
    
    NSPoint scaledLengthPoint = [self convertPointToBacking:mouseLoc];
    
    if (_dragRegion == DragRegionEnd) {
        newFrameLocation = _visibleFrameRange.location;
        newFrameLength = scaledRectSize.width * _framesPerPixel;
    } else {
        NSUInteger lastFrame = NSMaxRange(_visibleFrameRange) - 1;
        
        newFrameLocation = scaledLengthPoint.x * _framesPerPixel;
        newFrameLength = lastFrame - newFrameLocation;
    }
    
    NSRange newFrameRange;
    newFrameRange = NSMakeRange(newFrameLocation, newFrameLength);
    
    [_delegate overviewBar:self requestVisibleRange:newFrameRange];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    [self cursorUpdate:theEvent];
}

- (void)cursorUpdate:(NSEvent *)event
{
    NSPoint mouseLoc = [self convertPoint:[event locationInWindow] fromView:nil];
 
    if ([self pointInVisibleEdges:mouseLoc]) {
        [[NSCursor resizeLeftRightCursor] set];
    } else {
        [super cursorUpdate:event];
    }
}
#pragma mark - Accessors

- (void)setFrameSize:(NSSize)newSize
{
    NSSize scaledSize = [self convertSizeToBacking:newSize];
    _framesPerPixel = [_sample numberOfFrames] / scaledSize.width;

    [super setFrameSize:newSize];
}

- (void)sampleDataDidChangeInRange:(NSNotification *)note
{
    [self createChannelMasks];
    [self setNeedsDisplay:YES];
}

- (void)setSample:(MLNSample *)sample
{
    if (_sample == sample) {
        return;
    }
    
    _sample = sample;
    [_sample addObserver:self
              forKeyPath:@"numberOfChannels"
                 options:NSKeyValueObservingOptionNew
                 context:sampleContext];
    [_sample addObserver:self
              forKeyPath:@"loaded"
                 options:NSKeyValueObservingOptionNew
                 context:sampleContext];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(sampleDataDidChangeInRange:)
               name:kMLNSampleDataDidChangeInRange object:_sample];
    
    if ([_sample isLoaded]) {
        _framesPerPixel = [_sample numberOfFrames] / [self bounds].size.width;
        [self createChannelMasks];
        [self invalidateIntrinsicContentSize];
        [self setNeedsDisplay:YES];
    }
}

- (MLNSample *)sample
{
    return _sample;
}

- (void)setSelection:(NSRange)selection
{
    if (NSEqualRanges(selection, _selection)) {
        return;
    }
    
    NSRect rect = [self selectionToRect:_selection];
    [self setNeedsDisplayInRect:rect];
    
    _selection = selection;

    rect = [self selectionToRect:_selection];
    [self setNeedsDisplayInRect:rect];
}

- (void)setVisibleRange:(NSRange)visibleFrameRange
{
    if (NSEqualRanges(visibleFrameRange, _visibleFrameRange)) {
        return;
    }
    
    NSRect newRect = [self visibleRangeToRect:visibleFrameRange];
    NSRect rect = _visiblePixelRect;
    
    if (NSEqualRects(newRect, rect)) {
        return;
    }
    
    NSRect unionRect = NSUnionRect(newRect, rect);
    unionRect.origin.x -= 10;
    unionRect.size.width += 20;
    [self setNeedsDisplayInRect:unionRect];
    
    _visibleFrameRange = visibleFrameRange;
    _visiblePixelRect = newRect;
}
@end
