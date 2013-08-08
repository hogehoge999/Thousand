//
//  T2NSDictionaryAdditions.m
//  Thousand
//
//  Created by R. Natori on 06/01/12.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "T2NSDictionaryAdditions.h"
#import "T2NSDataAdditions.h"


@implementation NSDictionary (T2NSDictionaryAdditions)

// NSDictionary <-> .gz file
+(id)dictionaryWithContentsOfGZipFile:(NSString *)path {
	NSData *rawPlistData = [NSData dataWithContentsOfGZipFile:path];
	if (!rawPlistData) {
		return nil;
	}
	id plistObject = [NSPropertyListSerialization propertyListFromData:rawPlistData
													  mutabilityOption:NSPropertyListImmutable
																format:NULL
													  errorDescription:NULL];
	if (plistObject && [plistObject isKindOfClass:[self class]]) {
		return plistObject;
	}
	return nil;
}

-(BOOL)writeToGZipFile:(NSString *)path {
	NSData *rawPlistData = [NSPropertyListSerialization dataFromPropertyList:self
																	  format:NSPropertyListXMLFormat_v1_0
															errorDescription:NULL];
	if (!rawPlistData) return NO;
	return [rawPlistData writeToGZipFile:path];
}
@end

@implementation NSMutableDictionary (T2NSMutableDictionaryAdditions)

+(NSMutableDictionary *)mutableDictionaryWithoutRetainingValues {
	CFDictionaryValueCallBacks dictionaryValueCallBacks = kCFTypeDictionaryValueCallBacks;
	dictionaryValueCallBacks.retain = NULL;
	dictionaryValueCallBacks.release = NULL;
	
	return [(NSMutableDictionary *)CFDictionaryCreateMutable(NULL, 0,
															 NULL,
															 &dictionaryValueCallBacks) autorelease];
}

@end
