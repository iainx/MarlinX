//
//  MLNSampleDelegate.h
//  Marlin
//
//  Created by iain on 14/03/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MLNSampleDelegate <NSObject>

- (void)sampleDataDidChangeInRange:(NSRange)range;

@end
