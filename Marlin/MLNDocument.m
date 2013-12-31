//
//  SLFDocument.m
//  Marlin
//
//  Created by iain on 29/01/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "MLNDocument.h"
#import "MLNApplicationDelegate.h"
#import "MLNOverviewBar.h"
#import "MLNPasteboardSampleData.h"
#import "MLNLoadOperation.h"
#import "MLNSample.h"
#import "MLNSample+Operations.h"
#import "MLNSampleView.h"
#import "MLNSelectionAction.h"
#import "MLNProgressViewController.h"
#import "MLNExportPanelController.h"
#import "MLNOperatorIndicator.h"
#import "MLNMarker.h"
#import "Constants.h"

@implementation MLNDocument {
    MLNProgressViewController *_progressViewController;
    NSView *_progressView;
    MLNSample *_sample;
    
    NSWindowController *_currentSheetController;
    NSWindow *_currentSheet;
    
    MLNOperatorIndicator *_indicator;
    NSTimer *_indicatorTimer;
}

+ (NSArray *)readableTypes
{
    UInt32 size;
    NSMutableArray *types;
    NSArray *all;
    OSStatus err;
    
    err = AudioFileGetGlobalInfoSize(kAudioFileGlobalInfo_AllUTIs, 0, NULL, &size);
    if (err == noErr)
        err = AudioFileGetGlobalInfo(kAudioFileGlobalInfo_AllUTIs, 0, NULL, &size, &all);
    
    if (err == noErr)
        NSLog(@"UTIs: %@", all);
    
    types = [NSMutableArray arrayWithArray:all];
    [types addObject:@"com.sleepfive.marlin"];
    return types;
}

+ (NSArray *)writableTypes
{
    return @[@"com.sleepfive.marlin"];
}

+ (BOOL)isNativeType:(NSString *)type
{
    return [type isEqualToString:@"com.sleepfive.marlin"];
}

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MLNDocument";
}

static void *sampleContext = &sampleContext;
static void *sampleViewContext = &sampleViewContext;

- (NSWindow*)documentWindow
{
    if([[self windowControllers] count] == 1)
    {
        return [[[self windowControllers] objectAtIndex:0] window];
    }
    return nil;
}

- (NSRange)boundsToVisibleSampleRange:(NSRect)bounds
{
    NSRect scaledBounds = [_sampleView convertRectToBacking:bounds];
    
    if (scaledBounds.origin.x < 0) {
        scaledBounds.size.width += (scaledBounds.origin.x);
        scaledBounds.origin.x = 0;
    }
    NSRange visibleRange = NSMakeRange(scaledBounds.origin.x * [_sampleView framesPerPixel],
                                       scaledBounds.size.width * [_sampleView framesPerPixel]);
    return visibleRange;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context != sampleContext && context != sampleViewContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
    if ([keyPath isEqualToString:@"loaded"]) {
        [_toolbar validateVisibleItems];
        
        NSRange visibleRange = [self boundsToVisibleSampleRange:[[_scrollView contentView] bounds]];
        [_overviewBarView setVisibleRange:visibleRange];
        
        return;
    }
    
    if ([keyPath isEqualToString:@"framesPerPixel"]) {
        NSRange visibleRange = [self boundsToVisibleSampleRange:[[_scrollView contentView] bounds]];
        [_overviewBarView setVisibleRange:visibleRange];
        return;
    }
    
    if ([keyPath isEqualToString:@"visibleRange"]) {
        [_overviewBarView setVisibleRange:[_sampleView visibleRange]];
    }
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    
    _overviewBarView = [[MLNOverviewBar alloc] initWithFrame:NSZeroRect];
    [_overviewBarView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_overviewBarView setDelegate:self];
    
    _progressViewController = [[MLNProgressViewController alloc] init];
    _progressView = [_progressViewController view];
    
    _scrollView = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    [_scrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    _sampleView = [[MLNSampleView alloc] initWithFrame:NSZeroRect];
    [_sampleView setDelegate:self];
    
    NSWindow *window = [aController window];
    [window setDelegate:self];
    
    [[window contentView] addSubview:_overviewBarView];
    [[window contentView] addSubview:_scrollView];
    [[window contentView] addSubview:_progressView];
    
    NSDictionary *viewsDict = @{@"overviewBarView": _overviewBarView,
                                @"scrollView": _scrollView,
                                @"sampleView": _sampleView,
                                @"progressView": _progressView};
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[overviewBarView][scrollView]-40-|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:viewsDict];
    [[window contentView] addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|[overviewBarView]|"
                                                          options:0
                                                          metrics:nil
                                                            views:viewsDict];
    [[window contentView] addConstraints:constraints];

    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|[progressView]|"
                                                          options:0
                                                          metrics:nil
                                                            views:viewsDict];
    [[window contentView] addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[progressView]-40-|"
                                                          options:0
                                                          metrics:nil
                                                            views:viewsDict];
    [[window contentView] addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|[scrollView]|"
                                                          options:0
                                                          metrics:nil
                                                            views:viewsDict];
    [[window contentView] addConstraints:constraints];
    
    [_sampleView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [_sample addObserver:self
              forKeyPath:@"loaded"
                 options:0
                 context:sampleContext];
    
    MLNOperation *operation = [_sample currentOperation];
    [_progressViewController setRepresentedObject:operation];
    
    [_overviewBarView setSample:_sample];
    [_sampleView setSample:_sample];
    
    [_sampleView addObserver:self
                  forKeyPath:@"visibleRange"
                     options:NSKeyValueObservingOptionNew
                     context:sampleViewContext];

    [_scrollView setHasHorizontalScroller:YES];
    [_scrollView setScrollerKnobStyle:NSScrollerKnobStyleLight];
    //[_scrollView setVerticalScrollElasticity:NSScrollElasticityAllowed];
    
    // FIXME: Only on 10.8
    [_scrollView setBackgroundColor:[NSColor underPageBackgroundColor]];
    
    //[_scrollView setHasHorizontalRuler:YES];
    //[_scrollView setRulersVisible:YES];
    
    [_scrollView setDocumentView:_sampleView];
    
    NSClipView *clipView = [_scrollView contentView];
    //[clipView setCopiesOnScroll:NO];
    
    // Set up the clipview so that the sampleView fills the whole of it vertically
    [clipView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[sampleView]|" options:0 metrics:nil views:viewsDict]];
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (BOOL)canAsynchronouslyWriteToURL:(NSURL *)URL
                             ofType:(NSString *)type
                   forSaveOperation:(NSSaveOperationType)op
{
    return YES;
}

- (BOOL)readFromURL:(NSURL *)url
             ofType:(NSString *)typeName
              error:(NSError *__autoreleasing *)outError
{
    DDLogInfo(@"Opening %@, %@", url, typeName);

    _sample = [[MLNSample alloc] init];
    [_sample setDelegate:self];

    if ([typeName isEqualToString:@"com.sleepfive.marlin"]) {
        [_sample startLoadFromURL:url];
    } else {
        
        [_sample startImportFromURL:url];
        
        [self setFileType:@"com.sleepfive.marlin"];
        [self setFileURL:nil];
        
        NSArray *filenameParts = [[url lastPathComponent] componentsSeparatedByString:@"."];
        [self setDisplayName:filenameParts[0]];
        
    }
    return YES;
}

- (void)saveToURL:(NSURL *)url
           ofType:(NSString *)typeName
 forSaveOperation:(NSSaveOperationType)saveOperation
completionHandler:(void (^)(NSError *))completionHandler
{
    id token = [self changeCountTokenForSaveOperation:saveOperation];
    
    DDLogInfo(@"saveToURL:%@ ofType:%@", [url absoluteString], typeName);
    
    [_sample startWriteToURL:url completionHandler:completionHandler];
    [self unblockUserInteraction];
    
    [self updateChangeCountWithToken:token forSaveOperation:saveOperation];
}

- (void)didEndExportSheet:(NSWindow *)sheet
               returnCode:(NSInteger)returnCode
              contextInfo:(void *)contextInfo
{
    [_currentSheet orderOut:self];
    _currentSheet = nil;
    _currentSheetController = nil;
}

- (void)exportPanelController:(MLNExportPanelController *)controller
              didSelectFormat:(NSDictionary *)formatDetails
{
    [NSApp endSheet:_currentSheet];
    
    if (_currentSheet != nil) {
        DDLogError(@"_currentSheet is not nil");
    }
    
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel beginSheetModalForWindow:[self documentWindow] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelCancelButton) {
            return;
        } else {
            DDLogVerbose(@"%@ - %@", [savePanel URL], formatDetails);
            
            [_sample startExportTo:[savePanel URL] asFormat:formatDetails];
        }
    }];
}

- (void)exportPanelControllerCancelled:(MLNExportPanelController *)controller
{
    [NSApp endSheet:_currentSheet];
}

- (IBAction)exportDocumentAs:(id)sender
{
    _currentSheetController = [[MLNExportPanelController alloc] init];
    [(MLNExportPanelController *)_currentSheetController setDelegate:self];
    
    _currentSheet = [_currentSheetController window];
    
    [NSApp beginSheet:_currentSheet
       modalForWindow:[self documentWindow]
        modalDelegate:self
       didEndSelector:@selector(didEndExportSheet:returnCode:contextInfo:)
          contextInfo:NULL];
}
#pragma mark - Menu & Toolbar actions

- (void)playSample:(id)sender
{
    [_sample play];
}

- (void)stopSample:(id)sender
{
    [_sample stop];
}

- (void)delete:(id)sender
{
    NSRange selection = [_sampleView selection];
    DDLogVerbose(@"Delete selected range: %@", NSStringFromRange(selection));
    
    NSUndoManager *undoManager = [self undoManager];
    [undoManager setActionName:@"Delete Range"];
    
    [_sample deleteRange:selection undoManager:undoManager];
    
    [_sampleView clearSelection];
    
    [self displayIndicatorForOperationName:@"Delete Range"];
}

- (IBAction)crop:(id)sender
{
    NSRange selection = [_sampleView selection];
    
    NSUndoManager *undoManager = [self undoManager];
    [undoManager setActionName:@"Crop Range"];
    
    [_sample cropRange:selection withUndoManager:undoManager];
    [_sampleView clearSelection];
    
    [self displayIndicatorForOperationName:@"Crop Range"];
}

- (IBAction)showInformation:(id)sender
{
    
}

- (void)copy:(id)sender
{
    NSRange selection = [_sampleView selection];
    
    NSArray *copyChannels = [_sample copyRange:selection withError:nil];
    MLNApplicationDelegate *appDelegate = [NSApp delegate];

    MLNPasteboardSampleData *content = [[MLNPasteboardSampleData alloc] initWithContent:copyChannels
                                                                             sampleRate:[_sample sampleRate]];
    [appDelegate setClipboardContent:content];
    
    [self displayIndicatorForOperationName:@"Copy"];
}

- (void)cut:(id)sender
{
    NSRange selection = [_sampleView selection];

    NSArray *copyChannels = [_sample copyRange:selection withError:nil];
    MLNApplicationDelegate *appDelegate = [NSApp delegate];
    
    MLNPasteboardSampleData *content = [[MLNPasteboardSampleData alloc] initWithContent:copyChannels
                                                                             sampleRate:[_sample sampleRate]];
    [appDelegate setClipboardContent:content];

    NSUndoManager *undoManager = [self undoManager];
    
    [undoManager setActionName:@"Cut"];
    [_sample deleteRange:selection undoManager:undoManager];
    [_sampleView clearSelection];
    
    [self displayIndicatorForOperationName:@"Cut"];
}

- (void)paste:(id)sender
{
    MLNApplicationDelegate *appDelegate = [NSApp delegate];
    
    MLNPasteboardSampleData *content = [appDelegate clipboardContent];
    
    NSUndoManager *undoManager = [self undoManager];
    [undoManager setActionName:@"Paste"];
    
    [_sample insertChannels:[content channels] atFrame:[_sampleView cursorFramePosition] withUndoManager:undoManager];
    
    [self displayIndicatorForOperationName:@"Paste"];
}

- (void)clearSelection:(id)sender
{
    NSUndoManager *undoManager = [self undoManager];
    
    [undoManager setActionName:@"Clear Selection"];
    [_sample clearRange:[_sampleView selection] withUndoManager:undoManager];
    
    [self displayIndicatorForOperationName:@"Clear Selection"];
}

- (IBAction)selectAll:(id)sender
{
    [_sampleView selectAll];
    [self displayIndicatorForOperationName:@"Select All"];
}

- (IBAction)selectNone:(id)sender
{
    [_sampleView clearSelection];
    [self displayIndicatorForOperationName:@"Select None"];
}

- (IBAction)zoomIn:(id)sender
{
    [_sampleView zoomIn];
    [self displayIndicatorForOperationName:@"Zoom In"];
}

- (IBAction)zoomOut:(id)sender
{
    [_sampleView zoomOut];
    [self displayIndicatorForOperationName:@"Zoom Out"];
}

- (IBAction)zoomToFit:(id)sender
{
    [_sampleView zoomToFit];
    [self displayIndicatorForOperationName:@"Zoom To Fit"];
}

- (IBAction)zoomToNormal:(id)sender
{
    [_sampleView zoomToNormal];
    [self displayIndicatorForOperationName:@"Zoom To Normal"];
}

- (IBAction)dumpSelectionData:(id)sender
{
    [_sample dumpDataInRange:[_sampleView selection]];
}

- (IBAction)addMarker:(id)sender
{
    MLNMarker *newMarker = [[MLNMarker alloc] init];
    [newMarker setName:@"New"];
    [newMarker setFrame:[NSNumber numberWithUnsignedInteger:[_sampleView cursorFramePosition]]];
    
    NSUndoManager *undoManager = [self undoManager];
    [undoManager setActionName:@"Add Marker"];
    [_sample addMarker:newMarker undoManager:undoManager];
    
    [self displayIndicatorForOperationName:@"Add Marker"];
}

- (IBAction)reverseSelection:(id)sender
{
    [_sample reverseRange:[_sampleView selection] withUndoManager:[self undoManager]];
}

#pragma mark - Indicator

- (void)displayIndicatorForOperationName:(NSString *)name
{
    NSWindow *window = [[[self windowControllers] objectAtIndex:0] window];
    NSView *parentView = [window contentView];
    
    if (_indicator) {
        [_indicatorTimer invalidate];
        _indicatorTimer = nil;
        [_indicator removeFromSuperview];
        _indicator = nil;
    }
    
    _indicator = [[MLNOperatorIndicator alloc] initWithLabel:name];
    [parentView addSubview:_indicator];
    
    [parentView addConstraint:[NSLayoutConstraint constraintWithItem:_indicator
                                                            attribute:NSLayoutAttributeCenterX
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:_scrollView
                                                            attribute:NSLayoutAttributeCenterX
                                                           multiplier:1.0 constant:0]];
    [parentView addConstraint:[NSLayoutConstraint constraintWithItem:_indicator
                                                           attribute:NSLayoutAttributeCenterY
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:_scrollView
                                                           attribute:NSLayoutAttributeCenterY
                                                          multiplier:1.0
                                                            constant:0.0]];
    _indicatorTimer = [NSTimer scheduledTimerWithTimeInterval:0.75
                                                       target:self
                                                     selector:@selector(fadeOutIndicatorFromTimer:)
                                                     userInfo:nil
                                                      repeats:NO];
}

- (void)fadeOutIndicatorFromTimer:(NSTimer *)timer
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setCompletionHandler:^{
        [_indicator removeFromSuperview];
        _indicator = nil;
    }];
    [[_indicator animator] setAlphaValue:0.0];
    [NSAnimationContext endGrouping];
    
    [timer invalidate];
}

#pragma mark - Validators

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    SEL action = [menuItem action];
    if (action == @selector(delete:)
        || action == @selector(crop:)
        || action == @selector(copy:)
        || action == @selector(cut:)) {
        return [_sampleView hasSelection];
    }
    
    if (action == @selector(paste:)) {
        MLNApplicationDelegate *appDelegate = [NSApp delegate];
        MLNPasteboardSampleData *content = [appDelegate clipboardContent];
        
        if (content) {
            if ([_sample canInsertChannels:[content channels] sampleRate:[content sampleRate]]) {
                return YES;
            }
        }
        
        return NO;
    }
    
    if (action == @selector(clearSelection:)) {
        return [_sampleView hasSelection];
    }
    
    if (action == @selector(selectAll:)) {
        return YES;
    }
    
    if (action == @selector(selectNone:)) {
        return [_sampleView hasSelection];
    }
    
    if (action == @selector(zoomToFit:)) {
        if ([_sampleView hasSelection]) {
            [menuItem setTitle:@"Zoom To Selection"];
        } else {
            [menuItem setTitle:@"Zoom To Fit"];
        }
        
        return YES;
    }
    
    // These are not implemented yet
    /*
    if (action == @selector(revertDocumentToSaved:)
        || action == @selector(saveDocument:)) {
        return NO;
    }
    */
    return YES;
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    BOOL valid = NO;
    
    if ([theItem action] == @selector(showInformation:)) {
        valid = [_sample isLoaded];
    }
    
    return valid;
}

#pragma mark - Sample delegate
- (void)sample:(MLNSample *)sample operationDidStart:(MLNOperation *)operation
{
    DDLogVerbose(@"Operation started");
    
    [_progressView setHidden:NO];
    [_progressViewController setRepresentedObject:operation];
    
    [_sampleView setHidden:YES];
}

- (void)sample:(MLNSample *)sample operationDidEnd:(MLNOperation *)operation
{
    DDLogVerbose(@"Operation ended");
    
    [_progressView setHidden:YES];
    [_sampleView setHidden:NO];
}

- (void)sample:(MLNSample *)sample operationError:(NSError *)error
{
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert runModal];
}

#pragma mark - Sample View delegate
- (void)sampleView:(MLNSampleView *)sampleView
selectionDidChange:(NSRange)selection
{
    [_overviewBarView setSelection:selection];
}

- (void)testAction:(id)action
{
    DDLogVerbose(@"Invoked test action");
}

- (NSArray *)sampleViewWillShowSelectionToolbar
{
    NSMutableArray *toolbarItems = [NSMutableArray arrayWithCapacity:3];
    
    for (int i = 0; i < 3; i++) {
        MLNSelectionAction *action = [[MLNSelectionAction alloc] init];
        SEL actionMethod = @selector(testAction:);
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:actionMethod]];

        [invocation setTarget:self];
        [invocation setSelector:actionMethod];
        
        [action setName:@"Test"];
        [action setIcon:[NSImage imageNamed:NSImageNameRefreshTemplate]];
        [action setInvocation:invocation];
        
        [toolbarItems addObject:action];
    }
    
    return toolbarItems;
}

- (NSArray *)sampleViewWillShowSelectionMenu
{
    return nil;
}

#pragma mark - Overview Bar Delegate
- (void)overviewBar:(MLNOverviewBar *)bar
     didSelectFrame:(NSUInteger)frame
{
    [_sampleView moveCursorTo:frame];
    [_sampleView centreOnCursor];
}

- (void)overviewBar:(MLNOverviewBar *)bar
requestVisibleRange:(NSRange)newVisibleRange
{
    [_sampleView requestNewVisibleRange:newVisibleRange];
}

#pragma mark - Window delegate
- (void)windowDidChangeOcclusionState:(NSNotification *)notification
{
    if ([[notification object] occlusionState] & NSWindowOcclusionStateVisible) {
        [_sampleView resetTimers];
    } else {
        [_sampleView stopTimers];
    }
}
@end
