//
//  MLNWindow.h
//  Marlin
//
//  Created by iain on 24/01/2014.
//  Copyright (c) 2014 iain. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MLNWindowDelegate.h"

@interface MLNWindow : NSWindow

@property (readwrite, weak) id<MLNWindowDelegate> delegate;

@end
