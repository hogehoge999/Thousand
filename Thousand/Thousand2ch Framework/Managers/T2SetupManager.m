//
//  T2SetupManager.m
//  Thousand
//
//  Created by R. Natori on 06/10/16.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "T2SetupManager.h"
#import "T2UtilityHeader.h"
#import "T2ResourceManager.h"
#import "T2PluginManager.h"
#import "T2ThreadFace.h"
#import "T2ThreadList.h"
#import "T2Thread.h"
#import "T2ListFace.h"
#import "T2BookmarkListFace.h"
#import "T2LabeledCell.h"

static T2SetupManager *__sharedManager;

@implementation T2SetupManager

#pragma mark -
#pragma mark Factory and Init
-(id)init {
	if (!__sharedManager) {
		self = [super init];
		
		[self setApplicationName:
			[[[NSBundle mainBundle] executablePath] lastPathComponent]];
		[self setLogFolderName:@"Log files"];
		[self setIconSetName:@"Standard"];
		[self setPluginFolderName:@"Plugins"];
		[self setPluginPrefFolderName:@"Plugin Prefs"];
		
		return self;
	}
	[self autorelease];
	return __sharedManager;
}
+(id)sharedManager {
	if (!__sharedManager) {
		__sharedManager = [[self alloc] init];
	}
	return __sharedManager;
}
-(void)dealloc {
	
	[_applicationName release];
	[_logFolderName release];
	[_pluginFolderName release];
	[_pluginPrefFolderName release];
    [_proxyHost release];
	
	[_defaultPluginClasses release];
	[_forbiddenPluginBundleIdentifiers release];
	
	[_threadStateNewImageName release];
	[_threadStateUpdatedImageName release];
	[_threadStateNoUpdatedImageName release];
	[_threadStateFallenImageName release];
	[_threadStateFallenNoLogImageName release];
	
	[_listAnimationImageNames release];
	
	[_bookmarkListImageName release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors
-(void)setApplicationName:(NSString *)aString { setObjectWithCopy(_applicationName, aString); }
-(NSString *)applicationName { return _applicationName; }
-(void)setLogFolderName:(NSString *)aString { setObjectWithCopy(_logFolderName, aString); }
-(NSString *)logFolderName { return _logFolderName; }
-(void)setLogFolderPath:(NSString *)path { setObjectWithCopy(_logFolderPath, path); }
-(NSString *)logFolderPath { return _logFolderPath; }
-(void)setPluginFolderName:(NSString *)aString { setObjectWithCopy(_pluginFolderName, aString); }
-(NSString *)pluginFolderName { return _pluginFolderName; }
-(void)setPluginPrefFolderName:(NSString *)aString { setObjectWithCopy(_pluginPrefFolderName, aString); }
-(NSString *)pluginPrefFolderName { return _pluginPrefFolderName; }

-(NSString *)proxyHost { return _proxyHost; }
-(void)setProxyHost:(NSString *)host {
    setObjectWithCopy(_proxyHost, host);
}

-(void)setThreadListExtension:(NSString *)aString { setObjectWithCopy(_threadListExtension, aString); }
-(NSString *)threadListExtension { return _threadListExtension; }
-(void)setThreadExtension:(NSString *)aString { setObjectWithCopy(_threadExtension, aString); }
-(NSString *)threadExtension { return _threadExtension; }

-(void)setIconSetName:(NSString *)aString { setObjectWithCopy(_iconSetName, aString); }
-(NSString *)iconSetName { return _iconSetName; }

-(void)setDefaultPluginClasses:(NSArray *)classes { setObjectWithCopy(_defaultPluginClasses, classes); }
-(NSArray *)defaultPluginClasses { return _defaultPluginClasses; }

-(void)setForbiddenPluginBundleIdentifiers:(NSArray *)bundleIdentifiers { setObjectWithCopy(_forbiddenPluginBundleIdentifiers, bundleIdentifiers); }
-(NSArray *)forbiddenPluginBundleIdentifiers { return _forbiddenPluginBundleIdentifiers; }


-(void)setThreadStateNewImageName:(NSString *)aString { setObjectWithCopy(_threadStateNewImageName, aString); }
-(NSString *)threadStateNewImageName { return _threadStateNewImageName; }
-(void)setThreadStateUpdatedImageName:(NSString *)aString { setObjectWithCopy(_threadStateUpdatedImageName, aString); }
-(NSString *)threadStateUpdatedImageName { return _threadStateUpdatedImageName; }
-(void)setThreadStateNoUpdatedImageName:(NSString *)aString { setObjectWithCopy(_threadStateNoUpdatedImageName, aString); }
-(NSString *)threadStateNoUpdatedImageName { return _threadStateNoUpdatedImageName; }
-(void)setThreadStateFallenImageName:(NSString *)aString { setObjectWithCopy(_threadStateFallenImageName, aString); }
-(NSString *)threadStateFallenImageName { return _threadStateFallenImageName; }
-(void)setThreadStateFallenNoLogImageName:(NSString *)aString { setObjectWithCopy(_threadStateFallenNoLogImageName, aString); }
-(NSString *)threadStateFallenNoLogImageName { return _threadStateFallenNoLogImageName; }

-(void)setListAnimationImageNames:(NSArray *)strings { setObjectWithCopy(_listAnimationImageNames, strings); }
-(NSArray *)listAnimationImageNames { return _listAnimationImageNames; }

-(void)setBookmarkListImageName:(NSString *)aString { setObjectWithCopy(_bookmarkListImageName, aString); }
-(NSString *)bookmarkListImageName { return _bookmarkListImageName; }

-(void)setLabelPopUpBaseImageName:(NSString *)aString { setObjectWithCopy(_labelPopUpBaseImageName, aString); }
-(NSString *)labelPopUpBaseImageName { return _labelPopUpBaseImageName; }
-(void)setLabelPopUpMaskImageName:(NSString *)aString { setObjectWithCopy(_labelPopUpMaskImageName, aString); }
-(NSString *)labelPopUpMaskImageName { return _labelPopUpMaskImageName; }

#pragma mark -
#pragma mark Setup
-(void)setup {
	// path settings
	[NSString setClassAppName:_applicationName];
	[NSString setClassAppLogFolderName:_logFolderName];
	if (_logFolderPath) {
		if (_logFolderName) {
			if (![[_logFolderPath lastPathComponent] isEqualToString:_logFolderName]) {
				setObjectWithCopy(_logFolderName, [_logFolderPath stringByAppendingPathComponent:_logFolderName]);
			}
		}
		[NSString setAppLogFolderPath:_logFolderPath];
	}
	
	NSString *appSupportFolderPath = [[NSString appSupportFolderPath] stringByAppendingPathComponent:_applicationName];
	
	// extension settings
	if (_threadListExtension) {
		NSArray *extensions = [T2ThreadList extensions];
		NSArray *newExtensions = [[NSArray arrayWithObject:_threadListExtension] arrayByAddingObjectsFromArray:extensions];
		[T2ThreadList setExtensions:newExtensions];
	}
	if (_threadExtension) {
		NSArray *extensions = [T2Thread extensions];
		NSArray *newExtensions = [[NSArray arrayWithObject:_threadExtension] arrayByAddingObjectsFromArray:extensions];
		[T2Thread setExtensions:newExtensions];
	}
	
	// ResourceManager Settings
	T2ResourceManager *resourceManager = [T2ResourceManager sharedManager];
	[resourceManager addResourceFolderPaths:[[NSBundle mainBundle] resourcePath]];
	[resourceManager addResourceFolderPaths:appSupportFolderPath];
	
	// Icon set Loading
	[resourceManager loadIconSetNamed:_iconSetName];
	
	// plugin manager settings
	[T2PluginManager setClassForbiddenPluginBundleIdentifiers:_forbiddenPluginBundleIdentifiers];
	[T2PluginManager setClassEmbeddedPluginClasses:_defaultPluginClasses];
	[T2PluginManager setClassPluginFolderPaths:[NSArray arrayWithObjects:
		[appSupportFolderPath stringByAppendingPathComponent:_pluginFolderName],
		[[NSBundle mainBundle] builtInPlugInsPath],
		nil]];
	[T2PluginManager setClassPluginPrefFolderPath:[appSupportFolderPath stringByAppendingPathComponent:_pluginPrefFolderName]];
	
	T2PluginManager *sharedManager = [T2PluginManager sharedManager];
	[sharedManager loadPluginPrefs];
	
	// ResourceManager Loading
	[resourceManager loadCSS];
	
	// T2ThreadItem stateImage
	if (_threadStateNewImageName)
		[T2ThreadFace setClassStateNewImage:[NSImage imageNamed:_threadStateNewImageName]];
	if (_threadStateUpdatedImageName)
		[T2ThreadFace setClassStateUpdatedImage:[NSImage imageNamed:_threadStateUpdatedImageName]];
	if (_threadStateNoUpdatedImageName)
		[T2ThreadFace setClassStateNoUpdatedImage:[NSImage imageNamed:_threadStateNoUpdatedImageName]];
	if (_threadStateFallenImageName)
		[T2ThreadFace setClassStateFallenImage:[NSImage imageNamed:_threadStateFallenImageName]];
	if (_threadStateFallenNoLogImageName)
		[T2ThreadFace setClassStateFallenNoLogImage:[NSImage imageNamed:_threadStateFallenNoLogImageName]];
	
	// T2ListFace animationImage
	if (_listAnimationImageNames) {
		NSMutableArray *listAnimationImages = [NSMutableArray array];
		NSEnumerator *nameEnumerator = [_listAnimationImageNames objectEnumerator];
		NSString *name;
		while (name = [nameEnumerator nextObject]) {
			[listAnimationImages addObject:[NSImage imageNamed:name]];
		}
		[T2ListFace setClassAnimationImages:listAnimationImages];
	}
	
	// List Default Images
	if (_bookmarkListImageName)
		[T2BookmarkListFace setClassDefaultImage:[NSImage imageNamed:_bookmarkListImageName]];
	
	// Label PopUp Image;
	if (_labelPopUpBaseImageName)
		[[T2LabeledCellManager sharedManager] setLabelPopUpBaseImage:[NSImage imageNamed:_labelPopUpBaseImageName]];
	if (_labelPopUpMaskImageName)
		[[T2LabeledCellManager sharedManager] setLabelPopUpMaskImage:[NSImage imageNamed:_labelPopUpMaskImageName]];
	
}
@end
