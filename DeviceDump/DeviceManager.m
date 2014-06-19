//
//  DeviceManager.m
//  DeviceDump
//
//  Created by Sam Dye on 2014-06-18.
//  Copyright (c) 2014 Sam Dye. All rights reserved.
//

#import "DeviceManager.h"
#import "NSDictionary+ArrayKeys.h"

@implementation DeviceManager {
	NSMutableArray *_devices;
}

- (id)init
{
    if ((self = [super init])) {
        [[MobileDeviceAccess singleton] setListener:self];
		_devices = [[NSMutableArray alloc] init];
    }
    return self;
}

- (BOOL)isDeviceConnected
{
	return [self.devices count] > 0;
}

- (NSString *)descriptionOfDevice:(AMDevice *)device
{
	NSString *deviceType = [device deviceValueForKey:@"ProductType"];
	
	return [NSString stringWithFormat:@"Device name: %@\nModel: %@\nOS version: %@\nType: %@\nModel number: %@\nSerial number: %@\nUDID: %@\n", device.deviceName, [self deviceModelForType:deviceType], [device deviceValueForKey:@"ProductVersion"], deviceType, [device deviceValueForKey:@"ModelNumber"], device.serialNumber, device.udid];
}

- (NSString *)descriptionOfDeviceAtIndex:(NSUInteger)index
{
	return [self descriptionOfDevice:_devices[index]];
}

- (BOOL)writeDeviceInfoToJSONFile:(NSString *)path
{
	NSError *error = nil;
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self dictionaryForDevices] options:NSJSONWritingPrettyPrinted error:&error];
	if (error) {
		fprintf(stderr, "Error serializing JSON data: %s", [[error description] UTF8String]);
		return NO;
	} else {
		[jsonData writeToFile:path atomically:YES];
	}
	
	return YES;
}

- (NSString *)deviceInfoJSONString
{
	NSError *error = nil;
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self dictionaryForDevices] options:NSJSONWritingPrettyPrinted error:&error];
	if (error) {
		fprintf(stderr, "Error serializing JSON data: %s", [[error description] UTF8String]);
		return nil;
	} else {
		return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
	}
}

- (NSDictionary *)dictionaryForDevice:(AMDevice *)device
{
	NSString *deviceType = [device deviceValueForKey:@"ProductType"];
	
	return @{@"name": device.deviceName,
			 @"model": [self deviceModelForType:deviceType],
			 @"os_version": [device deviceValueForKey:@"ProductVersion"],
			 @"type": deviceType,
			 @"model_number": [device deviceValueForKey:@"ModelNumber"],
			 @"serial_number": device.serialNumber,
			 @"udid": device.udid};
}

- (NSDictionary *)dictionaryForDevices
{
	NSMutableArray *devices = [[NSMutableArray alloc] init];
	for (AMDevice *device in _devices) {
		[devices addObject:[self dictionaryForDevice:device]];
	}
	
	return @{@"devices": devices};
}

- (NSString *)deviceModelForType:(NSString *)type
{
	NSDictionary *deviceModelDictionary = @{@[@"iPhone1,1"]: @"iPhone, 1st gen",
											@[@"iPhone1,2"]: @"iPhone 3G",
											@[@"iPhone2,1"]: @"iPhone 3GS",
											@[@"iPhone3,1", @"iPhone3,2", @"iPhone3,3"]: @"iPhone 4",
											@[@"iPhone4,1"]: @"iPhone 4S",
											@[@"iPhone5,1", @"iPhone5,2"]: @"iPhone 5",
											@[@"iPhone5,3", @"iPhone5,4"]: @"iPhone 5C",
											@[@"iPhone6,1", @"iPhone6,2"]: @"iPhone 5S",
											@[@"iPad1,1"]: @"iPad 1",
											@[@"iPad2,1", @"iPad2,2", @"iPad2,3", @"iPad2,4"]: @"iPad 2",
											@[@"iPad2,5", @"iPad2,6", @"iPad2,7"]: @"iPad Mini",
											@[@"iPad3,1", @"iPad3,2", @"iPad3,3"]: @"iPad 3",
											@[@"iPad3,4", @"iPad3,5", @"iPad3,6"]: @"iPad, 4th gen",
											@[@"iPad4,1", @"iPad4,2", @"iPad4,3"]: @"iPad Air",
											@[@"iPad4,4", @"iPad4,5", @"iPad4,6"]: @"iPad Mini Retina",
											@[@"iPod1,1"]: @"iPod Touch, 1st gen",
											@[@"iPod2,1"]: @"iPod Touch, 2nd gen",
											@[@"iPod3,1"]: @"iPod Touch, 3rd gen",
											@[@"iPod4,1"]: @"iPod Touch, 4th gen",
											@[@"iPod5,1"]: @"iPod Touch, 5th gen"};
	
	return [deviceModelDictionary objectForArrayKey:type] ?: @"Device model not found (only touchscreen models listed).";
}

#pragma mark - MobileDeviceAccessListener

- (void)deviceConnected:(AMDevice*)device
{
	[_devices addObject:device];
}

- (void)deviceDisconnected:(AMDevice*)device
{
	[_devices removeObject:device];
}




@end
