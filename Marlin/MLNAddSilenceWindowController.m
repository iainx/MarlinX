//
//  MLNAddSilenceWindowController.m
//  Marlin
//
//  Created by iain on 09/02/2014.
//  Copyright (c) 2014 iain. All rights reserved.
//

#import "MLNAddSilenceWindowController.h"
#import "MLNSecondsFormatter.h"
#import "MLNDurationFormatter.h"

@implementation MLNAddSilenceWindowController {
    NSArray *_formatters;
}

@synthesize typeIndex = _typeIndex;

- (id)init
{
    self = [super initWithWindowNibName:@"MLNAddSilenceWindowController" owner:self];
    if (!self) {
        return nil;
    }
    
    _duration = 44100;
    
    _formatters = @[[[NSNumberFormatter alloc] init],
                    [[MLNSecondsFormatter alloc] init],
                    [[MLNDurationFormatter alloc] init]];
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    [_durationStepper setMinValue:1.0];
    [_durationStepper setIncrement:1.0];
    [_durationStepper setMaxValue:MAXFLOAT];
    
    [[_durationField cell] setFormatter:_formatters[0]];
}

- (void)setDuration:(NSUInteger)duration
{
    if (_duration == duration) {
        return;
    }
    _duration = duration;
}

- (NSInteger)typeIndex
{
    return _typeIndex;
}

- (void)setTypeIndex:(NSInteger)typeIndex
{
    if (typeIndex == _typeIndex) {
        return;
    }
    
    _typeIndex = typeIndex;

    NSFormatter *formatter = _formatters[_typeIndex];
    if (_typeIndex == 1 || _typeIndex == 2) {
        [(MLNSecondsFormatter *)formatter setSampleRate:44100];
        [(MLNSecondsFormatter *)formatter setIgnoreUpdate:YES];
    }
    
    [[_durationField cell] setFormatter:formatter];
    
    // Need this to force an update using the new formatter
    [_durationField setStringValue:[NSString stringWithFormat:@"%lu", _duration]];
    
    if (_typeIndex == 1 || _typeIndex == 2) {
        [(MLNSecondsFormatter *)formatter setIgnoreUpdate:NO];
    }
}

- (IBAction)insertSilence:(id)sender
{
    _didCloseBlock(_duration);
}

- (IBAction)cancel:(id)sender
{
    _didCloseBlock(0);
}
@end
