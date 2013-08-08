//
//  THSpotlightSearchListImporter.m
//  Thousand
//
//  Created by R. Natori on 08/11/09.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import "THSpotlightSearchListImporter.h"

static NSString *__uniqueName = @"jp_natori_Thousand_THSpotlightSearchList";
static NSString *__rootPath = @"THSpotlightSearchList";

#define plugLocalizedString(aString) ([_selfBundle localizedStringForKey:aString value:aString table:@"THSpotlightSearchListLocalizable"])


@implementation THSpotlightSearchListImporter
-(id)init {
	self = [super init];
	_selfBundle = [[NSBundle bundleForClass:[self class]] retain];
	_rootImage = [[NSImage imageNamed:@"TH16_SearchBoard"] retain];
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
			@"searchString",
			nil];
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

-(int)pluginOrder { return T2PluginOrderLast; }

#pragma mark -
#pragma mark protocol T2ListImporting_v100 <T2PluginInterface_v100>
-(NSString *)importableRootPath { return __rootPath; }
-(T2List *)listForListFace:(T2ListFace *)listFace {
	T2ThreadList *list = [T2ThreadList listWithListFace:listFace];
	[self loadList];
	return list;
}
-(NSURLRequest *)URLRequestForList:(T2List *)list {
	[self loadList];
	return nil;
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
		//[list load];
		[self loadList];
	}
}
-(NSString *)searchString { return _searchString; }
-(T2ListFace *)persistentListFaceForSearchString:(NSString *)searchString {
	/*
	NSString *internalPath = [__rootPath stringByAppendingPathComponent:[searchString stringByAddingUTF8PercentEscapesForce]];
	if (internalPath) {
		return [T2ListFace listFaceWithInternalPath:internalPath
											  title:[NSString stringWithFormat:@"%@ - %@", plugLocalizedString(__rootPath), searchString]
											  image:_rootImage];
	}
	 */
	return nil;
}
-(BOOL)receivesWholeSearchString { return NO; }

-(void)loadList {
	T2List *list = [T2List availableObjectWithInternalPath:__rootPath];
	if (!list || !_searchString || [_searchString length] == 0) return;
	/*
	NSPredicate * predicate = [NSPredicate predicateWithFormat:
                               @"kMDItemContentType == 'jp.natori.thousand.thread'"];
    if (_searchString != nil) {
        NSPredicate * subPredicate = [NSPredicate predicateWithFormat:
                                      @"kMDItemTextContent like[cd] %@", 
                                      [_searchString stringByAppendingString:@"*"]];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:
                     [NSArray arrayWithObjects:predicate, subPredicate, nil]];
    }
	 */
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"kMDItemTextContent like[cd] %@", 
							  [_searchString stringByAppendingString:@"*"]];
	
	
	if (!_query) {
		_query = [[NSMetadataQuery alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(queryDidUpdate:)
													 name:NSMetadataQueryDidUpdateNotification
												   object:_query];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(queryDidUpdate:)
													 name:NSMetadataQueryDidFinishGatheringNotification
												   object:_query];
		
		[_query setValueListAttributes:
		 [NSArray arrayWithObjects:
		  (id)kMDItemContentType,
		  (id)kMDItemDisplayName,
		  @"jp_natori_Thousand_thread_threadInternalPath",
		  @"jp_natori_Thousand_thread_resCount",
		  @"jp_natori_Thousand_thread_label",
		  nil]];
		//NSLog(@"%f",[_query notificationBatchingInterval]);
		[_query setNotificationBatchingInterval:0.2];
	}
	[_query setSearchScopes:[NSArray arrayWithObject:[NSString appLogFolderPath]]];
	[_query setPredicate:predicate];
	[_query startQuery];
}
-(void)queryDidUpdate:(NSNotification *)notification {
	T2List *list = [T2List availableObjectWithInternalPath:__rootPath];
	if (!list || !_query) return;
	
	NSMutableArray *resultArray = [NSMutableArray array];
	
	unsigned maxCount = [_query resultCount];
	unsigned i;
	for (i=0; i<maxCount; i++) {
		NSMetadataItem *item = [_query resultAtIndex:i];
		
		NSString *internalPath = [item valueForAttribute:@"jp_natori_Thousand_thread_threadInternalPath"];
		if (internalPath) {
			T2ThreadFace *threadFace = [T2ThreadFace threadFaceWithInternalPath:internalPath];
			if ([threadFace resCount] == 0) {
				[threadFace setTitle:[item valueForAttribute:(NSString *)kMDItemDisplayName]];
				int resCount = [(NSNumber *)[item valueForAttribute:@"jp_natori_Thousand_thread_resCount"] intValue];
				int resCountNew = [(NSNumber *)[item valueForAttribute:@"jp_natori_Thousand_thread_resCountNew"] intValue];
				[threadFace setResCount:resCount];
				if (resCountNew == 0) {
					[threadFace setResCountNew:resCount];
				} else {
					[threadFace setResCountNew:resCountNew];
				}
				int label = [(NSNumber *)[item valueForAttribute:@"jp_natori_Thousand_thread_label"] intValue];
				[threadFace setLabel:label];
				int state = [(NSNumber *)[item valueForAttribute:@"jp_natori_Thousand_thread_state"] intValue];
				if (state == T2ThreadFaceStateUndefined) {
					[threadFace setStateFromResCount];
				} else {
					[threadFace setState:state];
				}
			}
			
			[resultArray addObject:threadFace];
		}
	}
	[list setObjects:resultArray];
}
@end
