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
	if (argc > 2) {
		fprintf(stderr, "Too many arguments (%d).\n", argc);
		return 1;
	} else {
		DeviceManager *deviceManager = [[DeviceManager alloc] init];
		
		__block BOOL timeout = YES;
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kPollSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			timeout = NO;
		});
		
		while(timeout && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
		
		if (argc == 1) {
			if ([deviceManager isDeviceConnected]) {
				NSUInteger deviceCount = [deviceManager.devices count];
				fprintf(stdout, "%lu device%s connected:\n\n", deviceCount, deviceCount > 1 ? "s" : "");
				for (AMDevice *device in deviceManager.devices) {
					fprintf(stdout, "%s\n", [[deviceManager descriptionOfDevice:device] UTF8String]);
				}
			} else {
				fprintf(stdout, "No devices found.\n");
			}
		} else {
			if (strcmp(argv[1], "--json") == 0) {
				fprintf(stdout, "%s", [[deviceManager deviceInfoJSONString] UTF8String]);
			} else {
				fprintf(stderr, "Unknown option '%s'\n", argv[1]);
			}
		}
	}
	
	return 0;
}