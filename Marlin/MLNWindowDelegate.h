//
//  MLNWindowDelegate.h
//  Marlin
//
//  Created by iain on 24/01/2014.
//  Copyright (c) 2014 iain. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NSWindow;

@protocol MLNWindowDelegate <NSWindowDelegate>

- (void)windowDidRequestTogglePlay:(NSWindow *)window;
- (void)windowDidRequestReturnToStart:(NSWindow *)window;

@end
