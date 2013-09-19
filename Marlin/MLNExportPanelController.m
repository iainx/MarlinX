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

struct _exportableTypeDetails {
    char *name;
    char *blurb;
    UInt32 formatID;
    AudioFileTypeID typeID;
    BOOL bigEndian;
} etDetails[] = {
    {"M4A", "Create a compressed M4A file with some loss of quality", kAudioFormatMPEG4AAC, kAudioFileM4AType, NO},
    {"WAV", "Create an uncompressed WAV file with no loss of quality", kAudioFormatLinearPCM, kAudioFileWAVEType, NO},
    {"AIFF", "Create an uncompressed AIFF file with no loss of quality", kAudioFormatLinearPCM, kAudioFileAIFFType, YES},
    {NULL, NULL}
};

- (id)init
{
    self = [super initWithWindowNibName:@"MLNExportPanelController"];
    
    _exportableTypes = [NSMutableArray array];
    for (int i = 0; etDetails[i].name; i++) {
        MLNExportableType *type = [[MLNExportableType alloc] initWithName:[NSString stringWithUTF8String:etDetails[i].name]];
        [type setInfo:[NSString stringWithUTF8String:etDetails[i].blurb]];
        [type setFormatID:etDetails[i].formatID];
        [type setTypeID:etDetails[i].typeID];
        [type setBigEndian:etDetails[i].bigEndian];
        
        [(NSMutableArray *)_exportableTypes addObject:type];
    }
    
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
    NSDictionary *formatDetails = @{@"formatDetails": _exportableTypes[_currentSelection]};
    [_delegate exportPanelController:self didSelectFormat:formatDetails];
}


@end
