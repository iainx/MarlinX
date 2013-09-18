//
//  MLNExportWindowController.h
//  Marlin
//
//  Created by iain on 16/09/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MLNExportPanelControllerDelegate.h"

@interface MLNExportPanelController : NSWindowController

@property (readwrite, weak) id<MLNExportPanelControllerDelegate> delegate;

- (IBAction)cancelSheet:(id)sender;
- (IBAction)selectFormat:(id)sender;

@end
