//
//  MLNLoadOperationDelegate.h
//  Marlin
//
//  Created by iain on 30/01/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "MLNOperationDelegate.h"

@protocol MLNLoadOperationDelegate <NSObject, MLNOperationDelegate>

- (void)sampleDidLoadData:(NSMutableArray *)channelData description:(AudioStreamBasicDescription)asbd;
- (void)didFailLoadWithError:(NSError *)error;

@end
