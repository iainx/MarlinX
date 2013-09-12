//
//  MLNLoadOperation.m
//  Marlin
//
//  Created by iain on 29/01/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>

#import "MLNLoadOperation.h"
#import "MLNSample.h"
#import "MLNSampleBlock.h"
#import "MLNSampleChannel.h"
#import "Constants.h"

@implementation MLNLoadOperation {
    ExtAudioFileRef _fileRef;
    AudioStreamBasicDescription _outputFormat;
    NSMutableArray *_channelArray;
    NSError *_error;
}

- (id)initForSample:(MLNSample *)sample
{
    self = [super init];
    if (!self) {
        return nil;
    }

    [self setPrimaryText:@"Loading"];
    [self setSecondaryText:@"Something something"];
    [self setProgress:0];
    
    __weak MLNLoadOperation *weakSelf = self;
    
    [self setCompletionBlock:^{
        [weakSelf performSelectorOnMainThread:@selector(updateSampleOnMainThread:) withObject:nil waitUntilDone:NO];
    }];
    
    OSStatus status;
    CFURLRef urlRef = (__bridge CFURLRef)[sample url];

    // Set up the fileRef on the main thread so we keep sample/url as main thread objects
    // _fileRef can now be safely handed over to the worker thread as it is never used
    // on the main thread again.
    status = ExtAudioFileOpenURL(urlRef, &_fileRef);
    if (check_status_is_error(status, "ExtAudioFileOpenURL")) {
        _error = make_error(status, "ExtAudioFileOpenURL", __PRETTY_FUNCTION__, __LINE__);
        
        if (_error && [_delegate respondsToSelector:@selector(didFailLoadWithError:)]) {
            [_delegate didFailLoadWithError:_error];
        }

        self = nil;
        return nil;
    }

    return self;
}

#define BUFFER_SIZE (1024 * 1024) // 1MB of data for each block initially. About 6 seconds of audio at 44.1khz
#define MAX_FRAMES_PER_BUFFER (BUFFER_SIZE / 4)

- (void)main
{
    AudioBufferList *bufferList = NULL;
    AudioStreamBasicDescription inFormat;
    OSStatus status;
    UInt32 i;
    
    UInt32 propSize = sizeof(inFormat);
    status = ExtAudioFileGetProperty(_fileRef, kExtAudioFileProperty_FileDataFormat, &propSize, &inFormat);
    if (check_status_is_error(status, "ExtAudioFileGetProperty")) {
        _error = make_error(status, "ExtAudioFileGetProperty", __PRETTY_FUNCTION__, __LINE__);
        goto cleanup;
    }


    // Setup the output asbd
    _outputFormat.mFormatID = kAudioFormatLinearPCM;
    _outputFormat.mFormatFlags = kAudioFormatFlagsAudioUnitCanonical;
    _outputFormat.mSampleRate = inFormat.mSampleRate;
    _outputFormat.mChannelsPerFrame = inFormat.mChannelsPerFrame;
    _outputFormat.mFramesPerPacket = 1;
    _outputFormat.mBytesPerFrame = 4;
    _outputFormat.mBytesPerPacket = 4;
    _outputFormat.mBitsPerChannel = 32;
    
    // Set the output format on the input file
    status = ExtAudioFileSetProperty(_fileRef, kExtAudioFileProperty_ClientDataFormat,
                                     sizeof(AudioStreamBasicDescription), &_outputFormat);
    if (check_status_is_error(status, "ExtAudioFileSetProperty")) {
        _error = make_error (status, "ExtAudioFileSetProperty", __PRETTY_FUNCTION__, __LINE__);
        goto cleanup;
    }
    
    propSize = sizeof(SInt64);
    SInt64 totalFrameCount;
    
    status = ExtAudioFileGetProperty(_fileRef, kExtAudioFileProperty_FileLengthFrames, &propSize, &totalFrameCount);
    if (check_status_is_error(status, "ExtAudioFileGetProperty")) {
        _error = make_error(status, "ExtAudioFileGetProperty", __PRETTY_FUNCTION__, __LINE__);
        goto cleanup;
    }
    
    // Create the array of buffers for each channel
    _channelArray = [NSMutableArray arrayWithCapacity:_outputFormat.mChannelsPerFrame];

    for (i = 0; i < _outputFormat.mChannelsPerFrame; i++) {
        MLNSampleChannel *channel = [[MLNSampleChannel alloc] init];
        [channel setChannelName:[NSString stringWithFormat:@"Channel %d", i + 1]];
        [_channelArray addObject:channel];
    }
    
    // Create enough AudioBuffers for our data.
    // AudioBufferList only defines enough buffers for mono.
    bufferList = malloc(sizeof(AudioBufferList) + (sizeof(AudioBuffer) * (_outputFormat.mChannelsPerFrame - 1)));
    bufferList->mNumberBuffers = _outputFormat.mChannelsPerFrame;
    for ( int i=0; i < bufferList->mNumberBuffers; i++ ) {
        bufferList->mBuffers[i].mNumberChannels = 1;
        bufferList->mBuffers[i].mDataByteSize = BUFFER_SIZE * sizeof(float);
        bufferList->mBuffers[i].mData = malloc(BUFFER_SIZE * sizeof(float));
    }
    
    SInt64 framesSoFar = 0;
    
    while (1) {
        OSStatus status;
        UInt32 frameCount = BUFFER_SIZE / sizeof(float);

        if ([self isCancelled]) {
            break;
        }
        
        status = ExtAudioFileRead(_fileRef, &frameCount, bufferList);
        if (check_status_is_error(status, "ExtAudioFileRead")) {
            _error = make_error(status, "ExtAudioFileRead", __PRETTY_FUNCTION__, __LINE__);
            break;
        }
        
        //fprintf(stdout, "Requested %d bytes: got %d\n", NUMBER_OF_FRAMES_PER_READ, numberOfFrames);
        if (frameCount == 0) {
            break;
        }
        
        for (i = 0; i < _outputFormat.mChannelsPerFrame; i++) {
            MLNSampleChannel *channel = _channelArray[i];
            
            [channel addData:bufferList->mBuffers[i].mData withLength:frameCount * sizeof(float)];
        }
        
        // Post percentage notification
        framesSoFar += frameCount;
        float percentage = ((float)framesSoFar / (float)totalFrameCount) * 100.0;
        
        [self setProgress:(int)percentage];
        [self sendProgressOnMainThread:percentage
                         operationName:@"Loading sample"
                           framesSoFar:framesSoFar
                           totalFrames:totalFrameCount];
    }

    for (int i = 0; i < _outputFormat.mChannelsPerFrame; i++) {
        MLNSampleChannel *channel = _channelArray[i];
        [channel dumpChannel:NO];
    }
    
    fprintf(stdout, "Loaded %lld frames\n", framesSoFar);
    // Sanity check
    if (framesSoFar != totalFrameCount) {
        fprintf(stderr, "Loaded %lld frames, desired %llu\n", framesSoFar, totalFrameCount);
        // FIXME: Should there be an assert of an exception thrown?
    }
cleanup:
    if (bufferList) {
        for ( int i=0; i < bufferList->mNumberBuffers; i++ ) {
            free(bufferList->mBuffers[i].mData);
        }
        free(bufferList);
    }
    
    // Dispose of the fileRef on the worker thread
    ExtAudioFileDispose(_fileRef);
    _fileRef = NULL;
}

- (void)updateSampleOnMainThread:(id)object
{
    if (_error && [_delegate respondsToSelector:@selector(didFailLoadWithError:)]) {
        [_delegate didFailLoadWithError:_error];
        
        _error = nil;
        return;
    }
    
    if ([_delegate respondsToSelector:@selector(sampleDidLoadData:description:)]) {
        [_delegate sampleDidLoadData:_channelArray description:_outputFormat];
    }
}

#pragma mark - Sending notifications

- (void)sendNotificationOnMainThread:(NSNotification *)note
{
    [[NSNotificationCenter defaultCenter] postNotification:note];
}

- (void)sendProgressOnMainThread:(float)percentage
                   operationName:(NSString *)operationName
                     framesSoFar:(SInt64)framesSoFar
                     totalFrames:(SInt64)totalFrames
{
    NSDictionary *userInfo = @{kMLNProgressPercentage : @(percentage), kMLNProgressFramesSoFar: @(framesSoFar), kMLNProgressTotalFrames: @(totalFrames), kMLNProgressOperationName: operationName};
    
    [self performSelectorOnMainThread:@selector(sendNotificationOnMainThread:)
                           withObject:[NSNotification notificationWithName:kMLNProgressNotification
                                                                    object:self
                                                                  userInfo:userInfo]
                        waitUntilDone:NO];
}

#pragma mark - Utility functions

static bool
check_status_is_error (OSStatus    status,
                       const char *operation)
{
    if (status == noErr) {
        return false;
    }
    
    char str[20];
	// see if it appears to be a 4-char-code
	*(UInt32 *)(str + 1) = CFSwapInt32HostToBig(status);
	if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
		str[0] = str[5] = '\'';
		str[6] = '\0';
	} else {
		// no, format it as an integer
		sprintf(str, "%d", (int)status);
	}
	fprintf(stderr, "Error: %s (%s)\n", operation, str);
    //fprintf(stderr, "   %s - %s", GetMacOSStatusErrorString(status), GetMacOSStatusCommentString(status));
    //NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
    //NSLog(@"   %@ - %@\n", [error localizedFailureReason], [error localizedDescription]);
    
    return true;
}

static NSError *
make_error (OSStatus    status,
            const char *operation,
            const char *function,
            int         linenumber)
{
    return [NSError errorWithDomain:kMLNSampleErrorDomain
                               code:MLNSampleLoadError
                           userInfo:@{@"method" : [NSString stringWithFormat:@"%s (%s:%d)", operation, function, linenumber], @"statusCode": @(status)}];
}
@end
