//
//  THFind2ch.m
//  THFind2ch
//
//  Created by R. Natori on  07/02/20.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "THFind2ch.h"
#import "TFInputWindowController.h"

static NSString *__uniqueName = @"jp_natori_Thousand_THFind2ch";
static NSString *__rootPath = @"Find2ch";

#define plugLocalizedString(aString) ([_selfBundle localizedStringForKey:aString value:aString table:@"THFind2chLocalizable"])

@implementation THFind2ch
-(id)init {
	self = [super init];
	_selfBundle = [[NSBundle bundleForClass:[self class]] retain];
	_rootImage = [[NSImage imageNamed:@"TH16_Find2ch" orInBundle:_selfBundle] retain];
	/*
	if (!_rootImage)
		_rootImage = [[NSImage alloc] initByReferencingFile:[_selfBundle pathForImageResource:@"TH16_Find2ch"]];
	 */
	_requestURLFormat = [plugLocalizedString(@"requestURLFormat") retain];
	_searchMax = 30;
	return self;
}
-(void)dealloc {
	[_rootImage release];
	[_selfBundle release];
	
	[super dealloc];
}


#pragma mark -
#pragma mark Protocol T2DictionaryConverting
-(NSArray *)dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use {
	return [NSArray arrayWithObjects:
			@"searchMax",
			@"searchString",
			@"previousSearchString",
			nil];
}

#pragma mark -
#pragma mark Accessors
-(void)setSearchMax:(int)searchMax {
	if (searchMax > 200) searchMax = 200;
	else if (searchMax < 1) searchMax = 1;
	_searchMax = searchMax;
}
-(int)searchMax { return _searchMax; }

-(void)setPreviousSearchString:(NSString *)searchString { setObjectWithRetain(_previousSearchString, searchString); }
-(NSString *)previousSearchString { return _previousSearchString; }

#pragma mark -
#pragma mark protocol T2PluginInterface_v100
+(NSArray *)pluginInstances {
	return [NSArray arrayWithObject:[[[self alloc] init] autorelease]];
}
-(NSString *)uniqueName { return __uniqueName; }
-(NSString *)localizedName { return plugLocalizedString(__uniqueName) ; }
-(NSString *)localizedPluginInfo { return plugLocalizedString([__uniqueName stringByAppendingString:@"_info"]) ; }
-(T2PluginType)pluginType { return T2EmbeddedPlugin; }

-(int)pluginOrder { return T2PluginOrderLast-1; }

-(NSArray *)preferenceItems {
	return [NSArray arrayWithObjects:
			[T2PreferenceItem numberItemWithKey:@"searchMax"
							   title:plugLocalizedString(@"searchMax")
								info:nil],
			nil];
}


#pragma mark -
#pragma mark protocol T2ListImporting_v100 <T2PluginInterface_v100>
-(NSString *)importableRootPath { return __rootPath; }
-(T2List *)listForListFace:(T2ListFace *)listFace {
	return [T2ThreadList listWithListFace:listFace];
}

#pragma mark -
#pragma mark interface NSObject (T2ListImporting_v100)
-(NSURLRequest *)URLRequestForList:(T2List *)list {
	
	NSString *inputString = _searchString;
	
	if (!inputString || [inputString length] == 0) return nil;
	//if ([inputString isEqualToString:_previousSearchString]) return nil;
	[self setPreviousSearchString:_searchString];
	
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
	NSString *srcString = [NSString stringUsingIconvWithData:[webData contentData] encoding:NSJapaneseEUCStringEncoding];
	if (!srcString) return T2LoadingFailed;
	NSScanner *scanner = [NSScanner scannerWithString:srcString];
	/*
	if (!([scanner scanUpToString:@"<dl>" intoString:NULL] &&
		  [scanner scanString:@"<dl>" intoString:NULL])) {
		[list setObjects:nil];
		return T2LoadingFailed;
	}
	 */
	
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
											   title:[title stringByReplacingCharacterReferences]
											   order:order
											resCount:-1
										 resCountNew:resCount];
			if (threadFace) {
				[threadFace setStateFromResCount];
				[listFaces addObject:threadFace];
				order++;
			}
		}
	}
	[list setObjects:listFaces];
	return T2LoadingSucceed;
}
-(NSArray *)rootListFaces {
	T2ListFace *listFace = [T2ListFace listFaceWithInternalPath:__rootPath
														  title:plugLocalizedString(__rootPath)
														  image:_rootImage];
	[listFace setLeaf:YES];
	return [NSArray arrayWithObject:listFace];
}

-(NSImage *)imageForListFace:(T2ListFace *)listFace {
	return _rootImage;
}

#pragma mark -
#pragma mark T2SearchListImporting_v100
-(void)setSearchString:(NSString *)searchString {
	if ([searchString isEqualToString:_searchString]) return;
	setObjectWithRetain(_searchString, searchString);
	
	T2List *list = [T2List availableObjectWithInternalPath:__rootPath];
	if (list) {
		[list load];
	}
}
-(NSString *)searchString { return _searchString; }
-(T2ListFace *)persistentListFaceForSearchString:(NSString *)searchString {
	NSString *internalPath = [__rootPath stringByAppendingPathComponent:[searchString stringByAddingUTF8PercentEscapesForce]];
	if (internalPath) {
		return [T2ListFace listFaceWithInternalPath:internalPath
											  title:[NSString stringWithFormat:@"%@ - %@", plugLocalizedString(__rootPath), searchString]
											  image:_rootImage];
	}
	return nil;
}
-(BOOL)receivesWholeSearchString { return YES; }
@end
