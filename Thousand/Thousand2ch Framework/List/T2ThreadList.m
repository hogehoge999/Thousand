//
//  T2ThreadList.m
//  Thousand
//
//  Created by R. Natori on 05/07/03.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "T2ThreadList.h"
#import "T2PluginManager.h"
#import "T2NSDictionaryAdditions.h"
#import "T2ThreadFace.h"
#import "T2Thread.h"
#import "T2Posting.h"

static NSArray *__extensions = nil;
static NSString *__plistName = @"threadList.plist";
static NSMutableDictionary *__threadListObserverForInternalPath = nil;
static NSMutableSet *__threadListObservers = nil;
static NSMutableSet *__notificationCue = nil;
static BOOL __doingNotification = NO;

@implementation T2ThreadList

+(void)initialize {
	if (__extensions) return;
	__extensions = [[NSArray arrayWithObjects:@"t2threadlist", @"plist", nil] retain];
	__threadListObserverForInternalPath = [[NSMutableDictionary alloc] init];
	__threadListObservers = [[NSMutableSet mutableSetWithoutRetainingObjects] retain];
	__notificationCue = [[NSMutableSet alloc] init];
}
+(void)addThreadListObserver:(NSObject *)observer forInternalPath:(NSString *)internalPath {
	if (!internalPath) {
		[__threadListObservers addObject:observer];
		return;
	}
	
	NSMutableSet *observers = [__threadListObserverForInternalPath objectForKey:internalPath];
	if (observers) {
		[observers addObject:observers];
	} else {
		observers = [NSMutableSet mutableSetWithoutRetainingObjects];
		[observers addObject:observer];
		[__threadListObserverForInternalPath setObject:observers forKey:internalPath];
	}
}
+(void)removeThreadListObserver:(NSObject *)observer forInternalPath:(NSString *)internalPath {
	if (!internalPath) {
		[__threadListObservers removeObject:observer];
		return;
	}
	
	NSMutableSet *observers = [__threadListObserverForInternalPath objectForKey:internalPath];
	if (observers) {
		[observers removeObject:observer];
		if ([observers count] == 0) {
			[__threadListObserverForInternalPath removeObjectForKey:internalPath];
		}
	}
}
+(void)registerUpdateThreadListOfInternalPath:(NSString *)internalPath {
	if (!internalPath || __doingNotification) return;
	[__notificationCue addObject:internalPath];
	if ([__notificationCue count] == 1) {
		[[NSRunLoop currentRunLoop] performSelector:@selector(doNotificationCue:) target:self
										   argument:nil order:1000
											  modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
	}
}
+(void)doNotificationCue:(id)object {
	NSSet *notificationCue = [[__notificationCue copy] autorelease];
	[__notificationCue removeAllObjects];
	__doingNotification = YES;
	
	NSEnumerator *internalPathEnumerator = [notificationCue objectEnumerator];
	NSString *internalPath;
	while (internalPath = [internalPathEnumerator nextObject]) {
	
		NSEnumerator *observerEnumerator = [__threadListObservers objectEnumerator];
		NSObject *observer;
		while (observer = [observerEnumerator nextObject]) {
			if ([observer respondsToSelector:@selector(updatedThreadListOfInternalPath:)]) {
				[observer updatedThreadListOfInternalPath:internalPath];
			}
		}
	
		unsigned i=1, count = [[internalPath pathComponents] count];
		do {
			NSMutableSet *observers = [__threadListObserverForInternalPath objectForKey:internalPath];
			if (observers) {
				observerEnumerator = [observers objectEnumerator];
				while (observer = [observerEnumerator nextObject]) {
					if ([observer respondsToSelector:@selector(updatedThreadListOfInternalPath:)]) {
						[observer updatedThreadListOfInternalPath:internalPath];
					}
				}
			}
			internalPath = [internalPath stringByDeletingLastPathComponent];
			i++;
		} while (i<count) ;
	}
	__doingNotification = NO;
}


#pragma mark -
#pragma mark dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use
-(NSArray *)dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use {
	if (!_objects && use == T2DictionaryEncoding) return nil;
	NSMutableArray *resultArray = [[[super dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use] mutableCopy] autorelease];
	[resultArray addObject:@"sortDescriptorKey"];
	[resultArray addObject:@"sortDescriptorAscending"];
	/*
	if (use == T2DictionaryDecoding ||
		(_shouldSavePList && _objects)) [resultArray addObject:@"objects"];
	 */
	return resultArray;
}

#pragma mark -
#pragma mark Init and Dealloc
-(id)initWithListFace:(T2ListFace *)listFace {
	self = [super initWithListFace:listFace];
	[self setShouldSaveFile:YES];
	return self;
}

-(void)dealloc {
	[self saveToFile];
	
	[_sortDescriptorKey release];
	[_webBrowserURLString release];
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors
// Accessors
-(void)setSortDescriptorKey:(NSString *)aString {
	setObjectWithRetainSynchronized(_sortDescriptorKey, aString);
}
-(NSString *)sortDescriptorKey { return _sortDescriptorKey; }

-(void)setSortDescriptorAscending:(BOOL)aBool { _sortDescriptorAscending = aBool; }
-(BOOL)sortDescriptorAscending { return _sortDescriptorAscending; }

-(void)setSortDescriptor:(NSSortDescriptor *)sortDescriptor {
	if (!sortDescriptor) return;
	[self setSortDescriptorKey:[sortDescriptor key]];
	[self setSortDescriptorAscending:[sortDescriptor ascending]];
}
-(NSSortDescriptor *)sortDescriptor {
	if (_sortDescriptorKey)
		return [[[NSSortDescriptor alloc] initWithKey:_sortDescriptorKey ascending:_sortDescriptorAscending] autorelease];
	return nil;
}

-(void)setShouldSavePList:(BOOL)aBool { [super setShouldSaveFile:aBool]; }
-(BOOL)shouldSavePList { return [super shouldSaveFile]; }

-(void)setWebBrowserURLString:(NSString *)urlString {
	setObjectWithRetainSynchronized(_webBrowserURLString, urlString);
}
-(NSString *)webBrowserURLString { return _webBrowserURLString; }

#pragma mark -
#pragma mark Getting Posting
-(T2Posting *)postingWithFirstRes:(T2Res *)res threadTitle:(NSString *)title {
	if (!_internalPath) return nil;
	T2PluginManager *pluginManager = [T2PluginManager sharedManager];
	id <T2Posting_v200> plugin = [pluginManager postingPluginForInternalPath:_internalPath];
	if (plugin) {
		T2Posting *posting = [plugin postingToThreadList:self res:res threadTitle:title];
		return posting;
	} else {
		id <T2ThreadPosting_v100> plugin2 = [pluginManager threadPostingPluginForInternalPath:_internalPath];
		if (plugin2) {
			return [[[T2Posting alloc] initWithThreadList:self res:res threadTitle:title] autorelease];
		}
	}
	return nil;
}

#pragma mark -
#pragma mark Automaticaly Saving & Loading
+(void)setExtensions:(NSArray *)extensions {
	setObjectWithRetainSynchronized(__extensions, extensions);
}
+(NSArray *)extensions {
	return __extensions;
}
-(NSString *)filePath {
	return [[[NSString appLogFolderPath] stringByAppendingPathComponent:_internalPath] stringByAppendingPathComponent:__plistName];
	
}

#pragma mark -
#pragma mark Repair
-(unsigned)repairWithLogFolderContents {
	NSString *internalPath = [self internalPath];
	if (!internalPath || [internalPath hasPrefix:@"History"]) return 0;
	
	NSString *folderPath = [[NSString appLogFolderPath] stringByAppendingPathComponent:internalPath];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	NSArray *files = [fileManager directoryContentsAtPath:folderPath];
	NSArray *extensions = [T2Thread extensions];
	NSMutableArray *infoFiles = [[[files pathsMatchingExtensions:extensions] mutableCopy] autorelease];
	NSMutableArray *notInfoFiles = [[files mutableCopy] autorelease];
	[notInfoFiles removeObjectsInArray:infoFiles];
	
	//NSArray *logFiles = [files pathsMatchingExtensions:[NSArray arrayWithObjects:@"dat", @"gz", nil]];
	//NSArray *plistFiles = [files pathsMatchingExtensions:[NSArray arrayWithObjects:@"plist",nil]];
	NSString *logFile;
	NSEnumerator *logFileEnumerator = [notInfoFiles objectEnumerator];
	
	int missingDatCount = 0;
	
	while (logFile = [logFileEnumerator nextObject]) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSString *threadInternalName = logFile;
		BOOL isDirectory = NO;
		BOOL fileExistsAtPath = [fileManager fileExistsAtPath:[folderPath stringByAppendingPathComponent:logFile] isDirectory:&isDirectory];
		
		if (fileExistsAtPath
			&& !isDirectory
			&& ![logFile hasPrefix:@"threadList"]
			&& ![logFile hasSuffix:@"."]) {
			
			if ([[logFile pathExtension] isEqualToString:@"gz"])
				threadInternalName = [logFile stringByDeletingPathExtension];
			
			NSString *threadInternalPath = [internalPath stringByAppendingPathComponent:threadInternalName];
			T2ThreadFace *threadFace = [T2ThreadFace threadFaceWithInternalPath:threadInternalPath];
			if ([threadFace resCount] == 0) {
				[threadFace thread];
				
				NSString *threadTitle = [threadFace title];
				if (threadTitle && [threadTitle length]>0) {
					[self addObject:threadFace];
					missingDatCount++;
				}
			}
			
			NSString *threadInfoFileBaseName = [threadInternalName stringByDeletingPathExtension];
			NSString *extension;
			NSEnumerator *extensionEnumerator = [extensions objectEnumerator];
			while (extension = [extensionEnumerator nextObject]) {
				NSString *threadInfoFileName = [threadInfoFileBaseName stringByAppendingPathExtension:extension];
				if ([infoFiles containsObject:threadInfoFileName]) {
					[infoFiles removeObject:threadInfoFileName];
					break;
				}
			}
		}
		
		[pool release];
	}
	
	//int missingPlistCount = 0;
	
	logFileEnumerator = [infoFiles objectEnumerator];
	while (logFile = [logFileEnumerator nextObject]) {
		if (![logFile hasPrefix:@"threadList"]) {
			[[folderPath stringByAppendingPathComponent:logFile] recycleFileAtPath];
			//missingPlistCount++;
		}
	}
	
	return missingDatCount;
}

#pragma mark -
#pragma mark OverRide
-(void)setObjects:(NSArray *)anArray {
	[super setObjects:anArray];
	if (_internalPath) {
		[T2ThreadList registerUpdateThreadListOfInternalPath:_internalPath];
	}
}
/*
-(void)loadLocal {
	_loadCount++;
	if (_internalPath && !_objects) {
		[self loadPlist];
	}
}
-(void)unload {
	if (_shouldSavePList && _loadCount==1) {
		[self savePlist];
		[self setIsActive:NO];
		[self setObjects:nil];
	}
	if (_loadCount>0) _loadCount--;
}

-(void)loadPlist {
	NSString *savePath = [[[NSString appLogFolderPath] stringByAppendingPathComponent:_internalPath] stringByAppendingPathComponent:__plistName];
	if (!savePath) return;
	[self setValuesFromFile:savePath];
}
-(void)savePlist {
	if (!_internalPath || !_objects) return;
	NSString *savePath = [[[NSString appLogFolderPath] stringByAppendingPathComponent:_internalPath] stringByAppendingPathComponent:__plistName];
	[self saveObjectToFile:savePath];
}
*/
@end
