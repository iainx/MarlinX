//
//  MLNSample+Operations.h
//  Marlin
//
//  Created by iain on 13/03/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNSample.h"

@interface MLNSample (Operations)

- (BOOL)deleteRange:(NSRange)range withError:(NSError **)error;
- (NSArray *)copyRange:(NSRange)range withError:(NSError **)error;

- (BOOL)canInsertChannels:(NSArray *)channels
               sampleRate:(NSUInteger)sampleRate;
- (BOOL)insertChannels:(NSArray *)channels
               atFrame:(NSUInteger)frame
             withError:(NSError **)error;
- (BOOL)cropRange:(NSRange)range withError:(NSError **)error;

@end
