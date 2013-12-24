//
//  MLNMarker.h
//  Marlin
//
//  Created by iain on 13/11/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MLNMarker : NSObject <NSCoding>

@property (readwrite) NSNumber *frame;
@property (readwrite, copy) NSString *name;

@end
