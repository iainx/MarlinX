//
//  MLNSample.m
//  Marlin
//
//  Created by iain on 29/01/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "Constants.h"
#import "MLNSample.h"
#import "MLNSampleChannel.h"
#import "MLNSampleBlock.h"
#import "MLNLoadOperation.h"
#import "MLNExportOperation.h"

#import "pa_ringbuffer.h"
#import "utils.h"

typedef struct PlaybackBlock {
    MLNSampleBlock *block;
    const float *data;
    NSUInteger framesInBlocks;
    UInt32 positionInBlock;
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

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _url = url;
    _loaded = NO;
    
    [self startLoad];
    
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
    
    return self;
}

- (void)startLoad
{
    _currentOperation = [[MLNLoadOperation alloc] initForSample:self];
    NSOperationQueue *defaultQueue = [MLNSample defaultOperationQueue];
    
    [_currentOperation setDelegate:self];
    [defaultQueue addOperation:_currentOperation];
    
    [_delegate sample:self operationDidStart:_currentOperation];
}

- (void)startExportTo:(NSURL *)url asFormat:(NSDictionary *)format
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
    NSLog(@"Error loading %@", [_url filePathURL]);
    NSLog(@"   Domain: %@", [error domain]);
    NSLog(@"   Code: %ld", [error code]);
    NSLog(@"   Method: %@", userInfo[@"method"]);
    
    NSNumber *statusCode = userInfo[@"statusCode"];
    UInt32 status = [statusCode intValue];
    
    print_coreaudio_error(status, "OSSStatus");
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
    
    //DDLogCVerbose(@"bufferSizePerChannel: %lu", bufferSizePerChannel);
    for (ushort channel = 0; channel < data->numberOfChannels; channel++) {
        // If there are no blocks, we're done.
        if (data->blocks[channel].block == NULL) {
            handleEos(data, queue);
            
            return;
        }
        
        NSUInteger positionInBlock = data->blocks[channel].positionInBlock;
        size_t positionInBuffer = 0;
        
        //DDLogCVerbose(@"Writing channel: %d/%d", channel, data->numberOfChannels);
        
        UInt32 j;
        for (j = 0; j < bufferFramesPerChannel; j++) {
            
            if (positionInBlock >= data->blocks[channel].framesInBlocks) {
                MLNSampleBlock *oldBlock = data->blocks[channel].block;
                
                if (oldBlock) {
                    // Need the next block
                    // FIXME: Would like blocks to be structures because we can't
                    // call objc from the realtime thread
                    data->blocks[channel].block = oldBlock->nextBlock;
                    if (data->blocks[channel].block) {
                        data->blocks[channel].data = MLNSampleBlockSampleData(data->blocks[channel].block);
                        data->blocks[channel].framesInBlocks = data->blocks[channel].block->numberOfFrames;
                        data->blocks[channel].positionInBlock = 0;
                        
                        positionInBlock = 0;
                    } else {
                        data->blocks[channel].block = NULL;
                        data->blocks[channel].data = NULL;
                        data->blocks[channel].framesInBlocks = 0;
                        data->blocks[channel].positionInBlock = 0;
                    }
                } else {
                    data->blocks[channel].block = NULL;
                    data->blocks[channel].data = NULL;
                    data->blocks[channel].framesInBlocks = 0;
                    data->blocks[channel].positionInBlock = 0;
                }
            }
            
            float *bufferData = (float *)buffer->mAudioData;
            if (data->blocks[channel].data != NULL) {
                //fprintf(stderr, "positionInBlock: %d", positionInBlock);
                bufferData[(positionInBuffer * data->numberOfChannels) + channel] = data->blocks[channel].data[positionInBlock];
                framesWritten++;
            } else {
                break;
            }
            
            positionInBuffer++;
            positionInBlock++;
            data->blocks[channel].positionInBlock++;
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
        MLNSampleBlock *block = [channel sampleBlockForFrame:_playbackPosition];
        _playbackData->blocks[i].block = block;
        _playbackData->blocks[i].data = MLNSampleBlockSampleData(block);
        _playbackData->blocks[i].framesInBlocks = block->numberOfFrames;
        _playbackData->blocks[i].positionInBlock = (UInt32)(_playbackPosition - block->startFrame);
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

@end
