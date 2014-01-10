//
//  MLNInfoPaneViewController.m
//  Marlin
//
//  Created by iain on 09/01/2014.
//  Copyright (c) 2014 iain. All rights reserved.
//

#import "MLNInfoPaneViewController.h"
#import "MLNSample.h"

@implementation MLNInfoPaneViewController {
    MLNSample *_sample;
}

- (id)initWithSample:(MLNSample *)sample
{
    self = [super initWithNibName:@"MLNInfoPaneViewController" bundle:nil];
    if (!self) {
        return nil;
    }
    
    _sample = sample;
    return self;
}

- (void)loadView
{
    [super loadView];
    DDLogVerbose(@"View did load");
    [self updateForSample];
}

- (void)updateForSample
{
    CGFloat duration = (float)[_sample numberOfFrames] / (float)[_sample sampleRate];
    [_duration setStringValue:[NSString stringWithFormat:@"%.3f seconds", duration]];
    [_numberOfFrames setIntegerValue:[_sample numberOfFrames]];
    
    NSUInteger channels = [_sample numberOfChannels];
    
    if (channels > 2) {
        [_numberOfChannels setIntegerValue:channels];
    } else {
        [_numberOfChannels setStringValue:(channels == 1 ? @"Mono" : @"Stereo")];
    }
    
    [_sampleRate setStringValue:[NSString stringWithFormat:@"%lu Hz", [_sample sampleRate]]];
    [_bitrate setStringValue:[NSString stringWithFormat:@"%lu bits per sample", [_sample bitrate]]];
}
@end
