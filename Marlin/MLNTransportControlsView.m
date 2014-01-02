//
//  MLNTransportControlsView.m
//  Marlin
//
//  Created by iain on 31/12/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNTransportControlsView.h"

@implementation MLNTransportControlsView {
    NSButton *_startButton;
    NSButton *_rewindButton;
    NSButton *_playButton;
    NSButton *_stopButton;
    NSButton *_ffwdButton;
    NSButton *_endButton;
}

- (NSButton *)createButtonWithImageNamed:(NSString *)imageName
                                  action:(SEL)action
{
    NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 27, 27)];
    
    [button setImage:[NSImage imageNamed:imageName]];
    [button setBezelStyle:NSTexturedRoundedBezelStyle];
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [button setTarget:self];
    [button setAction:action];
    
    [self addSubview:button];
    
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[button]|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:@{@"button":button}];
    [self addConstraints:constraints];
    
    return button;
}

- (void)doRealInit
{
    _startButton = [self createButtonWithImageNamed:@"goto-start" action:@selector(requestMoveToStart:)];
    _rewindButton = [self createButtonWithImageNamed:@"rewind-icon" action:@selector(requestPreviousFrame:)];
    _playButton = [self createButtonWithImageNamed:@"play-icon" action:@selector(requestPlay:)];
    _stopButton = [self createButtonWithImageNamed:@"stop-icon" action:@selector(requestStop:)];
    _ffwdButton = [self createButtonWithImageNamed:@"ffwd-icon" action:@selector(requestNextFrame:)];
    _endButton = [self createButtonWithImageNamed:@"goto-end" action:@selector(requestMoveToEnd:)];
    
    NSArray *constraints;
    NSDictionary *viewsDict = NSDictionaryOfVariableBindings(_startButton,_rewindButton,_playButton,_stopButton,_ffwdButton,_endButton);
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|[_startButton][_rewindButton(==_startButton)][_playButton(==_startButton)][_stopButton(==_startButton)][_ffwdButton(==_startButton)][_endButton(==_startButton)]|"
                                                          options:NSLayoutFormatAlignAllBaseline
                                                          metrics:nil
                                                            views:viewsDict];
    [self addConstraints:constraints];
}

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (!self) {
        return nil;
    }
    
    [self doRealInit];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return nil;
    }
    
    [self doRealInit];
    return self;
}

- (void)requestMoveToStart:(id)sender
{
    [_delegate transportControlsViewDidRequestMoveToStart];
}

- (void)requestMoveToEnd:(id)sender
{
    [_delegate transportControlsViewDidRequestMoveToEnd];
}

- (void)requestPreviousFrame:(id)sender
{
    [_delegate transportControlsViewDidRequestBackFrame];
}

- (void)requestNextFrame:(id)sender
{
    [_delegate transportControlsViewDidRequestForwardFrame];
}

- (void)requestPlay:(id)sender
{
    [_delegate transportControlsViewDidRequestPlay];
}

- (void)requestPause:(id)sender
{
    [_delegate transportControlsViewDidRequestPause];
}

- (void)requestStop:(id)sender
{
    [_delegate transportControlsViewDidRequestStop];
}

@end
