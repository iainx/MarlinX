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
#import "Constants.h"

@implementation MLNDocument {
    MLNProgressViewController *_progressViewController;
    NSView *_progressView;
    MLNSample *_sample;
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
        
        [_progressView removeFromSuperview];
        _progressView = nil;
        
        // FIXME: Do we need to nil out the viewcontroller? We don't need it anymore do we?
        // I suppose we could reuse it for Save/Export
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
    
    MLNLoadOperation *operation = [_sample loadOperation];
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
    
    return YES;
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
    
    [_sample deleteRange:selection];
    [_sampleView clearSelection];
}

- (IBAction)showInformation:(id)sender
{
    
}

- (void)copy:(id)sender
{
    NSRange selection = [_sampleView selection];
    
    NSArray *copyChannels = [_sample copyRange:selection];
    MLNApplicationDelegate *appDelegate = [NSApp delegate];

    MLNPasteboardSampleData *content = [[MLNPasteboardSampleData alloc] initWithContent:copyChannels
                                                                             sampleRate:[_sample sampleRate]];
    [appDelegate setClipboardContent:content];
}

- (void)cut:(id)sender
{
    NSRange selection = [_sampleView selection];

    NSArray *copyChannels = [_sample copyRange:selection];
    MLNApplicationDelegate *appDelegate = [NSApp delegate];
    
    MLNPasteboardSampleData *content = [[MLNPasteboardSampleData alloc] initWithContent:copyChannels
                                                                             sampleRate:[_sample sampleRate]];
    [appDelegate setClipboardContent:content];

    [_sample deleteRange:selection];
    [_sampleView clearSelection];
}

- (void)paste:(id)sender
{
    DDLogVerbose(@"Paste: %lu", [_sampleView cursorFramePosition]);
    MLNApplicationDelegate *appDelegate = [NSApp delegate];
    
    MLNPasteboardSampleData *content = [appDelegate clipboardContent];
    [_sample insertChannels:[content channels] atFrame:[_sampleView cursorFramePosition]];
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
