//
//  MLNSampleTests.m
//  MLNSampleTests
//
//  Created by iain on 15/04/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNSampleTests.h"

#import "MLNSampleBlock.h"
#import "MLNSampleChannel.h"
#import "MLNSample.h"

@implementation MLNSampleTests {
    MLNSample *_testSample;
}

static const NSUInteger BUFFER_FRAME_SIZE = 44100;

- (void)setUp
{
    [super setUp];
    
    NSMutableArray *channels = [NSMutableArray array];
    
    MLNSampleChannel *channel = [[MLNSampleChannel alloc] init];
    [channel setChannelName:@"Test channel"];
    
    float *buffer = malloc(BUFFER_FRAME_SIZE * sizeof(float));
    
    // Fill all the frames with dummy data
    for (int i = 0; i < BUFFER_FRAME_SIZE; i++) {
        buffer[i] = (float)i;
    }
    
    [channel addData:buffer withLength:BUFFER_FRAME_SIZE * sizeof(float)];
    
    [channels addObject:channel];
    
    _testSample = [[MLNSample alloc] init];
    [_testSample setChannelData:channels];
}

- (void)tearDown
{
    _testSample = nil;
    
    [super tearDown];
}

- (void)testData
{
    MLNSampleChannel *channel = [_testSample channelData][0];
    
    STAssertNotNil(channel, @"Channel is nil");
    
    MLNSampleBlock *block = [channel firstBlock];
    
    STAssertFalse(block == NULL, @"Block is NULL");
    
    NSUInteger numberOfFrames = block->numberOfFrames;
    
    STAssertEquals(numberOfFrames, BUFFER_FRAME_SIZE, @"Number of frames are different: Expected %d, got %d", BUFFER_FRAME_SIZE, numberOfFrames);
    
    const float *data = MLNSampleBlockSampleData(block);
    
    STAssertFalse(data == NULL, @"Sample data is NULL");
    
    for (int i = 0; i < BUFFER_FRAME_SIZE; i++) {
        float d = data[i];
        
        STAssertEquals(d, (float)i, @"Frame %d is %f: Expected %f", i, d, (float)i);
    }
}

@end
