//
//  SLFDocument.m
//  Marlin
//
//  Created by iain on 29/01/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "NSColor+Extra.h"
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
#import "MLNTransportControlsView.h"
#import "MLNInfoPaneViewController.h"
#import "MLNAddSilenceWindowController.h"
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
    
    BOOL _infoPaneOpen;
    MLNInfoPaneViewController *_infoPaneVC;
    NSView *_infoPane;
    NSLayoutConstraint *_infoPanelXConstraint;
    NSArray *_infoPaneHConstraints;
    NSArray *_infoPaneVConstraints;
    NSLayoutConstraint *_scrollviewRightConstraint;
    
    MLNAddSilenceWindowController *_insertSilenceController;
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

- (id)initForURL:(NSURL *)urlOrNil withContentsOfURL:(NSURL *)contentsURL ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    self = [super init];

    DDLogVerbose(@"initForURL: %@ withContentsOfURL: %@ ofType: %@", urlOrNil, contentsURL, typeName);
    [self readFromURL:contentsURL ofType:typeName error:outError];
    
    return self;
}

- (id)initWithContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    self = [super init];
    
    DDLogVerbose(@"initWithContentsOfURL: %@ ofType: %@", url, typeName);
    
    [self readFromURL:url ofType:typeName error:outError];
    return self;
}

- (id)initWithType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    self = [super init];
    
    DDLogVerbose(@"initWithType: %@", typeName);
    return self;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[_sample url] forKey:kMLNDocumentRestoreURL];
    
    [super encodeRestorableStateWithCoder:coder];
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
/*
- (void)restoreDocumentWindowWithIdentifier:(NSString *)identifier state:(NSCoder *)state completionHandler:(void (^)(NSWindow *, NSError *))completionHandler
{
    DDLogVerbose(@"Restore %@: %@", identifier, state);
    [super restoreDocumentWindowWithIdentifier:identifier state:state completionHandler:completionHandler];
}
*/
- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    
    DDLogVerbose(@"Document controller: %@", [NSDocumentController sharedDocumentController]);
    
    [_transportControlsView setDelegate:self];
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
    //[window setBackgroundColor:[NSColor marlinBackgroundColor]];
    [window setDelegate:self];
    
    NSView *contentView = [window contentView];
    [contentView addSubview:_overviewBarView];
    [contentView addSubview:_scrollView];
    [contentView addSubview:_progressView];
    
    NSDictionary *viewsDict = @{@"overviewBarView": _overviewBarView,
                                @"scrollView": _scrollView,
                                @"sampleView": _sampleView,
                                @"progressView": _progressView};
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[overviewBarView][scrollView]-40-|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:viewsDict];
    [contentView addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-4-[overviewBarView]-4-|"
                                                          options:0
                                                          metrics:nil
                                                            views:viewsDict];
    [contentView addConstraints:constraints];

    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|[progressView]|"
                                                          options:0
                                                          metrics:nil
                                                            views:viewsDict];
    [contentView addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[progressView]-40-|"
                                                          options:0
                                                          metrics:nil
                                                            views:viewsDict];
    [contentView addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-4-[scrollView]"
                                                          options:0
                                                          metrics:nil
                                                            views:viewsDict];
    [contentView addConstraints:constraints];
    
    _scrollviewRightConstraint = [NSLayoutConstraint constraintWithItem:_scrollView
                                                              attribute:NSLayoutAttributeRight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:contentView
                                                              attribute:NSLayoutAttributeRight
                                                             multiplier:1.0
                                                               constant:-4.0];
    [contentView addConstraint:_scrollviewRightConstraint];
    
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
    
    //[_scrollView setBackgroundColor:[NSColor marlinBackgroundColor]];
    //[_scrollView setDrawsBackground:NO];
    [_scrollView setDocumentView:_sampleView];
    
    NSClipView *clipView = [_scrollView contentView];
    [clipView setCopiesOnScroll:YES];
    
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
        [self setFileURL:url];
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

- (void)setSelection:(NSRange)selection
     withUndoManager:(NSUndoManager *)undoManager
{
    [_sampleView setSelection:selection];
    [[undoManager prepareWithInvocationTarget:self] clearSelectionWithUndoManager:undoManager];
}

- (void)clearSelectionWithUndoManager:(NSUndoManager *)undoManager
{
    NSRange oldSelection = [_sampleView selection];
    
    [_sampleView clearSelection];
    [[undoManager prepareWithInvocationTarget:self] setSelection:oldSelection withUndoManager:undoManager];
}

- (void)delete:(id)sender
{
    NSRange selection = [_sampleView selection];
    DDLogVerbose(@"Delete selected range: %@", NSStringFromRange(selection));
    
    NSUndoManager *undoManager = [self undoManager];
    [undoManager setActionName:@"Delete Range"];
    
    [_sample deleteRange:selection undoManager:undoManager];
    
    [self clearSelectionWithUndoManager:undoManager];
    
    [self displayIndicatorForOperationName:@"Delete Range"];
}

- (IBAction)crop:(id)sender
{
    NSRange selection = [_sampleView selection];
    
    NSUndoManager *undoManager = [self undoManager];
    [undoManager setActionName:@"Crop Range"];
    
    [_sample cropRange:selection withUndoManager:undoManager];
    [self clearSelectionWithUndoManager:undoManager];
    
    [self displayIndicatorForOperationName:@"Crop Range"];
}

- (IBAction)showInformation:(id)sender
{
    if (_infoPaneVC == nil) {
        _infoPaneVC = [[MLNInfoPaneViewController alloc] initWithSample:_sample];
        
        _infoPane = [_infoPaneVC view];
        [_infoPane setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        NSView *contentView = [[self documentWindow] contentView];
        [contentView addSubview:_infoPane];
        
        [contentView removeConstraint:_scrollviewRightConstraint];
        
        NSDictionary *viewsDict = @{@"infoPane":_infoPane,
                                    @"overviewBarView":_overviewBarView,
                                    @"scrollView":_scrollView};
        NSArray *constraints;
        
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[overviewBarView][infoPane]-40-|"
                                                              options:0
                                                              metrics:nil
                                                                views:viewsDict];
        [contentView addConstraints:constraints];
        
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-4-[scrollView]-4-[infoPane]"
                                                              options:0
                                                              metrics:nil
                                                                views:viewsDict];
        [contentView addConstraints:constraints];
        
        _infoPanelXConstraint = [NSLayoutConstraint constraintWithItem:_infoPane
                                                                 attribute:NSLayoutAttributeLeft
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:contentView
                                                                 attribute:NSLayoutAttributeRight
                                                                multiplier:1
                                                                  constant:0];
        [contentView addConstraint:_infoPanelXConstraint];
        [[_infoPanelXConstraint animator] setConstant:-240.0];
    } else {
        [NSAnimationContext beginGrouping];
        NSAnimationContext *ctxt = [NSAnimationContext currentContext];

        [ctxt setCompletionHandler:^{
            // Technically this is a reference loop and we should use a weak pointer
            // but the block will be executed too quickly to actually matter... I think?
            [_infoPane removeFromSuperview];
            _infoPane = nil;
            _infoPanelXConstraint = nil;
            _infoPaneVC = nil;
            
            [[[self documentWindow] contentView] addConstraint:_scrollviewRightConstraint];
        }];
        [[_infoPanelXConstraint animator] setConstant:0.0];
        [NSAnimationContext endGrouping];
    }
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
    [self clearSelectionWithUndoManager:undoManager];
    
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
    [self clearSelectionWithUndoManager:undoManager];
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
    if ([_sampleView hasSelection]) {
        [_sampleView zoomToSelection];
    } else {
        [_sampleView zoomToFit];
    }
    
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

- (IBAction)insertSilence:(id)sender
{
    if (_insertSilenceController == nil) {
        NSWindow *window = [self documentWindow];
        
        _insertSilenceController = [[MLNAddSilenceWindowController alloc] init];
        NSWindow *addSilenceWindow = [_insertSilenceController window];
        
        MLNSample *sample = _sample;
        MLNSampleView *sampleView = _sampleView;
        NSUndoManager *undoManager = [self undoManager];
        
        [_insertSilenceController setDidCloseBlock:^(NSUInteger numberOfFramesToAdd) {
            [window endSheet:addSilenceWindow];
            
            if (numberOfFramesToAdd == 0) {
                return;
            }
            
            [sample insertSilenceAtFrame:[sampleView cursorFramePosition]
                          numberOfFrames:numberOfFramesToAdd
                             undoManager:undoManager];
        }];
        
        [window beginSheet:addSilenceWindow completionHandler:^(NSModalResponse returnCode) {
            _insertSilenceController = nil;
        }];
    }
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
    BOOL isPlaying = [_sample isPlaying];
    
    SEL action = [menuItem action];
    if (action == @selector(delete:)
        || action == @selector(crop:)
        || action == @selector(copy:)
        || action == @selector(cut:)
        || action == @selector(clearSelection:)
        || action == @selector(reverseSelection:)) {
        return (!isPlaying && [_sampleView hasSelection]);
    }
    
    if (action == @selector(paste:)) {
        MLNApplicationDelegate *appDelegate = [NSApp delegate];
        MLNPasteboardSampleData *content = [appDelegate clipboardContent];
        
        if (content) {
            if ([_sample canInsertChannels:[content channels] sampleRate:[content sampleRate]]) {
                return !isPlaying;
            }
        }
        
        return NO;
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
    
    [_progressView setHidden:YES];
    [_sampleView setHidden:NO];
}

- (void)samplePlaybackDidEnd:(MLNSample *)sample
{
}

- (void)sample:(MLNSample *)sample playbackPositionChanged:(NSUInteger)frame
{
    [_sampleView setCursorFramePosition:frame];
}

#pragma mark - Sample View delegate
- (void)sampleView:(MLNSampleView *)sampleView
selectionDidChange:(NSRange)selection
{
    [_overviewBarView setSelection:selection];
}

typedef struct {
    char *actionName;
    char *actionImage;
    char *actionSelectorName;
} _SelectionAction;

static _SelectionAction selectionActions[] = {
    { "Delete Selection", "delete-selection16x16", "delete:" },
    { "Crop Selection", "crop-selection16x16", "crop:" },
    { "Clear Selection", "clear-selection16x16", "clearSelection:" },
    { "Reverse Selection", "reverse-selection16x16", "reverseSelection:" },
    { NULL, NULL, NULL },
};

- (NSArray *)sampleViewWillShowSelectionToolbar
{
    NSMutableArray *toolbarItems = [NSMutableArray array];
    
    for (int i = 0; selectionActions[i].actionName; i++) {
        MLNSelectionAction *action = [[MLNSelectionAction alloc] init];
        SEL actionMethod = NSSelectorFromString([NSString stringWithUTF8String:selectionActions[i].actionSelectorName]);
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:actionMethod]];
        
        [invocation setTarget:self];
        [invocation setSelector:actionMethod];
        
        [action setName:[NSString stringWithUTF8String:selectionActions[i].actionName]];
        if (selectionActions[i].actionImage) {
            [action setIcon:[NSImage imageNamed:[NSString stringWithUTF8String:selectionActions[i].actionImage]]];
        }
        [action setInvocation:invocation];
        
        [toolbarItems addObject:action];
    }

    return toolbarItems;
}

- (BOOL)sampleViewValidateSelectionToolbarItem:(SEL)action
{
    BOOL isPlaying = [_sample isPlaying];
    
    if (action == @selector(delete:)
        || action == @selector(crop:)
        || action == @selector(clearSelection:)
        || action == @selector(reverseSelection:)) {
        return !isPlaying;
    }
    
    return NO;
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

- (void)windowDidRequestReturnToStart:(NSWindow *)window
{
    [self transportControlsViewDidRequestMoveToStart];
}

- (void)windowDidRequestTogglePlay:(NSWindow *)window
{
    [self transportControlsViewDidRequestPlay];
}

#pragma mark - Transport View delegate
- (void)transportControlsViewDidRequestBackFrame
{
    NSUInteger cursorPosition = [_sampleView cursorFramePosition];
    
    [_sampleView setCursorFramePosition:cursorPosition - [_sampleView framesPerPixel]];
}

- (void)transportControlsViewDidRequestForwardFrame
{
    NSUInteger cursorPosition = [_sampleView cursorFramePosition];
    
    [_sampleView setCursorFramePosition:cursorPosition + [_sampleView framesPerPixel]];
}

- (void)transportControlsViewDidRequestMoveToStart
{
    [_sampleView setCursorFramePosition:0];
    [_sampleView centreOnCursor];
}

- (void)transportControlsViewDidRequestMoveToEnd
{
    // FIXME: This magic number seems wrong...
    [_sampleView setCursorFramePosition:[_sample numberOfFrames] - [_sampleView framesPerPixel] * 2];
    [_sampleView centreOnCursor];
}

- (void)transportControlsViewDidRequestPlay
{
    if ([_sample isPlaying]) {
        [_sample stop];
    } else {
        if ([_sampleView hasSelection]) {
            NSRange selection = [_sampleView selection];
            [_sample playFromFrame:selection.location toFrame:NSMaxRange(selection) - 1];
        } else {
            [_sample playFromFrame:[_sampleView cursorFramePosition]];
        }
    }
}

- (void)transportControlsViewDidRequestPause
{
    
}

- (void)transportControlsViewDidRequestStop
{
    [_sample stop];
}

@end
