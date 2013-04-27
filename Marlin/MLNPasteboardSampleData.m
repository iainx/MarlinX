//
//  MLNPasteboardSampleData.m
//  Marlin
//
//  Created by iain on 27/04/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNPasteboardSampleData.h"

@implementation MLNPasteboardSampleData

- (id)initWithContent:(NSArray *)content
           sampleRate:(NSUInteger)sampleRate
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _channels = content;
    _sampleRate = sampleRate;
    
    return self;
}
@end
