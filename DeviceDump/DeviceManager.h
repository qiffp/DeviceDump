//
//  DeviceManager.h
//  DeviceDump
//
//  Created by Sam Dye on 2014-06-18.
//  Copyright (c) 2014 Sam Dye. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MobileDeviceAccess.h"

@interface DeviceManager : NSObject <MobileDeviceAccessListener>

@property (nonatomic, strong) NSArray *devices;

- (BOOL)isDeviceConnected;
- (NSString *)descriptionOfDevice:(AMDevice *)device;
- (NSString *)descriptionOfDeviceAtIndex:(NSUInteger)index;
- (BOOL)writeDeviceInfoToJSONFile:(NSString *)path;
- (NSString *)deviceInfoJSONString;

@end
