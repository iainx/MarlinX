//
//  SLFButton.m
//  ButtonTest
//
//  Created by iain on 19/10/2012.
//  Copyright (c) 2012 iain. All rights reserved.
//

#import "SLFButton.h"

@implementation SLFButton

+ (void)load
{
    [self setCellClass:NSClassFromString(@"SLFButtonCell")];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
 
    [self setButtonType:6];
    [self setBordered:YES];
    [self setBezelStyle:NSRegularSquareBezelStyle];
    
    return self;
}

@end
