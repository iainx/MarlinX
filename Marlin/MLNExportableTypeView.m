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
    if (_selected) {
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
    if (_selected == selected) {
        return;
    }
    
    _selected = selected;
    [self setNeedsDisplay:YES];
}

@end
