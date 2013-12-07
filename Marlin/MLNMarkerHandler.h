//
//  MLNMarkerHandler.h
//  Marlin
//
//  Created by iain on 26/11/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLNMarkerHandlerDelegate.h"

@class MLNMarker;
@class MLNSampleView;

@interface MLNMarkerHandler : NSObject

@property (readwrite, weak) id<MLNMarkerHandlerDelegate> delegate;

- (id)initForMarker:(MLNMarker *)marker
              owner:(MLNSampleView *)sampleView;
- (NSTrackingArea *)trackingAreaForRect:(NSRect)rect;
- (NSArray *)trackingAreas;

@end
