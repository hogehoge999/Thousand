//
//  THLocalFileImporter.m
//  THLocalFileImporter
//
//  Created by R. Natori on 05/10/08.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "THLocalFileImporter.h"
#import "TH2chImporterPlug.h"

#define plugLocalizedString(aString) ([_selfBundle localizedStringForKey:aString value:aString table:@"StandardPlugLocalizable"])

static NSString *__uniqueName = @"jp_natori_THLocalFileImporter";
static NSString *__rootPath = @"Local File";

static NSImage *__masterImage = nil;
static NSImage *__boardImage = nil;

@implementation THLocalFileImporter

-(id)init {
	self = [super init];
	_selfBundle = [[NSBundle bundleForClass:[self class]] retain];
	
	__masterImage = [[NSImage imageNamed:@"TH16_Folder Master" orInBundle:_selfBundle] retain];
	__boardImage = [[NSImage imageNamed:@"TH16_Folder Board" orInBundle:_selfBundle] retain];
	return self;
}
-(void)dealloc {
	[_2chImporterPlug release];
	[super dealloc];
}

#pragma mark protocol T2PluginInterface_v100
+(NSArray *)pluginInstances {
	return [NSArray arrayWithObject:[[[self alloc] init] autorelease]];
}
-(NSString *)uniqueName { return __uniqueName; }
-(NSString *)localizedName { return plugLocalizedString(__uniqueName) ; }
-(NSString *)localizedPluginInfo { return plugLocalizedString([__uniqueName stringByAppendingString:@"_info"]) ; }
-(T2PluginType)pluginType { return T2EmbeddedPlugin; }
-(int)pluginOrder { return T2PluginOrderFirst+1; }
-(NSArray *)uniqueNamesOfdependingPlugins { return nil; }


-(NSString *)importableRootPath { return __rootPath; }
-(T2List *)listForListFace:(T2ListFace *)listFace {
	NSString *internalPath = [listFace internalPath];
	
	NSString *folderPath;
	if ([internalPath isEqualToString:__rootPath]) folderPath = @"/";
	else if ([internalPath hasPrefix:__rootPath]) folderPath = [internalPath substringFromIndex:[__rootPath length]];
	else return nil;
	BOOL isFolder = NO;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:folderPath isDirectory:&isFolder] && isFolder) {
		T2List *resultList = nil;
		NSArray *folderContents = [fileManager directoryContentsAtPath:folderPath];
		NSEnumerator *folderContentEnumerator = [folderContents objectEnumerator];
		NSString *contentPath;
		NSMutableArray *contentListHolders = [NSMutableArray array];
		NSMutableArray *contentThreadItems = [NSMutableArray array];
		BOOL isFolder2 = NO;
		BOOL isLogFolder = NO;
		while (contentPath = [folderContentEnumerator nextObject]) {
			if ([fileManager fileExistsAtPath:[folderPath stringByAppendingPathComponent:contentPath] isDirectory:&isFolder2]) {
				if (isFolder2 && !isLogFolder) {
					T2ListFace *listFace = [T2ListFace listFaceWithInternalPath:[internalPath stringByAppendingPathComponent:contentPath]
																		  title:contentPath
																		  image:__boardImage];
					if (listFace) {
						[contentListHolders addObject:listFace];
					}
				} else if ([[contentPath pathExtension] isEqualToString:@"dat"]) {
					isLogFolder = YES;
					T2ThreadFace *threadFace = [self threadItemWithDatFilePath:[folderPath stringByAppendingPathComponent:contentPath]];
					if (threadFace) [contentThreadItems addObject:threadFace];
				}
			}
		}
		if (isLogFolder) {
			resultList = [T2ThreadList listWithListFace:listFace];
			[resultList setObjects:contentThreadItems];
			return resultList;
			//[NSThread detachNewThreadSelector:@selector(loadAllInfoForThreadList:)
			//						 toTarget:self withObject:list];
		} else {
			resultList = [T2List listWithListFace:listFace];
			[resultList setObjects:contentListHolders];
			return resultList;
		}
	}
	return nil;;
}
-(NSImage *)imageForListFace:(T2ListFace *)listFace {
	NSString *internalPath = [listFace internalPath];
	
	if ([internalPath isEqualToString:__rootPath])
		return __masterImage;
	return __boardImage;
}


#pragma mark Internal
-(T2ThreadFace *)threadItemWithDatFilePath:(NSString *)pathString {
	NSFileHandle *srcFileHandle = [NSFileHandle fileHandleForReadingAtPath:pathString];
	if (!srcFileHandle) {
		[self release];
		return nil;
	}
	unsigned long long readLocation = 0;
	unsigned long long fileSize = [srcFileHandle seekToEndOfFile];
	unsigned readSize = 1024;
	
	//_bytes = (int)(fileSize/1024);
	
	NSData *srcData;
	NSString *src = nil;
	NSRange firstReturnCode;
	NSString *firstLine = nil;
	//NSData *srcData2;
	
	[srcFileHandle seekToFileOffset:readLocation];
	
	do {
		if (readSize > fileSize) readSize = fileSize;
		srcData = [srcFileHandle readDataOfLength:readSize];
		
		src = [NSString stringUsingIconvWithData:srcData encoding:NSShiftJISStringEncoding];
		if (!src) return nil;
		firstReturnCode = [src rangeOfString:@"\n" options:NSLiteralSearch];
		if (firstReturnCode.location != NSNotFound) {
			firstLine = [src substringToIndex:firstReturnCode.location];
		}
		
	} while (readLocation >= fileSize && readSize < 5000 || !(firstLine));
	
	NSRange lastDelimiter = [firstLine rangeOfLastString:@"<>" options:NSLiteralSearch];
	if (lastDelimiter.location == NSNotFound) return nil;
	NSString *title = [firstLine substringFromIndex:lastDelimiter.location+2];
	
	T2ThreadFace *resultItem = [T2ThreadFace threadFaceWithInternalPath:[__rootPath stringByAppendingString:pathString]
																  title:title
																  order:0
															   resCount:0
															resCountNew:0];
	
	[resultItem setState:T2ThreadFaceStateNotUpdated];
	NSTimeInterval timeInterval = [[pathString lastPathComponent] intValue];
	[resultItem setCreatedDate:[NSDate dateWithTimeIntervalSince1970:timeInterval]];
	return resultItem;
}

-(BOOL)readableFileIsInFolder:(NSString *)folderPath {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *folderContents = [fileManager directoryContentsAtPath:folderPath];
	NSEnumerator *folderContentEnumerator = [folderContents objectEnumerator];
	NSString *contentPath;
	while (contentPath = [folderContentEnumerator nextObject]) {
		if ([[contentPath pathExtension] isEqualToString:@"dat"])
			return YES;
	}
	return NO;
}

#pragma mark delayed loading
-(void)loadAllInfoForThreadList:(T2ThreadList *)list {
	return;
	NSAutoreleasePool *myPool, *masterPool;
	masterPool = [[NSAutoreleasePool alloc] init];
	
	
	NSEnumerator *threadItemEnumerator = [[list objects] objectEnumerator];
	T2ThreadFace *threadItem;
	while (threadItem = [threadItemEnumerator nextObject]) {
		myPool = [[NSAutoreleasePool alloc] init];
		
		NSString *fileName = [@"/" stringByAppendingString:[[threadItem internalPath] stringByDeletingfirstPathComponent]];
		NSData *data = [NSData dataWithContentsOfFile:fileName]; if (!data) return;
		NSDictionary *fileHeaders = [NSDictionary dictionaryWithObject:fileName forKey:@"localFilePath"];
		//T2WebData *tempWebData = [[[T2WebData alloc] initWithData:data URLString:nil headers:fileHeaders code:200] autorelease];
		T2Thread *tempThread = [T2Thread threadWithThreadFace:threadItem resArray:nil];
		[tempThread load];
		if (tempThread) {
			NSFileManager *fileManager = [NSFileManager defaultManager];
			NSDate *date = [[fileManager fileAttributesAtPath:fileName traverseLink:YES] fileModificationDate];
			
			[threadItem setModifiedDate:date];
			
		}
		[myPool release];
	}
	[masterPool release];
}



#pragma mark -
#pragma mark protocol T2ThreadImporting_v100
-(T2Thread *)threadForThreadFace:(T2ThreadFace *)threadFace {
	NSString *filePath = [self threadLogFilePathForInternalPath:[threadFace internalPath]];
	if (![filePath isExistentPath]) return nil;
	if ([[filePath pathExtension] isEqualToString:@"dat"] ||
		[filePath hasSuffix:@"dat.gz"]) {
		NSData *datData = [NSData dataWithContentsOfGZipFile:filePath];
		if (!datData) return nil;
		NSString *datString = [NSString stringUsingIconvWithData:datData encoding:NSShiftJISStringEncoding];
		if (!datString) return nil;
		
		if (!_2chImporterPlug)
			_2chImporterPlug = [[[T2PluginManager sharedManager] pluginForUniqueName:@"jp_natori_Thousand_2chImporter"] retain];
		
		T2Thread *thread = [T2Thread threadWithThreadFace:threadFace resArray:nil];
		[thread setShouldSaveFile:NO];
		[_2chImporterPlug buildThread:thread withSrcString:datString appending:NO];
		return thread;
	}
	return nil;
}

-(NSArray *)importableTypes {
	return [NSArray arrayWithObjects:@"dat", @"gz", @"thread", nil];
}
-(NSString *)threadLogFilePathForInternalPath:(NSString *)internalPath {
	NSRange rootRange = [internalPath rangeOfString:__rootPath];
	if (rootRange.location == NSNotFound) return nil;
	return [internalPath substringFromIndex:rootRange.location+rootRange.length]; 
}

@end
