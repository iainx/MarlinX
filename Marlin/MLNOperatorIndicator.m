//
//  MLNOperatorIndicator.m
//  Marlin
//
//  Created by iain on 13/12/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNOperatorIndicator.h"

@implementation MLNOperatorIndicator {
    NSTextField *_labelField;
}

- (id)initWithLabel:(NSString *)label
{
    self = [super initWithFrame:NSZeroRect];
    if (!self) {
        return nil;
    }
    
    [self setWantsLayer:YES];
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationVertical];
    
    _labelField = [[NSTextField alloc] initWithFrame:NSZeroRect];
    [_labelField setEditable:NO];
    [_labelField setDrawsBackground:NO];
    [_labelField setBezeled:NO];
    [_labelField setStringValue:label];
    [_labelField setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_labelField setTextColor:[NSColor lightGrayColor]];
    NSFont *font = [NSFont systemFontOfSize:17.0];
    [_labelField setFont:font];
    
    [self addSubview:_labelField];
    
    NSDictionary *viewsDict = @{@"labelField" : _labelField};
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-[labelField]-|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:viewsDict];
    [self addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[labelField]-5-|"
                                                          options:0
                                                          metrics:nil
                                                            views:viewsDict];
    [self addConstraints:constraints];
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect bounds = [self bounds];
	[super drawRect:dirtyRect];
	
    [[NSColor clearColor] set];
    NSRectFillUsingOperation(bounds, NSCompositeSourceOver);
    
    [[NSColor colorWithCalibratedWhite:0.1 alpha:0.78] setFill];
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:bounds xRadius:5.0 yRadius:5.0];
    [path fill];
}

- (BOOL)isOpaque
{
    return NO;
}

@end
