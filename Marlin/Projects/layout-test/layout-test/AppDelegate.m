//
//  AppDelegate.m
//  layout-test
//
//  Created by iain on 22/09/2012.
//  Copyright (c) 2012 iain. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (IBAction)hideButton:(id)sender
{
    //[_button setFrameSize:NSMakeSize(10, [_button frame].size.height)];
    NSRect oldFrame = [_button frame];
    oldFrame.size.width = 50;
    
    [_button setFrame:oldFrame];
}
@end
