//
//  MLNMarkerHandlerDelegate.h
//  Marlin
//
//  Created by iain on 01/12/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MLNMarkerHandler, MLNMarker;

@protocol MLNMarkerHandlerDelegate <NSObject>

- (void)handler:(MLNMarkerHandler *)handler didEnterMarker:(MLNMarker *)marker;
- (void)handler:(MLNMarkerHandler *)handler didLeaveMarker:(MLNMarker *)marker;
- (void)handler:(MLNMarkerHandler *)handler didMoveMarker:(MLNMarker *)marker from:(NSUInteger)oldPosition;
@end
