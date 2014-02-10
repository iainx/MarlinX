//
//  MLNAddSilenceWindowController.h
//  Marlin
//
//  Created by iain on 09/02/2014.
//  Copyright (c) 2014 iain. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void (^AddSilenceWindowDidClose)(NSUInteger numberOfFramesToAdd);

@interface MLNAddSilenceWindowController : NSWindowController

@property (readwrite, weak) IBOutlet NSTextField *titleLabel;
@property (readwrite, weak) IBOutlet NSTextField *durationField;
@property (readwrite, weak) IBOutlet NSStepper *durationStepper;
@property (readwrite, weak) IBOutlet NSPopUpButton *framePopup;

@property (readwrite) NSUInteger duration;
@property (nonatomic, readwrite) NSInteger typeIndex;
@property (readwrite, copy) AddSilenceWindowDidClose didCloseBlock;

- (IBAction)insertSilence:(id)sender;
- (IBAction)cancel:(id)sender;
@end
