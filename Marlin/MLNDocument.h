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
#import "MLNTransportControlsViewDelegate.h"

@class MLNSampleView;
@class MLNOverviewBar;
@class MLNTransportControlsView;

@interface MLNDocument : NSDocument <MLNExportPanelControllerDelegate, MLNSampleViewDelegate, MLNOverviewBarDelegate, MLNSampleDelegate, MLNTransportControlsViewDelegate, NSWindowDelegate>

@property (readwrite, weak) IBOutlet NSToolbar *toolbar;
@property (readwrite, weak) IBOutlet MLNTransportControlsView *transportControlsView;
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

- (IBAction)crop:(id)sender;
- (IBAction)clearSelection:(id)sender;
- (IBAction)reverseSelection:(id)sender;

- (IBAction)showInformation:(id)sender;

- (IBAction)dumpSelectionData:(id)sender;
@end
