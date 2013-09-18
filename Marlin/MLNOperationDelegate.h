//
//  MLNOperationDelegate.h
//  Marlin
//
//  Created by iain on 18/09/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MLNOperation;

@protocol MLNOperationDelegate <NSObject>

- (void)operationDidFinish:(MLNOperation *)operation;
@end
