//
//  SLFDocument.h
//  Marlin
//
//  Created by iain on 29/01/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MLNSampleView;

@interface MLNDocument : NSDocument

@property (readwrite, weak) IBOutlet NSToolbar *toolbar;
@property (readwrite, weak) IBOutlet NSScrollView *scrollView;
@property (readwrite, weak) IBOutlet MLNSampleView *sampleView;

- (IBAction)playSample:(id)sender;
- (IBAction)stopSample:(id)sender;
- (IBAction)showInformation:(id)sender;

@end
