//
//  MLNExportPanelControllerDelegate.h
//  Marlin
//
//  Created by iain on 16/09/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MLNExportPanelController;

@protocol MLNExportPanelControllerDelegate <NSObject>

- (void)exportPanelController:(MLNExportPanelController *)controller didSelectFormat:(NSDictionary *)formatDetails;
- (void)exportPanelControllerCancelled:(MLNExportPanelController *)controller;

@end
