//
//  MLNSampleBlockSilence.h
//  Marlin
//
//  Created by iain on 08/02/2014.
//  Copyright (c) 2014 iain. All rights reserved.
//

#import "MLNSampleBlock.h"

#ifndef __MLNSAMPLEBLOCKSILENCE_H
#define __MLNSAMPLEBLOCKSILENCE_H

typedef struct _MLNSampleBlockSilence {
    MLNSampleBlock parentBlock;
} MLNSampleBlockSilence;

MLNSampleBlock *
MLNSampleBlockSilenceCreateBlock(NSUInteger numberOfFrames);

#endif