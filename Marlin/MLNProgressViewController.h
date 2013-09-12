//
//  MLNProgressViewController.h
//  Marlin
//
//  Created by iain on 12/09/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MLNProgressViewController : NSViewController

@property (readwrite, weak) IBOutlet NSTextField *primaryLabel;
@property (readwrite, weak) IBOutlet NSTextField *secondaryLabel;
@property (readwrite, weak) IBOutlet NSProgressIndicator *progressIndicator;

@end
