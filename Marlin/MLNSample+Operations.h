//
//  MLNSample+Operations.h
//  Marlin
//
//  Created by iain on 13/03/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNSample.h"

@interface MLNSample (Operations)

- (void)deleteRange:(NSRange)range;
- (NSArray *)copyRange:(NSRange)range;

- (BOOL)canInsertChannels:(NSArray *)channels;
- (void)insertChannels:(NSArray *)channels
               atFrame:(NSUInteger)frame;

@end
