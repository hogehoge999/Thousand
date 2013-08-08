//
//  T2PluginManager.m
//  Thousand
//
//  Created by R. Natori on 05/06/26.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "T2PluginManager.h"
#import "T2UtilityHeader.h"
#import "T2Thread.h"
#import "T2ThreadFace.h"
#import "T2List.h"
#import "T2ListFace.h"

static NSArray 	*__pluginFolderPaths 		= nil;
static NSArray 	*__embeddedPluginClasses	= nil;
static NSString *__pluginPrefFolderPath		= nil;
static NSArray 	*__forbiddenBundleIdentifiers	= nil;
//static NSUserDefaults *__standardUserDefaults	= nil;

static T2PluginManager 	*__sharedManager 	= nil;

@implementation T2PluginManager


+(void)setClassPluginFolderPaths:(NSArray *)anArray {
	setObjectWithCopy(__pluginFolderPaths, anArray);
}

+(void)setClassEmbeddedPluginClasses:(NSArray *)anArray {
	setObjectWithCopy(__embeddedPluginClasses, anArray);
}

+(void)setClassPluginPrefFolderPath:(NSString *)path {
	setObjectWithCopy(__pluginPrefFolderPath, path);
}
+(void)setClassForbiddenPluginBundleIdentifiers:(NSArray *)bundleIdentifiers {
	setObjectWithCopy(__forbiddenBundleIdentifiers, bundleIdentifiers);
}


+(T2PluginManager *)sharedManager {
	if (!__sharedManager) {
		__sharedManager = [[self alloc] init];
	}
	return __sharedManager;
}

-(id)init {
	self = [super init];
	if (!__sharedManager) {
		__sharedManager = self;
		[self loadAllPlugins];
		return self;
	}
	if (self != __sharedManager) [self autorelease];
	return __sharedManager;
}

-(void)dealloc {
	[self unloadAllPlugins];
	[super dealloc];
}

#pragma mark -
#pragma mark Genaral Plugin Management
-(void)loadAllPlugins {
	
	// search plugin bundles
	NSMutableDictionary *bundlesDic = [NSMutableDictionary dictionary];
	if (__pluginFolderPaths) {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSEnumerator *pluginFoldersEnumerator = [__pluginFolderPaths objectEnumerator];
		NSString *pluginFolderPath;
		while (pluginFolderPath = [pluginFoldersEnumerator nextObject]) {
			NSArray *bundlePaths = [fileManager directoryContentsAtPath:pluginFolderPath];
			if (bundlePaths && [bundlePaths count] > 0) {
				NSEnumerator *bundlePathsEnumerator = [bundlePaths objectEnumerator];
				NSString *bundlePath;
				while (bundlePath = [bundlePathsEnumerator nextObject]) {
					if ([[bundlePath pathExtension] isEqualToString:@"bundle"]) {
						bundlePath = [pluginFolderPath stringByAppendingPathComponent:bundlePath];
						NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
						NSString *bundleIdentifier = [bundle bundleIdentifier];
						if (![__forbiddenBundleIdentifiers containsObject:bundleIdentifier]) { // check forbidden
							NSBundle *sameBundle = [bundlesDic objectForKey:bundleIdentifier];
							if (sameBundle) { // check version
								NSString *sameBundleVersionString = [sameBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
								NSString *bundleVersionString = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
								if (sameBundleVersionString && bundleVersionString &&
									([bundleVersionString floatValue] > [sameBundleVersionString floatValue])) {
									[bundlesDic setObject:bundle forKey:bundleIdentifier];
								}
							}
							[bundlesDic setObject:bundle forKey:bundleIdentifier];
						}
						
					}
				}
			}
		}
	}
	NSMutableArray *classesArray = [NSMutableArray array];
	// embeded clases
	if (__embeddedPluginClasses) [classesArray addObjectsFromArray:__embeddedPluginClasses];
	
	// external classes
	NSArray *bundles = [bundlesDic allValues];
	NSEnumerator *bundleEnumerator = [bundles objectEnumerator];
	id nextBundle;
	while (nextBundle = [bundleEnumerator nextObject]) {
		
		Class bundleClass = [nextBundle principalClass];
		if (bundleClass) [classesArray addObject:bundleClass];
	}
	
	//load classes
	NSEnumerator *classesEnumerator = [classesArray objectEnumerator];
	NSMutableArray *instancesArray = [NSMutableArray array];
	id nextObject;
	
	while (nextObject = [classesEnumerator nextObject]) {
		if ([nextObject conformsToProtocol:@protocol(T2PluginInterface_v100)]) {
			NSArray *tempInstances = [(Class <T2PluginInterface_v100>)nextObject pluginInstances];
			if (tempInstances) [instancesArray addObjectsFromArray:tempInstances];
		}
	}
	
	//load instances
	NSSortDescriptor *instancesSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"pluginOrder" ascending:YES] autorelease];
	[instancesArray sortUsingDescriptors:[NSArray arrayWithObject:instancesSortDescriptor]];
	NSEnumerator *instancesEnumerator = [instancesArray objectEnumerator];
	
	_allPluginDic = [[NSMutableDictionary alloc] init];
	_allPlugins = [[NSMutableArray alloc] init];
	
	_listImporterPlugins	= [[NSMutableArray alloc] init];
	_listImporterPluginDic	= [[NSMutableDictionary alloc] init];
	
	_searchListImporterPlugins	= [[NSMutableArray alloc] init];
	
	_threadFaceScorerPluginDic			= [[NSMutableDictionary alloc] init];
	_threadFaceScoreKeyArray			= [[NSMutableArray alloc] init];
	_threadFaceScoreLocalizedNameArray	= [[NSMutableArray alloc] init];
	
	_threadFaceFilterPluginDic			= [[NSMutableDictionary alloc] init];
	_threadFaceFilterNameArray			= [[NSMutableArray alloc] init];
	_threadFaceFilterLocalizedNameArray	= [[NSMutableArray alloc] init];
	
	
	_threadImporterPluginDic		= [[NSMutableDictionary alloc] init];
	_threadExporterPlugins	= [[NSMutableArray alloc] init];
	
	_threadProcessorPlugins	= [[NSMutableArray alloc] init];
	_extractorPluginDic			= [[NSMutableDictionary alloc] init];
	_extractorPlugins			= [[NSMutableArray alloc] init];
	_HTMLProcessorPlugins		= [[NSMutableArray alloc] init];
	
	_partialHTMLExporterPlugins	= [[NSMutableArray alloc] init];
	_viewHtmlPlugins			= [[NSMutableArray alloc] init];
	_threadViewerPlugins	= [[NSMutableArray alloc] init];
	
	// URL Previewer
	_hostPreviewerPluginDic		= [[NSMutableDictionary alloc] init];
	_extensionPreviewerPluginDic	= [[NSMutableDictionary alloc] init];
	_previewerPlugins			= [[NSMutableArray alloc] init];
	
	
	// Posting
	_postingPluginDic 		= [[NSMutableDictionary alloc] init];
	_resPostingPluginDic	= [[NSMutableDictionary alloc] init];
	_threadPostingPluginDic	= [[NSMutableDictionary alloc] init];
	
	// Posting (WebView)
	_webResPostingPluginDic		= [[NSMutableDictionary alloc] init];
	_webThreadPostingPluginDic	= [[NSMutableDictionary alloc] init];
	
	while (nextObject = [instancesEnumerator nextObject]) {
		
		NSString *plugUniqueName = [(id <T2PluginInterface_v100>)nextObject uniqueName];
		if (plugUniqueName) {
			[_allPluginDic setObject:nextObject forKey:plugUniqueName];
			[_allPlugins addObject:nextObject];
		}
		
		//T2ListImporting_v100
		if ([nextObject conformsToProtocol:@protocol(T2ListImporting_v100)]) {
			[_listImporterPlugins addObject:nextObject];
			NSString *importableRootPath = [(id <T2ListImporting_v100>)nextObject importableRootPath];
			if (importableRootPath)
				[_listImporterPluginDic setObject:nextObject forKey:importableRootPath];
			
			if ([nextObject conformsToProtocol:@protocol(T2SearchListImporting_v100)]) {
				[_searchListImporterPlugins addObject:nextObject];
			}
		}
		
		//T2ThreadFaceScoring_v100
		if ([nextObject conformsToProtocol:@protocol(T2ThreadFaceScoring_v100)]) {
			id <T2ThreadFaceScoring_v100> scorer = nextObject;
			NSArray *keys = [scorer scoreKeys];
			NSEnumerator *keyEnumerator = [keys objectEnumerator];
			NSString *key;
			while (key = [keyEnumerator nextObject]) {
				[_threadFaceScorerPluginDic setObject:scorer forKey:key];
				if (![key hasSuffix:@"String"]) {
					[_threadFaceScoreKeyArray addObject:key];
					NSString *localizedName = [scorer localizedNameForScoreKey:key];
					if (!localizedName) localizedName = @"--";
					[_threadFaceScoreLocalizedNameArray addObject:localizedName];
				} else if ([key length]>6){
					[T2ThreadFace setKeys:[NSArray arrayWithObject:[key substringToIndex:([key length]-6)]]
triggerChangeNotificationsForDependentKey:key];
				}
			}
			
		}
		
		//T2ThreadFaceFiltering_v100
		if ([nextObject conformsToProtocol:@protocol(T2ThreadFaceFiltering_v100)]) {
			id <T2ThreadFaceFiltering_v100> filter = nextObject;
			NSArray *names = [filter filterNames];
			NSEnumerator *nameEnumerator = [names objectEnumerator];
			NSString *name;
			while (name = [nameEnumerator nextObject]) {
				[_threadFaceFilterPluginDic setObject:filter forKey:name];
				[_threadFaceFilterNameArray addObject:name];
				NSString *localizedName = [filter localizedNameForFilterName:name];
				[_threadFaceFilterLocalizedNameArray addObject:localizedName];
			}
			
		}
		
		//T2ThreadImporting_v100
		if ([nextObject conformsToProtocol:@protocol(T2ThreadImporting_v100)]) {
			NSString *importableRootPath = [(id <T2ThreadImporting_v100>)nextObject importableRootPath];
			if (importableRootPath)
				[_threadImporterPluginDic setObject:nextObject forKey:importableRootPath];
			
			if ([nextObject respondsToSelector:@selector(importableTypes)]) {
				NSEnumerator *typeEnumerator = [[nextObject importableTypes] objectEnumerator];
				NSString *type;
				while (type = [typeEnumerator nextObject]) {
					[_threadImporterPluginDic setObject:nextObject forKey:type];
				}
			}
		}
		
		//T2ThreadExporting
		//if ([nextObject conformsToProtocol:@protocol(T2ThreadExporting_v090)])
		//	[_threadExporterPlugins addObject:nextObject];
		
		//T2ThreadProcessing_v100
		if ([nextObject conformsToProtocol:@protocol(T2ThreadProcessing_v100)])
			[_threadProcessorPlugins addObject:nextObject];
		
		//T2ResExtracting_v100
		if ([nextObject conformsToProtocol:@protocol(T2ResExtracting_v100)]) {
			[_extractorPlugins addObject:nextObject];
			NSArray *keys = [(id <T2ResExtracting_v100>)nextObject extractKeys];
			NSEnumerator *keysEnumerator = [keys objectEnumerator];
			NSString *key;
			while (key = [keysEnumerator nextObject]) {
				[_extractorPluginDic setObject:nextObject forKey:key];
			}
		}
		
		//T2ThreadHTMLProcessing_v100
		if ([nextObject conformsToProtocol:@protocol(T2ThreadHTMLProcessing_v100)])
			[_HTMLProcessorPlugins addObject:nextObject];
		
		//T2ThreadPartialHTMLExporting_v100
		if ([nextObject conformsToProtocol:@protocol(T2ThreadPartialHTMLExporting_v100)])
			[_partialHTMLExporterPlugins addObject:nextObject];
		
		//T2ThreadHTMLExporting_v100
		if ([nextObject conformsToProtocol:@protocol(T2ThreadHTMLExporting_v100)])
			[_viewHtmlPlugins addObject:nextObject];
		
		//T2ThreadViewing_v100
		if ([nextObject conformsToProtocol:@protocol(T2ThreadViewing_v100)])
			[_threadViewerPlugins addObject:nextObject];
		
		// URL Previewer
		if ([nextObject conformsToProtocol:@protocol(T2URLPreviewing_v100)]) {
			[_previewerPlugins addObject:nextObject];
			NSArray *keys = [(id <T2URLPreviewing_v100>)nextObject previewableURLHosts];
			NSEnumerator *keysEnumerator = [keys objectEnumerator];
			NSString *key;
			while (key = [keysEnumerator nextObject]) {
				[_hostPreviewerPluginDic setObject:nextObject forKey:key];
			}
			keys = [(id <T2URLPreviewing_v100>)nextObject previewableURLExtensions];
			keysEnumerator = [keys objectEnumerator];
			while (key = [keysEnumerator nextObject]) {
				[_extensionPreviewerPluginDic setObject:nextObject forKey:key];
			}
		}
		
		// For Panther Bug, This Plugins will loaded Tiger or later
		SInt32 MacVersion;
		if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr) {
			if (MacVersion >= 0x1040){
				//T2Posting_v200
				if ([nextObject conformsToProtocol:@protocol(T2Posting_v200)])
					[_postingPluginDic setObject:nextObject forKey:[nextObject postableRootPath]];
				
				//T2ResPosting_v100
				if ([nextObject conformsToProtocol:@protocol(T2ResPosting_v100)])
					[_resPostingPluginDic setObject:nextObject forKey:[nextObject postableRootPath]];
				
				//T2ThreadPosting_v100
				if ([nextObject conformsToProtocol:@protocol(T2ThreadPosting_v100)])
					[_threadPostingPluginDic setObject:nextObject forKey:[nextObject postableRootPath]];
			}
		}
		
		//T2ResPostingUsingWebView_v100
		if ([nextObject conformsToProtocol:@protocol(T2ResPostingUsingWebView_v100)])
			[_webResPostingPluginDic setObject:nextObject forKey:[nextObject postableRootPath]];
		
		//T2ThreadPostingUsingWebView_v100
		if ([nextObject conformsToProtocol:@protocol(T2ThreadPostingUsingWebView_v100)])
			[_webThreadPostingPluginDic setObject:nextObject forKey:[nextObject postableRootPath]];
		
		//if ([nextObject conformsToProtocol:@protocol(T2ThreadViewing)]) 
		//	[_threadViewerPlugins addObject:nextObject];
		
	}
}

-(void)unloadAllPlugins {
	releaseObjectWithNil(_allPluginDic);
	releaseObjectWithNil(_allPlugins);
	
	releaseObjectWithNil(_listImporterPlugins);
	releaseObjectWithNil(_listImporterPluginDic);
	
	releaseObjectWithNil(_threadFaceScorerPluginDic);
	releaseObjectWithNil(_threadFaceScoreKeyArray);
	releaseObjectWithNil(_threadFaceScoreLocalizedNameArray);
	
	releaseObjectWithNil(_threadFaceFilterPluginDic);
	releaseObjectWithNil(_threadFaceFilterNameArray);
	releaseObjectWithNil(_threadFaceFilterLocalizedNameArray);
	
	releaseObjectWithNil(_threadImporterPluginDic);
	releaseObjectWithNil(_threadExporterPlugins);
	
	releaseObjectWithNil(_extractorPluginDic);
	releaseObjectWithNil(_extractorPlugins);
	
	releaseObjectWithNil(_threadProcessorPlugins);
	releaseObjectWithNil(_HTMLProcessorPlugins);
	
	releaseObjectWithNil(_viewHtmlPlugins);
	releaseObjectWithNil(_partialHTMLExporterPlugins);
	releaseObjectWithNil(_viewPartialHtmlPlug);
	releaseObjectWithNil(_threadViewerPlugins);
	
	releaseObjectWithNil(_webResPostingPluginDic);
	releaseObjectWithNil(_webThreadPostingPluginDic);
}

-(NSArray *)allPlugins {
	return _allPlugins;
}

-(NSDictionary *)pluginDictionary {
	return _allPluginDic;
}

-(id <T2PluginInterface_v100>)pluginForUniqueName:(NSString *)uniqueName {
	id <T2PluginInterface_v100> tempPlug = [_allPluginDic objectForKey:uniqueName];
	return tempPlug;
}

-(void)loadPluginPrefs {
	NSUserDefaults *myUserDefaults = [NSUserDefaults standardUserDefaults];
	//NSMutableArray *plugins = [NSMutableArray array];
	NSMutableDictionary *pluginOldPrefDic = [NSMutableDictionary dictionary];
	NSDictionary *prefDic = _allPluginDic;
	NSEnumerator *prefKeyEnumerator = [prefDic keyEnumerator];
	id key;
	NSObject <T2PluginInterface_v100> *plugin;
	while (key = [prefKeyEnumerator nextObject]) {
		plugin = [prefDic objectForKey:key];
		//[plugins addObject:plugin];
		if ([[plugin class] conformsToProtocol:@protocol(T2DictionaryConverting)]) {
			NSString *uniqueName = [plugin uniqueName];
			NSDictionary *savedDic = nil;
			if ([plugin pluginType] == T2EmbeddedPlugin) {
				savedDic = [myUserDefaults dictionaryForKey:uniqueName];
			} else {
				NSString *prefFilePath = __pluginPrefFolderPath;
				prefFilePath = [[prefFilePath stringByAppendingPathComponent:uniqueName] stringByAppendingPathExtension:@"plist"];
				if ([prefFilePath isExistentPath])
					savedDic = [NSDictionary dictionaryWithContentsOfFile:prefFilePath];
			}
			if (savedDic) {
				[plugin setValuesWithEncodedDictionary:savedDic];
				[pluginOldPrefDic setObject:savedDic forKey:key];
			}
		}
	}
	//[self setPlugins:plugins];
	[_pluginOldPrefDic release];
	_pluginOldPrefDic = [pluginOldPrefDic retain];
	
}
-(void)savePluginPrefs {
	NSUserDefaults *myUserDefaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *prefDic = _allPluginDic;
	NSEnumerator *prefKeyEnumerator = [prefDic keyEnumerator];
	id key;
	NSObject <T2PluginInterface_v100> *plugin;
	while (key = [prefKeyEnumerator nextObject]) {
		plugin = [prefDic objectForKey:key];
		if ([[plugin class] conformsToProtocol:@protocol(T2DictionaryConverting)]) {
			
			NSString *uniqueName = [plugin uniqueName];
			NSDictionary *savedDic = [plugin encodedDictionary];
			
			if (savedDic) {
				if ([plugin pluginType] == T2EmbeddedPlugin) {
					[myUserDefaults setObject:savedDic forKey:uniqueName];
				} else {
					if (![savedDic isEqualToDictionary:[_pluginOldPrefDic objectForKey:uniqueName]]) {
						NSString *prefFilePath = __pluginPrefFolderPath;
						prefFilePath = [[prefFilePath stringByAppendingPathComponent:uniqueName] stringByAppendingPathExtension:@"plist"];
						if ([prefFilePath prepareFoldersInPath]) 
							[savedDic writeToFile:prefFilePath atomically:YES];
					}  /*else {
						NSLog(@"plugin not saved (%@)", uniqueName);
					}*/
				}
			}
		}
	}
}


#pragma mark -
#pragma mark T2ListImporting_v100
-(NSArray *)listImporterPlugins {
	return _listImporterPlugins;
}

-(NSArray *)rootListFaces {
	NSMutableArray *resultArray = [NSMutableArray array];
	NSEnumerator *pluginEnumerator = [_listImporterPlugins objectEnumerator];
	id nextObject;
	while (nextObject = [pluginEnumerator nextObject]) {
		if (![nextObject conformsToProtocol:@protocol(T2SearchListImporting_v100)]) {
			if ([(NSObject *)nextObject respondsToSelector:@selector(rootListFaces)]) {
				NSArray *rootListFaces = [(NSObject *)nextObject rootListFaces];
				if (rootListFaces) [resultArray addObjectsFromArray:rootListFaces];
			}
		}
	}
	return resultArray;
}
-(id <T2ListImporting_v100>)listImporterForInternalPath:(NSString *)internalPath {
	return [_listImporterPluginDic objectForKey:[[internalPath pathComponents] objectAtIndex:0]];
}
-(T2List *)listForListFace:(T2ListFace *)listFace {
	NSString *internalPath = [listFace internalPath];
	if (!internalPath) return nil;
	
	id <T2ListImporting_v100> listImporter = [_listImporterPluginDic objectForKey:[[internalPath pathComponents] objectAtIndex:0]];
	if (listImporter)
		return [listImporter listForListFace:listFace];
	return nil;
}

-(NSImage *)imageForListFace:(T2ListFace *)listFace {
	NSString *internalPath = [listFace internalPath];
	if (!internalPath) return nil;
	
	NSObject <T2ListImporting_v100> *listImporter = [_listImporterPluginDic objectForKey:[[internalPath pathComponents] objectAtIndex:0]];
	if (listImporter && [listImporter respondsToSelector:@selector(imageForListFace:)])
		return [listImporter imageForListFace:listFace];
	return nil;
}
-(NSString *)listInternalPathForProposedURLString:(NSString *)URLString {
	NSEnumerator *pluginEnumerator = [_listImporterPlugins objectEnumerator];
	id <T2ListImporting_v100> plugin;
	while (plugin = [pluginEnumerator nextObject]) {
		if ([plugin respondsToSelector:@selector(listInternalPathForProposedURLString:)]) {
			NSString *internalPath = [(NSObject *)plugin listInternalPathForProposedURLString:URLString];
			if (internalPath)
				return internalPath;
		}
	}
	return nil;
}

#pragma mark -
#pragma mark T2SearchListImporting_v100
-(NSArray *)searchListImporterPlugins {
	return _searchListImporterPlugins;
}
-(NSArray *)searchListRootListFaces {
	NSMutableArray *resultArray = [NSMutableArray array];
	NSEnumerator *pluginEnumerator = [_searchListImporterPlugins objectEnumerator];
	id nextObject;
	while (nextObject = [pluginEnumerator nextObject]) {
		if ([(NSObject *)nextObject respondsToSelector:@selector(rootListFaces)]) {
			NSArray *rootListFaces = [(NSObject *)nextObject rootListFaces];
			if (rootListFaces) [resultArray addObjectsFromArray:rootListFaces];
		}
	}
	return resultArray;
}

-(BOOL)isSearchList:(T2List *)list {
	NSString *internalPath = [list internalPath];
	id <T2ListImporting_v100> listImporter = [self listImporterForInternalPath:internalPath];
	if ([listImporter conformsToProtocol:@protocol(T2SearchListImporting_v100)]) {
		return YES;
	}
	return NO;
}

-(void)setSearchString:(NSString *)searchString forList:(T2List *)list {
	NSString *internalPath = [list internalPath];
	id <T2ListImporting_v100> listImporter = [self listImporterForInternalPath:internalPath];
	if ([listImporter conformsToProtocol:@protocol(T2SearchListImporting_v100)]) {
		[(id <T2SearchListImporting_v100>)listImporter setSearchString:searchString];
	}
}
-(NSString *)searchStringForList:(T2List *)list {
	NSString *internalPath = [list internalPath];
	id <T2ListImporting_v100> listImporter = [self listImporterForInternalPath:internalPath];
	if ([listImporter conformsToProtocol:@protocol(T2SearchListImporting_v100)]) {
		return [(id <T2SearchListImporting_v100>)listImporter searchString];
	}
	return nil;
}
-(BOOL)shouldSendWholeSearchStringForList:(T2List *)list {
	
	NSString *internalPath = [list internalPath];
	id <T2ListImporting_v100> listImporter = [self listImporterForInternalPath:internalPath];
	if ([listImporter conformsToProtocol:@protocol(T2SearchListImporting_v100)]) {
		return [(id <T2SearchListImporting_v100>)listImporter receivesWholeSearchString];
	}
	return YES;
}
-(T2ListFace *)persistentListFaceFromList:(T2List *)list {
	NSString *internalPath = [list internalPath];
	id <T2ListImporting_v100> listImporter = [self listImporterForInternalPath:internalPath];
	if ([listImporter conformsToProtocol:@protocol(T2SearchListImporting_v100)]) {
		return [(id <T2SearchListImporting_v100>)listImporter persistentListFaceForSearchString:[self searchStringForList:list]];
	}
	return nil;
}

#pragma mark -
#pragma mark T2ThreadImporting_v100
-(NSArray *)threadImporterPlugins {
	return [_threadImporterPluginDic allValues];
}

-(id <T2ThreadImporting_v100>)threadImporterForInternalPath:(NSString *)internalPath {
	id <T2ThreadImporting_v100> threadImporter = [_threadImporterPluginDic objectForKey:[[internalPath pathComponents] objectAtIndex:0]];
	if (!threadImporter)
		threadImporter = [_threadImporterPluginDic objectForKey:[internalPath pathExtension]];
	return threadImporter;
}

-(T2Thread *)threadForThreadFace:(T2ThreadFace *)threadFace {
	NSString *internalPath = [threadFace internalPath];
	if (!internalPath) return nil;
	
	id <T2ThreadImporting_v100> threadImporter = [self threadImporterForInternalPath:internalPath];
	return [threadImporter threadForThreadFace:threadFace];
}

-(NSString *)threadLogFilePathForInternalPath:(NSString *)internalPath {
	id <T2ThreadImporting_v100> plugin = [self threadImporterForInternalPath:internalPath];
	if (plugin) {
		if ([plugin respondsToSelector:@selector(threadLogFilePathForInternalPath:)]) {
			NSString *filePath = [(NSObject *)plugin threadLogFilePathForInternalPath:internalPath];
			if (filePath)
				return filePath;
		}
	}
	return nil;
}
-(NSString *)threadInternalPathForProposedURLString:(NSString *)URLString {
	NSMutableArray *plugins = [[[_threadImporterPluginDic allValues] mutableCopy] autorelease];
	[plugins sortUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"pluginOrder" ascending:YES] autorelease]]];
	
	NSEnumerator *pluginEnumerator = [plugins objectEnumerator];
	id <T2ThreadImporting_v100> plugin;
	while (plugin = [pluginEnumerator nextObject]) {
		if ([plugin respondsToSelector:@selector(threadInternalPathForProposedURLString:)]) {
			NSString *internalPath = [(NSObject *)plugin threadInternalPathForProposedURLString:URLString];
			if (internalPath)
				return internalPath;
		}
	}
	return nil;
}
-(NSString *)resExtractPatnForProposedURLString:(NSString *)URLString {
	NSEnumerator *pluginEnumerator = [[_threadImporterPluginDic allValues] objectEnumerator];
	id <T2ThreadImporting_v100> plugin;
	while (plugin = [pluginEnumerator nextObject]) {
		if ([plugin respondsToSelector:@selector(threadInternalPathForProposedURLString:)]) {
			NSString *internalPath = [(NSObject *)plugin threadInternalPathForProposedURLString:URLString];
			if (internalPath) {
				if ([plugin respondsToSelector:@selector(resExtractPatnForProposedURLString:)]) {
					NSString *resExtractPath = [(NSObject *)plugin resExtractPatnForProposedURLString:URLString];
					if (resExtractPath)
						return resExtractPath;
				}
			}
		}
	}
	return nil;	
}


#pragma mark -
#pragma mark T2ThreadFaceScoring_v100
-(NSArray *)threadFaceScorerPlugins {
	return [_threadFaceScorerPluginDic allValues];
}
-(NSArray *)threadFaceScoreKeys {
	return _threadFaceScoreKeyArray;
}
-(NSArray *)threadFaceScoreLocalizedNames {
	return _threadFaceScoreLocalizedNameArray;
}
-(id <T2ThreadFaceScoring_v100>)threadFaceScoringPluginForKey:(NSString *)key {
	return (id <T2ThreadFaceScoring_v100>)[_threadFaceScorerPluginDic objectForKey:key];
}

#pragma mark -
#pragma mark T2ThreadFaceFiltering_v100
-(NSArray *)threadFaceFilterPlugins {
	return [_threadFaceFilterPluginDic allValues];
}
-(NSArray *)threadFaceFilterNames {
	return _threadFaceFilterNameArray;
}
-(NSArray *)threadFaceFilterLocalizedNames {
	return _threadFaceFilterLocalizedNameArray;
}
-(id <T2ThreadFaceFiltering_v100>)threadFaceFilteringPluginForName:(NSString *)name {
	return (id <T2ThreadFaceFiltering_v100>)[_threadFaceFilterPluginDic objectForKey:name];
}

#pragma mark -
#pragma mark T2ThreadProcessing_v100
-(NSArray *)threadProcessorPlugins { return _threadProcessorPlugins; }
-(void)processThread:(T2Thread *)thread appendingIndex:(unsigned)index {
	NSEnumerator *processorEnumerator = [_threadProcessorPlugins objectEnumerator];
	id <T2ThreadProcessing_v100> processor;
	while (processor = [processorEnumerator nextObject]) {
		[processor processThread:thread appendingIndex:index];
	}
}

#pragma mark -
#pragma mark T2ResExtracting_v100
-(NSArray *)resExtractorPlugins {
	return _extractorPlugins;
}
-(id <T2ResExtracting_v100>)resExtractorForKey:(NSString *)key {
	return [_extractorPluginDic objectForKey:key];
}
-(NSIndexSet *)extractResIndexesInThread:(T2Thread *)thread forPath:(NSString *)path {
	NSArray *pathComponents = [path pathComponents];
	unsigned pathComponentsCount = [pathComponents count];
	NSString *key = [pathComponents objectAtIndex:0];
	NSString *subPath = nil;
	if ([key isEqualToString:@"internal:"] && pathComponentsCount>1) {
		key = [pathComponents objectAtIndex:1];
		if (pathComponentsCount>2) {
			subPath = [NSString pathWithComponents:[pathComponents subarrayWithRange:NSMakeRange(2,pathComponentsCount-2)]];
		}
	} else {
		key = [pathComponents objectAtIndex:0];
		if (pathComponentsCount>1) {
			subPath = [NSString pathWithComponents:[pathComponents subarrayWithRange:NSMakeRange(1,pathComponentsCount-1)]];
		}
	}
	
	id <T2ResExtracting_v100> resExtractor = [_extractorPluginDic objectForKey:key];
	if (resExtractor) {
		return [resExtractor extractResIndexesInThread:thread forKey:key path:subPath];
	}
	return nil;
}
-(NSString *)localizedDescriptionOfExtractPath:(NSString *)path {
	NSArray *pathComponents = [path pathComponents];
	unsigned pathComponentsCount = [pathComponents count];
	NSString *key = [pathComponents objectAtIndex:0];
	NSString *subPath = nil;
	if ([key isEqualToString:@"internal:"] && pathComponentsCount>1) {
		key = [pathComponents objectAtIndex:1];
		if (pathComponentsCount>2) {
			subPath = [NSString pathWithComponents:[pathComponents subarrayWithRange:NSMakeRange(2,pathComponentsCount-2)]];
		}
	} else {
		key = [pathComponents objectAtIndex:0];
		if (pathComponentsCount>1) {
			subPath = [NSString pathWithComponents:[pathComponents subarrayWithRange:NSMakeRange(1,pathComponentsCount-1)]];
		}
	}
	
	id <T2ResExtracting_v100> resExtractor = [_extractorPluginDic objectForKey:key];
	if (resExtractor) {
		return [resExtractor localizedDescriptionForKey:key path:subPath];
	}
	return nil;	
}

-(NSArray *)defaultExtractPaths {
	if (!_defaultExtractPaths) {
		NSMutableArray *defaultExtractPaths = [NSMutableArray array];
		NSMutableArray *localizedDefaultExtractPaths = [NSMutableArray array];
		NSEnumerator *plugEnumerator = [_extractorPlugins objectEnumerator];
		NSObject <T2ResExtracting_v100> *resExtractor;
		while (resExtractor = [plugEnumerator nextObject]) {
			if ([resExtractor respondsToSelector:@selector(defaultExtractPaths)]) {
				NSArray *paths = [resExtractor defaultExtractPaths];
				if (paths) {
					[defaultExtractPaths addObjectsFromArray:paths];
					NSEnumerator *pathEnumerator = [paths objectEnumerator];
					NSString *path;
					while (path = [pathEnumerator nextObject]) {
						if ([path hasPrefix:@"-"]) {
							[localizedDefaultExtractPaths addObject:@"-"];
						} else {
							NSString *key = [path firstPathComponent];
							NSString *secondPath = [path stringByDeletingfirstPathComponent];
							NSString *localizedPath = [resExtractor localizedDescriptionForKey:key
																						  path:secondPath];
							if (localizedPath) {
								[localizedDefaultExtractPaths addObject:localizedPath];
							} else {
								[localizedDefaultExtractPaths addObject:@"-"];
							}
						}
					}
				}
			}
		}
		_defaultExtractPaths = [defaultExtractPaths copy];
		_localizedDefaultExtractPaths = [localizedDefaultExtractPaths copy];
	}
	return _defaultExtractPaths;
}
-(NSArray *)localizedDefaultExtractPaths {
	if (!_localizedDefaultExtractPaths) {
		[self defaultExtractPaths];
	}
	return _localizedDefaultExtractPaths;
}
-(NSArray *)defautlExtractPathMenuItems {
	NSMutableArray *menuItems = [NSMutableArray array];
	
	NSArray *defaultExtractPaths = [self defaultExtractPaths];
	NSArray *localizedDefaultExtractPaths = [self localizedDefaultExtractPaths];
	
	NSEnumerator *pathEnumerator = [defaultExtractPaths objectEnumerator];
	NSEnumerator *localizedPathEnumerator = [localizedDefaultExtractPaths objectEnumerator];
	
	NSString *path;
	NSString *localizedPath;
	
	while ((path = [pathEnumerator nextObject]) && (localizedPath = [localizedPathEnumerator nextObject])) {
		NSMenuItem *menuItem;
		if ([path hasPrefix:@"-"]) {
			menuItem = [NSMenuItem separatorItem];
		} else {
			menuItem = [[[NSMenuItem alloc] initWithTitle:localizedPath
												   action:@selector(selectResExtractPathAction:)
											keyEquivalent:@""] autorelease];
			[menuItem setRepresentedObject:path];
		}
		[menuItems addObject:menuItem];
	}
	return [[menuItems copy] autorelease];
}

#pragma mark -
#pragma mark T2ThreadHTMLProcessing_v100
-(NSArray *)HTMLProcessorPlugins { return _HTMLProcessorPlugins; }
-(NSString *)processedHTML:(NSString *)htmlString ofRes:(T2Res *)res inThread:(T2Thread *)thread {
	
	NSEnumerator *processorEnumerator = [_HTMLProcessorPlugins objectEnumerator];
	id <T2ThreadHTMLProcessing_v100> processor;
	while (processor = [processorEnumerator nextObject]) {
		htmlString = [processor processedHTML:htmlString
										ofRes:res
									 inThread:thread];
	}
	return htmlString;
}

#pragma mark -
#pragma mark T2ThreadPartialHTMLExporting_v100
-(NSArray *)partialHTMLExporterPlugins { return _partialHTMLExporterPlugins; }
-(void)setPartialHTMLExporterPlugin:(id <T2ThreadPartialHTMLExporting_v100>)partialHTMLExporterPlugin {
	setObjectWithRetain(_viewPartialHtmlPlug, partialHTMLExporterPlugin);
}
-(id <T2ThreadPartialHTMLExporting_v100>)partialHTMLExporterPlugin {
	if (_viewPartialHtmlPlug) return _viewPartialHtmlPlug;
	else if (_partialHTMLExporterPlugins && [_partialHTMLExporterPlugins count]>0)
		return [_partialHTMLExporterPlugins objectAtIndex:0];
	return nil;
}

#pragma mark -
#pragma mark T2ThreadHTMLExporting_v100
-(NSArray *)HTMLExporterPlugins {
	return _viewHtmlPlugins;
}
-(id <T2ThreadHTMLExporting_v100>)HTMLExporterPlugin {
	return nil;
}
-(NSArray *)HTMLExporterMenuItems {
	NSMutableArray *menuItems = [NSMutableArray array];
	
	NSEnumerator *pluginEnumerator = [_viewHtmlPlugins objectEnumerator];
	
	NSObject <T2ThreadHTMLExporting_v100> *plugin;
	NSString *uniqueName;
	NSString *localizedName;
	
	while (plugin = [pluginEnumerator nextObject]) {
		uniqueName = [plugin uniqueName];
		localizedName = [plugin localizedName];
		if (uniqueName && localizedName) {
			NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:localizedName
															   action:@selector(selectHTMLExporterAction:)
														keyEquivalent:@""] autorelease];
			[menuItem setRepresentedObject:uniqueName];
			[menuItems addObject:menuItem];
		}
	}
	return [[menuItems copy] autorelease];	
}

#pragma mark -
#pragma mark Thread Viewer (View)
-(NSArray *)threadViewerPlugins {
	return _threadViewerPlugins;
}
-(NSArray *)threadViewerMenuItems {
	NSMutableArray *menuItems = [NSMutableArray array];
	
	NSEnumerator *pluginEnumerator = [_threadViewerPlugins objectEnumerator];
	
	NSObject <T2ThreadViewing_v100> *plugin;
	NSString *uniqueName;
	NSString *localizedName;
	
	while (plugin = [pluginEnumerator nextObject]) {
		uniqueName = [plugin uniqueName];
		localizedName = [plugin localizedName];
		if (uniqueName && localizedName) {
			NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:localizedName
															   action:@selector(selectThreadViewerAction:)
														keyEquivalent:@""] autorelease];
			[menuItem setRepresentedObject:uniqueName];
			[menuItems addObject:menuItem];
		}
	}
	return [[menuItems copy] autorelease];	
}


#pragma mark -
#pragma mark T2URLPreviewing_v100
-(NSArray *)URLpreviewerPlugins {
	return _previewerPlugins;
}
-(id <T2URLPreviewing_v100>)URLPreviewerForURLString:(NSString *)urlString {
	NSString *urlExtension = [urlString pathExtension];
	NSString *urlHost = [[NSURL URLWithString:urlString] host];
	
	id <T2URLPreviewing_v100> urlPreviewer = nil;
	if (urlHost) {
		urlPreviewer = [_hostPreviewerPluginDic objectForKey:urlHost];
	}
	if (!urlPreviewer && urlExtension) {
		urlPreviewer = [_extensionPreviewerPluginDic objectForKey:urlExtension];
	}
	return urlPreviewer;
}
-(BOOL)isPreviewableURLString:(NSString *)urlString type:(T2PreviewType)type {
	id <T2URLPreviewing_v100> urlPreviewer = [self URLPreviewerForURLString:urlString];
	if (urlPreviewer)
		return [urlPreviewer isPreviewableURLString:urlString type:type];
	return NO;
}
-(NSString *)partialHTMLforPreviewingURLString:(NSString *)urlString type:(T2PreviewType)type minSize:(NSSize *)minSize {
	id <T2URLPreviewing_v100> urlPreviewer = [self URLPreviewerForURLString:urlString];
	if (urlPreviewer) {
		return [urlPreviewer partialHTMLForPreviewingURLString:urlString
														  type:type
													   minSize:minSize];
	}
	return nil;
}

#pragma mark -
#pragma mark T2Posting_v200
-(NSArray *)postingPlugins {
	return [_postingPluginDic allValues];
}
-(id <T2Posting_v200>)postingPluginForInternalPath:(NSString *)path {
	return [_postingPluginDic objectForKey:[path firstPathComponent]];
}

#pragma mark -
#pragma mark T2ResPosting_v100
-(NSArray *)resPostingPlugins {
	return [_resPostingPluginDic allValues];
}
-(id <T2ResPosting_v100>)resPostingPluginForInternalPath:(NSString *)path {
	return [_resPostingPluginDic objectForKey:[path firstPathComponent]];
}
-(BOOL)canPostResToThread:(T2Thread *)thread {
	
	id <T2Posting_v200> modernPostingPlug = [_postingPluginDic
										  objectForKey:[[thread internalPath] firstPathComponent]];
	if (modernPostingPlug) return [modernPostingPlug canPostResToThread:thread];
	
	id <T2ResPosting_v100> postingPlug = [_resPostingPluginDic
										  objectForKey:[[thread internalPath] firstPathComponent]];
	if (postingPlug) return [postingPlug canPostResToThread:thread];
	
	id <T2ResPostingUsingWebView_v100> webPostingPlug = [_webResPostingPluginDic
														 objectForKey:[[thread internalPath] firstPathComponent]];
	if (webPostingPlug) return [webPostingPlug canPostResToThread:thread];
	return NO;
	
}
#pragma mark T2ResPostingUsingWebView_v100
-(NSArray *)webResPostingPlugins {
	return [_webResPostingPluginDic allValues];
}
-(id <T2ResPostingUsingWebView_v100>)webResPostingPluginForInternalPath:(NSString *)path {
	return [_webResPostingPluginDic objectForKey:[path firstPathComponent]];
}
/*
-(BOOL)canPostResToThread:(T2Thread *)thread {
	id <T2ResPostingUsingWebView_v100> postingPlug = [_webResPostingPluginDic
													  objectForKey:[[thread internalPath] firstPathComponent]];
	if (postingPlug) return [postingPlug canPostResToThread:thread];
	return NO;
}
 */

#pragma mark -
#pragma mark T2ThreadPosting_v100
-(NSArray *)threadPostingPlugins {
	return [_threadPostingPluginDic allValues];
}
-(id <T2ThreadPosting_v100>)threadPostingPluginForInternalPath:(NSString *)path {
	return [_threadPostingPluginDic objectForKey:[path firstPathComponent]];
}
-(BOOL)canPostThreadToThreadList:(T2ThreadList *)threadList {
	
	id <T2Posting_v200> modernPostingPlug = [_postingPluginDic
											 objectForKey:[[threadList internalPath] firstPathComponent]];
	if (modernPostingPlug) return [modernPostingPlug canPostThreadToThreadList:threadList];
	
	id <T2ThreadPosting_v100> postingPlug = [_threadPostingPluginDic
											 objectForKey:[[threadList internalPath] firstPathComponent]];
	if (postingPlug) return [postingPlug canPostThreadToThreadList:threadList];
	
	id <T2ThreadPostingUsingWebView_v100> webPostingPlug = [_webThreadPostingPluginDic
															objectForKey:[[threadList internalPath] firstPathComponent]];
	if (webPostingPlug) return [webPostingPlug canPostThreadToThreadList:threadList];
	return NO;
}

#pragma mark T2ThreadPostingUsingWebView_v100
-(NSArray *)webThreadPostingPlugins {
	return [_webThreadPostingPluginDic allValues];
}
-(id <T2ThreadPostingUsingWebView_v100>)webThreadPostingPluginForInternalPath:(NSString *)path {
	return [_webThreadPostingPluginDic objectForKey:[path firstPathComponent]];
}
/*
-(BOOL)canPostThreadToThreadList:(T2ThreadList *)threadList {
	id <T2ThreadPostingUsingWebView_v100> postingPlug = [_webThreadPostingPluginDic
														 objectForKey:[[threadList internalPath] firstPathComponent]];
	if (postingPlug) return [postingPlug canPostThreadToThreadList:threadList];
	return NO;
}
 */
@end
