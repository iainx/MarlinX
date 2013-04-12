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
    MLNSelectionAction *_action;
}

- (id)initWithAction:(MLNSelectionAction *)action
{
    self = [super initWithFrame:NSZeroRect];
    if (!self) {
        return nil;
    }
    
    _action = action;
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor blueColor] setFill];
    NSRectFill(dirtyRect);
}

- (NSSize)intrinsicContentSize
{
    return NSMakeSize(20, 20);
}

@end
