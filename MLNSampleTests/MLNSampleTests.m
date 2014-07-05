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
#import "MLNSampleChannelIterator.h"
#import "MLNSample.h"
#import "MLNSample+Operations.h"

@implementation MLNSampleTests {
    MLNSample *_testSample;
    MLNSample *_testStereoSample;
}

static const NSUInteger BUFFER_FRAME_SIZE = 44100;

- (MLNSampleChannel *)makeChannelWithName:(NSString *)name
{
    MLNSampleChannel *channel = [[MLNSampleChannel alloc] init];
    [channel setChannelName:name];
    
    float *buffer = malloc(BUFFER_FRAME_SIZE * sizeof(float));
    
    // Fill all the frames with dummy data
    for (int i = 0; i < BUFFER_FRAME_SIZE; i++) {
        buffer[i] = (float)i;
    }
    
    [channel addData:buffer withByteLength:BUFFER_FRAME_SIZE * sizeof(float)];
    
    return channel;
}

- (void)setUp
{
    srand((unsigned int)time(NULL));
    
    [super setUp];
    
    NSMutableArray *channels = [NSMutableArray array];
    
    [channels addObject:[self makeChannelWithName:@"Test Channel - Mono"]];
    
    _testSample = [[MLNSample alloc] initWithChannels:channels];
    
    
    channels = [NSMutableArray arrayWithCapacity:2];
    [channels addObject:[self makeChannelWithName:@"Test Channel - Left"]];
    [channels addObject:[self makeChannelWithName:@"Test Channel - Right"]];
    
    _testStereoSample = [[MLNSample alloc] initWithChannels:channels];
}

- (void)tearDown
{
    _testSample = nil;
    _testStereoSample = nil;
    [super tearDown];
}

- (void)testData
{
    XCTAssertEqual([_testSample numberOfFrames], (NSUInteger)44100);
    
    MLNSampleChannel *channel = [_testSample channelData][0];
    
    XCTAssertNotNil(channel, @"Channel is nil");
    
    MLNSampleBlock *block = [channel firstBlock];
    
    XCTAssertFalse(block == NULL, @"Block is NULL");
    
    NSUInteger numberOfFrames = block->numberOfFrames;
    
    XCTAssertEqual(numberOfFrames, BUFFER_FRAME_SIZE, @"Number of frames are different: Expected %d, got %d", BUFFER_FRAME_SIZE, numberOfFrames);
    
    for (int i = 0; i < BUFFER_FRAME_SIZE; i++) {
        float value = MLNSampleBlockDataAtFrame(block, i);
        
        XCTAssertEqual(value, (float)i, @"Frame %d is %f: Expected %f", i, value, (float)i);
    }
}

- (void)checkData
{
    MLNSampleChannel *channel = [_testSample channelData][0];
    MLNSampleChannelIterator *iter = [[MLNSampleChannelIterator alloc] initWithChannel:channel
                                                                               atFrame:0];
    BOOL moreData = YES;
    int i = 0;
    
    while (moreData) {
        float value;
        moreData = [iter frameDataAndAdvance:&value];
        
        XCTAssertEqual(value, (float)i, @"");
        i++;
    }
}

- (void)testDeleteRange
{
    [_testSample deleteRange:NSMakeRange(100, 100) undoManager:nil];
    
    // If the Channel tests have passed then the only thing this needs to test is that the sample has the correct number of frames
    XCTAssertEqual([_testSample numberOfFrames], (NSUInteger)44000, @"[_testSample numberOfFrames != 44000: %lu", [_testSample numberOfFrames]);
}

- (void)testDeleteRangeUndo
{
    NSUndoManager *undo = [[NSUndoManager alloc] init];
    
    [_testSample deleteRange:NSMakeRange(100, 100) undoManager:undo];
    
    XCTAssertTrue([undo canUndo], @"");
    
    [undo undo];
    
    XCTAssertFalse([undo canUndo], @"");
    
    XCTAssertEqual([_testSample numberOfFrames], (NSUInteger)44100, @"");
    
    [self checkData];
}

- (void)testInsert
{
    MLNSampleChannel *channel = [self makeChannelWithName:@"testchannel"];
    NSUInteger insertFrame = rand() % [_testSample numberOfFrames];
    
    BOOL result = [_testSample insertChannels:@[channel]
                                      atFrame:insertFrame
                              withUndoManager:nil];
    
    XCTAssertTrue(result, @"");
    
    XCTAssertEqual([_testSample numberOfFrames], (NSUInteger)88200, @"%lu", insertFrame);
}

- (void)testInsertStart
{
    MLNSampleChannel *channel = [self makeChannelWithName:@"testchannel"];
    
    BOOL result = [_testSample insertChannels:@[channel]
                                      atFrame:0
                              withUndoManager:nil];
    
    XCTAssertTrue(result, @"");
    
    XCTAssertEqual([_testSample numberOfFrames], (NSUInteger)88200, @"");
}

- (void)testInsertEnd
{
    MLNSampleChannel *channel = [self makeChannelWithName:@"testchannel"];
    
    BOOL result = [_testSample insertChannels:@[channel]
                                      atFrame:[_testSample numberOfFrames]
                              withUndoManager:nil];
    
    XCTAssertTrue(result, @"");
    
    XCTAssertEqual([_testSample numberOfFrames], (NSUInteger)88200, @"");
}

- (void)testInsertUndo
{
    NSUndoManager *undo = [[NSUndoManager alloc] init];
    
    MLNSampleChannel *channel = [self makeChannelWithName:@"testchannel"];
    NSUInteger insertFrame = rand() % [_testSample numberOfFrames];
    
    BOOL result = [_testSample insertChannels:@[channel]
                                      atFrame:insertFrame
                              withUndoManager:undo];
    
    XCTAssertTrue(result, @"");
    
    XCTAssertEqual([_testSample numberOfFrames], (NSUInteger)88200, @"%lu", insertFrame);
    
    [undo undo];
    
    XCTAssertEqual([_testSample numberOfFrames], (NSUInteger)44100, @"%lu", insertFrame);
    
    [self checkData];
}

- (void)testCropRange
{
    NSUInteger start = rand() % [_testSample numberOfFrames];
    NSUInteger length = rand() % ([_testSample numberOfFrames] - start);
    
    NSRange range = NSMakeRange(start, length);
    
    [_testSample cropRange:range withUndoManager:nil];
    
    XCTAssertEqual([_testSample numberOfFrames], length, @"Range is %@", NSStringFromRange(range));
}

- (void)testCropRangeUndo
{
    NSUndoManager *undo = [[NSUndoManager alloc] init];
    NSUInteger start = rand() % [_testSample numberOfFrames];
    NSUInteger length = rand() % ([_testSample numberOfFrames] - start);
    
    NSRange range = NSMakeRange(start, length);
    
    [_testSample cropRange:range withUndoManager:undo];
    
    MLNSampleChannel *channel = [_testSample channelData][0];
    MLNSampleBlock *block = [channel firstBlock];
    
    XCTAssertFalse(block == NULL, @"");
    [undo undo];
    
    XCTAssertEqual([_testSample numberOfFrames], (NSUInteger)44100, @"");
    [self checkData];
}

- (void)checkSilenceInRange:(NSRange)range
{
    MLNSampleChannelIterator *iter;
    MLNSampleChannel *channel = [_testSample channelData][0];
    
    NSLog(@"number of frames in channel: %lu", [channel numberOfFrames]);
    NSUInteger i;
    
    iter = [[MLNSampleChannelIterator alloc] initWithChannel:channel atFrame:0];
    BOOL moreData = YES;
    
    i = 0;
    while (moreData) {
        float value;
        moreData = [iter frameDataAndAdvance:&value];
        
        if (NSLocationInRange(i, range)) {
            XCTAssertEqual(value, (float)0, @"at %lu (%@)", i, NSStringFromRange(range));
        } else if (i < range.location) {
            XCTAssertEqual(value, (float)i, @"at %lu (%@)", i, NSStringFromRange(range));
        } else {
            XCTAssertEqual(value, (float)i - range.length, @"at %lu (%@)", i, NSStringFromRange(range));
        }
        
        i++;
    }
}

- (void)testInsertSilence
{
    NSUInteger frame = rand() % [_testSample numberOfFrames];
    NSUInteger numberOfFrames = rand() % 44100;
    NSUInteger expectedNumberOfFrames = [_testSample numberOfFrames] + numberOfFrames;
    
    [_testSample insertSilenceAtFrame:frame numberOfFrames:numberOfFrames undoManager:nil];
    
    XCTAssertEqual([_testSample numberOfFrames], (NSUInteger)expectedNumberOfFrames, @"");
    
    [self checkSilenceInRange:NSMakeRange(frame, numberOfFrames)];
}

- (void)testInsertSilenceStart
{
    NSUInteger numberOfFrames = rand() % 44100;
    NSUInteger expectedNumberOfFrames = [_testSample numberOfFrames] + numberOfFrames;
    
    [_testSample insertSilenceAtFrame:0 numberOfFrames:numberOfFrames undoManager:nil];
    
    XCTAssertEqual([_testSample numberOfFrames], expectedNumberOfFrames, @"");
    
    [self checkSilenceInRange:NSMakeRange(0, numberOfFrames)];
}

- (void)testInsertSilenceEnd
{
    NSUInteger numberOfFrames = rand() % 44100;
    NSUInteger expectedNumberOfFrames = [_testSample numberOfFrames] + numberOfFrames;
    
    [_testSample insertSilenceAtFrame:[_testSample numberOfFrames] numberOfFrames:numberOfFrames undoManager:nil];
    
    XCTAssertEqual([_testSample numberOfFrames], expectedNumberOfFrames, @"");

    [self checkSilenceInRange:NSMakeRange(44100, numberOfFrames)];
}

- (void)testInsertSilenceUndo
{
    NSUndoManager *undo = [[NSUndoManager alloc] init];

    NSUInteger frame = rand() % [_testSample numberOfFrames];
    NSUInteger numberOfFrames = rand() % 44100;
    NSUInteger expectedNumberOfFrames = [_testSample numberOfFrames] + numberOfFrames;
    
    [_testSample insertSilenceAtFrame:frame numberOfFrames:numberOfFrames undoManager:undo];
    
    XCTAssertEqual([_testSample numberOfFrames], (NSUInteger)expectedNumberOfFrames, @"");
    
    [undo undo];
    
    XCTAssertEqual([_testSample numberOfFrames], (NSUInteger)44100, @"");
    
    [self checkData];
}

- (void)checkClearInRange:(NSRange)range
{
    MLNSampleChannel *channel = [_testSample channelData][0];
    MLNSampleChannelIterator *iter = [[MLNSampleChannelIterator alloc] initWithChannel:channel atFrame:0];
    BOOL moreData = YES;
    int i = 0;
    
    while (moreData) {
        float value;
        
        moreData = [iter frameDataAndAdvance:&value];
        
        if (NSLocationInRange(i, range)) {
            XCTAssertEqual(value, (float)0.0, @"");
        } else {
            XCTAssertEqual(value, (float)i, @"");
        }
        
        i++;
    }
}

- (void)testClearRange
{
    NSUInteger start = rand() % [_testSample numberOfFrames];
    NSUInteger length = (rand() % ([_testSample numberOfFrames] - start) + 1);
    NSRange range = NSMakeRange(start, length);
    
    [_testSample clearRange:range withUndoManager:nil];
    
    XCTAssertEqual([_testSample numberOfFrames], (NSUInteger)44100, @"");
    
    [self checkClearInRange:range];
}

- (void)testClearRangeStart
{
    NSUInteger length = (rand() % [_testSample numberOfFrames] + 1);
    NSUInteger start = 0;
    NSRange range = NSMakeRange(start, length);
    
    [_testSample clearRange:range withUndoManager:nil];
    
    XCTAssertEqual([_testSample numberOfFrames], (NSUInteger)44100, @"");
    
    [self checkClearInRange:range];
}

- (void)testClearRangeEnd
{
    NSUInteger length = (rand() % [_testSample numberOfFrames] + 1);
    NSUInteger start = [_testSample numberOfFrames] - length;
    NSRange range = NSMakeRange(start, length);
    
    [_testSample clearRange:range withUndoManager:nil];
    
    XCTAssertEqual([_testSample numberOfFrames], (NSUInteger)44100, @"");
    
    [self checkClearInRange:range];
}

- (void)testClearAll
{
    NSRange range = NSMakeRange(0, [_testSample numberOfFrames]);
    
    [_testSample clearRange:range withUndoManager:nil];
    
    XCTAssertEqual([_testSample numberOfFrames], (NSUInteger)44100, @"");
    
    [self checkClearInRange:range];
}

- (void)testClearRangeUndo
{
    NSUndoManager *undo = [[NSUndoManager alloc] init];

    NSUInteger start = rand() % [_testSample numberOfFrames];
    NSUInteger length = (rand() % ([_testSample numberOfFrames] - start) + 1);
    NSRange range = NSMakeRange(start, length);
    
    [_testSample clearRange:range withUndoManager:undo];
    
    XCTAssertEqual([_testSample numberOfFrames], (NSUInteger)44100, @"");
    
    [undo undo];
    
    XCTAssertEqual([_testSample numberOfFrames], (NSUInteger)44100, @"");
    
    [self checkData];
}

- (void)checkReverseInRange:(NSRange)range
{
    MLNSampleChannel *channel = [_testSample channelData][0];
    MLNSampleChannelIterator *iter = [[MLNSampleChannelIterator alloc] initWithChannel:channel
                                                                               atFrame:0];
    BOOL moreData = YES;
    NSUInteger i = 0;
    
    while (moreData) {
        float value = 0;
        moreData = [iter frameDataAndAdvance:&value];
        
        if (NSLocationInRange(i, range)) {
            NSUInteger offset = i - range.location;
            XCTAssertEqual(value, (float)((NSMaxRange(range) - 1) - offset), @"%@ - %lu - %lu - %lu", NSStringFromRange(range), offset, NSMaxRange(range), i);
        } else {
            XCTAssertEqual(value, (float)i, @"");
        }
        
        i++;
    }
}

- (void)testReverseRange
{
    NSUInteger start = rand() % [_testSample numberOfFrames];
    NSUInteger length = (rand() % ([_testSample numberOfFrames] - start) + 1);
    NSRange range = NSMakeRange(start, length);
    
    [_testSample reverseRange:range withUndoManager:nil];
    
    XCTAssertEqual([_testSample numberOfFrames], (NSUInteger)44100, @"");
    [self checkReverseInRange:range];
}

- (void)testReverseStart
{
    NSUInteger length = (rand() % [_testSample numberOfFrames] + 1);
    NSRange range = NSMakeRange(0, length);
    
    [_testSample reverseRange:range withUndoManager:nil];
    
    XCTAssertEqual([_testSample numberOfFrames], (NSUInteger)44100, @"");
    [self checkReverseInRange:range];
}

- (void)testReverseEnd
{
    NSUInteger length = (rand() % [_testSample numberOfFrames] + 1);
    NSUInteger start = [_testSample numberOfFrames] - length;
    NSRange range = NSMakeRange(start, length);
    
    [_testSample reverseRange:range withUndoManager:nil];
    
    XCTAssertEqual([_testSample numberOfFrames], (NSUInteger)44100, @"");
    [self checkReverseInRange:range];
}

- (void)testReverseAll
{
    NSRange range = NSMakeRange(0, [_testSample numberOfFrames]);
    
    [_testSample reverseRange:range withUndoManager:nil];
    
    XCTAssertEqual([_testSample numberOfFrames], (NSUInteger)44100, @"");
    [self checkReverseInRange:range];
}

- (void)testReverseUndo
{
    NSUndoManager *undo = [[NSUndoManager alloc] init];
    NSUInteger start = rand() % [_testSample numberOfFrames];
    NSUInteger length = (rand() % ([_testSample numberOfFrames] - start) + 1);
    NSRange range = NSMakeRange(start, length);
    
    [_testSample reverseRange:range withUndoManager:undo];
    
    XCTAssertEqual([_testSample numberOfFrames], (NSUInteger)44100, @"");
    
    [undo undo];
    
    XCTAssertEqual([_testSample numberOfFrames], (NSUInteger)44100, @"");
    [self checkData];
}
@end
