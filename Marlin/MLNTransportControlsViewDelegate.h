//
//  MLNTransportControlsViewDelegate.h
//  Marlin
//
//  Created by iain on 02/01/2014.
//  Copyright (c) 2014 iain. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MLNTransportControlsViewDelegate <NSObject>

- (void)transportControlsViewDidRequestPlay;
- (void)transportControlsViewDidRequestPause;
- (void)transportControlsViewDidRequestStop;

- (void)transportControlsViewDidRequestMoveToStart;
- (void)transportControlsViewDidRequestMoveToEnd;
- (void)transportControlsViewDidRequestBackFrame;
- (void)transportControlsViewDidRequestForwardFrame;
@end
