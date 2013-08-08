//
//  T2BookmarkList.m
//  Thousand
//
//  Created by R. Natori on 06/02/18.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "T2BookmarkList.h"
#import "T2ListFace.h"
#import "T2ThreadFace.h"
/*
static NSMutableArray		*__allBookmarkLists;
static T2BookmarkList	*__allBookmarkList;
 */

@implementation T2BookmarkList

#pragma mark -
#pragma mark dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use
-(NSArray *)dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use {
	NSMutableArray *resultArray = [[[super dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use] mutableCopy] autorelease];
	if (![resultArray containsObject:@"objects"] && _objects)
		[resultArray addObject:@"objects"];
	return resultArray;
}

#pragma mark -
#pragma mark Object Initialize

/*
+(void)initialize {
	if (__allBookmarkLists) return;
	__allBookmarkLists = [[NSMutableArray mutableArrayWithoutRetainingObjects] retain];
}
+(NSArray *)allBookmarkLists { return __allBookmarkLists; }

+(void)loadAll {
	NSMutableArray *allBookmarkItems = [NSMutableArray array];
	NSEnumerator *bookmarkListHolderEnumerator = [__allBookmarkLists objectEnumerator];
	T2BookmarkList *bookmarkList;
	while (bookmarkList = [bookmarkListHolderEnumerator nextObject]) {
		[allBookmarkItems addObjectsFromArray:[bookmarkList objects]];
	}
	if ([allBookmarkItems count] > 0) {
		__allBookmarkList = [[self alloc] initWithoutRegistering];
		[__allBookmarkList setObjects:allBookmarkItems];
		[__allBookmarkList load];
	}
}
 */

+(id)bookmarkList {
	return [[[self alloc] init] autorelease];
}
	
-(id)init {
	self = [super init];
	return self;
}
/*
-(id)initWithoutRegistering {
	return [super init];
}
 */

-(void)dealloc {
	_listFace = nil;
	[self cancelLoading];
	[super dealloc];
}


#pragma mark -
#pragma mark Accessors
-(void)setObjects:(NSArray *)anArray { // for Broken files
	NSEnumerator *enumerator = [anArray objectEnumerator];
	id object;
	NSMutableArray *resultArray = [NSMutableArray array];
	Class threadFaceClass = [T2ThreadFace class];
	while (object = [enumerator nextObject]) {
		if ([object isKindOfClass:threadFaceClass]) {
			[resultArray addObject:object];
		}
	}
	setObjectWithRetain(_objects, resultArray);
}

-(void)setListFace:(T2ListFace *)listFace { _listFace = listFace; }
-(T2ListFace *)listFace { return _listFace; }

-(BOOL)allowsEditingObjects { return YES; }
-(BOOL)allowsEditingTitle { return YES; }

-(BOOL)shouldSavePList { return NO; }



#pragma mark -
#pragma mark Internal Loading
-(void)load {
	
	if (_isLoading || !_objects) return;
	
	[self setProgress:0.0];
	[self setProgressInfo:nil];
	
	NSMutableArray *loadingListHolders = [NSMutableArray array];
	NSEnumerator *itemEnumerator = [_objects objectEnumerator];
	T2ThreadFace *item;
	T2List *parentList;
	while (item = [itemEnumerator nextObject]) {
		NSString *internalPath = [item internalPath];
		if (internalPath) {
			T2ListFace *parentListFace = [T2ListFace listFaceWithInternalPath:[internalPath stringByDeletingLastPathComponent]
																		title:nil
																		image:nil];
			parentList = [parentListFace list];
			if (parentList) {
				if ([loadingListHolders indexOfObjectIdenticalTo:parentList] == NSNotFound) {
					[loadingListHolders addObject:parentList];
				}
			}
		}
	}
	_loadingListHoldersCount = [loadingListHolders count];
	if (_loadingListHoldersCount == 0) return;
	
	[self setIsLoading:YES];
	_loadingListHolders = [loadingListHolders retain];
	[self loadPartWithTimer:nil];
}

-(void)cancelLoading {
	if (_timer) {
		[_timer invalidate];
		[_timer release];
		_timer = nil;
	}
	if (_loadingListHolders) {
		if (_loadingList) {
			[_loadingList removeObserver:self forKeyPath:@"isLoading"];
			[_loadingList cancelLoading];
			[_loadingList release];
			_loadingList = nil;
		}
		/*
		T2List *list;
		NSEnumerator *listEnumerator = [_loadingListHolders objectEnumerator];
		while (list = [listEnumerator nextObject]) {
			[list removeObserver:self forKeyPath:<#(NSString *)keyPath#>
		}
		 */
		[_loadingListHolders autorelease];
		_loadingListHolders = nil;
	}
	[self setIsLoading:NO];
}

#pragma mark -
#pragma mark Internal Loading
-(void)loadPartWithTimer:(NSTimer *)timer {
	[_timer release];
	_timer = nil;
	if (!_loadingListHolders) return;
	T2List *list = [_loadingListHolders objectAtIndex:0];
	_loadingListContentObjects = [[list objects] copy];
	[list load];
	if ([list isLoading]) {
		_loadingList = [list retain];
		[list addObserver:self forKeyPath:@"isLoading"
						options:NSKeyValueObservingOptionOld context:NULL];
	} else {
		_loadingList = nil;
		[self partLoaded];
		if (_loadingListHolders)
			[self loadPartWithTimer:nil];
	}
}

-(void)partLoaded {
	T2List *loadedList = [[[_loadingListHolders objectAtIndex:0] retain] autorelease];
	if (_loadingList) {
		[_loadingList removeObserver:self forKeyPath:@"isLoading"];
		[_loadingList release];
		_loadingList = nil;
	}
	if (_loadingListContentObjects) {
		[loadedList setObjects:_loadingListContentObjects];
		[_loadingListContentObjects release];
		_loadingListContentObjects = nil;
	}
	
	[_loadingListHolders removeObjectAtIndex:0];
	unsigned count = [_loadingListHolders count];
	[self setProgress:((float)(_loadingListHoldersCount - count) / (float)_loadingListHoldersCount)];
	[self setProgressInfo:[NSString stringWithFormat:@"%d / %d", (_loadingListHoldersCount - count),_loadingListHoldersCount]];
	if (count == 0) {
		[self cancelLoading];
		/*
		if (self == __allBookmarkList) {
			[__allBookmarkList release];
			__allBookmarkList = nil;
		}
		 */
	} else {
		_timer = [[NSTimer scheduledTimerWithTimeInterval:1.0
												   target:self
												 selector:@selector(loadPartWithTimer:)
												 userInfo:nil
												  repeats:NO] retain];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
						change:(NSDictionary *)change context:(void *)context {
	T2List *list = [_loadingListHolders objectAtIndex:0];
	if (!(object == list && [keyPath isEqualToString:@"isLoading"] && ![list isLoading])) return;
	
	[self partLoaded];
}

#pragma mark -
#pragma mark Automaticaly Saving & Loading
-(NSString *)filePath {
	return nil;
}
@end
