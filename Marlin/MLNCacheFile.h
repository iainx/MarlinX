//
//  MLNCacheFile.h
//  Marlin
//
//  Created by iain on 20/04/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MLNCacheFile : NSObject

@property (readwrite, copy) NSString *filePath;
@property (readwrite) int fd;

@end
