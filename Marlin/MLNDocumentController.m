//
//  MLNDocumentController.m
//  Marlin
//
//  Created by iain on 16/02/2014.
//  Copyright (c) 2014 iain. All rights reserved.
//

#import "MLNDocumentController.h"
#import "Constants.h"

@implementation MLNDocumentController

- (void)reopenDocumentForURL:(NSURL *)urlOrNil
           withContentsOfURL:(NSURL *)contentsURL
                     display:(BOOL)displayDocument
           completionHandler:(void (^)(NSDocument *, BOOL, NSError *))completionHandler
{
    [super reopenDocumentForURL:urlOrNil withContentsOfURL:contentsURL display:displayDocument completionHandler:completionHandler];
}

+ (void)restoreWindowWithIdentifier:(NSString *)identifier
                              state:(NSCoder *)state
                  completionHandler:(void (^)(NSWindow *, NSError *))completionHandler
{
    NSURL *autoReopenURL = [state decodeObjectForKey:kMLNDocumentRestoreURL];
    
    if (autoReopenURL) {
        [[self sharedDocumentController] reopenDocumentForURL:autoReopenURL
                                            withContentsOfURL:autoReopenURL
                                                      display:NO
                                            completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
                                                NSWindow *resultWindow = nil;
                                                if (documentWasAlreadyOpen == NO) {
                                                    if ([[document windowControllers] count] == 0) {
                                                        [document makeWindowControllers];
                                                    }
                                                    
                                                    if ([[document windowControllers] count] == 1) {
                                                        NSWindowController *controller;
                                                        
                                                        controller = [document windowControllers][0];
                                                        resultWindow = [controller window];
                                                    } else {
                                                        for (NSWindowController *wc in [document windowControllers]) {
                                                            NSWindow *window = [wc window];
                                                            if ([[window identifier] isEqualToString:identifier]) {
                                                                resultWindow = window;
                                                                break;
                                                            }
                                                        }
                                                    }
                                                }
                                                
                                                completionHandler(resultWindow, error);
                                            }];
    } else {
        [super restoreWindowWithIdentifier:identifier state:state
                         completionHandler:completionHandler];
    }
}
@end
