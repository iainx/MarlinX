//
//  MLNAddSilenceWindowController.m
//  Marlin
//
//  Created by iain on 09/02/2014.
//  Copyright (c) 2014 iain. All rights reserved.
//

#import "MLNAddSilenceWindowController.h"

@interface MLNAddSilenceWindowController ()

@end

@implementation MLNAddSilenceWindowController

- (id)init
{
    self = [super initWithWindowNibName:@"MLNAddSilenceWindowController" owner:self];
    if (!self) {
        return nil;
    }
    
    _duration = 44100;
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    [_durationStepper setMinValue:1.0];
    [_durationStepper setIncrement:1.0];
}

- (IBAction)insertSilence:(id)sender
{
    _didCloseBlock(_duration);
}

- (IBAction)cancel:(id)sender
{
    _didCloseBlock(0);
}
@end
