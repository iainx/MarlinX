//
//  SLFButtonCell.m
//  Cyclorama
//
//  Created by iain on 12/10/2012.
//  Copyright (c) 2012 Sleep(5). All rights reserved.
//

#import "SLFButtonCell.h"

@implementation SLFButtonCell {
    NSBezierPath *_bezelPath;
}

#define SNRButtonBlackGradientBottomColor         [NSColor colorWithCalibratedWhite:0.150 alpha:1.000]
#define SNRButtonBlackGradientTopColor            [NSColor colorWithCalibratedWhite:0.220 alpha:1.000]
#define SNRButtonBlackHighlightColor              [NSColor colorWithCalibratedWhite:1.000 alpha:0.050]
#define SNRButtonBlueGradientBottomColor          [NSColor colorWithCalibratedRed:0.000 green:0.310 blue:0.780 alpha:1.000]
#define SNRButtonBlueGradientTopColor             [NSColor colorWithCalibratedRed:0.000 green:0.530 blue:0.870 alpha:1.000]
#define SNRButtonBlueHighlightColor               [NSColor colorWithCalibratedWhite:1.000 alpha:0.250]

#define SNRButtonTextFont                         [NSFont systemFontOfSize:11.f]
#define SNRButtonTextColor                        [NSColor whiteColor]
#define SNRButtonBlackTextShadowOffset            NSMakeSize(0.f, 1.f)
#define SNRButtonBlackTextShadowBlurRadius        1.f
#define SNRButtonBlackTextShadowColor             [NSColor blackColor]
#define SNRButtonBlueTextShadowOffset             NSMakeSize(0.f, -1.f)
#define SNRButtonBlueTextShadowBlurRadius         2.f
#define SNRButtonBlueTextShadowColor              [NSColor colorWithCalibratedWhite:0.000 alpha:0.600]

#define SNRButtonDisabledAlpha                    0.7f
#define SNRButtonCornerRadius                     3.f
#define SNRButtonDropShadowColor                  [NSColor colorWithCalibratedWhite:1.000 alpha:0.050]
#define SNRButtonDropShadowBlurRadius             1.f
#define SNRButtonDropShadowOffset                 NSMakeSize(0.f, -1.f)
#define SNRButtonBorderColor                      [NSColor blackColor]
#define SNRButtonHighlightOverlayColor            [NSColor colorWithCalibratedWhite:0.000 alpha:0.300]

#define SNRButtonCheckboxTextOffset               3.f
#define SNRButtonCheckboxCheckmarkColor           [NSColor colorWithCalibratedWhite:0.780 alpha:1.000]
#define SNRButtonCheckboxCheckmarkLeftOffset      4.f
#define SNRButtonCheckboxCheckmarkTopOffset       1.f
#define SNRButtonCheckboxCheckmarkShadowOffset    NSMakeSize(0.f, 0.f)
#define SNRButtonCheckboxCheckmarkShadowBlurRadius 3.f
#define SNRButtonCheckboxCheckmarkShadowColor     [NSColor colorWithCalibratedWhite:0.000 alpha:0.750]
#define SNRButtonCheckboxCheckmarkLineWidth       2.f

- (id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return nil;
    }
    
    return self;
}

#pragma mark - Drawing

/*
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    [super drawWithFrame:cellFrame inView:controlView];
}
*/

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
    NSLog(@"Got frame %@", NSStringFromRect(frame));
    NSLog(@"Cell size: %@", NSStringFromSize([self cellSize]));
    [self slf_drawButtonBezelWithFrame:frame inView:controlView];
}

- (void)drawImage:(NSImage *)image withFrame:(NSRect)frame inView:(NSView *)controlView
{
    
}

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView
{
    BOOL blue = NO;//[self snr_shouldDrawBlueButton];
    NSString *label = [title string];
    NSShadow *textShadow = [NSShadow new];
    
    [textShadow setShadowOffset:blue ? SNRButtonBlueTextShadowOffset : SNRButtonBlackTextShadowOffset];
    [textShadow setShadowColor:blue ? SNRButtonBlueTextShadowColor : SNRButtonBlackTextShadowColor];
    [textShadow setShadowBlurRadius:blue ? SNRButtonBlueTextShadowBlurRadius : SNRButtonBlackTextShadowBlurRadius];
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:SNRButtonTextFont, NSFontAttributeName, SNRButtonTextColor, NSForegroundColorAttributeName, textShadow, NSShadowAttributeName, nil];
    NSAttributedString *attrLabel = [[NSAttributedString alloc] initWithString:label attributes:attributes];
    NSSize labelSize = [attrLabel size];
    NSRect labelRect = NSMakeRect(NSMidX(frame) - (labelSize.width / 2.f),
                                  NSMidY(frame) - (labelSize.height / 2.f),
                                  labelSize.width, labelSize.height);
    
    NSLog(@"Drawing label: %@ in %@", NSStringFromRect(labelRect), NSStringFromRect(frame));
    [attrLabel drawInRect:NSIntegralRect(labelRect)];
    return labelRect;
}

- (void)slf_drawButtonBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
    [[NSColor redColor] setFill];
    NSRectFill(frame);
    
    /*
    frame = NSInsetRect(frame, 0.5f, 0.5f);
    frame.size.height -= SNRButtonDropShadowBlurRadius;
    
    BOOL blue = NO;//[self snr_shouldDrawBlueButton];
    _bezelPath = [NSBezierPath bezierPathWithRoundedRect:frame xRadius:SNRButtonCornerRadius yRadius:SNRButtonCornerRadius];
    
    NSGradient *gradientFill = [[NSGradient alloc] initWithStartingColor:blue ? SNRButtonBlueGradientBottomColor : SNRButtonBlackGradientBottomColor endingColor:blue ? SNRButtonBlueGradientTopColor : SNRButtonBlackGradientTopColor];
    
    // Draw the gradient fill
    [gradientFill drawInBezierPath:_bezelPath angle:270.f];
    
    // Draw the border and drop shadow
    [NSGraphicsContext saveGraphicsState];
    [SNRButtonBorderColor set];
    
    NSShadow *dropShadow = [NSShadow new];
    [dropShadow setShadowColor:SNRButtonDropShadowColor];
    [dropShadow setShadowBlurRadius:SNRButtonDropShadowBlurRadius];
    [dropShadow setShadowOffset:SNRButtonDropShadowOffset];
    [dropShadow set];
    [_bezelPath stroke];
    
    [NSGraphicsContext restoreGraphicsState];
    
    // Draw the highlight line around the top edge of the pill
    // Outset the width of the rectangle by 0.5px so that the highlight "bleeds" around the rounded corners
    // Outset the height by 1px so that the line is drawn right below the border
    NSRect highlightRect = NSInsetRect(frame, -0.5f, 1.f);
    
    // Make the height of the highlight rect something bigger than the bounds so that it won't show up on the bottom
    highlightRect.size.height *= 2.f;
    
    [NSGraphicsContext saveGraphicsState];
    NSBezierPath *highlightPath = [NSBezierPath bezierPathWithRoundedRect:highlightRect xRadius:SNRButtonCornerRadius yRadius:SNRButtonCornerRadius];
    
    //[_bezelPath addClip];
    [[NSColor redColor] set];
    [_bezelPath stroke];
    NSLog(@"bounds: %@", NSStringFromRect([_bezelPath bounds]));
    
    [blue ? SNRButtonBlueHighlightColor : SNRButtonBlackHighlightColor set];
    [highlightPath stroke];
    
    [NSGraphicsContext restoreGraphicsState];
     */
}

#pragma mark - Hit testing

- (NSUInteger)hitTestForEvent:(NSEvent *)event
                       inRect:(NSRect)cellFrame
                       ofView:(NSView *)controlView
{
    NSPoint locationInView = [controlView convertPoint:[event locationInWindow] fromView:nil];
    NSLog(@"Hit at %@ in %@", NSStringFromPoint(locationInView), NSStringFromRect(cellFrame));
    
    return [super hitTestForEvent:event inRect:cellFrame ofView:controlView];
}
@end
