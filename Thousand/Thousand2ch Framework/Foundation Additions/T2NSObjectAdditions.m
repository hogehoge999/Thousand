//
//  T2NSObjectAdditions.m
//  Thousand
//
//  Created by R. Natori on 05/07/17.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "T2NSObjectAdditions.h"
#import "T2NSStringAdditions.h"
#import "T2NSDictionaryAdditions.h"
#import "T2NSDataAdditions.h"

#define NSArrayClass ([NSArray class])
#define NSDictionaryClass ([NSDictionary class])
#define NSStringClass ([NSString class])
#define NSNumberClass ([NSNumber class])
#define NSDateClass ([NSDate class])

#define isPlistEncodable(anObject) (([anObject isKindOfClass:NSStringClass] || [anObject isKindOfClass:NSNumberClass] || [anObject isKindOfClass:NSDateClass])) 


static BOOL __binaryPList = YES;
static BOOL __gzipPList = NO;

static NSMutableSet *__objectsToReleaseAfterDelay = nil;
static NSTimer *__delayedReleaseTimer = nil;



@implementation NSObject (T2NSObjectAdditions)

+(id)objectWithDictionary:(id)dic {
	if (!dic) return nil;
	else if (isPlistEncodable(dic)) {
		return dic;
	} else if ([dic isKindOfClass:NSDictionaryClass]) {
		NSData *archivedData = [dic objectForKey:@"__archivedData"];
		if (archivedData) {
			return [NSKeyedUnarchiver unarchiveObjectWithData:archivedData];
		}
		
		NSString *objectClassString = [dic objectForKey:@"__className"];
		if (objectClassString) {
			Class objectClass = NSClassFromString(objectClassString);
			return [[[objectClass alloc] initWithEncodedDictionary:dic] autorelease];
		} else {
			NSDictionary *orDic = dic;
			NSMutableDictionary *decodedDic = [NSMutableDictionary dictionary];
			NSEnumerator *dicEnumerator = [orDic keyEnumerator];
			id key;
			id contentObject;
			while (key = [dicEnumerator nextObject]) {
				contentObject = [NSObject objectWithDictionary:[orDic objectForKey:key]];
				if (contentObject) [decodedDic setObject:contentObject forKey:key];
			}
			return decodedDic;
		}
	} else if ([dic isKindOfClass:NSArrayClass]) {
		NSArray *dicArray = dic;
		NSMutableArray *decodedArray = [NSMutableArray array];
		NSEnumerator *dicEnumerator = [dicArray objectEnumerator];
		id contentObject;
		while (contentObject = [dicEnumerator nextObject]) {
			contentObject = [NSObject objectWithDictionary:contentObject];
			if (contentObject) [decodedArray addObject:contentObject];
		}
		return decodedArray;
	} else return nil;
}

-(id)initWithEncodedDictionary:(NSDictionary *)dic {
	
	if (![[self class] conformsToProtocol:@protocol(T2DictionaryConverting)]) {
		[self autorelease];
		return nil;
	}
	[self init];
	NSArray *keys = [(id <T2DictionaryConverting>)self dictionaryConvertingKeysForUse:T2DictionaryDecoding];
	NSEnumerator *keyEnumerator = [keys objectEnumerator];
	NSString *key = nil;
	id valueObject;
	while (key = [keyEnumerator nextObject]) {
		valueObject = [dic objectForKey:key];
		if (valueObject) valueObject = [NSObject objectWithDictionary:valueObject];
		if (valueObject) [self setValue:valueObject forKey:key];
	}
	return self;
}
-(void)setValuesWithEncodedDictionary:(NSDictionary *)dic {
	NSArray *keys = [(id <T2DictionaryConverting>)self dictionaryConvertingKeysForUse:T2DictionaryDecoding];
	NSEnumerator *keyEnumerator = [keys objectEnumerator];
	NSString *key = nil;
	id valueObject;
	while (key = [keyEnumerator nextObject]) {
		valueObject = [dic objectForKey:key];
		if (valueObject) valueObject = [NSObject objectWithDictionary:valueObject];
		if (valueObject) [self setValue:valueObject forKey:key];
	}
}

-(id)encodedDictionary {
	
	if (isPlistEncodable(self)) {
		return self;
	} else if ([self isKindOfClass:NSDictionaryClass]) {
		NSDictionary *orDic = (NSDictionary *)self;
		if ([orDic count] == 0) return nil;
		
		NSMutableDictionary *encodedDic = [NSMutableDictionary dictionary];
		NSEnumerator *dicEnumerator = [orDic keyEnumerator];
		id key;
		id contentObject;
		while (key = [dicEnumerator nextObject]) {
			contentObject = [[orDic objectForKey:key] encodedDictionary];
			if (contentObject) [encodedDic setObject:contentObject forKey:key];
		}
		return encodedDic;
		
	} else if ([self isKindOfClass:NSArrayClass]) {
		NSArray *orArray = (NSArray *)self;
		if ([orArray count] == 0) return nil;
		
		NSMutableArray *encodedArray = [NSMutableArray array];
		NSEnumerator *orEnumerator = [orArray objectEnumerator];
		id contentObject;
		while (contentObject = [orEnumerator nextObject]) {
			contentObject = [contentObject encodedDictionary];
			if (contentObject) [encodedArray addObject:contentObject];
		}
		return encodedArray;
	} else if (![[self class] conformsToProtocol:@protocol(T2DictionaryConverting)]) {
		if ([[self class] conformsToProtocol:@protocol(NSCoding)]) {
			NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:self];
			if (archivedData) {
				return [NSDictionary dictionaryWithObject:archivedData forKey:@"__archivedData"];
			} else return nil;
		} else return nil;
	}
	NSArray *keys = [(id <T2DictionaryConverting>)self dictionaryConvertingKeysForUse:T2DictionaryEncoding];
	if (!keys || [keys count] == 0) return nil;
	NSEnumerator *keyEnumerator = [keys objectEnumerator];
	NSString *key = nil;
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setObject:NSStringFromClass([self class]) forKey:@"__className"];
	
	while (key = [keyEnumerator nextObject]) {
		id valueObject = [self valueForKey:key];
		if (valueObject) {
			NSDictionary *encodedDictionary = [valueObject encodedDictionary];
			if (encodedDictionary) {
				[dic setObject:encodedDictionary forKey:key];
			}
		}
	}
	
	return dic;
}

+(id)loadObjectFromFile:(NSString *)filePath {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	NSString *pathExtension = [filePath pathExtension];
	if (!pathExtension || [pathExtension length] == 0)
		filePath = [filePath stringByAppendingPathExtension:@"plist"];
	
	NSData *plistData;
	if ([fileManager fileExistsAtPath:filePath]) {
		plistData = [NSData dataWithContentsOfFile:filePath];
	} else {
		filePath = [filePath stringByAppendingPathExtension:@"gz"];
		if ([fileManager fileExistsAtPath:filePath]) {
			plistData = [NSData dataWithContentsOfGZipFile:filePath];
		} else return nil;
	}
	NSDictionary *dictionary = [NSPropertyListSerialization propertyListFromData:plistData
																mutabilityOption:NSPropertyListImmutable
																		  format:NULL
																errorDescription:NULL];
	if (!dictionary) return nil;
	return [self objectWithDictionary:dictionary];
}
-(BOOL)saveObjectToFile:(NSString *)filePath {
	NSDictionary *dictionary = [self encodedDictionary];
	NSData *data = nil;
	if (dictionary) {
		if (__binaryPList) {
			data = [NSPropertyListSerialization dataFromPropertyList:dictionary
															  format:NSPropertyListBinaryFormat_v1_0
													errorDescription:NULL];
		} else {
			data = [NSPropertyListSerialization dataFromPropertyList:dictionary
															  format:NSPropertyListXMLFormat_v1_0
													errorDescription:NULL];
		}
	}
	NSString *pathExtension = [filePath pathExtension];
	if (!pathExtension || [pathExtension length] == 0)
		filePath = [filePath stringByAppendingPathExtension:@"plist"];
	
	[filePath prepareFoldersInPath];
	NSString *gzFilePath = [filePath stringByAppendingPathExtension:@"gz"];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error;
	if (!data) {
		if ([fileManager fileExistsAtPath:filePath])
			[fileManager removeItemAtPath:filePath error:&error];
		if ([fileManager fileExistsAtPath:gzFilePath])
			[fileManager removeItemAtPath:gzFilePath error:&error];
		return NO;
	}
	if (__gzipPList) {
		[data writeToGZipFile:gzFilePath];
		if ([fileManager fileExistsAtPath:filePath])
			[fileManager removeItemAtPath:filePath error:&error];
	} else {
		[data writeToFile:filePath atomically:YES];
		if ([fileManager fileExistsAtPath:gzFilePath])
			[fileManager removeItemAtPath:gzFilePath error:&error];
	}
	return YES;
}

-(void)setValuesFromFile:(NSString *)filePath {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	NSString *pathExtension = [filePath pathExtension];
	if (!pathExtension || [pathExtension length] == 0)
		filePath = [filePath stringByAppendingPathExtension:@"plist"];
	
	NSData *plistData;
	if ([fileManager fileExistsAtPath:filePath]) {
		plistData = [NSData dataWithContentsOfFile:filePath];
	} else {
		filePath = [filePath stringByAppendingPathExtension:@"gz"];
		if ([fileManager fileExistsAtPath:filePath]) {
			plistData = [NSData dataWithContentsOfGZipFile:filePath];
		} else return ;
	}
	NSDictionary *dictionary = [NSPropertyListSerialization propertyListFromData:plistData
																mutabilityOption:NSPropertyListImmutable
																		  format:NULL
																errorDescription:NULL];
	if (!dictionary) return ;
	[self setValuesWithEncodedDictionary:dictionary];
}

#pragma mark -
-(id)releaseAfterDelay {
	[NSObject addObjectToReleaseAfterDelay:self];
	return self;
}
+(void)addObjectToReleaseAfterDelay:(id)anObject {
	if (__delayedReleaseTimer) {
		[__delayedReleaseTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:1]];
	} else {
		__delayedReleaseTimer = [[NSTimer scheduledTimerWithTimeInterval:1
																  target:self
																selector:@selector(delayedReleaseTimerFired:)
																userInfo:nil
																 repeats:NO] retain];
	}
	if (!__objectsToReleaseAfterDelay) {
		__objectsToReleaseAfterDelay = [[NSMutableSet alloc] init];
	}
	[__objectsToReleaseAfterDelay addObject:anObject];
}
+(void)delayedReleaseTimerFired:(NSTimer *)timer {
	[__delayedReleaseTimer release];
	__delayedReleaseTimer = nil;
	[__objectsToReleaseAfterDelay removeAllObjects];
}
@end
