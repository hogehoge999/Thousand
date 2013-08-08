//
//  THHistoryImporter.m
//  Thousand
//
//  Created by R. Natori on 06/02/18.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "THHistoryImporter.h"
#import "T2UtilityHeader.h"

#define plugLocalizedString(aString) ([_selfBundle localizedStringForKey:aString value:aString table:@"StandardPlugLocalizable"])

static NSString *__uniqueName =			@"jp_natori_Thousand_HistoryImporter";

static NSString *__rootPath			 	= @"History";
static NSString *__rootListImageName 	= @"TH16_History";
static NSImage *__rootListImage 		= nil;

static NSString *__threadHistoryKey	 	= @"threadHistory";
static NSString *__resPostedThreadHistoryKey	 = @"resPostedThreadHistory";
static NSString *__threadListHistoryKey	= @"threadListHistory";

@implementation THHistoryImporter
-(id)init {
	self = [super init];
	_selfBundle = [[NSBundle bundleForClass:[self class]] retain];
	
	__rootListImage = [[NSImage imageNamed:__rootListImageName orInBundle:_selfBundle] retain];
	
	T2ListFace *threadHistoryFace = [T2ListFace listFaceWithInternalPath:[__rootPath stringByAppendingPathComponent:__threadHistoryKey]
																   title:plugLocalizedString(__threadHistoryKey)
																   image:__rootListImage];
	[threadHistoryFace setLeaf:YES];
	
	T2ListFace *resPostedThreadHistoryFace = [T2ListFace listFaceWithInternalPath:[__rootPath stringByAppendingPathComponent:__resPostedThreadHistoryKey]
																			title:plugLocalizedString(__resPostedThreadHistoryKey)
																			image:__rootListImage];
	[resPostedThreadHistoryFace setLeaf:YES];
	
	T2ListFace *threadListHistoryFace = [T2ListFace listFaceWithInternalPath:[__rootPath stringByAppendingPathComponent:__threadListHistoryKey]
																	   title:plugLocalizedString(__threadListHistoryKey)
																	   image:__rootListImage];
	
	_listFaces = [[NSArray arrayWithObjects:threadHistoryFace,
		resPostedThreadHistoryFace, threadListHistoryFace, nil] retain];
	
	_threadHistory = [[T2ThreadHistory listWithListFace:threadHistoryFace] retain];
	_resPostedThreadHistory = [[T2ThreadHistory listWithListFace:resPostedThreadHistoryFace] retain];
	_threadListHistory = [[T2ListHistory listWithListFace:threadListHistoryFace] retain];
	
	return self;
}
-(void)dealloc {
	[_threadHistory saveToFile];
	[_resPostedThreadHistory saveToFile];
	[_threadListHistory saveToFile];
	
	[_threadHistory release];
	[_resPostedThreadHistory release];
	[_threadListHistory release];
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors
-(void)setThreadHistoryMax:(int)count {
	if (count>=0) {
		_threadHistoryMax = count;
		[_threadHistory setMaxHistoryCount:count];
	}
}
-(int)threadHistoryMax { return _threadHistoryMax; }

-(void)setResPostedThreadHistoryMax:(int)count {
	if (count>=0) {
		_resPostedThreadHistoryMax = count;
		[_resPostedThreadHistory setMaxHistoryCount:count];
	}
}
-(int)resPostedThreadHistoryMax { return _resPostedThreadHistoryMax; }

-(void)setThreadListHistoryMax:(int)count {
	if (count>=0) {
		_threadListHistoryMax = count;
		[_threadListHistory setMaxHistoryCount:count];
	}
}
-(int)threadListHistoryMax { return _threadListHistoryMax; }

#pragma mark -
#pragma mark protocol T2PluginInterface_v100
+(NSArray *)pluginInstances {
	return [NSArray arrayWithObject:[[[self alloc] init] autorelease]];
}
-(NSString *)uniqueName { return __uniqueName; }
-(NSString *)localizedName { return plugLocalizedString(__uniqueName) ; }
-(NSString *)localizedPluginInfo { return plugLocalizedString([__uniqueName stringByAppendingString:@"_info"]) ; }
-(T2PluginType)pluginType { return T2EmbeddedPlugin; }
-(int)pluginOrder { return T2PluginOrderLast; }


#pragma mark -
#pragma mark protocol T2DictionaryConverting
-(NSArray *)dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use {
	return [NSArray arrayWithObjects:
		@"threadHistoryMax",
		@"resPostedThreadHistoryMax",
		@"threadListHistoryMax",
		nil];
}


#pragma mark -
#pragma mark protocol T2PluginPrefSetting_v100
-(NSArray *)preferenceItems {
	return [NSArray arrayWithObjects:
		[T2PreferenceItem numberItemWithKey:@"threadHistoryMax"
									  title:plugLocalizedString(@"threadHistoryMax")
									   info:nil],
		[T2PreferenceItem buttonItemWithAction:@selector(eraseThreadHistory:) target:self 
										 title:plugLocalizedString(@"Erase Thread History")
										  info:nil],
		[T2PreferenceItem separateLineItem],
		
		[T2PreferenceItem numberItemWithKey:@"resPostedThreadHistoryMax"
									  title:plugLocalizedString(@"resPostedThreadHistoryMax")
									   info:nil],
		[T2PreferenceItem buttonItemWithAction:@selector(eraseResPostedThreadHistory:) target:self 
										 title:plugLocalizedString(@"Erase Posting History")
										  info:nil],
		[T2PreferenceItem separateLineItem],
		
		[T2PreferenceItem numberItemWithKey:@"threadListHistoryMax"
									  title:plugLocalizedString(@"threadListHistoryMax")
									   info:nil],
		[T2PreferenceItem buttonItemWithAction:@selector(eraseThreadListHistory:) target:self 
										 title:plugLocalizedString(@"Erase Board History")
										  info:nil],
		[T2PreferenceItem separateLineItem],
		nil];
}


#pragma mark -
#pragma mark protocol T2ListImporting_v100
-(NSString *)importableRootPath { return __rootPath; }
-(T2List *)listForListFace:(T2ListFace *)listFace {
	
	if ([[listFace internalPath] isEqualToString:__rootPath]) {
		return [T2List listWithListFace:listFace
								objects:_listFaces];
	}
	return nil;
}
-(NSArray *)rootListFaces {
	return [NSArray arrayWithObject:
		[T2ListFace listFaceWithInternalPath:__rootPath
									   title:plugLocalizedString(__rootPath)
									   image:__rootListImage]];
}
-(NSImage *)imageForListFace:(T2ListFace *)listFace {
	return __rootListImage;
}


#pragma mark -
#pragma mark Actions
-(IBAction)eraseThreadHistory:(id)sender {
	[_threadHistory setObjects:nil];
}

-(IBAction)eraseResPostedThreadHistory:(id)sender {
	[_resPostedThreadHistory setObjects:nil];
}

-(IBAction)eraseThreadListHistory:(id)sender {
	[_threadListHistory setObjects:nil];
}
@end
