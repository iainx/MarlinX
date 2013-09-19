//
//  MLNExportableType.h
//  Marlin
//
//  Created by iain on 19/09/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>

@interface MLNExportableType : NSObject

@property (readonly) NSString *name;
@property (readwrite) NSString *info;
@property (readwrite) UInt32 formatID;
@property (readwrite) AudioFileTypeID typeID;
@property (readwrite, getter = isBigEndian) BOOL bigEndian;

- (id)initWithName:(NSString *)name;
@end
