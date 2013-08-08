//
//  T2ListFace.m
//  Thousand
//
//  Created by R. Natori on 06/09/22.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "T2ListFace.h"
#import "T2List.h"
#import "T2PluginManager.h"

static NSMutableDictionary *__instancesDictionary;

static NSMutableArray *__animatingListFaces = nil;
static NSArray *__animationImages = nil;
static unsigned __animationImagesCount = 0;
static unsigned __animationImagesMaxCount = 0;
static NSTimeInterval __loadingAnimationInterval = 0.2;
static NSTimer *__timer = nil;

@implementation T2ListFace

+(void)initialize {
	if (__instancesDictionary) return;
	__instancesDictionary = [self createMutableDictionaryForIdentify];
	__animatingListFaces = [[NSMutableArray mutableArrayWithoutRetainingObjects] retain];
}
+(NSMutableDictionary *)dictionaryForIndentify {
	return __instancesDictionary;
}
-(NSMutableDictionary *)dictionaryForIndentify {
	return __instancesDictionary;
}

-(NSArray *)dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use {
	return [NSArray arrayWithObjects:@"internalPath",
		@"title",nil];
}

#pragma mark -
#pragma mark Factory and Init
+(id)listFaceWithInternalPath:(NSString *)internalPath
						title:(NSString *)title
						image:(NSImage *)image {
	return [[[self alloc] initWithInternalPath:internalPath
										 title:title
										 image:image] autorelease];
}
-(id)initWithInternalPath:(NSString *)internalPath
					title:(NSString *)title
					image:(NSImage *)image {
	self = [super initWithInternalPath:internalPath];
	if (title) [self setTitle:title];
	if (image) [self setImage:image];
	return self;
}
-(void)dealloc {
	if (_animating) {
		[self stopAnimation];
	}
	[self setTitle:nil];
	[self setImage:nil];
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors
-(void)setTitle:(NSString *)aString { setObjectWithRetainSynchronized(_title, aString); }
-(NSString *)title {
	return _title;
}

-(void)setImage:(NSImage *)anImage { setObjectWithRetainSynchronized(_image, anImage); }
-(NSImage *)image { 
	if (_image && _animating && __animationImages) {
		NSImage *destinationImage = [[_image copy] autorelease];
		NSImage *sourceImage = [__animationImages objectAtIndex:__animationImagesCount];
		[destinationImage lockFocus];
		[sourceImage compositeToPoint:NSMakePoint(0,0) operation:NSCompositeSourceOver];
		[destinationImage unlockFocus];
		return destinationImage;
	}
	return _image;
}
-(void)setImageByListImporter {
	if (!_internalPath) return;
	[self setImage:[[T2PluginManager sharedManager] imageForListFace:self]];
}

-(void)setLeaf:(BOOL)aBool { _isLeaf = aBool; }
-(BOOL)isLeaf { return _isLeaf; }

-(BOOL)allowsEditingTitle { return NO; }

-(T2List *)list {
	T2List *list = [T2List availableObjectWithInternalPath:_internalPath];
	if (!list) list = [[T2PluginManager sharedManager] listForListFace:self];
	return list;
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
	if (__animationImagesMaxCount == 0 || [__animatingListFaces count] == 0) return;
	
	NSArray *animatingListFaces = [__animatingListFaces copy];
	[animatingListFaces makeObjectsPerformSelector:@selector(willChangeValueForKey:) withObject:@"image"];
	if (__animationImagesCount < __animationImagesMaxCount-1)
		__animationImagesCount++;
	else
		__animationImagesCount = 0;
	[animatingListFaces makeObjectsPerformSelector:@selector(didChangeValueForKey:) withObject:@"image"];
	[animatingListFaces release];
}

-(void)startAnimation {
	_animating = YES;
	[__animatingListFaces addObject:self];
	if ([__animatingListFaces count] == 1) {
		[T2ListFace startAnimation];
	}
}

-(void)stopAnimation {
	[self willChangeValueForKey:@"image"];
	_animating = NO;
	[__animatingListFaces removeObjectIdenticalTo:self];
	[self didChangeValueForKey:@"image"];
	if ([__animatingListFaces count] == 0) {
		[T2ListFace stopAnimation];
	}
}	
@end
