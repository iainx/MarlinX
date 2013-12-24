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
#import "MLNArrayController.h"

@class MLNOperation;
@class MLNMarker;

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
@property (readwrite) NSMutableArray *markers;
@property (readonly) MLNArrayController *markerController;

- (id)initWithURL:(NSURL *)url;
- (id)initWithChannels:(NSArray *)channelData;

- (void)startWriteToURL:(NSURL *)url completionHandler:(void (^)(NSError *))completionHandler;
- (void)startExportTo:(NSURL *)url asFormat:(NSDictionary *)format;

- (void)play;
- (void)stop;

- (BOOL)containsRange:(NSRange)range;

- (void)insertObject:(MLNMarker *)object inMarkersAtIndex:(NSUInteger)index;
- (void)removeObjectFromMarkersAtIndex:(NSUInteger)index;

@end
