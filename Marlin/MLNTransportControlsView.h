//
//  MLNTransportControlsView.h
//  Marlin
//
//  Created by iain on 31/12/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MLNTransportControlsViewDelegate.h"

@interface MLNTransportControlsView : NSView
@property (readwrite, weak) id<MLNTransportControlsViewDelegate> delegate;

@end
