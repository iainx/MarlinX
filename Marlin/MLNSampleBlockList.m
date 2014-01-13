//
//  MLNSampleBlockList.m
//  Marlin
//
//  Created by iain on 13/01/2014.
//  Copyright (c) 2014 iain. All rights reserved.
//

#import "MLNSampleBlockList.h"

@implementation MLNSampleBlockList

- (id)initWithBlocks:(MLNSampleBlock *)blocks
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _cBlockList = blocks;
    return self;
}

- (void)dealloc
{
    if (_cBlockList) {
        MLNSampleBlockListFree(_cBlockList);
    }
}

- (void)disownBlockList
{
    _cBlockList = NULL;
}
@end
