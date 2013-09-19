//
//  MLNExportableTypeView.m
//  Marlin
//
//  Created by iain on 19/09/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNExportableTypeView.h"

@implementation MLNExportableTypeView

@synthesize selected = _selected;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    DDLogVerbose(@"Draw rect %@", NSStringFromRect([self bounds]));
    if (_selected) {
        DDLogVerbose(@"Draw selection %@", NSStringFromRect([self bounds]));
        [[NSColor selectedControlColor] set];
        NSRectFill(dirtyRect);
    }
}

- (BOOL)selected
{
    return _selected;
}

- (void)setSelected:(BOOL)selected
{
    DDLogVerbose(@"Selected: %@", selected ? @"YES" : @"NO");
    
    if (_selected == selected) {
        return;
    }
    
    DDLogVerbose(@"Redrawing");
    _selected = selected;
    [self setNeedsDisplay:YES];
}

@end
