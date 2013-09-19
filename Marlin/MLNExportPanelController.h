//
//  MLNExportWindowController.h
//  Marlin
//
//  Created by iain on 16/09/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MLNExportPanelControllerDelegate.h"

@interface MLNExportPanelController : NSWindowController <NSCollectionViewDelegate>

@property (readwrite, weak) id<MLNExportPanelControllerDelegate> delegate;

@property (readwrite, weak) IBOutlet NSCollectionView *collectionView;
@property (readwrite, weak) IBOutlet NSArrayController *exportableTypesController;
@property (readonly, strong) NSArray *exportableTypes;

- (IBAction)cancelSheet:(id)sender;
- (IBAction)selectFormat:(id)sender;

@end
