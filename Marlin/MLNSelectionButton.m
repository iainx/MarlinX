//
//  MLNSelectionButton.m
//  Marlin
//
//  Created by iain on 05/04/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNSelectionButton.h"
#import "MLNSelectionAction.h"

@implementation MLNSelectionButton {
    MLNSelectionAction *_selectionAction;
}

- (id)initWithAction:(MLNSelectionAction *)selectionAction
{
    self = [super initWithFrame:NSZeroRect];
    if (!self) {
        return nil;
    }
    
    _selectionAction = selectionAction;
    [self setAction:@selector(invokeSelectionAction:)];
    [self setTarget:self];
    
    [self setToolTip:[_selectionAction name]];
    
    [self setContentCompressionResistancePriority:NSLayoutPriorityRequired
                                   forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self setContentCompressionResistancePriority:NSLayoutPriorityRequired
                                   forOrientation:NSLayoutConstraintOrientationVertical];
    [self setContentHuggingPriority:NSLayoutPriorityRequired
                     forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self setContentHuggingPriority:NSLayoutPriorityRequired
                     forOrientation:NSLayoutConstraintOrientationVertical];
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{

    [[NSColor orangeColor] setFill];
    NSRectFill(dirtyRect);
}

- (NSSize)intrinsicContentSize
{
    return NSMakeSize(20, 20);
}

- (void)invokeSelectionAction:(id)sender
{
    NSInvocation *invocation = [_selectionAction invocation];
    [invocation invoke];
    
    DDLogVerbose(@"Button clicked");
}

@end
