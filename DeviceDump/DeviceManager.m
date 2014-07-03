//
//  DeviceManager.m
//  DeviceDump
//
//  Created by Sam Dye on 2014-06-18.
//  Copyright (c) 2014 Sam Dye. All rights reserved.
//

#import "DeviceManager.h"
#import "NSDictionary+ArrayKeys.h"

typedef NS_ENUM(NSUInteger, systemProfilerAttribute) {
	systemProfilerVendorId,
	systemProfilerProductId
};

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

- (NSString *)descriptionOfAllDevices
{
	NSMutableString *description = [NSMutableString string];
	if (_jsonFormatted) {
		description = [[self deviceInfoJSONString] mutableCopy];
	} else {
		NSUInteger deviceCount = [_devices count];
		fprintf(stdout, "%lu device%s connected:\n\n", deviceCount, deviceCount > 1 ? "s" : "");
		for (AMDevice *device in _devices) {
			[description appendString:[self descriptionOfDevice:device]];
		}
	}

	return description;
}

- (NSString *)descriptionOfDevice:(AMDevice *)device
{
	NSString *deviceType = [device deviceValueForKey:@"ProductType"];
	NSString *vmwareAttributes = _useVmwareAttributes ? [NSString stringWithFormat:@"USB Product ID: %@\nUSB Vendor ID: %@\n", [self systemProfilerAttribute:systemProfilerProductId forDevice:device], [self systemProfilerAttribute:systemProfilerVendorId forDevice:device]] : @"";
	
	return [NSString stringWithFormat:@"Device name: %@\nModel: %@\nOS version: %@\nType: %@\nModel number: %@\nSerial number: %@\nUDID: %@\n%@\n", device.deviceName, [self deviceModelForType:deviceType], [device deviceValueForKey:@"ProductVersion"], deviceType, [device deviceValueForKey:@"ModelNumber"], device.serialNumber, device.udid, vmwareAttributes];
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

- (NSString *)systemProfilerAttribute:(systemProfilerAttribute)attribute forDevice:(AMDevice *)device
{
//	'print $3' only includes the product id, vender id, serial number and a bunch of empty lines - happy coincidence
	NSString *argument = [NSString stringWithFormat:@"system_profiler SPUSBDataType | sed -n -e '/%@/,/Serial/p' | awk '{ print $3 }'", device.deviceClass];

	NSPipe *pipe = [NSPipe pipe];
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:@"/bin/sh"];
	[task setArguments:@[@"-c", argument]];
	[task setStandardOutput:pipe];
	[task launch];
	[task waitUntilExit];

	NSString *output = [[NSString alloc] initWithData:[[pipe fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding];
	NSMutableArray *outputArray = [[output componentsSeparatedByString:@"\n"] mutableCopy];
	[outputArray removeObject:@""];
	NSArray *reverseOutputArray = [[outputArray reverseObjectEnumerator] allObjects];

//	At this point, reverseOutputArray is in the format:
//	[serial number, vendor id, product id, ...repeat per device]

//	Match device on serial number...this is kind of gross
	NSString *result;
	for (NSUInteger i = 0; i < [reverseOutputArray count]; i = i + 3) {
		if ([reverseOutputArray[i] isEqualToString:device.udid]) {
			switch (attribute) {
				case systemProfilerVendorId:
					result = reverseOutputArray[i + 1];
					break;
				case systemProfilerProductId:
					result = reverseOutputArray[i + 2];
					break;
				default:
					result = @"Not found";
					break;
			}
		}
	}

	return result;
}

- (NSDictionary *)dictionaryForDevice:(AMDevice *)device
{
	NSString *deviceType = [device deviceValueForKey:@"ProductType"];

	NSMutableDictionary *deviceAttributes = [NSMutableDictionary dictionaryWithDictionary:@{@"name": device.deviceName,
																							@"model": [self deviceModelForType:deviceType],
																							@"os_version": [device deviceValueForKey:@"ProductVersion"],
																							@"type": deviceType,
																							@"model_number": [device deviceValueForKey:@"ModelNumber"],
																							@"serial_number": device.serialNumber,
																							@"udid": device.udid}];

	if (_useVmwareAttributes) {
		[deviceAttributes addEntriesFromDictionary:@{@"usb_product_id": [self systemProfilerAttribute:systemProfilerProductId forDevice:device],
													 @"usb_vendor_id": [self systemProfilerAttribute:systemProfilerVendorId forDevice:device]}];
	}
	
	return deviceAttributes;
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
