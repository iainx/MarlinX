//
//  MLNSaveOperation.m
//  Marlin
//
//  Created by iain on 16/09/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#include <AudioToolbox/AudioToolbox.h>

#import "MLNExportOperation.h"
#import "MLNExportableType.h"
#import "MLNSample.h"
#import "MLNSampleChannel.h"
#import "utils.h"

@implementation MLNExportOperation {
    MLNSample *_sample;
    NSURL *_url;
    NSDictionary *_format;
    
    AudioStreamBasicDescription _outputFormat;
    ExtAudioFileRef _outputFile;
}

- (id)initWithSample:(MLNSample *)sample URL:(NSURL *)url format:(NSDictionary *)format
{
    OSStatus err = noErr;
    UInt32 size;
    
    self = [super init];
    if (!self) {
        return nil;
    }
    
    [self setPrimaryText:@"Exporting"];
    [self setSecondaryText:@"Something something"];
    [self setProgress:0];
    
    __weak MLNExportOperation *weakSelf = self;
    
    [self setCompletionBlock:^{
        [weakSelf performSelectorOnMainThread:@selector(finishUpOnMainThread:) withObject:nil waitUntilDone:NO];
    }];
    
    _sample = sample;
    _url = url;
    _format = format;
    
    MLNExportableType *exportableType = format[@"formatDetails"];
    
    _outputFormat.mSampleRate = [sample sampleRate];
    _outputFormat.mFormatID = [exportableType formatID];
    _outputFormat.mChannelsPerFrame = (UInt32)[sample numberOfChannels];
    if (_outputFormat.mFormatID == kAudioFormatLinearPCM) {
        _outputFormat.mBitsPerChannel = 16;
        _outputFormat.mBytesPerPacket = _outputFormat.mChannelsPerFrame * (_outputFormat.mBitsPerChannel / 8);
        _outputFormat.mFramesPerPacket = 1;
        _outputFormat.mBytesPerFrame = _outputFormat.mBytesPerPacket;
        _outputFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        
        if ([exportableType isBigEndian]) {
            _outputFormat.mFormatFlags |= kLinearPCMFormatFlagIsBigEndian;
        }
    } else {
        size = sizeof(_outputFormat);
        err = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &_outputFormat);
        if (check_status_is_error(err, "AudioFileGetProperty")) {
            self = nil;
            return nil;
        }
    }
    
    CFURLRef urlRef = (__bridge CFURLRef)_url;

    err = ExtAudioFileCreateWithURL(urlRef, [exportableType typeID], &(_outputFormat),
                                    NULL, kAudioFileFlags_EraseFile, &(_outputFile));
    if (check_status_is_error(err, "ExtAudioFileCreateWithURL")) {
        self = nil;
        return nil;
    }
    
    AudioStreamBasicDescription clientFormat;
    
    clientFormat.mFormatID = kAudioFormatLinearPCM;
    clientFormat.mFormatFlags = kAudioFormatFlagsAudioUnitCanonical;
    clientFormat.mSampleRate = _outputFormat.mSampleRate;
    clientFormat.mChannelsPerFrame = _outputFormat.mChannelsPerFrame;
    clientFormat.mFramesPerPacket = 1;
    clientFormat.mBytesPerFrame = 4;
    clientFormat.mBytesPerPacket = 4;
    clientFormat.mBitsPerChannel = 8 * sizeof(AudioUnitSampleType);
    
    size = sizeof(clientFormat);
    err = ExtAudioFileSetProperty(_outputFile, kExtAudioFileProperty_ClientDataFormat, size, &clientFormat);
    if (check_status_is_error(err, "ExtAudioFileSetProperty")) {
        dump_asbd(&clientFormat);
        
        self = nil;
        return nil;
    }
    
    return self;
}

- (void)finishUpOnMainThread:(id)object
{
    [super operationDidFinish];
}

#define BUFFER_SIZE (1024 * 1024) // 1MB of data for each block initially. About 6 seconds of audio at 44.1khz
#define MAX_FRAMES_PER_BUFFER (BUFFER_SIZE / 4)

- (void)main
{
    AudioBufferList *bufferList = NULL;
    NSUInteger *channelLocations;
    int i;
    
    
    bufferList = malloc(sizeof(AudioBufferList) + (sizeof(AudioBuffer) * (_outputFormat.mChannelsPerFrame - 1)));
    bufferList->mNumberBuffers = _outputFormat.mChannelsPerFrame;
    
    channelLocations = calloc(bufferList->mNumberBuffers, sizeof(NSUInteger));
    
    for (i = 0; i < bufferList->mNumberBuffers; i++) {
        bufferList->mBuffers[i].mNumberChannels = 1;
        bufferList->mBuffers[i].mDataByteSize = BUFFER_SIZE * sizeof(float);
        bufferList->mBuffers[i].mData = malloc(BUFFER_SIZE * sizeof(float));
        
        channelLocations[i] = 0;
    }
    
    NSArray *channelArray = [_sample channelData];
    
    BOOL channelIsFinished = NO;
    
    NSUInteger totalFrames = [_sample numberOfFrames];
    
    while (1) {
        size_t bytesInBuffer = 0;

        if ([self isCancelled]) {
            break;
        }
        
        for (i = 0; i < bufferList->mNumberBuffers; i++) {
            MLNSampleChannel *channel = channelArray[i];            
            bytesInBuffer = [channel fillBuffer:bufferList->mBuffers[i].mData
                                     withLength:BUFFER_SIZE * sizeof(float)
                                      fromFrame:channelLocations[i]];
            
            if (bytesInBuffer == 0) {
                channelIsFinished = YES;
                break;
            }

            channelLocations[i] += bytesInBuffer / sizeof(float);

            bufferList->mBuffers[i].mDataByteSize = (UInt32)bytesInBuffer;
        }
        
        OSStatus err = noErr;
        
        if (channelIsFinished) {
            break;
        }
        
        err = ExtAudioFileWrite(_outputFile, (UInt32)bytesInBuffer / sizeof(float), bufferList);
        if (check_status_is_error(err, "ExtAudioFileWrite")) {
            break;
        }
        
        float percentage = ((float)channelLocations[0] / (float)totalFrames) * 100.0;
        
        [self setProgress:(int)percentage];
        [self sendProgressOnMainThread:percentage
                         operationName:@"Exporting sample"
                           framesSoFar:channelLocations[0]
                           totalFrames:totalFrames];
    }
    
    ExtAudioFileDispose(_outputFile);

    free(channelLocations);
    for (i = 0; i < bufferList->mNumberBuffers; i++) {
        free(bufferList->mBuffers[i].mData);
    }
    free(bufferList);
}

// FIXME: This should be a shared function
@end
