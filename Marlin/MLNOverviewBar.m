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
    NSMutableArray *_channelMasks;
}

@synthesize sample = _sample;

static void *sampleContext = &sampleContext;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
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
    
    if ([_sample numberOfChannels] < 2) {
        height = 24;
    } else {
        height = 12 * [_sample numberOfChannels];
    }
    
    DDLogVerbose(@"Overview height: %f", height);
    return NSMakeSize(NSViewNoInstrinsicMetric, height);
}

- (void)drawRect:(NSRect)dirtyRect
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    NSRect bounds = [self bounds];
    NSRect channelRect = bounds;
    CGFloat channelHeight = bounds.size.height / [_sample numberOfChannels];
    
    channelRect.size.height = (channelHeight - 1);
    NSColor *darkBG = [NSColor colorWithCalibratedRed:0.214 green:0.218 blue:0.226 alpha:1.0];

    [[NSColor underPageBackgroundColor] setFill];
    NSRectFill(dirtyRect);
    
    for (int channel = 0; channel < [_sample numberOfChannels]; channel++) {
        channelRect.origin.y = (bounds.size.height - (channelHeight * (channel + 1))) + 1;
        
        // Draw the background
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:channelRect
                                                             xRadius:4 yRadius:4];
        [darkBG set];
        [path fill];
        
        // Draw the sample mask
        CGContextSaveGState(context);
        CGImageRef channelMask = (CGImageRef)CFBridgingRetain([_channelMasks objectAtIndex:channel]);
        
        CGContextClipToMask(context, channelRect, channelMask);
    
        NSColor *waveformColour = [NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.2 alpha:1.0];
        [waveformColour setFill];
        
        NSRectFill(channelRect);
        CGContextRestoreGState(context);
    }
    
    [[NSColor blackColor] set];
    [[NSBezierPath bezierPathWithRect:bounds] stroke];
}

- (CGContextRef)createMaskContextForRect:(NSRect)scaledRect
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
    NSUInteger framesPerPixel;
    
    channelRect.size.height /= [_sample numberOfChannels];
    //channelRect = NSInsetRect(channelRect, 0, 1);
    
    framesPerPixel = [_sample numberOfFrames] / channelRect.size.width;

    [_channelMasks removeAllObjects];
    for (int channel = 0; channel < [_sample numberOfChannels]; channel++) {
        CGContextRef maskContext = [self createMaskContextForRect:channelRect];
        CGImageRef channelMask;
        
        [_sample drawWaveformInContext:maskContext
                         channelNumber:channel
                                  rect:channelRect
                    withFramesPerPixel:framesPerPixel];
        channelMask = CGBitmapContextCreateImage(maskContext);
        
        [_channelMasks addObject:CFBridgingRelease(channelMask)];
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
        [self invalidateIntrinsicContentSize];
        [self setNeedsDisplay:YES];
        return;
    }
}

#pragma mark - Accessors

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
    
    if ([_sample isLoaded]) {
        [self createChannelMasks];
        [self invalidateIntrinsicContentSize];
        [self setNeedsDisplay:YES];
    }
}

- (MLNSample *)sample
{
    return _sample;
}
@end
