//
//  T2SourceList.m
//  Thousand
//
//  Created by R. Natori on 06/10/15.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "T2SourceList.h"
#import "T2ListFace.h"
#import "T2PluginManager.h"
#import "T2BookmarkListFace.h"
#import "T2BookmarkList.h"

static NSString *__sharedInternalPath = @"Bookmarks.plist";
static T2SourceList *__sharedSourceList = nil;

@implementation T2SourceList

-(id)init {
	if (!__sharedSourceList) {
		self = [super init];
		[self loadFromFile];
		__sharedSourceList = self;
		return self;
	}
	[self autorelease];
	return __sharedSourceList;
}
-(oneway void)release {
}

+(id)sharedSourceList {
	if (!__sharedSourceList) {
		__sharedSourceList = [[self alloc] init];
	}
	return __sharedSourceList;
}

-(void)setObjects:(NSArray *)anArray {
	NSEnumerator *objectEnumerator = [anArray objectEnumerator];
	NSMutableArray *array = [NSMutableArray array];
	id object;
	while (object = [objectEnumerator nextObject]) {
		if ([object isKindOfClass:[T2ListFace class]]) {
			[array addObject:object];
		}
	}
	setObjectWithRetain(_objects, array);
}

-(NSString *)filePath {
	return [[NSString appLogFolderPath] stringByAppendingPathComponent:__sharedInternalPath];
}
-(void)loadFromFile {
	NSString *path = [self filePath];
	NSArray *savedListFaces = nil;
	if (path) {
		savedListFaces = [NSObject loadObjectFromFile:path];
	}
	NSMutableArray *listFaces = [NSMutableArray array];
	NSArray *lockedListFaces = [[T2PluginManager sharedManager] rootListFaces];
	if (lockedListFaces) {
		_firstBookmarkIndex = [lockedListFaces count];
		[listFaces addObjectsFromArray:lockedListFaces];
	}
	
	if (savedListFaces) {
		[savedListFaces makeObjectsPerformSelector:@selector(setImageByListImporter)];
		[listFaces addObjectsFromArray:savedListFaces];
	}
	[self setObjects:listFaces];
}
-(void)saveToFile {
	NSArray *tempObjects = [[_objects copy] autorelease];
	if ([_objects count] <= _firstBookmarkIndex) {
		[self setObjects:nil];
	} else {
		NSArray *listFaces = [_objects subarrayWithRange:NSMakeRange(_firstBookmarkIndex, [_objects count] - _firstBookmarkIndex)];
		[self setObjects:listFaces];
	}
	NSString *path = [self filePath];
	if (path) {
		[_objects saveObjectToFile:path];
	}
	[self setObjects:tempObjects];
}

-(unsigned)firstBookmarkIndex {
	return _firstBookmarkIndex;
}

-(BOOL)hasBookmarkedThreadFace:(T2ThreadFace *)threadFace {
	NSEnumerator *listFaceEnumerator = [[self objects] objectEnumerator];
	T2ListFace *listFace;
	while (listFace = [listFaceEnumerator nextObject]) {
		if ([listFace isKindOfClass:[T2BookmarkListFace class]]) {
			T2BookmarkList *bookmarkList = (T2BookmarkList *)[listFace list];
			NSArray *bookmarkedThreadFaces = [bookmarkList objects];
			if (bookmarkedThreadFaces) {
				unsigned index = [bookmarkedThreadFaces indexOfObjectIdenticalTo:threadFace];
				if (index != NSNotFound) {
					return YES;
				}
			}
		}
	}
	return NO;
}

-(NSArray *)bookmarkListFacesContainThreadFace:(T2ThreadFace *)threadFace {
	NSMutableArray *results = [NSMutableArray array];
	NSEnumerator *listFaceEnumerator = [[self objects] objectEnumerator];
	T2ListFace *listFace;
	while (listFace = [listFaceEnumerator nextObject]) {
		if ([listFace isKindOfClass:[T2BookmarkListFace class]]) {
			T2BookmarkList *bookmarkList = (T2BookmarkList *)[listFace list];
			NSArray *bookmarkedThreadFaces = [bookmarkList objects];
			if (bookmarkedThreadFaces) {
				unsigned index = [bookmarkedThreadFaces indexOfObjectIdenticalTo:threadFace];
				if (index != NSNotFound) {
					[results addObject:listFace];
				}
			}
		}
	}
	if ([results count] == 0) return nil;
	return results;
}
-(void)removeBookmarkedThreadFace:(T2ThreadFace *)threadFace {
	NSArray *bookmarkListFaces = [self bookmarkListFacesContainThreadFace:threadFace];
	if (!bookmarkListFaces) return;
	NSEnumerator *bookmarkListFaceEnumerator = [bookmarkListFaces objectEnumerator];
	T2BookmarkListFace *bookmarkListFace;
	while (bookmarkListFace = [bookmarkListFaceEnumerator nextObject]) {
		T2BookmarkList *bookmarkList = (T2BookmarkList *)[bookmarkListFace list];
		NSMutableArray *newObjects = [[[bookmarkList objects] mutableCopy] autorelease];
		[newObjects removeObject:threadFace];
		[bookmarkList setObjects:newObjects];
	}
}
-(void)replaceBookmarkedThreadFace:(T2ThreadFace *)oldThreadFace withThreadFace:(T2ThreadFace *)newThreadFace {
	NSArray *bookmarkListFaces = [self bookmarkListFacesContainThreadFace:oldThreadFace];
	if (!bookmarkListFaces) return;
	NSEnumerator *bookmarkListFaceEnumerator = [bookmarkListFaces objectEnumerator];
	T2BookmarkListFace *bookmarkListFace;
	while (bookmarkListFace = [bookmarkListFaceEnumerator nextObject]) {
		T2BookmarkList *bookmarkList = (T2BookmarkList *)[bookmarkListFace list];
		NSMutableArray *newObjects = [[[bookmarkList objects] mutableCopy] autorelease];
		unsigned index = [newObjects indexOfObjectIdenticalTo:oldThreadFace];
		if (index != NSNotFound) {
			[newObjects replaceObjectAtIndex:index withObject:newThreadFace];
			[bookmarkList setObjects:newObjects];
		}
	}
}
@end
