//
//  NSDictionary+ArrayKeys.m
//  DeviceDump
//
//  Created by Sam Dye on 2014-06-18.
//  Copyright (c) 2014 Sam Dye. All rights reserved.
//

#import "NSDictionary+ArrayKeys.h"

@implementation NSDictionary (ArrayKeys)

- (id)objectForArrayKey:(id)aKey
{
	__block id object = nil;
	
	[self enumerateKeysAndObjectsUsingBlock:^(id arrayKey, id obj, BOOL *stop) {
		if ([arrayKey isKindOfClass:[NSArray class]] && [(NSArray *)arrayKey containsObject:aKey]) {
			object = obj;
			*stop = YES;
		}
	}];
	
	return object ?: self[aKey];
}

@end
