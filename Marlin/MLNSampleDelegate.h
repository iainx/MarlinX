//
//  MLNSampleDelegate.h
//  Marlin
//
//  Created by iain on 14/03/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MLNSample;
@class MLNOperation;

@protocol MLNSampleDelegate <NSObject>

- (void)sample:(MLNSample *)sample operationDidStart:(MLNOperation *)operation;
- (void)sample:(MLNSample *)sample operationDidEnd:(MLNOperation *)operation;
- (void)sample:(MLNSample *)sample operationError:(NSError *)error;

- (void)sample:(MLNSample *)sample playbackPositionChanged:(NSUInteger)frame;
- (void)samplePlaybackDidEnd:(MLNSample *)sample;
@end
