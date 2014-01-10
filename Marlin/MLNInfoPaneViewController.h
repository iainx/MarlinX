//
//  MLNInfoPaneViewController.h
//  Marlin
//
//  Created by iain on 09/01/2014.
//  Copyright (c) 2014 iain. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MLNSample;

@interface MLNInfoPaneViewController : NSViewController

@property (readwrite, weak) IBOutlet NSTextField *numberOfFrames;
@property (readwrite, weak) IBOutlet NSTextField *numberOfChannels;
@property (readwrite, weak) IBOutlet NSTextField *duration;
@property (readwrite, weak) IBOutlet NSTextField *sampleRate;
@property (readwrite, weak) IBOutlet NSTextField *bitrate;

- (id)initWithSample:(MLNSample *)sample;

@end
