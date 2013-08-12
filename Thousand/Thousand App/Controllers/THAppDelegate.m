//
//  THAppDelegate.m
//  Thousand
//
//  Created by R. Natori on 05/08/07.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//
#import "THAppDelegate.h"
//#import "THStandardPlugs.h"
#import "THMetalWindow.h"
#import "THDocument.h"
#import "THPostingWindowController.h"
#import "THBookmarkController.h"
#import "THPrefWindowController.h"
#import "THDownloadWindowController.h"
#import "THInputWindowController.h"
#import "THCrashLogWindowController.h"
#import "THCookiesWindowController.h"

#import "THOperationWindowController.h"
#import "THSaveOperation.h"
#import "THKeepOperation.h"
#import "THLoadListOperation.h"
#import "THLoadThreadOperation.h"

#define THthreadListCacheCapacity 10

#define THFontDisplayName(font)			([NSString stringWithFormat:@"%@ - %.1f", [font displayName], [font pointSize]])
#define THPrefToolBarLocalize(string)	(NSLocalizedString(string, @"Pref ToolBar"))

static THAppDelegate *__sharedInstance;

static NSString *__appDelegatePrefKey 		= @"appDelegatePref";

static NSString *__thousandAppName			= @"Thousand";
static NSString *__defaultPluginFolderName 	= @"Plugins";
static NSString *__defaultLogFolderName 	= @"Log Files";
static NSString *__pluginPrefFolderName 	= @"Plugin Prefs";

@implementation THAppDelegate

+(THAppDelegate *)sharedInstance { return __sharedInstance; }

-(id)init {
	self = [super init];
	__sharedInstance = self;
	
	_enableThreadListCache = YES;
	_threadListCache = [[NSMutableArray alloc] init];
	
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	
	// load self prefs
	NSString *ThousandDefaultPrefPath = [[NSBundle mainBundle] pathForResource:@"ThousandDefaultPref" ofType:@"plist"];
	NSDictionary *ThousandDefaultPref = [NSDictionary dictionaryWithContentsOfFile:ThousandDefaultPrefPath];
	[standardUserDefaults registerDefaults:ThousandDefaultPref];
	
	// Thousand 2ch Cookies
	NSString *cookiesFilePath = [[[NSString appSupportFolderPath] stringByAppendingPathComponent:@"Thousand"]
								  stringByAppendingPathComponent:@"Thousand Cookies.plist"];
	[[T2HTTPCookieStorage sharedHTTPCookieStorage] setValuesFromFile:cookiesFilePath];
	
	// Thousand 2ch Init
	T2SetupManager *setupManager = [T2SetupManager sharedManager];
	[setupManager setApplicationName:@"Thousand"];
	
	NSDictionary *prefDic = [standardUserDefaults objectForKey:@"appDelegatePref"];
	
	// version specific
	NSString *lastVersionString = [standardUserDefaults stringForKey:@"lastVersionString"];
	if (lastVersionString) {
		/*
		NSScanner *versionScanner = [NSScanner scannerWithString:lastVersionString];
		float version = 0;
		int betaVersion = 0;
		[versionScanner scanFloat:&version];
		if ([versionScanner scanUpToString:@"Beta" intoString:NULL]) {
			[versionScanner scanString:@"Beta" intoString:NULL];
			[versionScanner scanInt:&betaVersion];
		}
		 */
		//NSLog(@"version %f beta %d", version, betaVersion);
	} else {
		//beta 177
		NSMutableDictionary *mutablePrefDic = [[prefDic mutableCopy] autorelease];
		[mutablePrefDic setObject:[NSNumber numberWithInt:0] forKey:@"defaultExtractPathIndex"];
		[standardUserDefaults setObject:[[mutablePrefDic copy] autorelease] forKey:@"appDelegatePref"];
	}
	
	NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
	if (versionString) {
		if (![lastVersionString isEqualToString:versionString]) {
			[standardUserDefaults setObject:versionString forKey:@"lastVersionString"];
			[standardUserDefaults synchronize];
		}
	}
		
	
	// Log Folder
	
	NSString *logFolderPath = [prefDic objectForKey:@"logFolderPath"];
	
	if (logFolderPath) {
		if ([logFolderPath rangeOfString:@"~"].location != NSNotFound) {
			logFolderPath = [logFolderPath stringByExpandingTildeInPath];
		}
		if (![logFolderPath isExistentPath]) {
			NSString *abbreviatedLogFolderPath = [prefDic objectForKey:@"abbreviatedLogFolderPath"];
			if (abbreviatedLogFolderPath) {
				logFolderPath = [logFolderPath stringByExpandingTildeInPath];
			}
		}
		[setupManager setLogFolderPath:logFolderPath];
	}
	
	// Extensions
	[setupManager setThreadListExtension:@"ththreadlist"];
	[setupManager setThreadExtension:@"ththread"];
	
	// Resources
	[setupManager setThreadStateNewImageName:@"TH16_StateNew"];
	[setupManager setThreadStateUpdatedImageName:@"TH16_StateUpdated"];
	[setupManager setThreadStateNoUpdatedImageName:@"TH16_StateNoUpdated"];
	[setupManager setThreadStateFallenImageName:@"TH16_StateFallen"];
	[setupManager setThreadStateFallenNoLogImageName:@"TH16_StateFallenNoLog"];
	
	[setupManager setListAnimationImageNames:
	 [NSArray arrayWithObjects:
	  @"TH16_Loading1",
	  @"TH16_Loading2",
	  @"TH16_Loading3",
	  @"TH16_Loading4", nil]];
	
	[setupManager setBookmarkListImageName:@"TH16_Custom List"];
	
	[setupManager setLabelPopUpBaseImageName:@"TH32_LabelPopUp"];
	[setupManager setLabelPopUpMaskImageName:@"TH32_LabelPopUpMask"];
	
	// Icon Set
	NSString *iconSetName = [prefDic objectForKey:@"iconSetName"];
	if (iconSetName)
		[setupManager setIconSetName:iconSetName];
	
	// Plugins

	// Disable Spotlight Plugin Under Panther
	NSArray *forbiddenPluginBundleIdentifiers = [NSArray arrayWithObjects:
												 @"jp.natori.AAdiscrimination",
												 @"com.yourcompany.yourcocoabundle",
												 nil];
	
	SInt32 MacVersion;
	if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr){
		if (MacVersion < 0x1040){ // Panther Only
			forbiddenPluginBundleIdentifiers = [forbiddenPluginBundleIdentifiers arrayByAddingObject:
												@"jp.natori.Thousand.THSpotlightSearchListImporter"];
		}
	}
	[setupManager setForbiddenPluginBundleIdentifiers:forbiddenPluginBundleIdentifiers];
	
	// Setup
	[setupManager setup];
	
	THPrefWindowController *prefWindowController = [THPrefWindowController sharedPrefWindowController];
	
	return self;
}

-(void)awakeFromNib {
	
	// Debug Menu
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"showsDebugMenu"] && _debugMenuItem) {
		[[NSApp mainMenu] removeItem:_debugMenuItem];
	}
	
	// Style Menu
	NSArray *menuItems = [[T2ResourceManager sharedManager] styleMenuItemsForTarget:nil
																			 action:@selector(setResStyleAction:)];
	NSEnumerator *menuItemEnumerator = [menuItems objectEnumerator];
	NSMenuItem *menuItem;
	NSMenu *resultMenu = [[[NSMenu alloc] initWithTitle:@"Styles"] autorelease];
	while (menuItem = [menuItemEnumerator nextObject]) {
		[resultMenu addItem:menuItem];
	}
	[resultMenu addItem:[NSMenuItem separatorItem]];
	NSMenuItem *removeStyleItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Remove Styles",@"app")
															  action:@selector(removeResStyleAction:) keyEquivalent:@""] autorelease];
	[resultMenu addItem:removeStyleItem];
	
	[_threadResStyleMenuItem setSubmenu:resultMenu];
	
	// Label Menu
	[self updateLabelMenu];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateLabelMenuWithNotification:)
												 name:T2LabelColorsChangedNotification
											   object:nil];
	
	// Display Menu
	NSMenu *displayMenu = [_threadDisplayMenuItem submenu];
	unsigned availableMenuItemCount = [displayMenu numberOfItems];
	unsigned i;
	for (i=0; i<availableMenuItemCount; i++) {
		[displayMenu removeItemAtIndex:0];
	}
	
	NSArray *rangeMenuItems = [[T2PluginManager sharedManager] defautlExtractPathMenuItems];
	menuItemEnumerator = [rangeMenuItems objectEnumerator];
	
	[displayMenu addItem:[[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Range", nil)
													 action:NULL
											  keyEquivalent:@""] autorelease]];
	while (menuItem = [menuItemEnumerator nextObject]) {
		[menuItem setIndentationLevel:1];
		[displayMenu addItem:menuItem];
	}
	// View Menu
	NSArray *htmlMenuItems = [[T2PluginManager sharedManager] HTMLExporterMenuItems];
	NSArray *viewMenuItems = [[T2PluginManager sharedManager] threadViewerMenuItems];
	NSMutableArray *htmlAndViewMenuItems = [NSMutableArray array];
	[htmlAndViewMenuItems addObjectsFromArray:htmlMenuItems];
	[htmlAndViewMenuItems addObjectsFromArray:viewMenuItems];
	if ([htmlAndViewMenuItems count] > 0) {
		[displayMenu addItem:[NSMenuItem separatorItem]];
		menuItemEnumerator = [htmlAndViewMenuItems objectEnumerator];
		//NSMenuItem *menuItem;
		[displayMenu addItem:[[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"View", nil)
												  action:NULL
										   keyEquivalent:@""] autorelease]];
		while (menuItem = [menuItemEnumerator nextObject]) {
			[menuItem setIndentationLevel:1];
			[displayMenu addItem:menuItem];
		}
	}
	
	
	// Close MenuItem
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowDidBecomeKey:)
												 name:NSWindowDidBecomeKeyNotification
											   object:nil];
}

-(oneway void)release {
	if (self != __sharedInstance) {
		[super release];
	}
}

#pragma mark -
#pragma mark NSApplication delegate
- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
	
	// Launch the crash reporter task
	// Make sure to change the name and email before running the application
	/*
	[[ILCrashReporter defaultReporter] 
	 launchReporterForCompany:@"R.Natori" reportAddr:@"thousand_natori@mac.com"];
	 */
	 
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
													   andSelector:@selector(handleAppleEvent:withReplyEvent:)
													 forEventClass:'GURL'
														andEventID:'GURL'];
}
- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
	NSDocumentController *documentController = [NSDocumentController sharedDocumentController];
	THDocument *document = [[documentController documents] lastObject];
	if (!document) {
		document = [documentController openUntitledDocumentAndDisplay:YES error:nil];
	}
	
	if (document) {
		NSMutableArray *threadFaces = [NSMutableArray array];
		NSArray *ththreadFiles = [filenames pathsMatchingExtensions:[NSArray arrayWithObject:@"ththread"]];
		NSEnumerator *ththreadFileEnumerator = [ththreadFiles objectEnumerator];
		NSString *ththreadFile;
		while (ththreadFile = [ththreadFileEnumerator nextObject]) {
			NSData *plistData = [NSData dataWithContentsOfFile:ththreadFile];
			if (plistData) {
				
				NSDictionary *dictionary = [NSPropertyListSerialization propertyListFromData:plistData
																			mutabilityOption:NSPropertyListImmutable
																					  format:NULL
																			errorDescription:NULL];
				
				NSDictionary *threadFaceDic = [dictionary objectForKey:@"threadFace"];
				if (threadFaceDic) {
					T2ThreadFace *threadFace = [T2ThreadFace objectWithDictionary:threadFaceDic];
					if (threadFace) {
						[threadFaces addObject:threadFace];
					}
				}
			}
		}
		
		NSArray *otherFiles = [filenames pathsMatchingExtensions:[NSArray arrayWithObject:@"dat"]];
		NSEnumerator *otherFileEnumerator = [otherFiles objectEnumerator];
		NSString *otherFile;
		while (otherFile = [otherFileEnumerator nextObject]) {
			NSString *internalPath = [@"Local File" stringByAppendingString:otherFile];
			T2ThreadFace *threadFace = [T2ThreadFace threadFaceWithInternalPath:internalPath];
			if (threadFace) {
				if (![threadFace title]) [threadFace setTitle:@"Untitled"];
				[threadFaces addObject:threadFace];
			}
		}
		
		if ([threadFaces count] > 0) {
			[document loadThreadsForThreadFaces:threadFaces activateTab:YES];
			[NSApp replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
			return;
		}
	}
	
	[NSApp replyToOpenOrPrint:NSApplicationDelegateReplyFailure];
	return;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	BOOL isNotFirstLaunch = [standardUserDefaults boolForKey:@"isNotFirstLaunch"];
	if (!isNotFirstLaunch)
		[standardUserDefaults setBool:YES forKey:@"isNotFirstLaunch"];
	
	if (isNotFirstLaunch && ![standardUserDefaults boolForKey:@"terminateWithoutCrash"]) {
		[self showCrashLogWindow:nil];
	} else {
		[standardUserDefaults setBool:NO forKey:@"terminateWithoutCrash"];
		[standardUserDefaults synchronize];
	}
	
	if ([standardUserDefaults boolForKey:@"savesTabsContents"]) {
		NSArray *documentDictionaries = [standardUserDefaults objectForKey:@"documentDictionaries"];
		NSMutableArray *documents = [NSMutableArray array];
		NSDocumentController *documentController = [NSDocumentController sharedDocumentController];
		[documents addObjectsFromArray:[documentController documents]];
		
		unsigned documentNumbers = [documentDictionaries count];
		unsigned documentNumbersToCreate = documentNumbers - [documents count];
		
		if (documentNumbers >= documentNumbersToCreate) {
			unsigned i;
			for (i=0; i<documentNumbersToCreate; i++) {
				THDocument *document = [documentController openUntitledDocumentAndDisplay:YES error:nil];
				[documents addObject:document];
			}
			
			for (i=0; i<documentNumbers; i++) {
				THDocument *document = [documents objectAtIndex:i];
				[document setTabContentsDictionary:[documentDictionaries objectAtIndex:i]];
			}
		}
	}
	
	
	[THOperationWindowController startWatchingOperations];
	/*
	if (_enableThreadListCache) {
		T2SourceList *sourceList = [T2SourceList sharedSourceList];
		NSEnumerator *listEnumerator = [[sourceList objects] objectEnumerator];
		T2ListFace *listFace;
		unsigned listToCacheCount = 0;
		NSMutableArray *listFacesToCache = [[[NSMutableArray alloc] initWithCapacity:THthreadListCacheCapacity] autorelease]; 
		while (listFace = [listEnumerator nextObject]) {
			NSString *internalPath = [listFace internalPath];
			if ([[internalPath pathComponents] count] > 1) {
				T2List *list = [T2List availableObjectWithInternalPath:internalPath];
				if (!list) {
					[listFacesToCache addObject:listFace];
					listToCacheCount++;
					if (listToCacheCount >= THthreadListCacheCapacity) break;
				}
			}
		}
		_loadListOperation = [[THLoadListOperation loadOperationWithListFaces:listFacesToCache] retain];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(loadListOperationFinished:)
													 name:T2OperationDidFinishedNotification
												   object:_loadListOperation];
		[_loadListOperation start];
	}
	 */
}
-(void)loadListOperationFinished:(NSNotification *)notification {
	[_threadListCache setArray:[_loadListOperation lists]];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:T2OperationDidFinishedNotification
												  object:_loadListOperation];
	[_loadListOperation release];
	_loadListOperation = nil;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	
	if (_loadThreadOperation) {
		[_loadThreadOperation release];
		_loadThreadOperation = nil;
	}
	
	if (_threadListCache) {
		[_threadListCache release];
		_threadListCache = nil;
	}
	
	if ([standardUserDefaults boolForKey:@"savesTabsContents"]) {
		NSMutableArray *documentDictionaries = [NSMutableArray array];
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
		THDocument *document;
		NSEnumerator *documentEnumerator = [documents objectEnumerator];
		while (document = [documentEnumerator nextObject]) {
			NSDictionary *documentDictionary = [document tabContentsDictionary];
			[documentDictionaries addObject:documentDictionary];
			[document close];
		}
		[pool release];
		[standardUserDefaults setObject:documentDictionaries forKey:@"documentDictionaries"];
	} else {
		[standardUserDefaults removeObjectForKey:@"documentDictionaries"];
	}
	
	[THPrefWindowController releaseSharedPrefWindowController];
	
	[[T2ThreadHistory threadHistoryForKey:@"threadHistory"] saveToFile];
	[[T2ThreadHistory threadHistoryForKey:@"resPostedThreadHistory"] saveToFile];
	[[T2ListHistory listHistoryForKey:@"threadListHistory"] saveToFile];
	
	[[T2SourceList sharedSourceList] saveToFile];
	
	T2PluginManager *sharedManager = [T2PluginManager sharedManager];
	[sharedManager savePluginPrefs];
	[sharedManager unloadAllPlugins];
	
	// Thousand 2ch Cookies
	
	NSString *cookiesFilePath = [[[NSString appSupportFolderPath] stringByAppendingPathComponent:@"Thousand"]
								 stringByAppendingPathComponent:@"Thousand Cookies.plist"];
	T2HTTPCookieStorage *sharedHTTPCookieStorage = [T2HTTPCookieStorage sharedHTTPCookieStorage];
	[sharedHTTPCookieStorage deleteExpiredCookies];
	[sharedHTTPCookieStorage saveObjectToFile:cookiesFilePath];
	
	[standardUserDefaults setBool:YES forKey:@"terminateWithoutCrash"];
}

- (void)applicationDidResignActive:(NSNotification *)aNotification {
	[T2PopUpWindowController closeAllPopUp];
}

- (void)documentController:(NSDocumentController *)docController 
			   didCloseAll: (BOOL)didCloseAll contextInfo:(void *)contextInfo {
}

#pragma mark -
#pragma mark  Accessors
-(void)setEnableThreadListCache:(BOOL)aBool { _enableThreadListCache = aBool; }
-(BOOL)enableThreadListCache { return _enableThreadListCache; }
-(void)setEnablePrefetchThread:(BOOL)aBool { _enablePrefetchThread = aBool; }
-(BOOL)enablePrefetchThread { return _enablePrefetchThread; }

#pragma mark -
#pragma mark  Methods
-(void)showSourceWindowWithString:(NSString *)aString {
	if (aString) {
		[_sourceTextView setString:aString];
		[_sourceWindow makeKeyAndOrderFront:nil];
	}
}

-(void)prefetchThreadWithThreadFaces:(NSArray *)threadFaces {
	if (!_enablePrefetchThread || [threadFaces count] == 0)
		return;
	
	THLoadThreadOperation *loadThreadOperation = [THLoadThreadOperation loadOperationWithThreadFaces:threadFaces];
	setObjectWithRetain(_loadThreadOperation, loadThreadOperation);
	[loadThreadOperation start];
}

-(void)cacheThreadList:(T2ThreadList *)threadList {
	
	if (!_enableThreadListCache || [[threadList objects] count] > 2000)
		return;
	
	if ([threadList isKindOfClass:[T2BookmarkList class]] ||
		[threadList isKindOfClass:[T2ThreadHistory class]])
		return;
	
	if (!_threadListCache) {
		return;
		//_threadListCache = [[NSMutableArray alloc] initWithCapacity:THthreadListCacheCapacity];
		//_prevSavedTimeInterval = [[NSDate date] timeIntervalSinceReferenceDate];
	}
	
	// remove old entry and add new entry
	if ([_threadListCache indexOfObjectIdenticalTo:threadList] == NSNotFound) {
		[_threadListCache addObject:threadList];
		if ([_threadListCache count] > (THthreadListCacheCapacity-1)) {
			[[_threadListCache objectAtIndex:0] releaseAfterDelay];
			//THKeepOperation *keepOperation = [THKeepOperation keepOperationWithObject:[_threadListCache objectAtIndex:0]];
			[_threadListCache removeObjectAtIndex:0];
			//[keepOperation start];
		}
	}
}

-(void)openURLString:(NSString *)URLString {
	if (!URLString || [URLString length]==0) return;
	NSDocumentController *sharedDocumentController = [NSDocumentController sharedDocumentController];
	THDocument *document = nil;
	NSArray *documents = [sharedDocumentController documents];
	if ([documents count] == 0) {
		document = [sharedDocumentController openUntitledDocumentAndDisplay:YES error:nil];
	} else {
		document = [documents lastObject];
		[document showWindows];
	}
	
	if (document) {
		[document loadThreadForURLString:URLString];
		
	}
	
}

#pragma mark -
#pragma mark Dynamic Menu
-(void)setThreadResStyleMenuTitle:(NSString *)aString enabled:(BOOL)aBool {
	[_threadResStyleMenuItem setEnabled:aBool];
	[_threadResStyleMenuItem setTitle:aString];
}
-(void)setThreadResTraceMenuTitle:(NSString *)aString enabled:(BOOL)aBool {
	[_threadResTraceMenuItem setEnabled:aBool];
	[_threadResTraceMenuItem setTitle:aString];
}


-(void)updateLabelMenu {
	NSMenu *threadMenu = [_threadLabelMenuItem submenu];
	unsigned availableMenuItemCount = [threadMenu numberOfItems];
	
	unsigned i;
	for (i=0; i<availableMenuItemCount; i++) {
		[threadMenu removeItemAtIndex:0];
	}
	
	NSArray *labelMenuItems = [[T2LabeledCellManager sharedManager] menuItems];
	NSEnumerator *menuItemEnumerator = [labelMenuItems objectEnumerator];
	NSMenuItem *menuItem;
	while (menuItem = [menuItemEnumerator nextObject]) {
		[threadMenu addItem:menuItem];
	}
}
-(void)updateLabelMenuWithNotification:(NSNotification *)notification {
	[self updateLabelMenu];
}
-(NSMenuItem *)labelMenuItem { return _threadLabelMenuItem; }

-(void)setKeyEquivalentForMultipleTabs:(BOOL)aBool {
	if (_keyEquivalentForMultipleTabs == aBool) return;
	_keyEquivalentForMultipleTabs = aBool;
	
	[_fileMenu setMenuChangedMessagesEnabled:NO];
	
	[_closeWindowMenuItem setKeyEquivalent:@""];
	[_closeWindowMenuItem setKeyEquivalentModifierMask:0];
	[_closeTabMenuItem setKeyEquivalent:@""];
	[_closeTabMenuItem setKeyEquivalentModifierMask:0];
	
	if (aBool) {
		[_closeTabMenuItem setKeyEquivalentModifierMask:NSCommandKeyMask];
		[_closeTabMenuItem setKeyEquivalent:@"w"];
		[_closeWindowMenuItem setKeyEquivalentModifierMask:NSCommandKeyMask | NSShiftKeyMask];
		[_closeWindowMenuItem setKeyEquivalent:@"w"];
		
	} else {
		[_closeWindowMenuItem setKeyEquivalent:@"w"];
		[_closeWindowMenuItem setKeyEquivalentModifierMask:NSCommandKeyMask];
		
	}
	[_fileMenu setMenuChangedMessagesEnabled:YES];
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification {
	NSWindow *window = [aNotification object];
	THDocument *document = [[NSDocumentController sharedDocumentController] documentForWindow:window];
	if (document) {
		[document updateMenu];
	} else {
		[self setKeyEquivalentForMultipleTabs:NO];
	}
}

-(void)setShowArchiveMenuItemIsDefault:(BOOL)aBool {
	if (aBool)
		[_showArchiveMenuItem setTitle:NSLocalizedString(@"Show Fallen Thread Archives", @"App")];
		
	else
		[_showArchiveMenuItem setTitle:NSLocalizedString(@"Hide Fallen Thread Archives", @"App")];
}

#pragma mark -
#pragma mark AppleEvent
-(void) handleAppleEvent:(NSAppleEventDescriptor*)event
		  withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
	AEEventClass eventClass = [event eventClass];
	AEEventID eventID = [event eventID];
	
	if (eventClass == 'GURL' && eventID == 'GURL') {
		NSString *URLString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
		[self openURLString:URLString];
	}
}

#pragma mark -
#pragma mark Actions
-(IBAction)showPrefWindow:(id)sender {
	[[[THPrefWindowController sharedPrefWindowController] window] makeKeyAndOrderFront:sender];
}

-(IBAction)showDownloadWindow:(id)sender {
	[[[THDownloadWindowController downloadWindowController] window] makeKeyAndOrderFront:sender];
}
-(IBAction)showCrashLogWindow:(id)sender {
	[[[THCrashLogWindowController sharedCrashLogWindowController] window] makeKeyAndOrderFront:sender];
}
-(IBAction)showCookiesWindow:(id)sender {
	[[[THCookiesWindowController sharedCookiesWindowController] window] makeKeyAndOrderFront:sender];
}
-(IBAction)saveBookmarksAndHistory:(id)sender {
	[[T2ThreadHistory threadHistoryForKey:@"threadHistory"] saveToFile];
	[[T2ThreadHistory threadHistoryForKey:@"resPostedThreadHistory"] saveToFile];
	[[T2ListHistory listHistoryForKey:@"threadListHistory"] saveToFile];
	
	[[T2SourceList sharedSourceList] saveToFile];
}
-(IBAction)openURL:(id)sender {
	//[THURLOpenWindowController beginSheetModalForWindow:nil delegate:self];
}
-(void)didEndInputSheetWithString:(NSString *)URLString {
	if (!URLString || [URLString length]==0) return;
    NSError *error;
	NSDocumentController *sharedDocumentController = [NSDocumentController sharedDocumentController];
	//THDocument *newDocument = [sharedDocumentController openUntitledDocumentOfType:@"2ch BBS dat file" display:YES];
	THDocument *newDocument = [sharedDocumentController openUntitledDocumentAndDisplay:YES error:&error];
	if (newDocument) {
		[newDocument loadThreadForURLString:URLString];

	}
}
@end
