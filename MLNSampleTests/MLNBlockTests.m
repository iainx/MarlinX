//
//  MLNBlockTests.m
//  Marlin
//
//  Created by iain on 17/04/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNBlockTests.h"
#import "MLNSampleBlock.h"

@implementation MLNBlockTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testAppend
{
    MLNSampleBlock *block1, *block2, *block3;
    
    block1 = MLNSampleBlockCreateBlock(NULL, 0, 0, NULL, 0, 0);
    block2 = MLNSampleBlockCreateBlock(NULL, 0, 0, NULL, 0, 0);
    block3 = MLNSampleBlockCreateBlock(NULL, 0, 0, NULL, 0, 0);
    
    // Append block 2 to block 1
    MLNSampleBlockAppendBlock(block1, block2);
    
    STAssertFalse(block1->nextBlock == NULL, @"block1->nextBlock == NULL");
    STAssertTrue(block1->nextBlock == block2, @"block2->nextBlock != block2");
    STAssertFalse(block2->previousBlock == NULL, @"block2->previousBlock == NULL");
    STAssertTrue(block2->previousBlock == block1, @"block2->previousBlock != block2");
    
    // Append block 3 to block 1, inserting it before block 2
    MLNSampleBlockAppendBlock(block1, block3);
    
    // Check that block 3 is connected to block 1
    STAssertFalse(block1->nextBlock == NULL, @"block1->nextBlock == NULL");
    STAssertTrue(block1->nextBlock == block3, @"block1->nextBlock != block3");
    STAssertFalse(block3->previousBlock == NULL, @"block3->previouBlock == NULL");
    STAssertTrue(block3->previousBlock == block1, @"block3->previousBlock != block1");
    
    // Check that block 3 is connected to block 2
    STAssertFalse(block3->nextBlock == NULL, @"block3->nextBlock == NULL");
    STAssertTrue(block3->nextBlock == block2, @"block3->nextBlock != block2");
    STAssertFalse(block2->previousBlock == NULL, @"block2->previousBlock == NULL");
    STAssertTrue(block2->previousBlock == block3, @"block2->previousBlock != block2");
    
    MLNSampleBlockFree(block1);
    MLNSampleBlockFree(block2);
    MLNSampleBlockFree(block3);
}

- (void)testPrepend
{
    MLNSampleBlock *block1, *block2, *block3;
    
    block1 = MLNSampleBlockCreateBlock(NULL, 0, 0, NULL, 0, 0);
    block2 = MLNSampleBlockCreateBlock(NULL, 0, 0, NULL, 0, 0);
    block3 = MLNSampleBlockCreateBlock(NULL, 0, 0, NULL, 0, 0);
    
    // Prepend block 2 to block 1
    MLNSampleBlockPrependBlock(block1, block2);
    
    STAssertFalse(block1->previousBlock == NULL, @"block1->previousBlock == NULL");
    STAssertTrue(block1->previousBlock == block2, @"block1->previousBlock != block2");
    STAssertFalse(block2->nextBlock == NULL, @"block2->nextBlock == NULL");
    STAssertTrue(block2->nextBlock == block1, @"block2->nextBlock != block1");
    
    // Prepend block 3 to block 1, inserting it after block 2
    MLNSampleBlockPrependBlock(block1, block3);
    
    // Check that block 3 is connected to block 1
    STAssertFalse(block1->previousBlock == NULL, @"block1->previousBlock == NULL");
    STAssertTrue(block1->previousBlock == block3, @"block1->previousBlock != block3");
    STAssertFalse(block3->nextBlock == NULL, @"block3->nextBlock == NULL");
    STAssertTrue(block3->nextBlock == block1, @"block3->nextBlock != block1");
    
    // Check that block 3 is connected to block 2
    STAssertFalse(block3->previousBlock == NULL, @"block3->previousBlock == NULL");
    STAssertTrue(block3->previousBlock == block2, @"block3->previousBlock != block2");
    STAssertFalse(block2->nextBlock == NULL, @"block2->nextBlock == NULL");
    STAssertTrue(block2->nextBlock == block3, @"block2->nextBlock != block3");
    
    MLNSampleBlockFree(block1);
    MLNSampleBlockFree(block2);
    MLNSampleBlockFree(block3);
}

- (void)testRemove
{
    MLNSampleBlock *block1, *block2, *block3;
    
    block1 = MLNSampleBlockCreateBlock(NULL, 0, 0, NULL, 0, 0);
    block2 = MLNSampleBlockCreateBlock(NULL, 0, 0, NULL, 0, 0);
    block3 = MLNSampleBlockCreateBlock(NULL, 0, 0, NULL, 0, 0);

    // Make a list of block1->block2->block3
    // We know this works because the earlier test succeeded
    MLNSampleBlockAppendBlock(block1, block2);
    MLNSampleBlockAppendBlock(block2, block3);
    
    // Remove block2
    MLNSampleBlockRemoveFromList(block2);
    
    // Check block2 is detached
    STAssertTrue(block2->previousBlock == NULL, @"block2->previousBlock != NULL");
    STAssertTrue(block2->nextBlock == NULL, @"block2->nextBlock != NULL");
    
    // Check block1 & block3 are connected
    STAssertFalse(block1->nextBlock == NULL, @"block1->nextBlock == NULL");
    STAssertTrue(block1->nextBlock == block3, @"block1->nextBlock != block3");
    STAssertFalse(block3->previousBlock == NULL, @"block3->previousBlock == NULL");
    STAssertTrue(block3->previousBlock == block1, @"block3->previousBlock != block1");
    
    // Remove block3
    MLNSampleBlockRemoveFromList(block3);
    
    // Check block3 is detached
    STAssertTrue(block3->previousBlock == NULL, @"block3->previousBlock != NULL");
    STAssertTrue(block3->nextBlock == NULL, @"block3->nextBlock != NULL");
    
    // Check block1 is detached
    STAssertTrue(block1->previousBlock == NULL, @"block3->previousBlock != NULL");
    STAssertTrue(block1->nextBlock == NULL, @"block3->nextBlock != NULL");

    MLNSampleBlockFree(block1);
    MLNSampleBlockFree(block2);
    MLNSampleBlockFree(block3);
}
@end
