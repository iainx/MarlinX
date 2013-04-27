//
//  MLNPasteboardSampleData.h
//  Marlin
//
//  Created by iain on 27/04/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MLNPasteboardSampleData : NSObject

@property (readwrite, strong) NSArray *channels;
@property (readwrite) NSUInteger sampleRate;

- (id)initWithContent:(NSArray *)content
           sampleRate:(NSUInteger)sampleRate;
@end
