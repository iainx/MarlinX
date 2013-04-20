//
//  MLNCacheFile.m
//  Marlin
//
//  Created by iain on 20/04/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNCacheFile.h"

@implementation MLNCacheFile

- (void)dealloc
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    
    close([self fd]);
    [fm removeItemAtPath:[self filePath] error:&error];
    
    if (error != nil) {
        DDLogError(@"Error removing %@: %@ - %@", [self filePath], [error localizedDescription], [error localizedFailureReason]);
    } else {
        DDLogInfo(@"Deleted %@", [self filePath]);
    }
}

@end
