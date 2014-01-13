//
//  MLNInfoPane.m
//  Marlin
//
//  Created by iain on 10/01/2014.
//  Copyright (c) 2014 iain. All rights reserved.
//

#import "MLNInfoPane.h"

@implementation MLNInfoPane

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
    [[NSColor underPageBackgroundColor] setFill];
    NSRectFill(dirtyRect);
}

@end
