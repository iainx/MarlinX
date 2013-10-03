//
//  File.c
//  Marlin
//
//  Created by iain on 03/10/2013.
//  Copyright (c) 2013 iain. All rights reserved.
//

#include <stdio.h>
#include "utils.h"

void
print_coreaudio_error (OSStatus    status,
                       const char *operation)
{
    char str[20];
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(status);
	if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
		str[0] = str[5] = '\'';
		str[6] = '\0';
	} else {
		// no, format it as an integer
		sprintf(str, "%d", (int)status);
	}
    
    fprintf(stderr, "Error: %s (%s)\n", operation, str);
}

bool
check_status_is_error (OSStatus    status,
                       const char *operation)
{
    if (status == noErr) {
        return false;
    }

    print_coreaudio_error(status, operation);
    
    return true;
}

void
dump_asbd (AudioStreamBasicDescription *asbd)
{
    fprintf(stdout, "Sample rate: %f\n", asbd->mSampleRate);
    
    char str[20];
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(asbd->mFormatID);
	if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
		str[0] = str[5] = '\'';
		str[6] = '\0';
	} else {
		// no, format it as an integer
		sprintf(str, "%d", (int)asbd->mFormatID);
	}
    fprintf(stdout, "Format ID: %s\n", str);
    fprintf(stdout, "Format flags: %d\n", asbd->mFormatFlags);
    fprintf(stdout, "Bytes per packet: %d\n", asbd->mBytesPerPacket);
    fprintf(stdout, "Frames per packet: %d\n", asbd->mFramesPerPacket);
    fprintf(stdout, "Bytes per frame: %d\n", asbd->mBytesPerFrame);
    fprintf(stdout, "Channels per frame: %d\n", asbd->mChannelsPerFrame);
    fprintf(stdout, "Bits per channel: %d\n", asbd->mBitsPerChannel);
}
