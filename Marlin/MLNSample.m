//
//  MLNSample.m
//  Marlin
//
//  Created by iain on 29/01/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "Constants.h"
#import "MLNArrayController.h"
#import "MLNSample.h"
#import "MLNSampleChannel.h"
#import "MLNSampleChannelIterator.h"
#import "MLNSampleBlock.h"
#import "MLNLoadOperation.h"
#import "MLNExportOperation.h"
#import "MLNExportPanelController.h"
#import "MLNMarker.h"

#import "pa_ringbuffer.h"
#import "utils.h"


typedef struct PlaybackBlock {
    /*
    MLNSampleBlock *block;
    const float *data;
    NSUInteger framesInBlocks;
    UInt32 positionInBlock;
     */
    MLNSampleChannelCIterator *cIter;
} PlaybackBlock;

typedef enum MessageType {
    MessageTypePosition,
    MessageTypeEOS
} MessageType;

typedef struct MessageData {
    MessageType type;
    union {
        struct {
            NSUInteger position;
        } position;
    } data;
} MessageData;

typedef struct PlaybackData {
    __unsafe_unretained MLNSample *sample;
    
    void *RTToMainBuffer;
    PaUtilRingBuffer RTToMainRB;
    
    ushort numberOfChannels;
    PlaybackBlock *blocks;
    NSUInteger position;
} PlaybackData;

@implementation MLNSample {
    AudioStreamBasicDescription _format;
    
    // Playback stuff
    AudioQueueRef _playbackQueue;
    UInt32 _playbackPosition;
    
    PlaybackData *_playbackData;
    NSTimer *_playbackTimer;
    void (^_saveCompletionHandler)(NSError *);
}

#pragma mark Class methods

+ (NSOperationQueue *)defaultOperationQueue
{
    static NSOperationQueue *defaultOperationQueue = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        defaultOperationQueue = [[NSOperationQueue alloc] init];
        [defaultOperationQueue setName:@"com.sleepfive.Marlin.SampleQueue"];
    });

    return defaultOperationQueue;
}

- (id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _loaded = NO;
    
    _markers = [[NSMutableArray alloc] init];
    _markerController = [[MLNArrayController alloc] init];
    [_markerController bind:@"contentArray"
                   toObject:self
                withKeyPath:@"markers"
                    options:nil];
    
    NSSortDescriptor *frameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"frame" ascending:YES];
    [_markerController setSortDescriptors:@[frameDescriptor]];
    
    return self;
}

- (id)initWithChannels:(NSArray *)channelData
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _url = nil;
    _loaded = YES;
    
    // Not a deep copy
    _channelData = [channelData mutableCopy];
    _numberOfFrames = [channelData[0] numberOfFrames];
    
    _markers = [[NSMutableArray alloc] init];

    return self;
}

- (void)startLoadFromURL:(NSURL *)url
{
    NSURL *markerURL = [url URLByAppendingPathComponent:@"markers.data"];
    NSData *markerData = [NSData dataWithContentsOfURL:markerURL];
    
    NSArray *markers = [NSKeyedUnarchiver unarchiveObjectWithData:markerData];
    [_markers addObjectsFromArray:markers];
    
    NSURL *dataURL = [url URLByAppendingPathComponent:@"marlin-filedata.wav"];

    [self importFromURL:dataURL];
}

- (void)startImportFromURL:(NSURL *)url
{
    _url = url;
    
    [self importFromURL:url];
}

- (void)importFromURL:(NSURL *)url
{
    _currentOperation = [[MLNLoadOperation alloc] initForSample:self fromURL:url];
    NSOperationQueue *defaultQueue = [MLNSample defaultOperationQueue];
    
    [_currentOperation setDelegate:self];
    [defaultQueue addOperation:_currentOperation];
    
    [_delegate sample:self operationDidStart:_currentOperation];
}

- (void)startWriteToURL:(NSURL *)url
      completionHandler:(void (^)(NSError *))completionHandler
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    _saveCompletionHandler = completionHandler;
    
    [fm createDirectoryAtURL:url withIntermediateDirectories:YES
                  attributes:nil error:nil];
    
    // Markers
    NSURL *markerURL = [url URLByAppendingPathComponent:@"markers.data"];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_markers];
    [data writeToURL:markerURL options:0 error:nil];
    
    // Write data
    NSURL *realURL = [url URLByAppendingPathComponent:@"marlin-filedata.wav"];
    NSDictionary *format = @{@"formatDetails": [MLNExportPanelController exportableTypeForName:@"WAV"]};
    
    DDLogVerbose(@"Exporting to %@: %@", [realURL absoluteString], format);
    [self startExportTo:realURL asFormat:format];
}

- (void)startExportTo:(NSURL *)url
             asFormat:(NSDictionary *)format
{
    _currentOperation = [[MLNExportOperation alloc] initWithSample:self URL:url format:format];
    NSOperationQueue *defaultQueue = [MLNSample defaultOperationQueue];
    
    [_currentOperation setDelegate:self];
    [defaultQueue addOperation:_currentOperation];
    [_delegate sample:self operationDidStart:_currentOperation];
}

- (void)progressUpdateNotification:(NSNotification *)note
{
    NSDictionary *userInfo = [note userInfo];
    NSLog (@"Progress: %@", userInfo);
}

#pragma mark - MLNOperationDelegate functions

- (void)operationDidFinish:(MLNOperation *)operation
{
    if (_saveCompletionHandler) {
        _saveCompletionHandler(nil);
        _saveCompletionHandler = nil;
    }
    
    [_delegate sample:self operationDidEnd:operation];
}

#pragma mark - MLNLoadOperationDelegate functions

- (void)sampleDidLoadData:(NSMutableArray *)channelData
              description:(AudioStreamBasicDescription)format
{
    _channelData = channelData;
    _format = format;
    
    MLNSampleChannel *channel = _channelData[0];
    
    [self willChangeValueForKey:@"numberOfFrames"];
    _numberOfFrames = [channel numberOfFrames];
    [self didChangeValueForKey:@"numberOfFrames"];
    
    [self willChangeValueForKey:@"sampleRate"];
    _sampleRate = format.mSampleRate;
    [self didChangeValueForKey:@"sampleRate"];
    
    [self willChangeValueForKey:@"numberOfChannels"];
    _numberOfChannels = _format.mChannelsPerFrame;
    [self didChangeValueForKey:@"numberOfChannels"];
    
    dump_asbd(&_format);
    
    // Because this is readonly we don't have a setter, so we need to announce changes
    // manually to KVO
    [self willChangeValueForKey:@"loaded"];
    _loaded = YES;
    [self didChangeValueForKey:@"loaded"];
}

- (void)didFailLoadWithError:(NSError *)error
{
    NSDictionary *userInfo = [error userInfo];
    DDLogError(@"Error loading %@", [_url filePathURL]);
    DDLogError(@"   Domain: %@", [error domain]);
    DDLogError(@"   Code: %ld", [error code]);
    DDLogError(@"   Method: %@", userInfo[@"method"]);
    
    NSNumber *statusCode = userInfo[@"statusCode"];
    UInt32 status = [statusCode intValue];
    
    print_coreaudio_error(status, "OSSStatus");
    
    [_delegate sample:self operationError:error];
}

// This should be a category but you can't have any ivars in a category
#pragma mark Playback

// Put an EOS message on the message queue and stop the queue.
static void
handleEos (PlaybackData *data,
           AudioQueueRef queue)
{
    MessageData *dataPtr1, *dataPtr2;
    ring_buffer_size_t sizePtr1, sizePtr2;
    
    if (PaUtil_GetRingBufferWriteRegions(&data->RTToMainRB, 1,
                                         (void *)&dataPtr1, &sizePtr1,
                                         (void *)&dataPtr2, &sizePtr2)) {
        dataPtr1->type = MessageTypeEOS;
        PaUtil_AdvanceRingBufferWriteIndex(&data->RTToMainRB, 1);
    } else {
        // Can probably handle an error here.
    }
    
    AudioQueueStop(queue, TRUE);
}

static void
MyAQOutputCallback (void *userData,
                    AudioQueueRef queue,
                    AudioQueueBufferRef buffer)
{
    PlaybackData *data = (PlaybackData *)userData;
    size_t bufferSizePerChannel = 0x10000 / data->numberOfChannels;
    UInt32 bufferFramesPerChannel = (UInt32)bufferSizePerChannel / sizeof(float);
    UInt32 framesWritten = 0;
    
    for (ushort channel = 0; channel < data->numberOfChannels; channel++) {
        BOOL moreData = YES;
        
        // If there are no blocks, we're done.
        if (MLNSampleChannelIteratorHasMoreData(data->blocks[channel].cIter) == NO) {
            handleEos(data, queue);
            
            return;
        }
        
        size_t positionInBuffer = 0;
        UInt32 j;
        
        for (j = 0; j < bufferFramesPerChannel && moreData; j++) {
            float value;
            float *bufferData = (float *)buffer->mAudioData;
            
            moreData = MLNSampleChannelIteratorNextFrameData(data->blocks[channel].cIter, &value);
            bufferData[(positionInBuffer * data->numberOfChannels) + channel] = value;
            positionInBuffer++;
            framesWritten++;
        }
    }
    
    UInt32 bytesWritten = framesWritten * sizeof(float);

    data->position += (framesWritten / data->numberOfChannels);
    
    MessageData *dataPtr1, *dataPtr2;
    ring_buffer_size_t sizePtr1, sizePtr2;
    
    if (PaUtil_GetRingBufferWriteRegions(&data->RTToMainRB, 1,
                                         (void *)&dataPtr1, &sizePtr1,
                                         (void *)&dataPtr2, &sizePtr2)) {
        dataPtr1->type = MessageTypePosition;
        dataPtr1->data.position.position = data->position;
        
        PaUtil_AdvanceRingBufferWriteIndex(&data->RTToMainRB, 1);
    } else {
        // We can drop a position counter or two
    }

    buffer->mAudioDataByteSize = bytesWritten;
    AudioQueueEnqueueBuffer(queue, buffer, 0, NULL);
}

- (void)play
{
    int i;
    
    _playbackPosition = 0;
    
    AudioStreamBasicDescription newAsbd = _format;
    
    newAsbd.mChannelsPerFrame = _format.mChannelsPerFrame;
    newAsbd.mFormatID = kAudioFormatLinearPCM;
    newAsbd.mFormatFlags = kAudioFormatFlagIsFloat;
    newAsbd.mBytesPerFrame = 4 * _format.mChannelsPerFrame;
    newAsbd.mBytesPerPacket = 4 * _format.mChannelsPerFrame;
    newAsbd.mFramesPerPacket = 1;
    newAsbd.mBitsPerChannel = 32;
    
    _playbackData = malloc(sizeof(PlaybackData));
    _playbackData->sample = self;
    _playbackData->numberOfChannels = _format.mChannelsPerFrame;
    _playbackData->position = _playbackPosition;
    
    // FIXME: How much space do we need for the messages?
    _playbackData->RTToMainBuffer = malloc(sizeof(MessageData) * 32);
    PaUtil_InitializeRingBuffer(&_playbackData->RTToMainRB, sizeof(MessageData), 32, _playbackData->RTToMainBuffer);
    
    // Store our initial buffer for each channel
    // Allocate the entire array rather than pointers for each.
    _playbackData->blocks = malloc(sizeof (PlaybackBlock) * _format.mChannelsPerFrame);
    for (i = 0; i < _format.mChannelsPerFrame; i++) {
        MLNSampleChannel *channel = [self channelData][i];
        //MLNSampleChannelIterator *iter = [[MLNSampleChannelIterator alloc] initWithChannel:channel atFrame:0];
        
        _playbackData->blocks[i].cIter = MLNSampleChannelIteratorNew(channel, 0, NO);
    }
    
    AudioQueueNewOutput(&newAsbd, MyAQOutputCallback, _playbackData, NULL, NULL, 0, &_playbackQueue);

    AudioQueueBufferRef buffers[3];
    
    for (i = 0; i < 3; i++) {
        AudioQueueAllocateBuffer(_playbackQueue, 0x10000, &buffers[i]);
        MyAQOutputCallback (_playbackData, _playbackQueue, buffers[i]);
    }
    
    AudioQueueStart(_playbackQueue, NULL);
    
    // Start a short callback to read from the ringbuffer.
    _playbackTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self
                                                    selector:@selector(readFromRingBuffer:)
                                                    userInfo:self repeats:YES];
}

- (void)readFromRingBuffer:(NSTimer *)timer
{
    while (PaUtil_GetRingBufferReadAvailable(&_playbackData->RTToMainRB)) {
        MessageData *dataPtr1, *dataPtr2;
        ring_buffer_size_t sizePtr1, sizePtr2;
        
        // Should we read more than one at a time?
        if (PaUtil_GetRingBufferReadRegions(&_playbackData->RTToMainRB, 1,
                                            (void *)&dataPtr1, &sizePtr1,
                                            (void *)&dataPtr2, &sizePtr2) != 1) {
            continue;
        }
        
        // Parse message
        switch (dataPtr1->type) {
            case MessageTypeEOS:
                DDLogInfo(@"Got EOS");
                [self disposePlayer];
                return;
                
            case MessageTypePosition:
                DDLogInfo(@"Got Position: %lu", dataPtr1->data.position.position);
                break;
                
            default:
                break;
        }
        PaUtil_AdvanceRingBufferReadIndex(&_playbackData->RTToMainRB, 1);
    }
}

- (void)disposePlayer
{
    if (_playbackData == NULL) {
        return;
    }
    
    [_playbackTimer invalidate];
    _playbackTimer = nil;
    
    AudioQueueDispose(_playbackQueue, TRUE);
    _playbackQueue = NULL;
    
    // Free the playback data
    free (_playbackData->RTToMainBuffer);
    free (_playbackData->blocks);
    free (_playbackData);
    _playbackData = NULL;
}

- (void)stop
{
    AudioQueueStop(_playbackQueue, TRUE);
    [self disposePlayer];
}

- (BOOL)containsRange:(NSRange)range
{
    if (range.location >= _numberOfFrames || NSMaxRange(range) - 1 >= _numberOfFrames) {
        return NO;
    }
    
    return YES;
}

#pragma mark Array controller methods

- (NSUInteger)countOfMarkers
{
    return [_markers count];
}

- (id)objectInMarkersAtIndex:(NSUInteger)index
{
    return _markers[index];
}

- (void)insertObject:(MLNMarker *)object inMarkersAtIndex:(NSUInteger)index
{
    [_markers insertObject:object atIndex:index];
}

- (void)removeObjectFromMarkersAtIndex:(NSUInteger)index
{
    [_markers removeObjectAtIndex:index];
}
@end
