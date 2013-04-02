//
//  MLNOverviewBar.m
//  Marlin
//
//  Created by iain on 02/04/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNOverviewBar.h"
#import "MLNSample.h"

@implementation MLNOverviewBar

@synthesize sample = _sample;

static void *sampleContext = &sampleContext;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor redColor] set];
    NSRectFill(dirtyRect);
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context != sampleContext) {
        return;
    }
    
    if ([keyPath isEqualToString:@"numberOfChannels"]) {
        [self invalidateIntrinsicContentSize];
        [self setNeedsDisplay:YES];
        return;
    }
}
#pragma mark - Layout

- (NSSize)intrinsicContentSize
{
    CGFloat height;
    
    if ([_sample numberOfChannels] == 0) {
        height = 24;
    } else {
        height = 12 * [_sample numberOfChannels];
    }
    
    DDLogVerbose(@"Overview height: %f", height);
    return NSMakeSize(NSViewNoInstrinsicMetric, height);
}

#pragma mark - Accessors

- (void)setSample:(MLNSample *)sample
{
    if (_sample == sample) {
        return;
    }
    
    _sample = sample;
    [_sample addObserver:self
              forKeyPath:@"numberOfChannels"
                 options:NSKeyValueObservingOptionNew
                 context:sampleContext];
    
    if ([_sample isLoaded]) {
        [self invalidateIntrinsicContentSize];
        [self setNeedsDisplay:YES];
    }
}

- (MLNSample *)sample
{
    return _sample;
}
@end
