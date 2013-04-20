//
//  MLNApplicationDelegate.m
//  Marlin
//
//  Created by iain on 11/02/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "MLNApplicationDelegate.h"
#import "MLNCacheFile.h"

@implementation MLNApplicationDelegate {
    NSMutableArray *_cacheFiles;
}

#pragma mark - Delegate methods

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    NSDocumentController *dc = [NSDocumentController sharedDocumentController];
    NSArray *urls = [dc URLsFromRunningOpenPanel];
    
    if (urls == nil) {
        // FIXME: Should we just quit here?
        return NO;
    }
    
    NSUInteger urlCount = [urls count];
    for (NSUInteger i = 0; i < urlCount; i++) {
        DDLogVerbose(@"Url: %@, %p", urls[i], self);
        //[dc makeDocumentWithContentsOfURL:urls[i] ofType:[dc defaultType] error:&error];
        [dc openDocumentWithContentsOfURL:urls[i] display:YES completionHandler:NULL];
    }
    
    return NO;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    // Configure DDLog to ASL and TTY
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    // Create the temporary cache directory we need
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSArray *filePaths = [fm URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
    if ([filePaths count] > 0) {
        _cacheURL = [[filePaths objectAtIndex:0] URLByAppendingPathComponent:bundleID];
        
        NSError *error = nil;
        
        if (![fm createDirectoryAtURL:_cacheURL
          withIntermediateDirectories:YES
                           attributes:nil
                                error:&error]) {
            DDLogError(@"Error: %@ - %@", [error localizedFailureReason], [error localizedDescription]);
        }
    }
    
    // We store all the cache files that we created so that on termination we can delete them all
    _cacheFiles = [NSMutableArray array];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    DDLogInfo(@"Terminating --- Cleaning up files");
    NSFileManager *fm = [NSFileManager defaultManager];

    for (MLNCacheFile *tfile in _cacheFiles) {
        NSError *error = nil;
        
        close([tfile fd]);
        [fm removeItemAtPath:[tfile filePath] error:&error];
        
        if (error != nil) {
            DDLogError(@"Error removing %@: %@ - %@", [tfile filePath], [error localizedDescription], [error localizedFailureReason]);
        } else {
            DDLogInfo(@"Deleted %@", [tfile filePath]);
        }
    }
    
    return NSTerminateNow;
}

#pragma mark - Cache file tracking
- (MLNCacheFile *)createNewCacheFileWithExtension:(NSString *)extension
{
    int fd;
    
    // Create a unique unpredictable filename
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString] ;
    NSString *uniqueFileName = [NSString stringWithFormat:@"Marlin_%@.%@", guid, extension];
    NSURL *cacheFileURL = [_cacheURL URLByAppendingPathComponent:uniqueFileName isDirectory:NO];
    
    const char *filePath = [[cacheFileURL path] UTF8String];
    fd = open (filePath, O_RDWR | O_CREAT, 0660);
    if (fd == -1) {
        // FIXME: Should return &error
        DDLogError(@"Error opening %s: %d", filePath, errno);
        return nil;
    } else {
        DDLogInfo(@"Opened %s for data cache", filePath);
    }

    // Track the path and the fd
    MLNCacheFile *tfile = [[MLNCacheFile alloc] init];
    [tfile setFd:fd];
    [tfile setFilePath:[cacheFileURL path]];
    
    [_cacheFiles addObject:tfile];
    
    return tfile;
}

- (void)removeCacheFile:(MLNCacheFile *)cacheFile
{
    [_cacheFiles removeObject:cacheFile];
}
@end
