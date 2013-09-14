//
//  MLNSelectionToolbar.m
//  Marlin
//
//  Created by iain on 06/04/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNSelectionToolbar.h"

@implementation MLNSelectionToolbar {
    NSArray *_constraints;
    NSBezierPath *_borderPath;
}

@synthesize horizontal = _horizontal;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    _horizontal = YES;
    [self setContentCompressionResistancePriority:NSLayoutPriorityRequired
                                   forOrientation:NSLayoutConstraintOrientationHorizontal];
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSColor *bgColor = [NSColor colorWithCalibratedRed:0.687 green:0.687 blue:1.0 alpha:1.0];
    [bgColor set];
    [_borderPath fill];
    [[NSColor blackColor] set];
    [_borderPath stroke];
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    
    NSRect borderRect = NSInsetRect([self bounds], 0.5, 0.5);
    _borderPath = [NSBezierPath bezierPathWithRoundedRect:borderRect
                                                  xRadius:5.0 yRadius:5.0];
}
#pragma mark - Constraints

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

#define TOOLBAR_PADDING 5.0
#define TOOLBAR_SPACING 2.0

- (NSSize)intrinsicContentSize
{
    NSArray *subviews = [self subviews];
    
    CGFloat width, height;
    
    for (NSView *subview in subviews) {
        NSSize ics = [subview intrinsicContentSize];
        
        if (_horizontal) {
            width += ics.width;
            height = MAX (height, ics.height);
        } else {
            width = MAX (width, ics.width);
            height += ics.height;
        }
    }
    
    if (_horizontal) {
        width += (TOOLBAR_PADDING * 2) + (TOOLBAR_SPACING * ([subviews count] - 1));
        height += (TOOLBAR_PADDING * 2);
    } else {
        width += (TOOLBAR_PADDING * 2);
        height += (TOOLBAR_PADDING * 2) + (TOOLBAR_SPACING * ([subviews count] - 1));
    }
    return NSMakeSize(width, height);
}

- (NSString *)visualFormat:(NSString *)visualFormat
       isVerticalByDefault:(BOOL)inverted
{
    char orientation;
    
    if (inverted) {
        orientation = [self isHorizontal] ? 'V':'H';
    } else {
        orientation = [self isHorizontal] ? 'H':'V';
    }
    return [NSString stringWithFormat:@"%c:%@", orientation, visualFormat];
}

- (void)updateConstraints
{
    NSDictionary *metrics = @{@"toolbarPadding": [NSNumber numberWithFloat:TOOLBAR_PADDING],
                              @"toolbarSpacing": [NSNumber numberWithFloat:TOOLBAR_SPACING]};
    [super updateConstraints];
    
    if (_constraints == nil) {
        NSMutableArray *constraints = [NSMutableArray array];
        NSMutableDictionary *viewsDict = [NSMutableDictionary dictionary];
        
        NSView *previousView = nil;
        NSString *vf;
        
        for (NSView *currentView in [self subviews]) {
            viewsDict[@"currentView"] = currentView;
            
            if (previousView == nil) {
                vf = [self visualFormat:@"|-toolbarPadding-[currentView]" isVerticalByDefault:NO];
                NSArray *c = [NSLayoutConstraint constraintsWithVisualFormat:vf
                                                                     options:0
                                                                     metrics:metrics
                                                                       views:viewsDict];
                [constraints addObjectsFromArray:c];
            } else {
                viewsDict[@"previousView"] = previousView;
                vf = [self visualFormat:@"[previousView]-toolbarSpacing-[currentView]" isVerticalByDefault:NO];
                NSArray *c = [NSLayoutConstraint constraintsWithVisualFormat:vf
                                                                     options:0
                                                                     metrics:metrics
                                                                       views:viewsDict];
                [constraints addObjectsFromArray:c];
            }
            
            vf = [self visualFormat:@"|-toolbarPadding-[currentView]-toolbarPadding-|" isVerticalByDefault:YES];
            [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:vf
                                                                                     options:0
                                                                                     metrics:metrics
                                                                                       views:viewsDict]];
            
            previousView = currentView;
        }
        
        if ([[self subviews] count] > 0) {
            vf = [self visualFormat:@"[currentView]-toolbarPadding-|" isVerticalByDefault:NO];
            [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:vf
                                                                                     options:0
                                                                                     metrics:metrics
                                                                                       views:viewsDict]];
        }
        
        [self setUpdateConstraints:constraints];
    }
}

- (void)setUpdateConstraints:(NSArray *)newConstraints
{
    if (newConstraints != _constraints) {
        if (_constraints) {
            [self removeConstraints:_constraints];
        }
        _constraints = newConstraints;
        
        if (_constraints) {
            [self addConstraints:_constraints];
        } else {
            [self setNeedsUpdateConstraints:YES];
        }
    }
}

#pragma mark - Subviews

- (void)didAddSubview:(NSView *)subview
{
    [subview setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self setUpdateConstraints:nil];
    
    [super didAddSubview:subview];
}

- (void)willRemoveSubview:(NSView *)subview
{
    [super willRemoveSubview:subview];
    [self setUpdateConstraints:nil];
}

#pragma mark - Accessors

- (void)setHorizontal:(BOOL)horizontal
{
    if (_horizontal == horizontal) {
        return;
    }
    
    _horizontal = horizontal;
    
    // Invalidate the constraints
    [self invalidateIntrinsicContentSize];
    [self setUpdateConstraints:nil];
}

- (BOOL)isHorizontal
{
    return _horizontal;
}

@end
