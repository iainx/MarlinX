//
//  SLFDocument.m
//  Marlin
//
//  Created by iain on 29/01/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

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
#import "Constants.h"

@implementation MLNDocument {
    MLNProgressViewController *_progressViewController;
    NSView *_progressView;
    MLNSample *_sample;
    
    NSWindowController *_currentSheetController;
    NSWindow *_currentSheet;
}

+ (NSArray *)readableTypes
{
    UInt32 size;
    NSArray *all;
    OSStatus err;
    
    err = AudioFileGetGlobalInfoSize(kAudioFileGlobalInfo_AllUTIs, 0, NULL, &size);
    if (err == noErr)
        err = AudioFileGetGlobalInfo(kAudioFileGlobalInfo_AllUTIs, 0, NULL, &size, &all);
    
    if (err == noErr)
        NSLog(@"UTIs: %@", all);
    
    return all;
}

+ (NSArray *)writableTypes
{
    return @[@"com.microsoft.waveform-audio", @"public.mpeg-4-audio"];
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
}

- (void)clipViewBoundsChanged:(NSNotification *)note
{
    NSRect newBounds = [[note object] bounds];
    
    NSRange visibleRange = [self boundsToVisibleSampleRange:newBounds];
    [_overviewBarView setVisibleRange:visibleRange];
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
                  forKeyPath:@"framesPerPixel"
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
    
    // Post the clip view bounds changed so we can track it with the overview bar
    [clipView setPostsBoundsChangedNotifications:YES];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(clipViewBoundsChanged:)
               name:NSViewBoundsDidChangeNotification
             object:clipView];
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return nil;
}

/*
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return YES;
}
*/

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    DDLogVerbose(@"Opening %@, %p", url, self);
    
    _sample = [[MLNSample alloc] initWithURL:url];
    [_sample setDelegate:self];
    
    return YES;
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
}

- (IBAction)crop:(id)sender
{
    NSRange selection = [_sampleView selection];
    
    NSUndoManager *undoManager = [self undoManager];
    [undoManager setActionName:@"Crop Range"];
    
    [_sample cropRange:selection withUndoManager:undoManager];
    [_sampleView clearSelection];
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
}

- (void)paste:(id)sender
{
    DDLogVerbose(@"Paste: %lu", [_sampleView cursorFramePosition]);
    MLNApplicationDelegate *appDelegate = [NSApp delegate];
    
    MLNPasteboardSampleData *content = [appDelegate clipboardContent];
    
    NSUndoManager *undoManager = [self undoManager];
    [undoManager setActionName:@"Paste"];
    
    [_sample insertChannels:[content channels] atFrame:[_sampleView cursorFramePosition] withUndoManager:undoManager];
}

- (IBAction)selectAll:(id)sender
{
    [_sampleView setSelection:NSMakeRange(0, [_sample numberOfFrames])];
}

- (IBAction)selectNone:(id)sender
{
    [_sampleView clearSelection];
}

- (IBAction)zoomIn:(id)sender
{
    [_sampleView zoomIn];
}

- (IBAction)zoomOut:(id)sender
{
    [_sampleView zoomOut];
}

- (IBAction)zoomToFit:(id)sender
{
    [_sampleView zoomToFit];
}

- (IBAction)zoomToNormal:(id)sender
{
    [_sampleView zoomToNormal];
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
- (void)overviewBar:(MLNOverviewBar *)bar didSelectFrame:(NSUInteger)frame
{
    [_sampleView moveCursorTo:frame];
    [_sampleView centreOnCursor];
}
@end
