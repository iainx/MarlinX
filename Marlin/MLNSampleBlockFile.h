//
//  MLNSampleBlockFile.h
//  Marlin
//
//  Created by iain on 03/01/2014.
//  Copyright (c) 2014 iain. All rights reserved.
//

#import "MLNSampleBlock.h"

#ifndef __MLNSAMPLEBLOCKFILE_H
#define __MLNSAMPLEBLOCKFILE_H

typedef struct _MLNSampleBlockFile {
    MLNSampleBlock parentBlock;
    
    size_t sampleByteLength;
    size_t cacheByteLength;
    
    MLNMapRegion *region;
    off_t byteOffset; // Byte offset into [_region dataRegion]
    
    MLNMapRegion *cacheRegion;
    off_t cacheByteOffset;
} MLNSampleBlockFile;

MLNSampleBlock *
MLNSampleBlockFileCreateBlock(MLNMapRegion *region,
                              size_t byteLength,
                              off_t offset,
                              MLNMapRegion *cacheRegion,
                              size_t cacheByteLength,
                              off_t cacheByteOffset);

#endif