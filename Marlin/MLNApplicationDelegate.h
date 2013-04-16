//
//  MLNApplicationDelegate.h
//  Marlin
//
//  Created by iain on 11/02/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MLNApplicationDelegate : NSObject <NSApplicationDelegate>

@property (readonly) NSURL *cacheURL;

- (int)createNewCacheFileWithExtension:(NSString *)extension;
- (void)removeCacheFileForFd:(int)fd;

@end
