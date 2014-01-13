//
//  MLNSampleBlockList.h
//  Marlin
//
//  Created by iain on 13/01/2014.
//  Copyright (c) 2014 iain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLNSampleBlock.h"

@interface MLNSampleBlockList : NSObject
@property (readonly) MLNSampleBlock *cBlockList;

- (id)initWithBlocks:(MLNSampleBlock *)blocks;
- (void)disownBlockList;

@end
