//
//  MLNSampleView.m
//  Marlin
//
//  Created by iain on 31/01/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNApplicationDelegate.h"
#import "MLNSampleView.h"
#import "MLNSample.h"
#import "MLNSample+Drawing.h"
#import "MLNSampleBlock.h"
#import "MLNSampleChannel.h"

// TODO: Allow selection resizing
//       Draw channel separator?
//       Regions
//       Markers
//       Playhead

@implementation MLNSampleView {
    CGFloat _intrinsicWidth;
    CGFloat _summedMagnificationLevel;
    
    int _selectionDirection;
    NSTrackingArea *_startTrackingArea;
    NSTrackingArea *_endTrackingArea;
    NSUInteger _selectionStartFrame;
    NSUInteger _selectionEndFrame;
    NSEvent *_dragEvent;
    BOOL _inStart;
    BOOL _inEnd;
    
    CGGradientRef _sampleGradient;
    
    NSTimer *_cursorTimer;
    NSUInteger _cursorFramePosition;
    BOOL _drawCursor;
}

@synthesize framesPerPixel = _framesPerPixel;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    _framesPerPixel = 256;
    _summedMagnificationLevel = 0;
    _drawCursor = YES;
    _cursorFramePosition = 0;
    [self resetCursorTimer:0.9];
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return nil;
    }
    
    _framesPerPixel = 128;
    _summedMagnificationLevel = 0;
    _drawCursor = YES;
    _cursorFramePosition = 0;
    [self resetCursorTimer:0.9];
    
    return self;
}

- (void)dealloc
{
    CGGradientRelease(_sampleGradient);
}

- (BOOL)isFlipped
{
    return NO;
}

- (NSSize)intrinsicContentSize
{
    NSSize intrinsicSize = NSMakeSize(_intrinsicWidth, NSViewNoInstrinsicMetric);
    return intrinsicSize;
}

#pragma mark - Sample view drawing

- (CGContextRef)createMaskContextForRect:(NSRect)scaledRect
{
    CGContextRef maskContext;
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray();
    
    //NSRect scaledRect = [self convertRectToBacking:bounds];
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

- (void)drawRect:(NSRect)dirtyRect
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    NSRect bounds = [self bounds];
    NSRect realDrawRect = dirtyRect;
    
    // We actually want to draw the whole of the vertical
    realDrawRect.origin.y = bounds.origin.y;
    realDrawRect.size.height = bounds.size.height;
    
    if ([_sample isLoaded] == NO) {
        return;
    }
    
    
    /**/
    
    NSUInteger numberOfChannels = [_sample numberOfChannels];
    //int numberOfGutters = (numberOfChannels - 1 == 0) ? 1 : (int)numberOfChannels - 1;
    //CGFloat gutterSize = 50 * numberOfGutters;
    
    NSRect channelRect = realDrawRect;
    CGFloat channelHeight = realDrawRect.size.height / numberOfChannels;
    
    // 55 56 58
    NSColor *darkBG = [NSColor colorWithCalibratedRed:0.214 green:0.218 blue:0.226 alpha:1.0];
    /*
    [darkBG setFill];
    NSRectFill(realDrawRect);
    */
    
    channelRect.size.height = channelHeight;
    
    NSRect maskRect = channelRect;
    maskRect.size.height -= 20;
    
    // Scale to take Retina display into consideration
    NSRect scaledRect = [self convertRectToBacking:maskRect];
    
    for (NSUInteger channel = 0; channel < numberOfChannels; channel++) {
        channelRect.origin.y = realDrawRect.size.height - (realDrawRect.size.height / (numberOfChannels - channel));
        maskRect.origin.y = channelRect.origin.y + 10.0;
        
        [darkBG setFill];
        
        NSRect channelBackgroundRect = maskRect;
        channelBackgroundRect.origin.x = bounds.origin.x;
        channelBackgroundRect.size.width = bounds.size.width;
        [[NSBezierPath bezierPathWithRoundedRect:channelBackgroundRect xRadius:10.0 yRadius:10.0] fill];
    }
    
    NSBezierPath *selectionPath;
    
    if (_hasSelection) {
        NSRect selectionRect = [self selectionToRect];
        
        NSColor *selectionBackgroundColour = [NSColor colorWithCalibratedRed:0.2 green:0.2 blue:0.6 alpha:0.75];
        [selectionBackgroundColour setFill];
        
        selectionRect.origin.x += 0.5;
        selectionRect.origin.y += 0.5;
        selectionRect.size.width -= 1;
        selectionRect.size.height -= 1;
        
        selectionPath = [NSBezierPath bezierPathWithRoundedRect:selectionRect xRadius:5 yRadius:5];
        
        [selectionPath fill];
    }
    
    for (NSUInteger channel = 0; channel < numberOfChannels; channel++) {
        CGContextRef maskContext;
        CGImageRef sampleMask;
        
        maskContext = [self createMaskContextForRect:scaledRect];
        [_sample drawWaveformInContext:maskContext
                         channelNumber:channel
                                  rect:scaledRect
                    withFramesPerPixel:_framesPerPixel];
        sampleMask = CGBitmapContextCreateImage(maskContext);
        
        CGContextSaveGState(context);
        
        channelRect.origin.y = realDrawRect.size.height - (realDrawRect.size.height / (numberOfChannels - channel));
        maskRect.origin.y = channelRect.origin.y + 10.0;
        
        NSRect smallerMaskRect = NSInsetRect(maskRect, 0, 6);
        CGContextClipToMask(context, smallerMaskRect, sampleMask);
/*
        if (_sampleGradient == NULL) {
            CGFloat components[16] = {1.0, 0.2386, 0.2318, 1.0,  // Start color
                0.3, 1.0, 0.0, 1.0, // Middle region
                0.3, 1.0, 0.0, 1.0, // Middle region
                1.0, 0.2386, 0.2318, 1.0}; // End color
            CGFloat locations[4] = {0.02, 0.45, 0.55, 0.98};
            size_t num_locations = 4;
            
            CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
            _sampleGradient = CGGradientCreateWithColorComponents(colorspace, components, locations, num_locations);
            CGColorSpaceRelease(colorspace);
        }
        
        CGPoint startPoint = maskRect.origin;
        CGPoint endPoint = CGPointMake(maskRect.origin.x, maskRect.origin.y + maskRect.size.height / 2);
        CGContextDrawLinearGradient(context, _sampleGradient, startPoint, endPoint, 0);
        
        startPoint = CGPointMake(maskRect.origin.x, maskRect.origin.y + (maskRect.size.height / 2));
        endPoint = CGPointMake(maskRect.origin.x, maskRect.origin.y + maskRect.size.height);
        CGContextDrawLinearGradient(context, _sampleGradient, startPoint, endPoint, 0);
*/
        NSColor *waveformColour = [NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.2 alpha:1.0];
        [waveformColour setFill];
        
        NSRectFill(smallerMaskRect);
        CGContextRestoreGState(context);
        
        CGImageRelease(sampleMask);
        CGContextRelease(maskContext);
    }

    if (_hasSelection) {
        [[NSColor blackColor] set];
        [selectionPath stroke];
    }
    
    if (_drawCursor) {
        NSPoint cursorPoint = [self convertFrameToPoint:_cursorFramePosition];
        NSRect cursorRect = NSMakeRect(cursorPoint.x + 0.5, 0, 1, [self bounds].size.height);
        if (NSIntersectsRect(cursorRect, dirtyRect)) {
            [[NSColor whiteColor] setFill];
            NSRectFillUsingOperation(cursorRect, NSCompositeCopy);
        }
    }
}

#pragma mark - accessors

static void *sampleContext = &sampleContext;

- (void)sampledLoadedHandler
{
    _intrinsicWidth = [_sample numberOfFrames] / (_framesPerPixel * 2);
    
    [self setNeedsDisplay:YES];
    
    [self invalidateIntrinsicContentSize];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context != sampleContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    if ([keyPath isEqualToString:@"loaded"]) {
        [self sampledLoadedHandler];
        return;
    }
    
    if ([keyPath isEqualToString:@"numberOfFrames"]) {
        [self sampledLoadedHandler];
        return;
    }
}

- (void)setSample:(MLNSample *)sample
{
    if (sample == _sample) {
        return;
    }
    
    _sample = sample;
    
    [_sample setDelegate:self];
    
    if ([_sample isLoaded]) {
        [self sampledLoadedHandler];
    } else {
        [_sample addObserver:self
                  forKeyPath:@"loaded"
                     options:0
                     context:sampleContext];
        [_sample addObserver:self
                  forKeyPath:@"numberOfFrames"
                     options:0
                     context:sampleContext];
    }
}

- (void)setFramesPerPixel:(NSUInteger)framesPerPixel
{
    if (_framesPerPixel == framesPerPixel) {
        return;
    }
    
    _framesPerPixel = framesPerPixel;
    _intrinsicWidth = [_sample numberOfFrames] / (_framesPerPixel * 2);
    
    [self setNeedsDisplay:YES];
    [self invalidateIntrinsicContentSize];
}

- (NSUInteger)framesPerPixel
{
    return _framesPerPixel;
}

#pragma mark - Events

- (NSUInteger)convertPointToFrame:(NSPoint)point
{
    NSPoint scaledPoint = [self convertPointToBacking:point];
    CGFloat x = (scaledPoint.x < 0) ? 0: scaledPoint.x;
    
    return (x * _framesPerPixel);
}

- (NSPoint)convertFrameToPoint:(NSUInteger)frame
{
    NSPoint scaledPoint = NSMakePoint(frame / _framesPerPixel, 0.0);
    return [self convertPointFromBacking:scaledPoint];
}

- (void)mouseDown:(NSEvent *)event
{
    if ([event type] != NSLeftMouseDown) {
        return;
    }
    
    // Store the current selection in case we need to remove it on mouseUp
    NSRect selectionRect = [self selectionToRect];
    
    [self clearSelection];
    
    // Possible selection start
    NSPoint mouseLoc = [self convertPoint:[event locationInWindow] fromView:nil];
    NSPoint startPoint = mouseLoc;
    
    if (!_inStart && !_inEnd) {
        _selectionStartFrame = [self convertPointToFrame:startPoint];
        _selectionEndFrame = _selectionStartFrame;
        _selectionDirection = 1; // No direction;
        DDLogVerbose(@"Maybe start drag: %lu", _selectionStartFrame);
    }

    // Grab the mouse and handle everything in a modal event loop
    NSUInteger eventMask = NSLeftMouseDraggedMask | NSLeftMouseUpMask | NSPeriodicMask;
    NSEvent *nextEvent;
    BOOL dragged = NO;
    BOOL timerOn = NO;
    
    while ((nextEvent = [[self window] nextEventMatchingMask:eventMask])) {
        NSRect visibleRect = [self visibleRect];
        
        switch ([nextEvent type]) {
            case NSPeriodic:
                [self resizeSelection:_dragEvent];
                [self autoscroll:_dragEvent];
                break;
                
            case NSLeftMouseDragged:
                dragged = YES;
                
                mouseLoc = [self convertPoint:[nextEvent locationInWindow] fromView:nil];
                if (![self mouse:mouseLoc inRect:visibleRect]) {
                    if (timerOn == NO) {
                        [NSEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.1];
                        timerOn = YES;
                    }
                    _dragEvent = nextEvent;
                    break;
                } else if (timerOn == YES) {
                    [NSEvent stopPeriodicEvents];
                    timerOn = NO;
                    _dragEvent = nil;
                }
                
                [self resizeSelection:nextEvent];
                break;
                
            case NSLeftMouseUp:
                [NSEvent stopPeriodicEvents];
                _dragEvent = nil;

                // Move the cursor
                [self moveCursor:_selectionStartFrame];
                
                /*
                if (dragged == NO) {
                    _selectionStartFrame = 0;
                    _selectionEndFrame = 0;
                    _hasSelection = NO;
                    [self selectionChanged];
                    
                    [self removeTrackingArea:_startTrackingArea];
                    [self removeTrackingArea:_endTrackingArea];
                    _startTrackingArea = nil;
                    _endTrackingArea = nil;
                    
                    selectionRect.size.width += 0.5;
                    [self setNeedsDisplayInRect:selectionRect];
                }
                 */
                return;
                
            default:
                break;
        }
    }
    
    _dragEvent = nil;
}

- (void)mouseEntered:(NSEvent *)event
{
    NSPoint mouseLoc = [self convertPoint:[event locationInWindow] fromView:nil];
    if (NSPointInRect(mouseLoc, [_startTrackingArea rect])) {
        _inEnd = NO;
        _inStart = YES;
    } else {
        _inStart = NO;
        _inEnd = YES;
    }
}

- (void)mouseExited:(NSEvent *)event
{
    _inStart = NO;
    _inEnd = NO;
}

- (void)cursorUpdate:(NSEvent *)event
{
    if (_inEnd || _inStart) {
        [[NSCursor resizeLeftRightCursor] set];
    } else {
        [[NSCursor arrowCursor] set];
    }
}

- (void)magnifyWithEvent:(NSEvent *)event
{
    NSPoint locationInView = [self convertPoint:[event locationInWindow] fromView:nil];
    NSInteger zoomFrame = locationInView.x * _framesPerPixel;
    CGFloat dx = locationInView.x - [self visibleRect].origin.x;
    NSUInteger fpp;
    
    CGFloat dfpp = (_framesPerPixel * [event magnification]);
    if (ABS(dfpp) < 1) {
        if ([event magnification] < 0) {
            dfpp = -1;
        } else {
            dfpp = 1;
        }
    }
    fpp = _framesPerPixel - dfpp;
    
    /*
    fpp = _framesPerPixel;
    
    _summedMagnificationLevel -= ([event magnification] * 2);
    if (_summedMagnificationLevel > -1 && _summedMagnificationLevel < 1) {
        // FIXME: Should we add a timeout to reset the mag level?
        return;
    }
    
    if (_summedMagnificationLevel > 1) {
        fpp *= 2;
        _summedMagnificationLevel = 0;
    } else if (_summedMagnificationLevel < -1) {
        fpp /= 2;
        _summedMagnificationLevel = 0;
    }
    */
    if (fpp < 1) {
        fpp = 1;
    }
    
    if (fpp > 65536) {
        fpp = 65536;
    }
    
    [self setFramesPerPixel:fpp];
    
    NSInteger newPosition = (zoomFrame / fpp) - dx;
    [self scrollPoint:CGPointMake(newPosition, 0)];
}

#pragma mark - Selection handling

- (NSRange)selection
{
    return NSMakeRange(_selectionStartFrame, _selectionEndFrame - _selectionStartFrame);
}

static NSRect
subtractSelectionRects (NSRect a, NSRect b)
{
    if (a.origin.x == b.origin.x) {
        if (a.size.width < b.size.width) {
            return NSMakeRect(NSMaxX(a), 0, b.size.width - a.size.width, a.size.height);
        } else {
            return NSMakeRect(NSMaxX(b), 0, a.size.width - b.size.width, a.size.height);
        }
    } else {
        if (a.size.width < b.size.width) {
            return NSMakeRect(NSMinX(b), 0, b.size.width - a.size.width, a.size.height);
        } else {
            return NSMakeRect(NSMinX(a), 0, a.size.width - b.size.width, a.size.height);
        }
    }
}

- (void)selectionChanged
{
    NSRange selectionRange = NSMakeRange(_selectionStartFrame, _selectionEndFrame - _selectionStartFrame);
    
    if ([_delegate respondsToSelector:@selector(sampleView:selectionDidChange:)]) {
        [_delegate sampleView:self
           selectionDidChange:selectionRange];
    }
}

- (NSRect)selectionToRect
{
    NSPoint startPoint = [self convertFrameToPoint:_selectionStartFrame];
    NSPoint endPoint = [self convertFrameToPoint:_selectionEndFrame];
    NSInteger selectionWidth = (endPoint.x - startPoint.x);
    NSRect selectionRect = NSMakeRect(startPoint.x, 0, selectionWidth, [self bounds].size.height);
    
    return selectionRect;
}

- (void)resizeSelection:(NSEvent *)event
{
    NSPoint endPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    
    NSUInteger tmp = [self convertPointToFrame:endPoint];
    NSUInteger otherEnd;
 
    NSRect oldSelectionRect = [self selectionToRect];
    
    if (tmp >= [_sample numberOfFrames]) {
        tmp = [_sample numberOfFrames] - 1;
    }
    
    if (_inStart) {
        _selectionStartFrame = tmp;
    } else if (_inEnd) {
        _selectionEndFrame = tmp;
    } else {
        if (_selectionDirection == -1) {
            otherEnd = _selectionEndFrame;
        } else {
            otherEnd = _selectionStartFrame;
        }

        int newDirection = (tmp < otherEnd) ? -1 : 1;
        BOOL directionChange = (newDirection != _selectionDirection);
        
        if (directionChange) {
            NSUInteger startTmp = _selectionStartFrame;
            _selectionStartFrame = _selectionEndFrame;
            _selectionEndFrame = startTmp;
        }
        
        _selectionDirection = newDirection;
        if (_selectionDirection == -1) {
            _selectionStartFrame = tmp;
        } else {
            _selectionEndFrame = tmp;
        }
    }
    
    _hasSelection = YES;
    
    NSRect newSelectionRect = [self selectionToRect];
    
    NSRect startRect = NSMakeRect(newSelectionRect.origin.x - 5, 0, 10, newSelectionRect.size.height);
    NSRect endRect = NSMakeRect(NSMaxX(newSelectionRect) - 5, 0, 10, newSelectionRect.size.height);
    
    if (_startTrackingArea) {
        [self removeTrackingArea:_startTrackingArea];
        _startTrackingArea = nil;
    }
    
    if (_endTrackingArea) {
        [self removeTrackingArea:_endTrackingArea];
        _endTrackingArea = nil;
    }
    
    _startTrackingArea = [[NSTrackingArea alloc] initWithRect:startRect
                                                      options:NSTrackingCursorUpdate | NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp
                                                        owner:self
                                                     userInfo:nil];
    _endTrackingArea = [[NSTrackingArea alloc] initWithRect:endRect
                                                    options:NSTrackingCursorUpdate | NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp
                                                      owner:self
                                                   userInfo:nil];
    [self addTrackingArea:_startTrackingArea];
    [self addTrackingArea:_endTrackingArea];
    
    [self selectionChanged];
    
    // Only redraw the changed selection
    oldSelectionRect.size.width += 0.5;
    newSelectionRect.size.width += 0.5;
    [self setNeedsDisplayInRect:oldSelectionRect];
    [self setNeedsDisplayInRect:newSelectionRect];
}

- (void)clearSelection
{
    NSRect selectionRect = [self selectionToRect];
    
    _selectionStartFrame = 0;
    _selectionEndFrame = 0;
    _hasSelection = NO;
    [self selectionChanged];
    
    [self removeTrackingArea:_startTrackingArea];
    [self removeTrackingArea:_endTrackingArea];
    _startTrackingArea = nil;
    _endTrackingArea = nil;
    
    selectionRect.size.width += 0.5;
    [self setNeedsDisplayInRect:selectionRect];
    DDLogVerbose(@"Mouse up: No drag %@", NSStringFromRect(selectionRect));
}

#pragma mark - Cursor

- (void)resetCursorTimer:(NSTimeInterval)interval
{
    [_cursorTimer invalidate];
    _cursorTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                    target:self
                                                  selector:@selector(invalidateCursor:)
                                                  userInfo:nil
                                                   repeats:YES];
}

- (void)invalidateCursor:(NSTimer *)timer
{
    _drawCursor = !_drawCursor;
    
    NSPoint cursorPoint = [self convertFrameToPoint:_cursorFramePosition];
    
    NSRect cursorRect = NSMakeRect(cursorPoint.x + 0.5, 0.0, 1.0, [self bounds].size.height);
    [self setNeedsDisplayInRect:cursorRect];
    
    [self resetCursorTimer:_drawCursor ? 0.8 : 0.4];
}

- (void)moveCursor:(NSUInteger)cursorFrame
{
    NSPoint cursorPoint = [self convertFrameToPoint:_cursorFramePosition];
    
    DDLogVerbose(@"old cursor at %@", NSStringFromPoint(cursorPoint));
    // Invalidate the old cursor
    NSRect cursorRect = NSMakeRect(cursorPoint.x + 0.5, 0.0, 1.0, [self bounds].size.height);
    [self setNeedsDisplayInRect:cursorRect];
    
    _cursorFramePosition = cursorFrame;

    // Now invalidate the new cursor
    cursorPoint = [self convertFrameToPoint:cursorFrame];
    DDLogVerbose(@"new cursor at %@", NSStringFromPoint(cursorPoint));
    cursorRect = NSMakeRect(cursorPoint.x + 0.5, 0.0, 1.0, [self bounds].size.height);
    _drawCursor = YES;
    [self resetCursorTimer:0.8];
    [self setNeedsDisplayInRect:cursorRect];
}

#pragma mark - MLNSampleDelegate methods

- (void)sampleDataDidChangeInRange:(NSRange)range
{
    NSRect changedRect = NSMakeRect(range.location / _framesPerPixel, 0,
                                    range.length / _framesPerPixel, [self bounds].size.height);
    
    DDLogVerbose(@"Sample changed: %@ %@", NSStringFromRange(range), NSStringFromRect(changedRect));
    [self setNeedsDisplayInRect:changedRect];
}

#pragma mark - Debugging

// Writes a CGImageRef to a PNG file
void CGImageWriteToFile(CGImageRef image, NSURL *fileURL) {
    CFURLRef url = (__bridge CFURLRef)fileURL;
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(destination, image, nil);
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", [fileURL path]);
    } else {
        NSLog(@"Wrote image to %@", [fileURL path]);
    }
    
    CFRelease(destination);
}

- (void)dumpCacheImage
{
    /*
    static int count = 0;
    NSString *filename = [NSString stringWithFormat:@"cacheDump-%d.png", count];
    MLNApplicationDelegate *appDelegate = [NSApp delegate];
    
    NSURL *url = [[appDelegate cacheURL] URLByAppendingPathComponent:filename];
    
    count++;
    
    CGImageWriteToFile(_sampleMask, url);
     */
}

@end
