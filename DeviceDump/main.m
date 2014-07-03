//
//  main.m
//  DeviceDump
//
//  Created by Sam Dye on 2014-06-18.
//  Copyright (c) 2014 Sam Dye. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MobileDeviceAccess.h"
#import "DeviceManager.h"

static const int kPollSeconds = 2;

int main (int argc, char * argv[]) {
	DeviceManager *deviceManager = [[DeviceManager alloc] init];

	__block BOOL timeout = YES;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kPollSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		timeout = NO;
	});

	while(timeout && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);

	if ([deviceManager isDeviceConnected]) {
		for (NSUInteger i = 1; i < argc; i++) {
			if (strcmp(argv[i], "--json") == 0) {
				deviceManager.jsonFormatted = YES;
			} else if (strcmp(argv[i], "--vmware") == 0) {
				deviceManager.useVmwareAttributes = YES;
			} else {
				fprintf(stderr, "Unknown option '%s'\n", argv[i]);
				return 1;
			}
		}
		fprintf(stdout, "%s", [[deviceManager descriptionOfAllDevices] UTF8String]);
	} else {
		fprintf(stdout, "No devices found.\n");
	}

	return 0;
}