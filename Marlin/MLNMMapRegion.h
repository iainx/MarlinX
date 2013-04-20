//
//  MLNMMapRegion.h
//  Marlin
//
//  Created by iain on 11/02/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MLNCacheFile;

#ifndef __MLNMAPREGION_H
#define __MLNMAPREGION_H

typedef struct MLNMapRegion {
    void *dataRegion;
    size_t byteLength;
    BOOL mapped;
    
    __unsafe_unretained MLNCacheFile *cacheFile;
    
    off_t filePos; // This is the position in the file that we are written to.
    
    int refCount;
} MLNMapRegion;

void MLNMapRegionRetain(MLNMapRegion *region);
void MLNMapRegionRelease(MLNMapRegion *region);

MLNMapRegion *MLNMapRegionCreateRegion (MLNCacheFile *cacheFile,
                                        void *data,
                                        size_t byteLength);
BOOL MLNMapRegionMapData (MLNMapRegion *region);

#endif