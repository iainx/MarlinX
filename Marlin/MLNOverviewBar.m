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
    // Drawing code here.
}

#pragma mark Layout

- (NSSize)intrinsicContentSize
{
    CGFloat height;
    
    if ([_sample numberOfChannels] == 0) {
        height = 30;
    } else {
        height = 12 * [_sample numberOfChannels];
    }
    
    return NSMakeSize(NSViewNoInstrinsicMetric, height);
}
@end
