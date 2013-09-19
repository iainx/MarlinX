//
//  AppDelegate.m
//  ButtonTest
//
//  Created by iain on 19/10/2012.
//  Copyright (c) 2012 iain. All rights reserved.
//

#import "AppDelegate.h"
#import "SLFButton.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    SLFButton *button = [[SLFButton alloc] initWithFrame:NSMakeRect(30.0, 30.0, 100.0, 22.0)];
    [button setTitle:@"Test Button"];
    
    [[_window contentView] addSubview:button];
}

@end
