//
//  MLNMMapRegion.m
//  Marlin
//
//  Created by iain on 11/02/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNMMapRegion.h"
#import "MLNCacheFile.h"

static BOOL MLNMapRegionWriteData (MLNMapRegion *region,
                                   void *data,
                                   size_t byteLength);

static int pagesize = -1;

MLNMapRegion *
MLNMapRegionCreateRegion(MLNCacheFile *cacheFile,
                         void *data,
                         size_t byteLength)
{
    MLNMapRegion *newRegion;
    
    // Get this the first time we create a region
    if (pagesize == -1) {
        pagesize = getpagesize();
    }
    
    newRegion = malloc(sizeof(MLNMapRegion));
    newRegion->cacheFile = cacheFile;
    
    MLNMapRegionWriteData(newRegion, data, byteLength);
    
    newRegion->byteLength = byteLength;
    
    MLNMapRegionMapData(newRegion);
    
    newRegion->refCount = 1;
    
    return newRegion;
}

void
MLNMapRegionFree(MLNMapRegion *region)
{
    if (region == NULL) {
        return;
    }
    
    if (region->refCount != 0) {
        DDLogCError(@"MapRegion being freed with non-zero refcount: %p - (%d)", region, region->refCount);
    }
    munmap(region->dataRegion, region->byteLength);

    // FIXME: Do we need to close fd?
    free(region);
}

void
MLNMapRegionRetain(MLNMapRegion *region)
{
    if (region == NULL) {
        return;
    }
    
    region->refCount++;
}

void
MLNMapRegionRelease(MLNMapRegion *region)
{
    if (region == NULL) {
        return;
    }
    
    region->refCount--;
    
    if (region->refCount == 0) {
        MLNMapRegionFree(region);
    }
}

#define BUFFER_SIZE 64 * 1024

static BOOL
MLNMapRegionWriteData (MLNMapRegion *region,
                       void *data,
                       size_t byteLength)
{
    NSUInteger bytesLeft;
    NSInteger paddingBytes = 0;
    
    int fd = [region->cacheFile fd];
    
    region->filePos = lseek(fd, 0, SEEK_CUR);
    bytesLeft = byteLength;
    while (bytesLeft) {
        size_t bytesToWrite = MIN (BUFFER_SIZE, bytesLeft);
        ssize_t bytesWritten = write(fd, data, bytesLeft);
        
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
    }
    
    paddingBytes = pagesize - (byteLength % pagesize);
    if (paddingBytes > 0) {
        DDLogCVerbose(@"Need to pad with %ld bytes", paddingBytes);
        
        off_t paddingOffset = lseek(fd, paddingBytes, SEEK_END);
        if (paddingOffset == -1) {
            DDLogCError(@"Error padding file for page size: errno - %d", errno);
        }
        
        if (paddingOffset % pagesize) {
            DDLogCError(@"Error padding file for page size: Padding offset says: %lld", paddingOffset);
        }
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
    int fd;
    
    if (region == NULL) {
        return NO;
    }
    
    if (region->mapped == YES) {
        return YES;
    }
    
    fd = [region->cacheFile fd];
    region->dataRegion = mmap(NULL, region->byteLength,
                              PROT_READ | PROT_WRITE, MAP_SHARED,
                              fd, region->filePos);
    if (region->dataRegion == MAP_FAILED) {
        DDLogCError(@"Error mmapping data: %d", errno);
        DDLogCError(@"   - %lld %lu", region->filePos, region->byteLength);
        
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

