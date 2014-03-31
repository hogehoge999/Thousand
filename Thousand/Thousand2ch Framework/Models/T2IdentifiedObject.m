//
//  T2IdentifiedObject.m
//  Thousand
//
//  Created by R. Natori on 05/11/26.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "T2IdentifiedObject.h"

#define CFStringWithNSString(str) (CFStringCreateWithCString(NULL,[str UTF8String],kCFStringEncodingUTF8))

@interface T2IdentifiedObject (T2IdentifiedObjectPrivate)
-(id)privateInitWithInternalPath:(NSString *)internalPath ;
@end

@implementation T2IdentifiedObject
-(NSArray *)dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use {
	return nil;
}

+(NSMutableDictionary *)createMutableDictionaryForIdentify {
	
	CFDictionaryValueCallBacks dictionaryValueCallBacks = kCFTypeDictionaryValueCallBacks;
	dictionaryValueCallBacks.retain = NULL;
	dictionaryValueCallBacks.release = NULL; //&dictionaryValueCallBacks
	
	return (NSMutableDictionary *)CFDictionaryCreateMutable(NULL, 0,
															&kCFTypeDictionaryKeyCallBacks,
															&dictionaryValueCallBacks);
	
	//return [[NSMutableDictionary alloc] init];
}

+(NSMutableDictionary *)dictionaryForIndentify {
	return nil;
}
-(NSMutableDictionary *)dictionaryForIndentify {
	return [[self class] dictionaryForIndentify];
}

+(NSArray *)availableObjectsWithInternalPaths:(NSArray *)internalPaths {
	NSMutableDictionary *dictionaryForIndentify = [self dictionaryForIndentify];
	NSMutableArray *resultArray;
	@synchronized(dictionaryForIndentify) {
		NSEnumerator *internalPathEnumerator = [internalPaths objectEnumerator];
		NSString *internalPath;
		resultArray = [NSMutableArray arrayWithCapacity:[internalPaths count]];
		while (internalPath = [internalPathEnumerator nextObject]) {
			id object = [dictionaryForIndentify objectForKey:internalPath];
			if (object) {
				[resultArray addObject:object];
			}
		}
	}
	return [[resultArray copy] autorelease];
}
+(NSArray *)internalPathsForObjects:(NSArray *)objects {
	NSEnumerator *objectEnumerator = [objects objectEnumerator];
	T2IdentifiedObject *object;
	NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:[objects count]];
	while (object = [objectEnumerator nextObject]) {
		NSString *internalPath = [object internalPath];
		if (internalPath) {
			[resultArray addObject:internalPath];
		}
	}
	return [[resultArray copy] autorelease];
}

+(id)availableObjectWithInternalPath:(NSString *)internalPath {
	NSMutableDictionary *dictionaryForIndentify = [self dictionaryForIndentify];
	id object;
	@synchronized(dictionaryForIndentify) {
		object = [dictionaryForIndentify objectForKey:internalPath];
	}
	return object;
}

#pragma mark -
/*
+(NSArray *)identifiedObjectsWithObjects:(NSArray *)objects {
	NSEnumerator *enumerator = [objects objectEnumerator];
	T2IdentifiedObject *object;
	NSMutableArray *results = [NSMutableArray arrayWithCapacity:[objects count]];
	while (object = [enumerator nextObject]) {
		T2IdentifiedObject *identifiedObject = 
	}
}
 */
+(id)objectWithInternalPath:(NSString *)internalPath {
	if (!internalPath) {
		return [[[self alloc] init] autorelease];
	}
	NSMutableDictionary *dictionaryForIndentify = [self dictionaryForIndentify];
	T2IdentifiedObject *object;
	@synchronized(dictionaryForIndentify) {
		object = [dictionaryForIndentify objectForKey:internalPath];
		if (!object) {
			object = [[[self alloc] privateInitWithInternalPath:internalPath] autorelease];
			[object loadFromFile];

		}
	}
	return object;
}

-(id)privateInitWithInternalPath:(NSString *)internalPath {
	self = [self init];
	_internalPath = [internalPath copy];
	NSMutableDictionary *dictionaryForIndentify = [[self class] dictionaryForIndentify];
	[dictionaryForIndentify setObject:self forKey:_internalPath];
	return self;
}

-(id)initWithInternalPath:(NSString *)internalPath {
	if (!internalPath) {
		self = [self init];
		return self;
	}
	
	NSMutableDictionary *dictionaryForIndentify = [[self class] dictionaryForIndentify];
	T2IdentifiedObject *object;
	@synchronized(dictionaryForIndentify) {
		object = [dictionaryForIndentify objectForKey:internalPath];
		if (object) {
			[object retain];
			[self autorelease];
		} else {
			self = [self privateInitWithInternalPath:internalPath];
			[self loadFromFile];
			object = self;
			/*
			_internalPath = [internalPath copy];
			[dictionaryForIndentify setObject:object forKey:_internalPath];
			[self loadFromFile];
			 */
		}
	}
	return object;
}

-(id)initWithEncodedDictionary:(NSDictionary *)dic {
	id selfObject;
	NSString *internalPath = [dic objectForKey:@"internalPath"];
	if (internalPath) {
		NSMutableDictionary *dictionaryForIndentify = [self dictionaryForIndentify];
		@synchronized(dictionaryForIndentify) {
			selfObject = [dictionaryForIndentify objectForKey:internalPath];
			if (selfObject) {
				[self autorelease];
				return [selfObject retain];
			} else {
				selfObject = [self privateInitWithInternalPath:internalPath];
			}
		}
		
	} else {
		selfObject = [self init];
	}
	
	NSArray *keys = [(id <T2DictionaryConverting>)selfObject dictionaryConvertingKeysForUse:T2DictionaryDecoding];
	NSEnumerator *keyEnumerator = [keys objectEnumerator];
	NSString *key = nil;
	id valueObject;
	while (key = [keyEnumerator nextObject]) {
		if (![key isEqualToString:@"internalPath"]) {
			valueObject = [dic objectForKey:key];
			if (valueObject) valueObject = [NSObject objectWithDictionary:valueObject];
			if (valueObject) [selfObject setValue:valueObject forKey:key];
		}
	}
	return selfObject;
}
/*
- (oneway void)release {
	if ([self retainCount] == 1) {
		[self saveToFile];
	}
	[super release];
}
*/
-(void)dealloc {
	if (_internalPath) {
		NSMutableDictionary *dictionaryForIndentify = [self dictionaryForIndentify];
		@synchronized(dictionaryForIndentify) {
			[dictionaryForIndentify removeObjectForKey:_internalPath];
		}
	}
	[_internalPath release];
	[_extraInfo release];
	[super dealloc];
}

#pragma mark -
#pragma mark Basic Object
-(unsigned)hash {
	if (_internalPath) return [_internalPath hash];
	return [super hash];
}
-(BOOL)isEqual:(id)anObject {
	return (self == anObject
			|| ([anObject isKindOfClass:[self class]]
				&& [_internalPath isEqualToString:[(T2IdentifiedObject *)anObject internalPath]]));
}

#pragma mark -
#pragma mark Accessors
-(void)setInternalPath:(NSString *)internalPath { setObjectWithRetainSynchronized(_internalPath, internalPath); }
-(NSString *)internalPath { return _internalPath; }

#pragma mark -
#pragma mark Automaticaly Saving & Loading
+(NSArray *)extensions {
	return [NSArray arrayWithObject:@"plist"];
}
-(NSString *)filePath { return nil; }

-(NSString *)recommendedFilePath {
	
	NSString *path = [self filePath];
	NSArray *extensions = [[self class] extensions];
	if ([extensions count] > 0) {
		path = [[path stringByDeletingPathExtension] stringByAppendingPathExtension:[extensions objectAtIndex:0]];
	}
	return path;
}
-(NSString *)availableFilePath {
	NSString *path = [self filePath];
	NSArray *extensions = [[self class] extensions];
	if (path && extensions && [extensions count]>0) {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSEnumerator *enumerator = [extensions objectEnumerator];
		NSString *extension;
		while (extension = [enumerator nextObject]) {
			NSString *path2 = [[path stringByDeletingPathExtension] stringByAppendingPathExtension:extension];
			if ([fileManager fileExistsAtPath:path2]) {
				return path2;
			}
		}
	}
	return nil;
}
-(void)loadFromFile {
	NSString *path = [self filePath];
	NSArray *extensions = [[self class] extensions];
	if (path && extensions && [extensions count]>0) {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSEnumerator *enumerator = [extensions objectEnumerator];
		NSString *extension;
		while (extension = [enumerator nextObject]) {
			NSString *path2 = [[path stringByDeletingPathExtension] stringByAppendingPathExtension:extension];
			if ([fileManager fileExistsAtPath:path2]) {
				@synchronized(self) {
					[self setValuesFromFile:path2];
				}
				break;
			}
		}
	}
}
-(void)saveToFile {
	if (_shouldSaveFile) {
		NSString *path = [self filePath];
		NSArray *extensions = [[self class] extensions];
		if (path && extensions && [extensions count]>0) {
			NSFileManager *fileManager = [NSFileManager defaultManager];
			NSEnumerator *enumerator = [extensions objectEnumerator];
			NSString *extension;
			BOOL fileSaved = NO;
			@synchronized(self) {
				while (extension = [enumerator nextObject]) {
					NSString *path2 = [[path stringByDeletingPathExtension] stringByAppendingPathExtension:extension];
					if (!fileSaved) {
						[self saveObjectToFile:path2];
						fileSaved = YES;
					} else if ([fileManager fileExistsAtPath:path2]) {
						[fileManager removeItemAtPath:path2 error:NULL];
					}
				}
			}
		}
	}
}

-(void)setShouldSaveFile:(BOOL)aBool { _shouldSaveFile = aBool; }
-(BOOL)shouldSaveFile { return _shouldSaveFile; }

#pragma mark -
#pragma mark Score or Other Property
-(void)setExtraInfo:(NSDictionary *)dic {
	@synchronized(self) {
		[_extraInfo release];
		_extraInfo = [dic mutableCopy];
	}
}
-(NSDictionary *)extraInfo { return _extraInfo; }
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
	@synchronized(self) {
		if (!_extraInfo) _extraInfo = [[NSMutableDictionary alloc] init];
		if (value) [_extraInfo setObject:value forKey:key];
		else [_extraInfo removeObjectForKey:key];
	}
}
- (id)valueForUndefinedKey:(NSString *)key {
	if (!_extraInfo) return nil;
	return [_extraInfo objectForKey:key];
}

-(void)setSaved:(BOOL)aBool {}
-(BOOL)saved { return ![self shouldSaveFile]; }
@end
