//
//  MLNExportWindowController.m
//  Marlin
//
//  Created by iain on 16/09/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNExportPanelController.h"
#import "MLNExportableType.h"
#import "MLNExportableTypeView.h"

@implementation MLNExportPanelController {
    NSUInteger _currentSelection;
}

static void *exportableTypesContext = &exportableTypesContext;

- (id)init
{
    self = [super initWithWindowNibName:@"MLNExportPanelController"];
    
    _exportableTypes = @[[[MLNExportableType alloc] initWithName:@"M4A"], [[MLNExportableType alloc] initWithName:@"WAV"]];
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [self setItemAtIndex:[_exportableTypesController selectionIndex] selected:YES];
    [_exportableTypesController addObserver:self
                                 forKeyPath:@"selectionIndexes"
                                    options:NSKeyValueObservingOptionNew
                                    context:exportableTypesContext];
}

- (void)setItemAtIndex:(NSUInteger)idx selected:(BOOL)selected
{
    NSCollectionViewItem *item;
    MLNExportableTypeView *view;

    item = [_collectionView itemAtIndex:idx];
    view = (MLNExportableTypeView *)[item view];
    
    DDLogVerbose(@"%@ -> %@", item, view);
    [view setSelected:selected];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context != exportableTypesContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    if ([keyPath isEqualToString:@"selectionIndexes"]) {
        DDLogVerbose(@"Selection changed to: %lu", [_exportableTypesController selectionIndex]);
        
        [self setItemAtIndex:_currentSelection selected:NO];
        [self setItemAtIndex:[_exportableTypesController selectionIndex] selected:YES];
        
        _currentSelection = [_exportableTypesController selectionIndex];
        return;
    }
}

- (IBAction)cancelSheet:(id)sender
{
    [_delegate exportPanelControllerCancelled:self];
}

- (IBAction)selectFormat:(id)sender
{
    NSDictionary *formatDetails = @{@"type": @"MP3"};
    [_delegate exportPanelController:self didSelectFormat:formatDetails];
}


@end
