//
//  MLNLoadOperation.h
//  Marlin
//
//  Created by iain on 29/01/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLNLoadOperationDelegate.h"

@class MLNSample;

@interface MLNLoadOperation : NSOperation

@property (readwrite, weak) id<MLNLoadOperationDelegate> delegate;
@property (readwrite) int progress;
@property (readwrite, strong) NSString *primaryText;
@property (readwrite, strong) NSString *secondaryText;

- (id)initForSample:(MLNSample *)sample;

@end
