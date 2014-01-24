//
//  MLNWindow.m
//  Marlin
//
//  Created by iain on 24/01/2014.
//  Copyright (c) 2014 iain. All rights reserved.
//

#import "MLNWindow.h"

@implementation MLNWindow

@dynamic delegate;

// Handle some global key commands
- (void)keyDown:(NSEvent *)theEvent
{
    NSString *characters = [theEvent charactersIgnoringModifiers];
    unichar keycode = [characters characterAtIndex:0];
    
    if (keycode == ' ') {
        [_delegate windowDidRequestTogglePlay:self];
        return;
    }
    
    if (keycode == '\r') {
        [_delegate windowDidRequestReturnToStart:self];
        return;
    }
    
    [super keyDown:theEvent];
}
@end
