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

@implementation MLNOverviewBar {
    NSSize _cachedSize;
    NSMutableArray *_channelMasks;
    NSRange _selection;
    NSRange _visibleRange;
    NSUInteger _framesPerPixel;
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
    NSColor *darkBG = [NSColor colorWithCalibratedRed:0.214 green:0.218 blue:0.226 alpha:1.0];

    [[NSColor underPageBackgroundColor] setFill];
    NSRectFill(dirtyRect);
    
    NSRect borderRect = NSZeroRect;
    if (_visibleRange.length != 0) {
        borderRect = [self visibleRangeToRect:_visibleRange];
    }
    
    for (int channel = 0; channel < [_sample numberOfChannels]; channel++) {
        channelRect.origin.y = ((bounds.size.height - 5) - (channelHeight * (channel + 1))) + 1;
        
        // Draw the background
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:channelRect
                                                             xRadius:4 yRadius:4];
        [darkBG set];
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
    
    if (_visibleRange.length != 0) {
        //[[NSColor blackColor] set];
        
        [[NSColor colorWithCalibratedRed:0.1 green:0.12 blue:0.15 alpha:1.0] set];
        DDLogVerbose(@"drawing %@", NSStringFromRect(borderRect));
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

#pragma mark - Accessors

- (void)setFrameSize:(NSSize)newSize
{
    NSSize scaledSize = [self convertSizeToBacking:newSize];
    _framesPerPixel = [_sample numberOfFrames] / scaledSize.width;

    [super setFrameSize:newSize];
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

- (void)setVisibleRange:(NSRange)visibleRange
{
    if (NSEqualRanges(visibleRange, _visibleRange)) {
        return;
    }
    
    NSRect newRect = [self visibleRangeToRect:visibleRange];
    NSRect rect = [self visibleRangeToRect:_visibleRange];
    
    if (NSEqualRects(newRect, rect)) {
        return;
    }
    
    NSRect unionRect = NSUnionRect(newRect, rect);
    unionRect.origin.x -= 10;
    unionRect.size.width += 20;
    [self setNeedsDisplayInRect:unionRect];
    
    _visibleRange = visibleRange;
}
@end
