//
//  SLFDocument.h
//  Marlin
//
//  Created by iain on 29/01/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MLNSampleViewDelegate.h"

@class MLNSampleView;
@class MLNOverviewBar;

@interface MLNDocument : NSDocument <MLNSampleViewDelegate>

@property (readwrite, weak) IBOutlet NSToolbar *toolbar;
@property (readwrite, strong) NSScrollView *scrollView;
@property (readwrite, strong) MLNSampleView *sampleView;
@property (readwrite, strong) MLNOverviewBar *overviewBarView;

- (IBAction)playSample:(id)sender;
- (IBAction)stopSample:(id)sender;
- (IBAction)showInformation:(id)sender;

@end
