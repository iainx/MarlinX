//
//  MLNOverviewBarDelegate.h
//  Marlin
//
//  Created by iain on 10/09/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MLNOverviewBar;
@protocol MLNOverviewBarDelegate <NSObject>

- (void)overviewBar:(MLNOverviewBar *)bar didSelectFrame:(NSUInteger)frame;

@end
