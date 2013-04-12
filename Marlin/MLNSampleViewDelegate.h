//
//  MLNSampleViewDelegate.h
//  Marlin
//
//  Created by iain on 05/03/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MLNSampleView;
@protocol MLNSampleViewDelegate <NSObject>

@optional
- (void)sampleView:(MLNSampleView *)sampleView selectionDidChange:(NSRange)selection;
- (void)sampleView:(MLNSampleView *)sampleView cursorDidMove:(NSUInteger)cursorFrame;

- (NSArray *)sampleViewWillShowSelectionToolbar;
- (NSArray *)sampleViewWillShowSelectionMenu;
@end
