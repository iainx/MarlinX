//
//  SLFAppDelegate.m
//  kyle-test
//
//  Created by iain on 17/03/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "SLFAppDelegate.h"

@implementation SLFAppDelegate {
    NSButton *_button;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    _button = [[NSButton alloc] initWithFrame:NSZeroRect];
    [_button setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_button setTitle:@"Hello World!"];
    
    [[_window contentView] addSubview:_button];
    
    NSDictionary *viewsDict = NSDictionaryOfVariableBindings(_button);

    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[_button(>=70)]"
                                                          options:0
                                                          metrics:nil
                                                            views:viewsDict];
    [[_window contentView] addConstraints:constraints];

    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[_button(==120)]"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:viewsDict];
    [[_window contentView] addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[_button]-|"
                                                          options:0
                                                          metrics:nil
                                                            views:viewsDict];
    [[_window contentView] addConstraints:constraints];
}

@end
