//
//  MLNApplicationDelegate.h
//  Marlin
//
//  Created by iain on 11/02/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MLNCacheFile;

@interface MLNApplicationDelegate : NSObject <NSApplicationDelegate>

@property (readonly) NSURL *cacheURL;

- (MLNCacheFile *)createNewCacheFileWithExtension:(NSString *)extension;
- (void)removeCacheFile:(MLNCacheFile *)cacheFile;

@end