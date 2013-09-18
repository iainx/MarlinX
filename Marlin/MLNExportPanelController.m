//
//  MLNExportWindowController.m
//  Marlin
//
//  Created by iain on 16/09/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNExportPanelController.h"

@implementation MLNExportPanelController

- (id)init
{
    self = [super initWithWindowNibName:@"MLNExportPanelController"];
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)cancelSheet:(id)sender
{
    [_delegate exportPanelControllerCancelled:self];
}

- (IBAction)selectFormat:(id)sender
{
    NSDictionary *formatDetails = @{@"type": @"MP3"};
    [_delegate exportPanelController:self didSelectFormat:formatDetails];
}
@end
