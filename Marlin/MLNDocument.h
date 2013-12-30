//
//  SLFDocument.h
//  Marlin
//
//  Created by iain on 29/01/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MLNExportPanelControllerDelegate.h"
#import "MLNSampleDelegate.h"
#import "MLNSampleViewDelegate.h"
#import "MLNOverviewBarDelegate.h"

@class MLNSampleView;
@class MLNOverviewBar;

@interface MLNDocument : NSDocument <MLNExportPanelControllerDelegate, MLNSampleViewDelegate, MLNOverviewBarDelegate, MLNSampleDelegate, NSWindowDelegate>

@property (readwrite, weak) IBOutlet NSToolbar *toolbar;
@property (readwrite, strong) NSScrollView *scrollView;
@property (readwrite, strong) MLNSampleView *sampleView;
@property (readwrite, strong) MLNOverviewBar *overviewBarView;
@property (readwrite, strong) NSFileWrapper *documentFileWrapper;

- (IBAction)exportDocumentAs:(id)sender;
- (IBAction)selectAll:(id)sender;
- (IBAction)selectNone:(id)sender;
- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;
- (IBAction)zoomToFit:(id)sender;
- (IBAction)zoomToNormal:(id)sender;

- (IBAction)playSample:(id)sender;
- (IBAction)stopSample:(id)sender;

- (IBAction)crop:(id)sender;
- (IBAction)clearSelection:(id)sender;
- (IBAction)reverseSelection:(id)sender;

- (IBAction)showInformation:(id)sender;

- (IBAction)dumpSelectionData:(id)sender;
@end
