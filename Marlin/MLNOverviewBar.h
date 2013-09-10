//
//  MLNOverviewBar.h
//  Marlin
//
//  Created by iain on 02/04/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MLNOverviewBarDelegate.h"

@class MLNSample;

@interface MLNOverviewBar : NSView

@property (readwrite, strong) MLNSample *sample;
@property (readwrite, weak) id<MLNOverviewBarDelegate> delegate;

- (void)setVisibleRange:(NSRange)visibleRange;
- (void)setSelection:(NSRange)selection;
@end
