//
//  MLNDurationFormatter.h
//  Marlin
//
//  Created by iain on 10/02/2014.
//  Copyright (c) 2014 iain. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MLNDurationFormatter : NSFormatter

@property (readwrite) BOOL ignoreUpdate;
@property (readwrite) NSUInteger sampleRate;
@end
