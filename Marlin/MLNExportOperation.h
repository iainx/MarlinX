//
//  MLNSaveOperation.h
//  Marlin
//
//  Created by iain on 16/09/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#import "MLNOperation.h"

@class MLNSample;

@interface MLNExportOperation : MLNOperation

- (id)initWithSample:(MLNSample *)sample URL:(NSURL *)url format:(NSDictionary *)format;

@end
