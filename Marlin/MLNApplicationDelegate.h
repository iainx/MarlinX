//
//  MLNApplicationDelegate.h
//  Marlin
//
//  Created by iain on 11/02/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MLNCacheFile;
@class MLNPasteboardSampleData;

@interface MLNApplicationDelegate : NSObject <NSApplicationDelegate>

@property (readonly) NSURL *cacheURL;

@property (readwrite, strong) MLNPasteboardSampleData *clipboardContent;

- (MLNCacheFile *)createNewCacheFileWithExtension:(NSString *)extension;
- (void)removeCacheFile:(MLNCacheFile *)cacheFile;

@end