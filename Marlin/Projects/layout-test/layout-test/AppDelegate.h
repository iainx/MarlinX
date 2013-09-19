//
//  AppDelegate.h
//  layout-test
//
//  Created by iain on 22/09/2012.
//  Copyright (c) 2012 iain. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSButton *button;

- (IBAction)hideButton:(id)sender;

@end
