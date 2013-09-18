//
//  MLNOperation.h
//  
//
//  Created by iain on 16/09/2013.
//
//

#import <Foundation/Foundation.h>
#import "MLNOperationDelegate.h"

@interface MLNOperation : NSOperation

@property (readwrite) int progress;
@property (readwrite, strong) NSString *primaryText;
@property (readwrite, strong) NSString *secondaryText;
@property (readwrite, weak) id<MLNOperationDelegate> delegate;

- (void)sendProgressOnMainThread:(float)percentage
                   operationName:(NSString *)operationName
                     framesSoFar:(SInt64)framesSoFar
                     totalFrames:(SInt64)totalFrames;

- (void)operationDidFinish;

@end
