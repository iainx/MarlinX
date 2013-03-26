//
//  MLNMMapRegion.m
//  Marlin
//
//  Created by iain on 11/02/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNMMapRegion.h"

static BOOL MLNMapRegionWriteData (MLNMapRegion *region,
                                   void *data,
                                   size_t byteLength);

MLNMapRegion *
MLNMapRegionCreateRegion(int fd,
                         void *data,
                         size_t byteLength)
{
    MLNMapRegion *newRegion;
    
    newRegion = malloc(sizeof(MLNMapRegion));
    newRegion->fd = fd;
    
    MLNMapRegionWriteData(newRegion, data, byteLength);
    
    newRegion->byteLength = byteLength;
    
    MLNMapRegionMapData(newRegion);
    
    return newRegion;
}

void
MLNMapRegionFree(MLNMapRegion *region)
{
    if (region == NULL) {
        return;
    }
    
    munmap(region->dataRegion, region->byteLength);

    // FIXME: Do we need to close fd?
    free(region);
}

#define BUFFER_SIZE 64 * 1024

static BOOL
MLNMapRegionWriteData (MLNMapRegion *region,
                       void *data,
                       size_t byteLength)
{
    NSUInteger bytesLeft;
    
    region->filePos = lseek(region->fd, 0, SEEK_CUR);
    bytesLeft = byteLength;
    while (bytesLeft) {
        size_t bytesToWrite = MIN (BUFFER_SIZE, bytesLeft);
        ssize_t bytesWritten = write(region->fd, data, bytesLeft);
        
        if (bytesWritten == -1) {
            if (errno == -EAGAIN) {
                continue;
            } else {
                DDLogCError(@"Error writing %lu bytes to channel", bytesToWrite);
                
                // FIXME: Return NSError
                return NO;
            }
        }
        
        data += bytesWritten;
        bytesLeft -= bytesWritten;
        
        //fprintf(stdout, "Wrote %lu bytes (%lu/%lu left)\n", bytesWritten, bytesLeft, byteLength);
    }
    
    return YES;
}

#pragma mark - Mapping data into memory
// We don't always want all the data mapped into memory
// When we need the data, we map some in and when we're done with it
// we unmap it again.
BOOL
MLNMapRegionMapData (MLNMapRegion *region)
{
    if (region == NULL) {
        return NO;
    }
    
    region->dataRegion = mmap(NULL, region->byteLength,
                              PROT_READ | PROT_WRITE, MAP_SHARED,
                              region->fd, region->filePos);
    if (region->dataRegion == MAP_FAILED) {
        DDLogCError(@"Error mmapping data: %d", errno);
        
        // Return error properly
        return NO;
    }
    
    region->mapped = YES;
    return YES;
}

void
MLNMapRegionUnmapData (MLNMapRegion *region)
{
    if (region == NULL) {
        return;
    }
    
    region->mapped = NO;
    munmap(region->dataRegion, region->byteLength);
    region->dataRegion = NULL;
}

