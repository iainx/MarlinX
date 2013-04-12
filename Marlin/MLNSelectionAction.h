//
//  MLNSelectionAction.h
//  Marlin
//
//  Created by iain on 07/04/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MLNSelectionAction : NSObject

@property (readwrite, strong) NSInvocation *invocation;
@property (readwrite, strong) NSImage *icon;
@property (readwrite, strong) NSString *name;
@property (readwrite, strong) NSColor *buttonColour;

@end
