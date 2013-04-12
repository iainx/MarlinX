//
//  SLFDocument.m
//  Marlin
//
//  Created by iain on 29/01/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNDocument.h"
#import "MLNOverviewBar.h"
#import "MLNSample.h"
#import "MLNSample+Operations.h"
#import "MLNSampleView.h"

@implementation MLNDocument {
    MLNSample *_testSample;
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
    if (context != sampleContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
    if ([keyPath isEqualToString:@"loaded"]) {
        [_toolbar validateVisibleItems];
        
        NSRange visibleRange = [self boundsToVisibleSampleRange:[[_scrollView contentView] bounds]];
        [_overviewBarView setVisibleRange:visibleRange];
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
    // Add any code here that needs to be executed once the windowController has loaded the document's window.

    //NSURL *url = [NSURL fileURLWithPath:@"/Users/iain/Desktop/Change of Scenery rado edit.wav" isDirectory:NO];
    //NSURL *url = [NSURL fileURLWithPath:@"/Users/iain/sine.wav" isDirectory:NO];
    
    // Doesn't like 8 channel.
    //NSURL *url = [NSURL fileURLWithPath:@"/Users/iain/Documents/6_Channel_ID.wav" isDirectory:NO];
    //NSURL *url = [NSURL fileURLWithPath:@"/Users/iain/Documents/8_Channel_ID.wav" isDirectory:NO];
    NSURL *url = [NSURL fileURLWithPath:@"/Users/iain/Documents/2dpl.wav" isDirectory:NO];
    
    _testSample = [[MLNSample alloc] initWithURL:url];
    [_testSample addObserver:self
                  forKeyPath:@"loaded"
                     options:0
                     context:sampleContext];
    
    _overviewBarView = [[MLNOverviewBar alloc] initWithFrame:NSZeroRect];
    [_overviewBarView setTranslatesAutoresizingMaskIntoConstraints:NO];
    _scrollView = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    [_scrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    _sampleView = [[MLNSampleView alloc] initWithFrame:NSZeroRect];
    [_sampleView setDelegate:self];
    
    NSWindow *window = [aController window];
    [[window contentView] addSubview:_overviewBarView];
    [[window contentView] addSubview:_scrollView];
    
    NSDictionary *viewsDict = @{@"overviewBarView": _overviewBarView,
                                @"scrollView": _scrollView,
                                @"sampleView": _sampleView};
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

    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|[scrollView]|"
                                                          options:0
                                                          metrics:nil
                                                            views:viewsDict];
    [[window contentView] addConstraints:constraints];
    
    [_overviewBarView setSample:_testSample];
    [_sampleView setSample:_testSample];
    [_sampleView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
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

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return YES;
}

#pragma mark - Menu & Toolbar actions

- (void)playSample:(id)sender
{
    [_testSample play];
}

- (void)stopSample:(id)sender
{
    [_testSample stop];
}

- (void)delete:(id)sender
{
    NSRange selection = [_sampleView selection];
    DDLogVerbose(@"Delete selected range: %@", NSStringFromRange(selection));
    
    [_testSample deleteRange:selection];
    [_sampleView clearSelection];
}

- (IBAction)showInformation:(id)sender
{
    
}

#pragma mark - Validators

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    BOOL valid = NO;
    
    DDLogVerbose(@"Validate");
    if ([menuItem action] == @selector(delete:)) {
        valid = [_sampleView hasSelection];
    }
    
    return valid;
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    BOOL valid = NO;
    
    if ([theItem action] == @selector(showInformation:)) {
        valid = [_testSample isLoaded];
    }
    
    return valid;
}

#pragma mark - Sample View delegate
- (void)sampleView:(MLNSampleView *)sampleView
selectionDidChange:(NSRange)selection
{
    [_overviewBarView setSelection:selection];
}

- (NSArray *)sampleViewWillShowSelectionToolbar
{
    return nil;
}

- (NSArray *)sampleViewWillShowSelectionMenu
{
    return nil;
}

@end
