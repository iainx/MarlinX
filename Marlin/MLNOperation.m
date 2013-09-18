//
//  MLNOperation.m
//  
//
//  Created by iain on 16/09/2013.
//
//

#import "MLNOperation.h"
#import "Constants.h"

@implementation MLNOperation

#pragma mark - Sending notifications

- (void)sendNotificationOnMainThread:(NSNotification *)note
{
    [[NSNotificationCenter defaultCenter] postNotification:note];
}

- (void)sendProgressOnMainThread:(float)percentage
                   operationName:(NSString *)operationName
                     framesSoFar:(SInt64)framesSoFar
                     totalFrames:(SInt64)totalFrames
{
    NSDictionary *userInfo = @{kMLNProgressPercentage : @(percentage), kMLNProgressFramesSoFar: @(framesSoFar), kMLNProgressTotalFrames: @(totalFrames), kMLNProgressOperationName: operationName};
    
    [self performSelectorOnMainThread:@selector(sendNotificationOnMainThread:)
                           withObject:[NSNotification notificationWithName:kMLNProgressNotification
                                                                    object:self
                                                                  userInfo:userInfo]
                        waitUntilDone:NO];
}

- (void)operationDidFinish
{
    [_delegate operationDidFinish:self];
}
@end
