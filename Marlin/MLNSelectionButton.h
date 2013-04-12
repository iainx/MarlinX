//
//  MLNSelectionButton.h
//  Marlin
//
//  Created by iain on 05/04/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MLNSelectionAction;

@interface MLNSelectionButton : NSButton

- (id)initWithAction:(MLNSelectionAction *)action;

@end
