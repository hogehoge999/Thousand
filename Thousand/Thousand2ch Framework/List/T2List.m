//
//  T2List.m
//  Thousand
//
//  Created by R. Natori on 05/07/03.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "T2List.h"
#import "T2ListFace.h"

#import "T2PluginProtocols.h"
#import "T2PluginManager.h"
#import "T2WebConnector.h"
#import "T2WebData.h"
#import "T2NSURLRequestAdditions.h"

NSString *T2ListDidStartLoadingNotification = @"T2ListDidStartLoadingNotification";
NSString *T2ListDidProgressLoadingNotification = @"T2ListDidProgressLoadingNotification";
NSString *T2ListDidEndLoadingNotification = @"T2ListDidEndLoadingNotification";

static NSMutableDictionary *__instancesDictionary = nil;

@implementation T2List
+(void)initialize {
	if (__instancesDictionary) return;
	__instancesDictionary = [self createMutableDictionaryForIdentify];
}
+(NSMutableDictionary *)dictionaryForIndentify {
	return __instancesDictionary;
}
-(NSMutableDictionary *)dictionaryForIndentify {
	return __instancesDictionary;
}


#pragma mark -
#pragma mark dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use
-(NSArray *)dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use {
	return [NSArray arrayWithObjects:@"title",
			@"internalPath",
			@"objects",
			@"extraInfo",
			@"lastLoadingDate",
			nil];
	/*
	if (use == T2DictionaryDecoding) {
		return [NSArray arrayWithObjects:@"title",
			@"internalPath",
			@"objects",
			@"extraInfo", nil];
	}
	if (_internalPath)
		return [NSArray arrayWithObjects:@"title",
			@"internalPath", nil];
	else
		return [NSArray arrayWithObjects:@"title",
			@"objects",
			@"extraInfo", nil];
	 */
}


#pragma mark -
#pragma mark Factory and Init

+(id)listWithListFace:(T2ListFace *)listFace {
	return [[[self alloc] initWithListFace:listFace] autorelease];
}
+(id)listWithListFace:(T2ListFace *)listFace objects:(NSArray *)objects {
	return [[[self alloc] initWithListFace:listFace objects:objects] autorelease];
}
+(id)listWithInternalPath:(NSString *)internalPath title:(NSString *)title
					image:(NSImage *)image objects:(NSArray *)objects {
	return [[[self alloc] initWithInternalPath:internalPath
										 title:title
										 image:image
									   objects:objects] autorelease];
}

-(id)initWithListFace:(T2ListFace *)listFace {
	NSString *internalPath = [listFace internalPath];
	self = [super initWithInternalPath:internalPath];
	[self setListFace:listFace];
	return self;
}
-(id)initWithListFace:(T2ListFace *)listFace objects:(NSArray *)objects {
	self = [self initWithListFace:listFace];
	[self setObjects:objects];
	return self;
}
-(id)initWithInternalPath:(NSString *)internalPath title:(NSString *)title
					image:(NSImage *)image objects:(NSArray *)objects {
	return [self initWithListFace:[T2ListFace listFaceWithInternalPath:internalPath
																 title:title
																 image:image]];
}

-(void)dealloc {
	[self setWebConnector:nil];
	[self setIsLoading:NO];
	[self saveToFile];
	
	[_listFace release];
	[_objects release];
	[_progressInfo release];
	[_lastLoadingDate release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Basic Object
/*
-(unsigned)hash {
	if (!_internalPath && _title) return [_title hash];
	return [super hash];
}
-(BOOL)isEqual:(id)anObject {
	if (![anObject isKindOfClass:[self class]]) return NO;
	if ([super isEqual:anObject]) return YES;
	NSString *title = [(T2List *)anObject title];
	NSArray *list = [(T2List *)anObject objects];
	if ([_title isEqualToString:title] && [_objects isEqualToArray:list]) return YES;
	return NO;
}
-(BOOL)isEqualToList:(T2List *)list {
	return [self isEqual:list];
}
*/

#pragma mark -
#pragma mark Accessors

-(void)setListFace:(T2ListFace *)listFace {
	setObjectWithRetainSynchronized(_listFace, listFace);
}
-(T2ListFace *)listFace { return _listFace; }

-(void)setTitle:(NSString *)aString { [_listFace setTitle:aString]; }
-(NSString *)title { return [_listFace title]; }

-(void)setImage:(NSImage *)anImage { [_listFace setImage:anImage]; }
-(NSImage *)image { return [_listFace image]; }

-(void)setObjects:(NSArray *)anArray {
	setObjectWithRetainSynchronized(_objects, anArray);
}
-(NSArray *)objects { return _objects; }

-(void)setWebConnector:(T2WebConnector *)webConnector {
	@synchronized(self) {
		if (_connector) {
			[_connector cancelLoading];
			[_connector release];
			_connector = nil;
		}
		if (webConnector) {
			_connector = [webConnector retain];
		}
	}
}
-(T2WebConnector *)webConnector {
	return _connector;
}

-(NSMutableArray *)mutableList {
	return [[[self objects] mutableCopy] autorelease];
}

-(BOOL)allowsRemovingObjects { return NO; }
-(BOOL)allowsEditingObjects { return NO; }

-(void)setLoadingInterval:(NSTimeInterval)timeInterval {
	_loadingInterval = timeInterval;
}
-(NSTimeInterval)loadingInterval { return _loadingInterval; }
-(void)setLastLoadingDate:(NSDate *)date {
	setObjectWithRetainSynchronized(_lastLoadingDate, date);
}
-(NSDate *)lastLoadingDate { return _lastLoadingDate; }
-(BOOL)loadableInterval {
	if (_loadingInterval <= 0 || !_lastLoadingDate)
		return YES;
	else {
		NSTimeInterval temp = [[NSDate date] timeIntervalSinceDate:_lastLoadingDate];
		if (temp >= _loadingInterval) {
			return YES;
		}
	}
	return NO;
}

#pragma mark -
#pragma mark Automaticaly Saving & Loading
-(NSString *)filePath {
	return nil;
}

#pragma mark -
#pragma mark Methods

-(void)addObject:(id)anObject {
	NSArray *objects = _objects;
	if (!objects) objects = [NSArray array];
	if ([objects indexOfObjectIdenticalTo:anObject] == NSNotFound)
		[self setObjects:[objects arrayByAddingObject:anObject]];
}
-(void)addObjects:(NSArray *)objects {
	NSMutableArray *tempObjects = [[_objects mutableCopy] autorelease];
	if (!tempObjects) tempObjects = [NSMutableArray array];
	NSEnumerator *objectEnumerator = [objects objectEnumerator];
	id object;
	while(object = [objectEnumerator nextObject]) {
		if ([tempObjects indexOfObjectIdenticalTo:object] == NSNotFound)
			[tempObjects addObject:object];
	}
	[self setObjects:tempObjects];
}
-(void)insertObject:(id)anObject atIndex:(unsigned)anInt {
	NSMutableArray *objects = [[_objects mutableCopy] autorelease];
	if (!objects) objects = [NSMutableArray array];
	if ([objects indexOfObjectIdenticalTo:anObject] == NSNotFound) {
		[objects insertObject:anObject atIndex:anInt];
		[self setObjects:objects];
	}
}
-(void)insertObjects:(NSArray *)objects atIndexes:(NSIndexSet *)indexes {
	NSMutableArray *duplicateObjects = [NSMutableArray array];
	NSMutableArray *tempObjects = [_objects mutableCopy];
	if (!tempObjects) tempObjects = [NSMutableArray array];
	
	NSEnumerator *objectEnumerator = [objects objectEnumerator];
	id object;
	while(object = [objectEnumerator nextObject]) {
		if ([tempObjects indexOfObjectIdenticalTo:object] != NSNotFound)
			[duplicateObjects addObject:object];
	}
	
	[tempObjects insertObjects_panther:objects atIndexes:indexes];
	objectEnumerator = [duplicateObjects objectEnumerator];
	while(object = [objectEnumerator nextObject]) {
		[tempObjects removeObjectIdenticalTo:object];
	}
	[self setObjects:tempObjects];
}
-(void)removeObject:(id)anObject {
	if (!_objects) return;
	NSMutableArray *objects = [[_objects mutableCopy] autorelease];
	[objects removeObjectIdenticalTo:anObject];
	[self setObjects:objects];
}
-(void)removeObjects:(NSArray *)objects {
	if (!objects) return;
	NSMutableArray *tempObjects = [[_objects mutableCopy] autorelease];
	NSEnumerator *objectEnumerator = [objects objectEnumerator];
	id object;
	while(object = [objectEnumerator nextObject]) {
		[tempObjects removeObjectIdenticalTo:object];
	}
	[self setObjects:tempObjects];
}
-(void)removeObjectAtIndex:(unsigned)anInt {
	if (!_objects) return;
	NSMutableArray *objects = [[_objects mutableCopy] autorelease];
	[objects removeObjectAtIndex:anInt];
	[self setObjects:objects];
}
-(void)removeObjectsAtIndexes:(NSIndexSet *)indexes {
	if (!_objects) return;
	NSMutableArray *objects = [[_objects mutableCopy] autorelease];
	[objects removeObjectsAtIndexes_panther:indexes];
	[self setObjects:objects];
}

#pragma mark -
#pragma mark protocol T2AsynchronousLoading
-(void)load {
	@synchronized(self) {
		if (_isLoading
			|| !_internalPath
			|| ![self loadableInterval]
			|| _connector) return;
		
		NSObject <T2ListImporting_v100> *listImporter = [[T2PluginManager sharedManager] listImporterForInternalPath:_internalPath];
		if (![listImporter respondsToSelector:@selector(URLRequestForList:)]) return;
		
		NSURLRequest *listRequest = [listImporter URLRequestForList:self];
		if (listRequest) {
			listRequest = [listRequest requestByAddingUserAgentAndImporterName:[listImporter uniqueName]];
			[self setIsLoading:YES];
			[self setProgress:0];
			[self setProgressInfo:[[listRequest URL] absoluteString]];
			//loading
			[[NSNotificationCenter defaultCenter] postNotificationName:T2ListDidStartLoadingNotification
																object:self
															  userInfo:nil];
			T2WebConnector *webConnector = [T2WebConnector connectorWithURLRequest:listRequest delegate:self inContext:_internalPath];
			[self setWebConnector:webConnector];
		}
	}
}


-(void)cancelLoading {
	@synchronized(self) {
		if (_connector) {
			[[NSNotificationCenter defaultCenter] postNotificationName:T2ListDidEndLoadingNotification
																object:self
															  userInfo:nil];
			[self setWebConnector:nil];
			[self setIsLoading:NO];
		}
		[self setProgress:0];
		[self setProgressInfo:nil];
	}
}

-(void)setIsLoading:(BOOL)aBool {
	if (aBool && !_isLoading) {
		[_listFace startAnimation];
	} else if (!aBool && _isLoading) {
		[_listFace stopAnimation];
	}
	_isLoading = aBool;
	
}
-(BOOL)isLoading { return _isLoading; }

-(void)setProgress:(float)aFloat { _progress = aFloat; }
-(float)progress { return _progress; }
-(void)setProgressInfo:(NSString *)aString { setObjectWithRetainSynchronized(_progressInfo, aString); }
-(NSString *)progressInfo { return _progressInfo; }

#pragma mark -
#pragma mark T2WebConnector delegate
-(void)connector:(T2WebConnector *)connector
		   ofURL:(NSString *)urlString
		progress:(float)progress
	   inContext:(id)contextObject {
	[self setProgress:progress];
	[[NSNotificationCenter defaultCenter] postNotificationName:T2ListDidProgressLoadingNotification
														object:self
													  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:progress]
																						   forKey:@"progress"]];
}

-(void)connector:(T2WebConnector *)connector
		   ofURL:(NSString *)urlString
 didReceiveError:(NSError *)error
	   inContext:(id)contextObject {
	
	[self setProgress:0];
	[self setProgressInfo:[error localizedDescription]];
	[self setIsLoading:NO];
	[self setWebConnector:nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:T2ListDidEndLoadingNotification
														object:self
													  userInfo:nil];
}

-(void)connector:(T2WebConnector *)connector
		   ofURL:(NSString *)urlString
didReceiveWebData:(T2WebData *)webData
	   inContext:(id)contextObject {
	
	@synchronized(self) {
		NSString *internalPath = [self internalPath];
		if (webData && internalPath) {
			NSObject <T2ListImporting_v100> *listImporter = [[T2PluginManager sharedManager] listImporterForInternalPath:internalPath];
			if ([listImporter respondsToSelector:@selector(buildList:withWebData:)]) {
				T2LoadingResult loadingResult = [listImporter buildList:self withWebData:webData];
				if (_loadingInterval > 0 && loadingResult == T2LoadingSucceed) {
					[self setLastLoadingDate:[NSDate date]];
					//[self saveToFile];
				}
			}
		}
		
		[self setProgress:1];
		[self setProgressInfo:[connector status]];
		[self setIsLoading:NO];
		[self setWebConnector:nil];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:T2ListDidEndLoadingNotification
															object:self
														  userInfo:nil];
	}
	
}
@end
