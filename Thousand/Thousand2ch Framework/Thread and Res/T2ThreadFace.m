//
//  T2ThreadFace.m
//  Thousand
//
//  Created by R. Natori on 05/07/03.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "T2Thread.h"
#import "T2ThreadFace.h"
#import "T2ListFace.h"
#import "T2PluginManager.h"

static NSImage *__stateNewImage			= nil;
static NSImage *__stateUpdatedImage		= nil;
static NSImage *__stateNoUpdatedImage	= nil;
static NSImage *__stateFallenImage		= nil;
static NSImage *__stateFallenNoLogImage	= nil;

static NSString *__stringSuffix = @"String";
static unsigned __stringSuffixLength;

static NSMutableDictionary *__instancesDictionary = nil;

static NSMutableArray *__animatingThreadFaces = nil;
static NSArray *__animationImages = nil;
static unsigned __animationImagesCount = 0;
static unsigned __animationImagesMaxCount = 0;
static NSTimeInterval __loadingAnimationInterval = 0.2;
static NSTimer *__timer = nil;


@implementation T2ThreadFace
+(void)initialize {
	if (__instancesDictionary) return;
	__instancesDictionary = [self createMutableDictionaryForIdentify];
	
	__stringSuffixLength = [__stringSuffix length];
	__animatingThreadFaces = [[NSMutableArray mutableArrayWithoutRetainingObjects] retain];
	
	[self setKeys:[NSArray arrayWithObjects:@"resCount", @"createdDate", @"modifiedDate", nil]
triggerChangeNotificationsForDependentKey:@"velocity"];
	[self setKeys:[NSArray arrayWithObjects:@"resCount", @"resCountNew", nil]
triggerChangeNotificationsForDependentKey:@"resCountGap"];
	[self setKeys:[NSArray arrayWithObject:@"state"]
triggerChangeNotificationsForDependentKey:@"stateImage"];
	//[self setKeys:[NSArray arrayWithObject:@"title"] triggerChangeNotificationsForDependentKey:@"replacedTitle"];
}
+(NSMutableDictionary *)dictionaryForIndentify {
	return __instancesDictionary;
}
-(NSMutableDictionary *)dictionaryForIndentify {
	return __instancesDictionary;
}


#pragma mark -
#pragma mark Class Properties

+(void)setClassStateNewImage:(NSImage *)anImage {
	setObjectWithRetain(__stateNewImage, anImage);
}
+(NSImage *)classStateNewImage { return __stateNewImage; }

+(void)setClassStateUpdatedImage:(NSImage *)anImage {
	setObjectWithRetain(__stateUpdatedImage, anImage);
}
+(NSImage *)classStateUpdatedImage { return __stateUpdatedImage; }

+(void)setClassStateNoUpdatedImage:(NSImage *)anImage {
	setObjectWithRetain(__stateNoUpdatedImage, anImage);
}
+(NSImage *)classStateNoUpdatedImage { return __stateNoUpdatedImage; }

+(void)setClassStateFallenImage:(NSImage *)anImage {
	setObjectWithRetain(__stateFallenImage, anImage);
}
+(NSImage *)classStateFallenImage { return __stateFallenImage; }

+(void)setClassStateFallenNoLogImage:(NSImage *)anImage {
	setObjectWithRetain(__stateFallenNoLogImage, anImage);
}
+(NSImage *)classStateFallenNoLogImage { return __stateFallenNoLogImage; }


#pragma mark -
#pragma mark dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use
-(NSArray *)dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use {
	
	return [NSArray arrayWithObjects:
			@"title", @"internalPath", @"order", @"resCount", @"resCountNew",
			@"createdDate", @"modifiedDate",
			@"state", @"label", @"extraInfo", nil];
}

#pragma mark -
#pragma mark Factory and Init

+(id)threadFaceWithURLString:(NSString *)URLString {
	NSString *internalPath = [[T2PluginManager sharedManager] threadInternalPathForProposedURLString:URLString];
	return [self threadFaceWithInternalPath:internalPath];
}
+(id)threadFaceWithInternalPath:(NSString *)internalPath {
	if (internalPath)
		return [self threadFaceWithInternalPath:internalPath
										  title:nil
										  order:-1
									   resCount:-1
									resCountNew:-1];
	return nil;
}
+(id)threadFaceWithInternalPath:(NSString *)internalPath title:(NSString *)title
						  order:(int)order resCount:(int)resCount resCountNew:(int)resCountNew {
	return [[[self alloc] initWithInternalPath:internalPath
										 title:title
										 order:order
									  resCount:resCount
								   resCountNew:resCountNew] autorelease];
}
-(id)initWithInternalPath:(NSString *)internalPath title:(NSString *)title
					order:(int)order resCount:(int)resCount resCountNew:(int)resCountNew {
	self = [super initWithInternalPath:internalPath];
	if (title) [self setTitle:title];
	if (order != -1) [self setOrder:order];
	if (resCount > 0) [self setResCount:resCount];
	if (resCountNew > 0) [self setResCountNew:resCountNew];
	return self;
}


-(id)init {
	self = [super init];
	_state = T2ThreadFaceStateNew;
	return self;
}

-(void)dealloc {	
	[_title release];
	
	[_createdDate release];
	[_modifiedDate release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Getting Thread
-(T2Thread *)thread {
	T2Thread *thread = [T2Thread availableObjectWithInternalPath:_internalPath];
	if (!thread) thread = [[T2PluginManager sharedManager] threadForThreadFace:self];
	[thread applyAllStyles];
	return thread;
}

#pragma mark -
#pragma mark Accessors

-(void)setTitle:(NSString *)aString {
	setObjectWithRetainSynchronized(_title, aString);
}
-(NSString *)title {
	return _title;
}

-(void)setOrder:(int)anInt { _order = anInt; }
-(int)order { return _order; }

-(void)setResCount:(int)anInt {
	_resCount = anInt;
	if (_resCount >= _resCountNew) {
		[self setResCountNew:_resCount];
	}
}
-(int)resCount { return _resCount; }
-(void)setResCountNew:(int)anInt {
	_resCountNew = anInt;
}
-(int)resCountNew { return _resCountNew; }

-(int)resCountGap {
	if (_resCount > 0)
		return _resCountNew - _resCount;
	else
		return 0;
}

-(void)setStateFromResCount {
	if (_resCount == 0 || _state == T2ThreadFaceStateFallen)
		return;
	//[self setState:T2ThreadFaceStateNone];
	else if (_resCountNew > _resCount)
		[self setState:T2ThreadFaceStateUpdated];
	else
		[self setState:T2ThreadFaceStateNotUpdated];
}

#pragma mark -
#pragma mark Optional Properties
-(T2ListFace *)threadListFace {
	NSString *listFaceInternalPath = [_internalPath stringByDeletingLastPathComponent];
	if (listFaceInternalPath) {
		T2ListFace *listFace = [T2ListFace listFaceWithInternalPath:listFaceInternalPath
															  title:nil
															  image:nil];
		if (listFace) return listFace;
	}
	return nil;
}
-(NSString *)threadListTitle {
	NSString *listFaceInternalPath = [_internalPath stringByDeletingLastPathComponent];
	if (listFaceInternalPath) {
		T2ListFace *listFace = [T2ListFace listFaceWithInternalPath:listFaceInternalPath
															  title:nil
															  image:nil];
		if (listFace) return [listFace title];
	}
	return @"(Untitled)";
}
-(NSString *)threadListInternalPath {
	return [_internalPath stringByDeletingLastPathComponent];
}

-(void)setCreatedDate:(NSDate *)aDate {
	setObjectWithRetainSynchronized(_createdDate, aDate);
}
-(NSDate *)createdDate { return _createdDate; }

-(void)setModifiedDate:(NSDate *)aDate {
	setObjectWithRetainSynchronized(_modifiedDate, aDate);
}
-(NSDate *)modifiedDate { return _modifiedDate; }

-(float)velocity {
	if (!_createdDate || !_modifiedDate) return 0;
	NSTimeInterval createdDateInterval = [_createdDate timeIntervalSinceReferenceDate];
	NSTimeInterval modifiedDateInterval = [_modifiedDate timeIntervalSinceReferenceDate];
	if (createdDateInterval >= modifiedDateInterval) return 0;
	return 3600.0 * (_resCountNew/([_modifiedDate timeIntervalSinceReferenceDate] - [_createdDate timeIntervalSinceReferenceDate]));
}

-(void)setState:(int)state {
	_state = state;
}
-(int)state { return _state; }
-(NSImage *)stateImage {
	NSImage *image = nil;
	if (_state == T2ThreadFaceStateNew)
		image = __stateNewImage;
	else if (_state == T2ThreadFaceStateUpdated)
		image = __stateUpdatedImage;
	else if (_state == T2ThreadFaceStateNotUpdated)
		image = __stateNoUpdatedImage;
	else if (_state == T2ThreadFaceStateFallen)
		image = __stateFallenImage;
	else if (_state == T2ThreadFaceStateFallenNoLog)
		image = __stateFallenNoLogImage;
	if (image && (_boolsMask & T2ThreadFaceAnimatingMask) && __animationImages) {
		NSImage *destinationImage = [[image copy] autorelease];
		NSImage *sourceImage = [__animationImages objectAtIndex:__animationImagesCount];
		[destinationImage lockFocus];
		[sourceImage compositeToPoint:NSMakePoint(0,0) operation:NSCompositeSourceOver];
		[destinationImage unlockFocus];
		image = destinationImage;
	}
	return image;
}

-(void)setHasFallen:(BOOL)aBool { _boolsMask = _boolsMask | T2ThreadHasFallenMask; }
-(BOOL)hasFallen { return (_boolsMask & T2ThreadHasFallenMask); }
-(void)setChecked:(BOOL)aBool { _boolsMask = _boolsMask | T2ThreadIsCheckedMask; }
-(BOOL)checked { return (_boolsMask & T2ThreadIsCheckedMask); }

-(void)setLabel:(int)anInt { _label = anInt; }
-(int)label { return _label; }


#pragma mark -
#pragma mark Score or Other Property
-(NSString *)voidProperty { return nil; }

- (id)valueForUndefinedKey:(NSString *)key {
	id <T2ThreadFaceScoring_v100> scorer;
	scorer = [[T2PluginManager sharedManager] threadFaceScoringPluginForKey:key];
	if (scorer) return [scorer scoreValueOfThreadFace:self forKey:key];
	else if ([key hasSuffix:__stringSuffix]) {
		NSString *nextKey = [key substringToIndex:([key length]-__stringSuffixLength)];
		return [self valueForKey:nextKey];
	} else {
		return [super valueForUndefinedKey:key];
	}
}


#pragma mark -
#pragma mark Other
-(id <T2ThreadImporting_v100>)threadImpoerterPlug {
	if (_internalPath)
		return [[T2PluginManager sharedManager] threadImporterForInternalPath:_internalPath];
	else
		return nil;
}
-(NSString *)logFilePath {
	if (_internalPath)
		return [[T2PluginManager sharedManager] threadLogFilePathForInternalPath:_internalPath];
	else
		return nil;
}
-(void)removeThread {
	[self recycleThreadLogFile];
}
-(void)recycleThreadLogFile {
	
	T2Thread *thread = [T2Thread availableObjectWithInternalPath:_internalPath];
	if (thread) {
		[thread setShouldSaveFile:NO];
	}
	
	[self setResCount:0];
	
	NSString *logFilePath = [self logFilePath];
	[logFilePath recycleFileAtPath];
	
	NSEnumerator *extensionEnumerator = [[T2Thread extensions] objectEnumerator];
	NSString *extension;
	while (extension = [extensionEnumerator nextObject]) {
		NSString *infoFilePath = [[[[NSString appLogFolderPath] stringByAppendingPathComponent:_internalPath]
								   stringByDeletingPathExtension] stringByAppendingPathExtension:extension];
		[infoFilePath recycleFileAtPath];
	}
}

#pragma mark -
#pragma mark Animation Support
+(void)setClassAnimationImages:(NSArray *)images {
	[images retain];
	[__animationImages release];
	__animationImages = images;
	__animationImagesMaxCount = [__animationImages count];
}
+(void)startAnimation {
	if (__animationImagesMaxCount == 0) return;
	__timer = [NSTimer scheduledTimerWithTimeInterval:__loadingAnimationInterval
											   target:self
											 selector:@selector(animate:)
											 userInfo:nil
											  repeats:YES];
}
+(void)stopAnimation {
	if (__animationImagesMaxCount == 0) return;
	[__timer invalidate];
	__timer = nil;
}
+(void)animate:(NSTimer *)timer {
	if (__animationImagesMaxCount == 0) return;
	[__animatingThreadFaces makeObjectsPerformSelector:@selector(willChangeValueForKey:) withObject:@"stateImage"];
	if (__animationImagesCount < __animationImagesMaxCount-1)
		__animationImagesCount++;
	else
		__animationImagesCount = 0;
	[__animatingThreadFaces makeObjectsPerformSelector:@selector(didChangeValueForKey:) withObject:@"stateImage"];
}

-(void)startAnimation {
	_boolsMask = _boolsMask & T2ThreadFaceAnimatingMask;
	[__animatingThreadFaces addObject:self];
	if ([__animatingThreadFaces count] == 1) {
		[T2ThreadFace startAnimation];
	}
}

-(void)stopAnimation {
	[self willChangeValueForKey:@"stateImage"];
	_boolsMask = _boolsMask ^ T2ThreadFaceAnimatingMask;
	[__animatingThreadFaces removeObjectIdenticalTo:self];
	[self didChangeValueForKey:@"stateImage"];
	if ([__animatingThreadFaces count] == 0) {
		[T2ThreadFace stopAnimation];
	}
}
@end
