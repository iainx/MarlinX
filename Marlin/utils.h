//
//  utils.h
//  Marlin
//
//  Created by iain on 03/10/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#ifndef Marlin_utils_h
#define Marlin_utils_h

#include <AudioToolbox/AudioToolbox.h>

void print_coreaudio_error (OSStatus    status,
                            const char *operation);
bool check_status_is_error (OSStatus    status,
                            const char *operation);
void dump_asbd (AudioStreamBasicDescription *asbd);

#endif
