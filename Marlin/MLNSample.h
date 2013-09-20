//
//  MLNSample.h
//  Marlin
//
//  Created by iain on 29/01/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLNLoadOperationDelegate.h"
#import "MLNSampleDelegate.h"

@class MLNOperation;
@interface MLNSample : NSObject <MLNLoadOperationDelegate>

enum {
    MLNSampleLoadError,
};

@property (readwrite, weak) id<MLNSampleDelegate> delegate;
@property (readonly, nonatomic) NSMutableArray *channelData;

@property (readonly, getter = isLoaded) bool loaded;
@property (readonly) NSUInteger numberOfChannels;
@property (readwrite) NSUInteger numberOfFrames;
@property (readwrite) NSUInteger sampleRate;

@property (readonly) NSInteger duration;
@property (readonly) NSURL *url;

@property (readonly) MLNOperation *currentOperation;

- (id)initWithURL:(NSURL *)url;
- (id)initWithChannels:(NSArray *)channelData;

- (void)startExportTo:(NSURL *)url asFormat:(NSDictionary *)format;

- (void)play;
- (void)stop;

- (BOOL)containsRange:(NSRange)range;

@end
