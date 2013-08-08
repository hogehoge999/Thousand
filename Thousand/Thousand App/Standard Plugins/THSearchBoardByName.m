//
//  THSearchBoardByName.m
//  Thousand
//
//  Created by R. Natori on 08/11/01.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import "THSearchBoardByName.h"

static NSString *__uniqueName = @"jp_natori_Thousand_THSearchBoardByName";
static NSString *__rootPath = @"THSearchBoardByName";
static NSString *__rootListImageName 	= @"TH16_SearchBoard";
static NSImage *__rootListImage 		= nil;

#define plugLocalizedString(aString) ([_selfBundle localizedStringForKey:aString value:aString table:@"AdditionalPlugLocalizable"])

@implementation THSearchBoardByName
-(id)init {
	self = [super init];
	_selfBundle = [[NSBundle bundleForClass:[self class]] retain];
	__rootListImage = [[NSImage imageNamed:__rootListImageName orInBundle:_selfBundle] retain];
	return self;
}
-(void)dealloc {
	[_rootImage release];
	[_selfBundle release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark protocol T2PluginInterface_v100
+(NSArray *)pluginInstances {
	return [NSArray arrayWithObject:[[[self alloc] init] autorelease]];
}
-(NSString *)uniqueName { return __uniqueName; }
-(NSString *)localizedName { return plugLocalizedString(__uniqueName) ; }
-(NSString *)localizedPluginInfo { return plugLocalizedString([__uniqueName stringByAppendingString:@"_info"]) ; }
-(T2PluginType)pluginType { return T2EmbeddedPlugin; }

-(int)pluginOrder { return T2PluginOrderMiddle; }


#pragma mark -
#pragma mark protocol T2ListImporting_v100 <T2PluginInterface_v100>
-(NSString *)importableRootPath { return __rootPath; }
-(T2List *)listForListFace:(T2ListFace *)listFace {
	if (!_searchString) {
		
		T2List *list = [T2List listWithListFace:listFace];
		return list;
	}
	
	NSDictionary *listDictionary = [T2ListFace dictionaryForIndentify];
	NSArray *listFaces = [[[listDictionary allValues] copy] autorelease];
	T2ListFace *tempListFace;
	NSEnumerator *listFaceEnumerator = [listFaces objectEnumerator];
	NSMutableArray *resultListFaces = [NSMutableArray array];
	while (tempListFace = [listFaceEnumerator nextObject]) {
		if (([[tempListFace title] rangeOfString:_searchString options:NSCaseInsensitiveSearch].location != NSNotFound)
		&& (![[tempListFace internalPath] isEqualToString:__rootPath])){
			[resultListFaces addObject:tempListFace];
		}
	}
	T2List *list = [T2List listWithListFace:listFace];
	[list setObjects:resultListFaces];
	return list;
}

#pragma mark -
#pragma mark interface NSObject (T2ListImporting_v100)

/*
-(NSURLRequest *)URLRequestForList:(T2List *)list {
	
	NSString *inputString = _searchString;
	if (!inputString || [inputString length] == 0) return nil;
	
	NSString *encodedString = 
	[(NSString *)CFURLCreateStringByAddingPercentEscapes (NULL,
														  (CFStringRef)inputString,
														  NULL,
														  NULL,
														  kCFStringEncodingEUC_JP) autorelease];
	
	if (!encodedString) return nil;
	
	NSURLRequest *request = [NSURLRequest requestWithURL:
							 [NSURL URLWithString:
							  [NSString stringWithFormat:_requestURLFormat, encodedString, _searchMax]]];
	return request;
	
}
-(T2LoadingResult)buildList:(T2List *)list withWebData:(T2WebData *)webData {
	NSString *srcString = [NSString stringUsingTECwithData:[webData contentData] encoding:NSJapaneseEUCStringEncoding];
	if (!srcString) return T2LoadingFailed;
	NSScanner *scanner = [NSScanner scannerWithString:srcString];
	
	NSMutableArray *listFaces = [NSMutableArray array];
	int order = 1;
	while (![scanner isAtEnd]) {
		NSString *URLString = nil;
		NSString *title = nil;
		int resCount = 0;
		
		[scanner scanUpToString:@"<dt><a href=\"" intoString:NULL];
		[scanner scanString:@"<dt><a href=\"" intoString:NULL];
		[scanner scanUpToString:@"\">" intoString:&URLString];
		[scanner scanString:@"\">" intoString:NULL];
		[scanner scanUpToString:@"</a> (" intoString:&title];
		[scanner scanString:@"</a> (" intoString:NULL];
		[scanner scanInt:&resCount];
		
		//[scanner scanUpToString:@"<dt>" intoString:NULL];
		
		NSString *boardKey = nil;
		NSString *threadKey = nil;
		if (URLString && title) {
			NSArray *pathComponents = [URLString pathComponents];
			if ([pathComponents count] >= 6) {
				boardKey = [pathComponents objectAtIndex:4];
				threadKey = [pathComponents objectAtIndex:5];
			}
		}
		
		if (boardKey && threadKey) {
			T2ThreadFace *threadFace = 
			[T2ThreadFace threadFaceWithInternalPath:
			 [NSString stringWithFormat:@"2ch BBS/%@/%@.dat", boardKey, threadKey]
											   title:title
											   order:order
											resCount:-1
										 resCountNew:resCount];
			if (threadFace) {
				[listFaces addObject:threadFace];
				order++;
			}
		}
	}
	[list setObjects:listFaces];
	return T2LoadingSucceed;
}
 */
-(NSArray *)rootListFaces {
	T2ListFace *listFace = [T2ListFace listFaceWithInternalPath:__rootPath
														  title:plugLocalizedString(__rootPath)
														  image:_rootImage];
	[listFace setLeaf:NO];
	return [NSArray arrayWithObject:listFace];
}

-(NSImage *)imageForListFace:(T2ListFace *)listFace {
	return _rootImage;
}

#pragma mark -
#pragma mark T2SearchListImporting_v100
-(void)setSearchString:(NSString *)searchString {
	if (!searchString || [searchString length]==0) return;
	if ([searchString isEqualToString:_searchString]) return;
	setObjectWithRetain(_searchString, searchString);
	
	T2List *list = [T2List availableObjectWithInternalPath:__rootPath];
	if (list) {
		[self listForListFace:[list listFace]];
	}
}
-(NSString *)searchString { return _searchString; }
-(T2ListFace *)persistentListFaceForSearchString:(NSString *)searchString {
	return nil;
}
-(BOOL)receivesWholeSearchString { return NO; }
@end
