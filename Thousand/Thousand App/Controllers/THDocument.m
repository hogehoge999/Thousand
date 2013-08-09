//
//  MyDocument.m
//  ﾇPROJECTNAMEﾈ
//
//  Created by ﾇFULLUSERNAMEﾈ on ﾇDATEﾈ.
//  Copyright ﾇORGANIZATIONNAMEﾈ ﾇYEARﾈ . All rights reserved.
//

#import "THDocument.h"
#import "THAppDelegate.h"
#import "THBookmarkController.h"
#import "THThreadController.h"
#import "THProgressIndicator.h"
#import "THInputWindowController.h"
#import "THPostingWindowController.h"

#import "THAppKitAdditions.h"
#import "THDownloadWindowController.h"

#import "THSplitView.h"
#import "THLabelButton.h"
#import "THImagePopUpButton.h"
#import "THImagePopUpToolbarItem.h"
//#import "PSMTabBarCell.h"

#import "THTestOperation.h"

#import <objc/objc-runtime.h>

#define THDocToolBarLocalize(string) (NSLocalizedString(string, @"Doc ToolBar"))
#define THDocLocalize(string) (NSLocalizedString(string, @"Doc"))

static int __maxTabCount = 5;
static int __maxWaitingCount = 20;
static float __listTabWidth = 120.0;
static BOOL __newTabAppearsInRightEnd = YES;

static NSString *__oreyonPath = nil;

@implementation THDocument

+(void)initialize {
	if (__oreyonPath) return;
	/*
	 [self setKeys:[NSArray arrayWithObject:@"selectedTabIndex"]
	 triggerChangeNotificationsForDependentKey:@"selectedThreadView"];
	 [self setKeys:[NSArray arrayWithObject:@"selectedTabIndex"]
	 triggerChangeNotificationsForDependentKey:@"selectedThreadController"];
	 */
	NSWorkspace *sharedWorkspace = [NSWorkspace sharedWorkspace];
	__oreyonPath = [[sharedWorkspace fullPathForApplication:@"Oreyon"] retain];
}

- (id)init
{
    self = [super init];
    if (self) {
		_maxTabCount = __maxTabCount;
		_waitingThreadInternalPaths = [[NSMutableArray alloc] init];
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
		
    }
    return self;
}

-(void)dealloc {
	
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_listInternalPathToSelect release];
	
	[_waitingTimer invalidate];
	[_waitingTimer release];
	[_waitingThreadInternalPaths release];
	
	[_tempThreadFace release];
	[self setProgressProvider:nil];
	
	[_searchField release];
	[_urlField release];
	[_labelButton release];
	[_actionButton release];
	[_threadTableViewScrollView release];
	[_threadTableViewPlaceHolder release];
	[_h1SplitView release];
	
	//[_bookmarkController release];
	
	[super dealloc];
}

-(void)awakeFromNib {
	[_searchField retain];
	[_urlField retain];
	
	[_threadTableViewScrollView retain];
	[_threadTableViewPlaceHolder retain];
	[_h1SplitView retain];
	// make ToolBar
	NSToolbar *toolbar=[[[NSToolbar alloc] initWithIdentifier:THDocToolBarIdentifier] autorelease];
	_toolbar = toolbar;
	[toolbar setDelegate:self];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration: YES]; 
	[toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
	
	//[toolbar addObserver:self forKeyPath:@"sizeMode" options:0 context:THDocToolBarIdentifier];
	
	// Label Button
	_labelButton = [[THLabelButton labelButtonForToolBar:toolbar] retain];
	[_labelButton setLabel:-1];
	
	// Action / Display Button
	// Build Menu Items
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:NSLocalizedString(@"Action", nil)] autorelease];
	
	// Range
	NSArray *rangeMenuItems = [[T2PluginManager sharedManager] defautlExtractPathMenuItems];
	NSEnumerator *menuItemEnumerator = [rangeMenuItems objectEnumerator];
	NSMenuItem *menuItem;
	[menu addItem:[[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Range", nil)
											  action:NULL
									   keyEquivalent:@""] autorelease]];
	while (menuItem = [menuItemEnumerator nextObject]) {
		//[menuItem setIndentationLevel:1];
		[menu addItem:menuItem];
	}
	
	// View
	NSArray *htmlMenuItems = [[T2PluginManager sharedManager] HTMLExporterMenuItems];
	NSArray *viewMenuItems = [[T2PluginManager sharedManager] threadViewerMenuItems];
	NSMutableArray *htmlAndViewMenuItems = [NSMutableArray array];
	[htmlAndViewMenuItems addObjectsFromArray:htmlMenuItems];
	[htmlAndViewMenuItems addObjectsFromArray:viewMenuItems];
	if ([htmlAndViewMenuItems count] > 0) {
		[menu addItem:[NSMenuItem separatorItem]];
		menuItemEnumerator = [htmlAndViewMenuItems objectEnumerator];
		/*
		menuItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"View", nil)
											   action:NULL
										keyEquivalent:@""] autorelease];
		
		[menu addItem:menuItem];
		 */
		while (menuItem = [menuItemEnumerator nextObject]) {
			//[menuItem setIndentationLevel:1];
			[menu addItem:menuItem];
		}
	}
	
	_actionButton = [[THImagePopUpButton imagePopUpButtonForToolBar:toolbar] retain];
	[_actionButton setMenu:menu];
	[_actionButton setImage:[NSImage imageNamed:@"TH32_ActionPopUp"]];
	
	// for Tab
	SInt32 MacVersion;
	if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr){
		if (MacVersion >= 0x1040){
			// this call is Tiger only
			objc_msgSend(toolbar, @selector(setShowsBaselineSeparator:), NO);
		}
	}
	
	[_docWindow setToolbar:toolbar];
	
	//tab
	[_tabBarControl setAllowsDragBetweenWindows:NO];
	[_tabBarControl setCellMaxWidth:180];
	[_tabBarControl setCellMinWidth:80];
	[_tabBarControl setCellOptimumWidth:180];
	if (!([_docWindow styleMask] & NSTexturedBackgroundWindowMask)) {
		[_tabBarControl setStyleNamed:@"Aqua"];
	}
    [_docWindow setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
	NSArray *cells = [_tabBarControl cells];
	PSMTabBarCell *cell = [cells objectAtIndex:0];
	[cell setHasCloseButton:NO];
	
	[self tabView:_tabView didSelectTabViewItem:_listTab];
}

-(void)saveOnApplicationTerminate {
	//
	[self close];
}
#pragma mark -
#pragma mark NSDocument Methods
- (NSString *)windowNibName {
    return @"THDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController {
    [super windowControllerDidLoadNib:aController];
	if([_docWindow respondsToSelector:@selector(setBottomCornerRounded:)]) {
		objc_msgSend(_docWindow, @selector(setBottomCornerRounded:), NO);
	}
	/*
	[aController setShouldCascadeWindows:NO];
	NSPoint docWindowTopLeft = [_docWindow frame].origin;
	[_docWindow setFrameUsingName:@"docWindow"];
	if ([[[NSDocumentController sharedDocumentController] documents] count] == 1) {
		[_docWindow setFrameTopLeftPoint:docWindowTopLeft];
	} else {
		docWindowTopLeft = [_docWindow cascadeTopLeftFromPoint:[_docWindow frame].origin];
		[_docWindow setFrameTopLeftPoint:docWindowTopLeft];
	}
	[_docWindow saveFrameUsingName:@"docWindow"];
	_docWindowSizeLoaded = YES;
	 */
	[_docWindow setFrameUsingName:@"docWindow"];
	_docWindowSizeLoaded = YES;
	[_docWindow setTitle:NSLocalizedString(@"Thousand", nil)];
	
	[self loadTabContents];
	
	if (_tempThreadFace) {
		[self loadThreadForThreadFace:_tempThreadFace activateTab:YES];
		[_tempThreadFace release];
		_tempThreadFace = nil;
	}
	[_bookmarkController loadSplitViewPositions];
}

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    // Insert code here to write your document from the given data.  You can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.
    return nil;
}

/*
 - (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
 {
 // Insert code here to read your document from the given data.  You can also choose to override -loadFileWrapperRepresentation:ofType: or -readFromFile:ofType: instead.
 
 }
 */
- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType {
	NSString *extension = [fileName pathExtension];
	
	if ([extension isEqualToString:@"ththread"]) {
		NSData *plistData = [NSData dataWithContentsOfFile:fileName];
		if (!plistData) return NO;
		
		NSDictionary *dictionary = [NSPropertyListSerialization propertyListFromData:plistData
																	mutabilityOption:NSPropertyListImmutable
																			  format:NULL
																	errorDescription:NULL];
		NSString *internalPath = [dictionary objectForKey:@"internalPath"];
		T2ThreadFace *threadFace = [T2ThreadFace threadFaceWithInternalPath:internalPath];
		_tempThreadFace = [threadFace retain];
		//[self loadThreadForThreadFace:threadFace activateTab:YES];
		return YES;
	}
	
	NSString *internalPath = [@"Local File" stringByAppendingString:fileName];
	T2ThreadFace *threadFace = [T2ThreadFace threadFaceWithInternalPath:internalPath];
	if (![threadFace title]) [threadFace setTitle:@"Untitled"];
	_tempThreadFace = [threadFace retain];
	return YES;
}

-(void)close {
	if (!_bookmarkController) return;
	//[_toolbar removeObserver:self forKeyPath:@"sizeMode"];
	[_progressIndicator unbind:@"hidden"];
	[_progressIndicator unbind:@"value"];
	[_labelButton setToolBar:nil];
	[_actionButton setToolBar:nil];
	[_bookmarkController documentWillClose];
	
	
	NSArray *tabViewItems = [[[_tabBarControl representedTabViewItems] copy] autorelease];
	NSEnumerator *tabViewItemEnumerator = [tabViewItems objectEnumerator];
	NSTabViewItem *tabViewItem;
	while (tabViewItem = [tabViewItemEnumerator nextObject]) {
		if (tabViewItem != _listTab) {
			THThreadController *threadController = (THThreadController *)[tabViewItem identifier];
			[[threadController threadView] saveScrollToThread];
			T2Thread *thread = [threadController thread];
			THPostingWindowController *resPostingWindowController = [THPostingWindowController availableResPostingWindowForThread:thread];
			if (resPostingWindowController) {
				[resPostingWindowController close];
			}
			[tabViewItem setIdentifier:nil];
			[_tabView removeTabViewItem:tabViewItem];
		}
	}
	[_bookmarkController documentWillClose];
	[_bookmarkSelfController setContent:nil];
	//[_bookmarkController release];
	_bookmarkController = nil;
	
	
	[super close];
}

- (void)updateChangeCount:(NSDocumentChangeType)changeType {
}

#pragma mark -
#pragma mark Accessors
+(void)setClassMaxThreadTabCount:(int)anInt {
	if (anInt < 1) anInt = 1;
	__maxTabCount = anInt;
}
+(int)classMaxThreadTabCount { return __maxTabCount; }

+(void)setClassNewTabAppearsInRightEnd:(BOOL)aBool { __newTabAppearsInRightEnd = aBool; }
+(BOOL)classNewTabAppearsInRightEnd { return __newTabAppearsInRightEnd; }

+(NSString *)oreyonPath { return __oreyonPath; }

-(void)setProgressProvider:(id <T2AsynchronousLoading>)progressProvider {
	setObjectWithRetain(_progressProvider, progressProvider);
	if ([progressProvider isKindOfClass:[T2Thread class]]) {
		[[_searchField cell] setSendsWholeSearchString:YES];
		return;
	} else if ([progressProvider isKindOfClass:[T2List class]]) {
		T2PluginManager *pluginManager = [T2PluginManager sharedManager];
		if ([pluginManager isSearchList:(T2List *)progressProvider]) {
			NSString *searchString = [pluginManager searchStringForList:(T2List *)progressProvider];
			if (!searchString) searchString = @"";
			[_searchField setStringValue:searchString];

			[[_searchField cell] setSendsWholeSearchString:[pluginManager shouldSendWholeSearchStringForList:(T2List *)progressProvider]];
			return;
		}
		[[_searchField cell] setSendsWholeSearchString:NO];
		[_searchField setStringValue:@""];
	}
}
-(id <T2AsynchronousLoading>)progressProvider {
	return _progressProvider;
}
-(void)setLabel:(int)label {
	_label = label;
	if (_labelButton)
		[_labelButton setLabel:label];
}
-(int)label { return _label; }

-(void)setTempThreadFace:(T2ThreadFace *)tempThreadFace { setObjectWithRetain(_tempThreadFace, tempThreadFace); }
-(T2ThreadFace *)tempThreadFace { return _tempThreadFace; }

-(void)setTabContentsDictionary:(NSDictionary *)tabContentsDictionary {
	
	setObjectWithRetain(_listInternalPathToSelect, [tabContentsDictionary objectForKey:@"listInternalPath"]);
	NSArray *threadInternalPaths = [tabContentsDictionary objectForKey:@"threadInternalPaths"];
	if (threadInternalPaths) {
		[_waitingThreadInternalPaths setArray:threadInternalPaths];
	}
	_tabIndexToSelect = [(NSNumber *)[tabContentsDictionary objectForKey:@"tabIndexToSelect"] intValue];
	
	if (_docWindow) {
		[self loadTabContents];
	}
}
-(NSDictionary *)tabContentsDictionary {
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	[dictionary setObject:[_bookmarkController selectedListInternalPath] forKey:@"listInternalPath"];
	
	NSMutableArray *internalPaths = [NSMutableArray array];
	NSArray *threads = [self threads];
	T2Thread *thread;
	NSEnumerator *threadEnumerator = [threads objectEnumerator];
	while (thread = [threadEnumerator nextObject]) {
		NSString *internalPath = [thread internalPath];
		if (internalPath)
			[internalPaths addObject:internalPath];
	}
	[dictionary setObject:internalPaths forKey:@"threadInternalPaths"];
	
	int tabIndex = [_tabView indexOfTabViewItem:[_tabView selectedTabViewItem]];
	NSNumber *tabIndexNumber = [NSNumber numberWithInt:tabIndex];
	[dictionary setObject:tabIndexNumber forKey:@"tabIndexToSelect"];
	
	return dictionary;
}
-(void)loadTabContents {

	if (_listInternalPathToSelect) {
		[_bookmarkController setSelectedListInternalPath:_listInternalPathToSelect];
		[_listInternalPathToSelect release];
		_listInternalPathToSelect = nil;
	}
	if ([_waitingThreadInternalPaths count] > 0) {
		
		NSMutableArray *newThreadControllers = [NSMutableArray array];
		NSEnumerator *internalPathEnumerator = [_waitingThreadInternalPaths objectEnumerator];
		NSString *internalPath;
		while (internalPath = [internalPathEnumerator nextObject]) {
			
			T2ThreadFace *threadFace = [T2ThreadFace threadFaceWithInternalPath:internalPath];
			T2Thread *thread = [threadFace thread];
			if (thread) {
				T2ThreadView *threadView = [[[T2ThreadView alloc] initWithFrame:[_tabView contentRect] frameName:nil groupName:nil] autorelease];
				[threadView setAutoresizingMask:(NSViewWidthSizable & NSViewHeightSizable)];
				
				THThreadController *threadController = [THThreadController threadControllerWithThreadView:threadView
																								   thread:thread
																								 document:self];
				
				
				[newThreadControllers addObject:threadController];
			}
		}
		[_waitingThreadInternalPaths removeAllObjects];
		if ([newThreadControllers count]>0) {
			[self addTabsForThreadControllers:newThreadControllers];
		}
	}
	if (_tabIndexToSelect > 0 && _tabIndexToSelect < [_tabView numberOfTabViewItems]) {
		[_tabView selectTabViewItemAtIndex:_tabIndexToSelect];
	}	
}

#pragma mark -
#pragma mark Internal Methods

-(THBookmarkController *)bookmarkController {
	return _bookmarkController;
}

-(NSArray *)threadFaces {
	NSMutableArray *resultArray = [NSMutableArray array];
	
	NSArray *tabViewItems = [[[_tabBarControl representedTabViewItems] copy] autorelease];
	NSEnumerator *tabViewItemEnumerator = [tabViewItems objectEnumerator];
	NSTabViewItem *tabViewItem;
	while (tabViewItem = [tabViewItemEnumerator nextObject]) {
		if (_listTab != tabViewItem) {
			[resultArray addObject:[[(THThreadController *)[tabViewItem identifier] thread] threadFace]];
		}
	}
	
	return [[resultArray copy] autorelease];	
}

-(NSArray *)threads {
	NSMutableArray *resultArray = [NSMutableArray array];
	
	NSArray *tabViewItems = [[[_tabBarControl representedTabViewItems] copy] autorelease];
	NSEnumerator *tabViewItemEnumerator = [tabViewItems objectEnumerator];
	NSTabViewItem *tabViewItem;
	while (tabViewItem = [tabViewItemEnumerator nextObject]) {
		if (_listTab != tabViewItem) {
			[resultArray addObject:[(THThreadController *)[tabViewItem identifier] thread]];
		}
	}
	
	return [[resultArray copy] autorelease];	
}
-(NSArray *)threadControllers {
	NSMutableArray *resultArray = [NSMutableArray array];
	
	NSArray *tabViewItems = [[[_tabBarControl representedTabViewItems] copy] autorelease];
	NSEnumerator *tabViewItemEnumerator = [tabViewItems objectEnumerator];
	NSTabViewItem *tabViewItem;
	while (tabViewItem = [tabViewItemEnumerator nextObject]) {
		if (_listTab != tabViewItem) {
			[resultArray addObject:[tabViewItem identifier]];
		}
	}
	
	return [[resultArray copy] autorelease];
}

-(THThreadController *)selectedThreadController {
	if (!_tabView) return nil;
	NSTabViewItem *tabViewItem = [_tabView selectedTabViewItem];
	if (tabViewItem == _listTab)
		return nil;
	return (THThreadController *)[tabViewItem identifier];
}

-(NSWindow *)docWindow {
	return _docWindow;
}



#pragma mark -
#pragma mark Tab Control Methods
-(void)loadThreadsForThreadFaces:(NSArray *)threadFaces activateTab:(BOOL)activateTab {
	if ([threadFaces count] > __maxWaitingCount) {
		threadFaces = [threadFaces subarrayWithRange:NSMakeRange(0, __maxWaitingCount)];
	}
	NSSet *availableThreadFaceSet;
	unsigned newMaxTabCount;
	NSArray *availableThreadFaces = [self threadFaces];
	if (availableThreadFaces && [availableThreadFaces count]>0 ) {
		availableThreadFaceSet = [NSSet setWithArray:availableThreadFaces];
		NSMutableSet *newThreadFaceSet = [NSMutableSet setWithArray:threadFaces];
		[newThreadFaceSet minusSet:availableThreadFaceSet];
		newMaxTabCount = [newThreadFaceSet count];
	} else {
		availableThreadFaceSet = [NSSet set];
		newMaxTabCount = [threadFaces count];
	}
	if (_maxTabCount < newMaxTabCount) {
		_maxTabCount = newMaxTabCount;
	}
	
	NSMutableArray *newThreadControllers = [NSMutableArray array];
	NSEnumerator *threadFacesEnumerator = [threadFaces objectEnumerator];
	T2ThreadFace *threadFace;
	BOOL first = YES;
	while (threadFace = [threadFacesEnumerator nextObject]) {
		
		T2Thread *thread = [threadFace thread];
		if (thread) {
			[(T2ThreadHistory *)[T2ThreadHistory threadHistoryForKey:@"threadHistory"] addHistory:threadFace];
			
			if (![availableThreadFaceSet containsObject:threadFace]) {
				T2ThreadView *threadView = [[[T2ThreadView alloc] initWithFrame:[_tabView contentRect] frameName:nil groupName:nil] autorelease];
				[threadView setAutoresizingMask:(NSViewWidthSizable & NSViewHeightSizable)];
				
				THThreadController *threadController = [THThreadController threadControllerWithThreadView:threadView
																								   thread:thread
																								 document:self];
				
				
				[newThreadControllers addObject:threadController];
			} 
			if (first && [_waitingThreadInternalPaths count] == 0) {
				[thread load];
			} else {
				[_waitingThreadInternalPaths addObject:[threadFace internalPath]];
			}
			first = NO;
		}
		
	}
	if ([newThreadControllers count]>0) {
		[self addTabsForThreadControllers:newThreadControllers];
	}
	
	if ([_waitingThreadInternalPaths count] > 0 && !_waitingTimer) {
		_waitingTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0
														  target:self
														selector:@selector(waitingTimerFired:)
														userInfo:nil
														 repeats:YES] retain];
	}
	
	if (activateTab) {
		T2ThreadFace *firstThreadFace = [threadFaces objectAtIndex:0];
		[self selectTabForThread:[firstThreadFace thread]];
	}
}
-(void)loadThreadForThreadFace:(T2ThreadFace *)threadFace activateTab:(BOOL)activateTab {
	[self loadThreadsForThreadFaces:[NSArray arrayWithObject:threadFace]
						activateTab:activateTab];
}

-(void)waitingTimerFired:(NSTimer *)timer {
	if (timer != _waitingTimer) {
		[timer invalidate];
		return;
	}
	if ([_waitingThreadInternalPaths count] <= 0) {
		[_waitingTimer invalidate];
		[_waitingTimer autorelease];
		_waitingTimer = nil;
	} else {
		NSString *internalPath = [_waitingThreadInternalPaths objectAtIndex:0];
		T2Thread *thread = [T2Thread availableObjectWithInternalPath:internalPath];
		if (thread) {
			[thread load];
		}
		[_waitingThreadInternalPaths removeObjectAtIndex:0];
	}
}
/*
 -(void)loadThread:(T2Thread *)thread {
 
 T2ThreadView *threadView = [[[T2ThreadView alloc] initWithFrame:[_tabView contentRect] frameName:nil groupName:nil] autorelease];
 [threadView setAutoresizingMask:(NSViewWidthSizable & NSViewHeightSizable)];
 
 THThreadController *threadController = [THThreadController threadControllerWithThreadView:threadView
 thread:thread
 document:self];
 
 [self addTabWithTitle:[[thread threadFace] title] threadController:threadController];
 if (__newTabAppearsInRightEnd)
 [self setSelectedTabIndex:[_threadControllers count]-1];
 else
 [self setSelectedTabIndex:0];
 }
 */
-(void)loadThread:(T2Thread *)thread resExtractedPath:(NSString *)path {
	
	T2ThreadView *threadView = [[[T2ThreadView alloc] initWithFrame:[_tabView contentRect] frameName:nil groupName:nil] autorelease];
	[threadView setAutoresizingMask:(NSViewWidthSizable & NSViewHeightSizable)];
	
	THThreadController *threadController = [THThreadController threadControllerWithThreadView:threadView
																					   thread:thread
																					 document:self];
	[threadView setResExtractPath:path];
	//[threadView displayThread];
	
	[_tabView selectTabViewItem:[self addTabForThreadController:threadController]];
}

-(void)loadThreadForURLString:(NSString *)URLString {
	NSString *internalPath = [[T2PluginManager sharedManager] threadInternalPathForProposedURLString:URLString];
	if (!internalPath) {
		internalPath = [[T2PluginManager sharedManager] listInternalPathForProposedURLString:URLString];
		if (!internalPath) return;
		
		// Board
		T2ListFace *listFace = [T2ListFace listFaceWithInternalPath:internalPath
															  title:nil image:nil];
		if (listFace) {
			[self openListWithListFace:listFace];
		}
		return;
	}
	// Thread
	T2ThreadFace *threadFace = [T2ThreadFace threadFaceWithInternalPath:internalPath];
	if (![threadFace title]) [threadFace setTitle:URLString];
	[self loadThreadForThreadFace:threadFace activateTab:YES];
	
	NSString *resExtractedPath = [[T2PluginManager sharedManager] resExtractPatnForProposedURLString:URLString];
	if (resExtractedPath) {
		[[self selectedThreadView] setResExtractPath:resExtractedPath];
	}
}

-(void)deleteLogFilesWithThreadFaces:(NSArray *)threadFaces {
	NSEnumerator *threadFacesEnumerator = [threadFaces objectEnumerator];
	T2ThreadFace *threadFace;
	
	int myTag = 0;
	BOOL didMove;
	
	//NSMutableArray *threadsWillRemove = [NSMutableArray array];
	
	while (threadFace = [threadFacesEnumerator nextObject]) {
		T2Thread *thread = [T2Thread availableObjectWithInternalPath:[threadFace internalPath]];
		if (thread) {
			[THDocument removeTabsForThreads:[NSArray arrayWithObject:thread]];
		}
		
		// thread List
		NSString *threadListHolderPath = [[threadFace internalPath] stringByDeletingLastPathComponent];
		T2ThreadList *threadList = [T2ThreadList objectWithInternalPath:threadListHolderPath];
		if (threadList && [threadList isKindOfClass:[T2ThreadList class]]) {
			int state = [threadFace state];
			if (state == T2ThreadFaceStateFallen) {
				[threadFace setState:T2ThreadFaceStateFallenNoLog];
				[threadList removeObject:threadFace];
			} else {
				[threadFace setState:T2ThreadFaceStateNone];
			}
		}
		
		[threadFace setExtraInfo:nil];
	}
	
	if ([threadFaces count] <= 5) {
		threadFacesEnumerator = [threadFaces objectEnumerator];
		while (threadFace = [threadFacesEnumerator nextObject]) {
			[threadFace recycleThreadLogFile];
		}
	} else {
		T2Operation *operation = [T2RecycleThreadLogFilesOperation recycleThreadLogFilesOperationWithThreadFaces:threadFaces];
		[operation start];
	}
}

-(T2ThreadView *)selectedThreadView {
	return [[self selectedThreadController] threadView];
}

-(void)addTabsForThreadControllers:(NSArray *)threadControllers {
	unsigned newCount = [threadControllers count];
	if (newCount > _maxTabCount) {
		_maxTabCount = newCount;
	}
	NSEnumerator *threadControllerEnumerator = [threadControllers objectEnumerator];
	THThreadController *threadController;
	while (threadController = [threadControllerEnumerator nextObject]) {
		[self addTabForThreadController:threadController];
	}
}
-(NSTabViewItem *)addTabForThreadController:(THThreadController *)threadController {
	//[self addTabsForThreadControllers:[NSArray arrayWithObject:threadController]];
	NSArray *tabViewItems = [[[_tabBarControl representedTabViewItems] copy] autorelease];
	unsigned tabCount = [tabViewItems count];
	unsigned listTabIndex = [tabViewItems indexOfObjectIdenticalTo:_listTab];
	if (listTabIndex == NSNotFound) return nil;
	NSTabViewItem *newTabViewItem = [[[NSTabViewItem alloc] initWithIdentifier:threadController] autorelease];
	NSString *title = [[threadController thread] title];
	if (!title) {
		title = THDocLocalize(@"Untitled");
	}
	[newTabViewItem setLabel:title];
	[newTabViewItem setView:[threadController threadView]];
	
	if (__newTabAppearsInRightEnd) {
		if ((tabCount-listTabIndex >= _maxTabCount+1) && (listTabIndex+1 < tabCount)) {
			[_tabView removeTabViewItem:[tabViewItems objectAtIndex:listTabIndex+1]];
		}
		[_tabView addTabViewItem:newTabViewItem];
	} else {
		if ((tabCount-listTabIndex >= _maxTabCount+1) && (listTabIndex+1 < tabCount)) {
			[_tabView removeTabViewItem:[tabViewItems lastObject]];
		}
		[_tabView insertTabViewItem:newTabViewItem atIndex:listTabIndex+1];
	}
	return newTabViewItem;
}

+(void)removeTabsForThreads:(NSArray *)threads {
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	NSEnumerator *documentEnumerator = [documents objectEnumerator];
	THDocument *document;
	while (document = [documentEnumerator nextObject]) {
		[document removeTabsForThreads:threads];
	}
}

-(void)removeTabsForThreads:(NSArray *)threads {
	NSEnumerator *threadEnumerator = [threads objectEnumerator];
	T2Thread *thread;
	while (thread = [threadEnumerator nextObject]) {
		THPostingWindowController *resPostingWindowController = [THPostingWindowController availableResPostingWindowForThread:thread];
		if (resPostingWindowController) {
			[resPostingWindowController close];
		}
		
		NSArray *tabViewItems = [[[_tabBarControl representedTabViewItems] copy] autorelease];
		NSEnumerator *tabViewItemEnumerator = [tabViewItems objectEnumerator];
		NSTabViewItem *tabViewItem;
		while (tabViewItem = [tabViewItemEnumerator nextObject]) {
			if (tabViewItem != _listTab) {
				if (thread == [(THThreadController *)[tabViewItem identifier] thread]) {
					[_tabView removeTabViewItem:tabViewItem];
				}
			}
		}
	}
}

-(void)removeTabViewItemAtIndex:(unsigned)index {
	NSArray *tabViewItems = [[[_tabBarControl representedTabViewItems] copy] autorelease];
	if (index < [tabViewItems count]) {
		NSTabViewItem *tabViewItem = [tabViewItems objectAtIndex:index];
		if (tabViewItem != _listTab) {
			[_tabView removeTabViewItem:tabViewItem];
		}
	}
	
}
-(void)removeTabAtEnd {
	NSArray *tabViewItems = [[[_tabBarControl representedTabViewItems] copy] autorelease];
	unsigned tabCount = [tabViewItems count];
	unsigned listTabIndex = [tabViewItems indexOfObjectIdenticalTo:_listTab];
	if (listTabIndex == NSNotFound) return;
	
	if (__newTabAppearsInRightEnd) {
		if (listTabIndex+1 < tabCount) {
			[_tabView removeTabViewItem:[tabViewItems objectAtIndex:listTabIndex+1]];
		}
	} else {
		if (listTabIndex+1 < tabCount) {
			[_tabView removeTabViewItem:[tabViewItems lastObject]];
		}
	}
}

-(void)displayTabTitleOfThreadController:(THThreadController *)threadController {
	NSArray *tabViewItems = [[[_tabBarControl representedTabViewItems] copy] autorelease];
	NSEnumerator *tabViewItemEnumerator = [tabViewItems objectEnumerator];
	NSTabViewItem *tabViewItem;
	while (tabViewItem = [tabViewItemEnumerator nextObject]) {
		if (tabViewItem != _listTab) {
			if (threadController == [tabViewItem identifier]) {
				[tabViewItem setLabel:[[threadController thread] title]];
				if ([self selectedThreadController] == threadController) {
					[_docWindow setTitle:[[threadController thread] title]];
				}
			}
		}
	}
}
-(void)displayURLString:(NSString *)aString {
	if (!aString)
		aString = @"";
	if (_urlField)
		[_urlField setStringValue:aString];
}

-(void)selectTabForThread:(T2Thread *)thread {
	NSArray *tabViewItems = [[[_tabBarControl representedTabViewItems] copy] autorelease];
	NSEnumerator *tabViewItemEnumerator = [tabViewItems objectEnumerator];
	NSTabViewItem *tabViewItem;
	while (tabViewItem = [tabViewItemEnumerator nextObject]) {
		if (tabViewItem != _listTab) {
			if (thread == [(THThreadController *)[tabViewItem identifier] thread]) {
				[_tabView selectTabViewItem:tabViewItem];
				break;
			}
		}
	}	
}

#pragma mark -
#pragma mark NSTabView and PSMTabBarControl delegate methods

- (BOOL)tabView:(NSTabView *)tabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem {
	if (tabViewItem == _listTab)
		return NO;
	return YES;
}

- (void)tabView:(NSTabView *)tabView willCloseTabViewItem:(NSTabViewItem *)tabViewItem {
	if ([_tabView selectedTabViewItem] != tabViewItem) return;
	
	NSArray *tabViewItems = [[[_tabBarControl representedTabViewItems] copy] autorelease];
	unsigned index = [tabViewItems indexOfObjectIdenticalTo:tabViewItem];
	if (index == NSNotFound || index+1 >= [tabViewItems count]) return;
	
	[_tabView selectTabViewItem:[tabViewItems objectAtIndex:index+1]];
}

- (void)tabViewDidChangeNumberOfTabViewItems:(NSTabView *)tabView {
	if ([[_tabView tabViewItems] count]>1)
		[[THAppDelegate sharedInstance] setKeyEquivalentForMultipleTabs:YES];
	else
		[[THAppDelegate sharedInstance] setKeyEquivalentForMultipleTabs:NO];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	NSString *searchString;
	
	if (tabViewItem == _listTab) {
		T2List *browsingList = [_bookmarkController browsingList];
		[self setProgressProvider:browsingList];
		if (browsingList) {
			searchString = [[T2PluginManager sharedManager] searchStringForList:browsingList];
			if (!searchString) {
				searchString = [_bookmarkController filterSearchString];
			}
			if (searchString) [_searchField setStringValue:searchString];
		} else {
			[_searchField setStringValue:@""];
		}
		
		[_bookmarkController updateLabelButton];
		T2ThreadList *threadList = [_bookmarkController threadList];
		NSString *urlString = [threadList webBrowserURLString];
		if (urlString) {
			[_urlField setStringValue:urlString];
		} else {
			[_urlField setStringValue:@""];
		}
		
		if (threadList && [threadList title]) {
			[_docWindow setTitle:[threadList title]];
		} else {
			[_docWindow setTitle:NSLocalizedString(@"Thousand", nil)];
		}
	} else {
		THThreadController *threadController = [tabViewItem identifier];
		[self setProgressProvider:[threadController thread]];
		[threadController updateLabelButton];
		[threadController updateThreadMenu];
		[[_searchField cell] setSendsWholeSearchString:YES];
		searchString = [threadController filterSearchString];
		if (searchString) [_searchField setStringValue:searchString];
		
		NSString *urlString = [[threadController thread] webBrowserURLString];
		if (urlString) {
			[_urlField setStringValue:urlString];
		} else {
			[_urlField setStringValue:@""];
		}
		
		[_docWindow setTitle:[tabViewItem label]];
		[_docWindow makeFirstResponder:[threadController threadView]];
	}
	[T2PopUpWindowController closeAllPopUp];
	[self updateMenu];
}

#pragma mark -
#pragma mark NSToolBar delegate methods
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
	NSMutableArray *array = [NSMutableArray arrayWithObjects:
							 THDocShowPrefItemIdentifier,
							 THDocShowBookmarkItemIdentifier,
							 
							 THDocAddBookmarkItemIdentifier,
							 THDocReloadItemIdentifier,
							 THDocWriteItemIdentifier,
							 THDocWriteThreadItemIdentifier,
							 THDocDeleteItemIdentifier,
							 THDocDeleteSpecialItemIdentifier,
							 
							 THDocLoadNextItemIdentifier,
							 THDocDownloadWindowItemIdentifier,
							 
							 THDocLeftTabItemIdentifier,
							 THDocRightTabItemIdentifier,
							 THDocCloseTabItemIdentifier,
							 
							 THDocLabelPopUpItemIdentifier,
							 THDocRangePopUpItemIdentifier,
							 
							 THDocSearchFieldItemIdentifier,
							 THDocURLFieldItemIdentifier,
							 nil];
	
	if (__oreyonPath)
		[array addObject:THDocOpenWithOreyonItemIdentifier];
	
	[array addObjectsFromArray:[NSArray arrayWithObjects:
								NSToolbarSeparatorItemIdentifier,
								NSToolbarSpaceItemIdentifier,
								NSToolbarFlexibleSpaceItemIdentifier,
								NSToolbarCustomizeToolbarItemIdentifier, nil]];
	
	return array;
}
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
	return [NSArray arrayWithObjects:
			THDocShowPrefItemIdentifier,
			
			NSToolbarSeparatorItemIdentifier,
			
			THDocReloadItemIdentifier,
			THDocDeleteItemIdentifier,
			THDocWriteItemIdentifier,
			THDocAddBookmarkItemIdentifier,
			THDocLabelPopUpItemIdentifier,
			THDocRangePopUpItemIdentifier,
			
			NSToolbarSeparatorItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			
			THDocSearchFieldItemIdentifier,
			nil];
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier: (NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag {
	// Create toolbar item
	NSToolbarItem *tempItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
	[tempItem setTarget:nil];
	
	// Get label, image, and action
	NSString*   label = nil;
	NSImage*    image = nil;
	SEL         action = NULL;
	NSString*   paletteLabel = nil;
	
	// Pref, Bookmark, add, Load
	if ([itemIdentifier isEqualToString:THDocShowPrefItemIdentifier]) {
		label = THDocToolBarLocalize(@"Preference");
		image = [NSImage imageNamed:@"TH32_PrefPane"];
		action = @selector(showPrefWindow:);
	}
	
	else if ([itemIdentifier isEqualToString:THDocShowBookmarkItemIdentifier]) {
		label = THDocToolBarLocalize(@"List");
		image = [NSImage imageNamed:@"TH32_BookmarkView"];
		action = @selector(showListTab:);
	}
	else if ([itemIdentifier isEqualToString:THDocLeftTabItemIdentifier]) {
		label = THDocToolBarLocalize(@"Left Tab");
		image = [NSImage imageNamed:@"TH32_Left"];
		action = @selector(switchToLeftTab:);
	}
	else if ([itemIdentifier isEqualToString:THDocRightTabItemIdentifier]) {
		label = THDocToolBarLocalize(@"Right Tab");
		image = [NSImage imageNamed:@"TH32_Right"];
		action = @selector(switchToRightTab:);
	}
	else if ([itemIdentifier isEqualToString:THDocCloseTabItemIdentifier]) {
		label = THDocToolBarLocalize(@"Close Tab");
		image = [NSImage imageNamed:@"TH32_CloseTab"];
		action = @selector(closeTab:);
	}
	
	else if ([itemIdentifier isEqualToString:THDocAddBookmarkItemIdentifier]) {
		label = THDocToolBarLocalize(@"Add Bookmark");
		image = [NSImage imageNamed:@"TH32_AddBookmark"];
		action = @selector(addToBookmark:);
	}
	else if ([itemIdentifier isEqualToString:THDocReloadItemIdentifier]) {
		label = THDocToolBarLocalize(@"Reload");
		image = [NSImage imageNamed:@"TH32_Reload"];
		action = @selector(reloadView:);
	}
	else if ([itemIdentifier isEqualToString:THDocDeleteItemIdentifier]) {
		label = THDocToolBarLocalize(@"Delete");
		image = [NSImage imageNamed:@"TH32_Delete"];
		action = @selector(removeSelectedThreads:);
	}
	else if ([itemIdentifier isEqualToString:THDocDeleteSpecialItemIdentifier]) {
		label = THDocToolBarLocalize(@"Delete Fallen Threads...");
		image = [NSImage imageNamed:@"TH32_DeleteSpecial"];
		action = @selector(removeFallenThreads:);
	}
	else if ([itemIdentifier isEqualToString:THDocWriteItemIdentifier]) {
		label = THDocToolBarLocalize(@"Write Message...");
		image = [NSImage imageNamed:@"TH32_Write"];
		action = @selector(postRes:);
	}
	else if ([itemIdentifier isEqualToString:THDocWriteThreadItemIdentifier]) {
		label = THDocToolBarLocalize(@"New Thread...");
		image = [NSImage imageNamed:@"TH32_WriteThread"];
		action = @selector(postThread:);
	}
	else if ([itemIdentifier isEqualToString:THDocLoadNextItemIdentifier]) {
		label = THDocToolBarLocalize(@"Next Updated Thread");
		image = [NSImage imageNamed:@"TH32_LoadNext"];
		action = @selector(openNextUpdatedThread:);
	}
	else if ([itemIdentifier isEqualToString:THDocDownloadWindowItemIdentifier]) {
		label = THDocToolBarLocalize(@"Download");
		image = [NSImage imageNamed:@"TH32_Download"];
		action = @selector(showDownloadWindow:);
	}
	// Label Selector
	else if ([itemIdentifier isEqualToString:THDocLabelPopUpItemIdentifier]) {
		tempItem = [[[THImagePopUpToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
		[tempItem setTarget:nil];
		
		label = THDocToolBarLocalize(@"Label");
		[tempItem setView:_labelButton];
		
		[tempItem setMaxSize:(NSSize){40,32}];
		[tempItem setMinSize:(NSSize){40,24}];
	}
	// Range Selector
	else if ([itemIdentifier isEqualToString:THDocRangePopUpItemIdentifier]) {
		tempItem = [[[THImagePopUpToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
		[tempItem setTarget:nil];
		
		label = THDocToolBarLocalize(@"Action");
		[tempItem setView:_actionButton];
		
		[tempItem setMaxSize:(NSSize){64,32}];
		[tempItem setMinSize:(NSSize){64,24}];
	}
	// Search Field
	else if ([itemIdentifier isEqualToString:THDocSearchFieldItemIdentifier]) {
		label = THDocToolBarLocalize(@"Search");
		[tempItem setView:_searchField];
		
		[tempItem setMaxSize:(NSSize){200,32}];
		[tempItem setMinSize:(NSSize){64,22}];
	}
	// URL Field
	else if ([itemIdentifier isEqualToString:THDocURLFieldItemIdentifier]) {
		label = THDocToolBarLocalize(@"URL");
		[tempItem setView:_urlField];
		
		[tempItem setMaxSize:(NSSize){1024,32}];
		[tempItem setMinSize:(NSSize){64,22}];
	}
	
	else if ([itemIdentifier isEqualToString:THDocOpenWithOreyonItemIdentifier]) {
		label = THDocToolBarLocalize(@"Oreyon");
		image = [[NSWorkspace sharedWorkspace] iconForFile:__oreyonPath];
		action = @selector(openUsingOreyon:);
	}
	// Set item attributes
	if (label) [tempItem setLabel:label];
	if (image) [tempItem setImage:image];
	if (action) [tempItem setAction:action];
	if (paletteLabel) [tempItem setPaletteLabel:paletteLabel];
	else if (label) [tempItem setPaletteLabel:label];
	return tempItem;	
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object 
                        change:(NSDictionary *)change
                       context:(void *)context {
	if (context == THDocToolBarIdentifier) {
		
		NSToolbarSizeMode sizeMode = [_toolbar sizeMode];
		
		NSArray *toolbarItems = [_toolbar items];
		NSEnumerator *toolbarItemEnumerator = [toolbarItems objectEnumerator];
		NSToolbarItem *toolbarItem;
		while (toolbarItem = [toolbarItemEnumerator nextObject]) {
			NSView *view = [toolbarItem view];
			if (view && [view isKindOfClass:[THImagePopUpButton class]]) {
				NSSize size = [toolbarItem minSize];
				if (sizeMode == NSToolbarSizeModeDefault || sizeMode == NSToolbarSizeModeRegular) {
					size.height = 32;
				} else if (sizeMode == NSToolbarSizeModeSmall) {
					size.height = 24;
				}
				[toolbarItem setMinSize:size];
				//[view setFrameSize:size];
			}
		}
	}
}

#pragma mark -
#pragma mark NSWindow Delegate Methods
- (void)windowWillClose:(NSNotification *)notification {
	NSArray *tabViewItems = [[_tabView tabViewItems] copy];
	NSEnumerator *tabViewItemENumerator = [tabViewItems objectEnumerator];
	NSTabViewItem *tabViewItem;
	while (tabViewItem = [tabViewItemENumerator nextObject]) {
		if (_listTab != tabViewItem) {
			[_tabView removeTabViewItem:tabViewItem];
		}
	}
	[tabViewItems release];
	[self setProgressProvider:nil];
}

- (void)windowDidResize:(NSNotification *)aNotification {
	if (_docWindowSizeLoaded) [_docWindow saveFrameUsingName:@"docWindow"];
}
- (void)windowDidMove:(NSNotification *)notification {
	if (_docWindowSizeLoaded) [_docWindow saveFrameUsingName:@"docWindow"];
}


#pragma mark -
#pragma mark UI Validation and Action Forwarding

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem {
	return [self validateUIOfAction:[(NSMenuItem *)menuItem action]];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
	if ([[theItem itemIdentifier] isEqualToString:THDocLabelPopUpItemIdentifier]) {
		THThreadController *threadController = [self selectedThreadController];
		int label;
		if (threadController) {
			label = [[[threadController thread] threadFace] label];
		} else {
			label = [_bookmarkController labelOfSelectedThreadFaces];
		}
		[(THLabelButton *)[theItem view] setLabel:label];
	}
	return [self validateUIOfAction:[theItem action]];
}

- (BOOL)validateUIOfAction:(SEL)action {
	NSTabViewItem *tabViewItem = [_tabView selectedTabViewItem];
	
	if (action == @selector(showListTab:)) {
		NSArray *tabViewItems = [_tabBarControl representedTabViewItems];
		if ([tabViewItems indexOfObjectIdenticalTo:tabViewItem] == 0)
			return NO;
		
	} else if (action == @selector(closeTab:)) {
		if ([[_tabView tabViewItems] count]==0) return NO;
	} else if (action == @selector(switchToRightTab:)) {
			
		NSArray *tabViewItems = [_tabBarControl representedTabViewItems];
		if ([tabViewItems lastObject] == tabViewItem)
			return NO;
	} else if (action == @selector(moveTabToRightEnd:)) {
		
		if (tabViewItem == _listTab)
			return NO;
		NSArray *tabViewItems = [_tabBarControl representedTabViewItems];
		if (__newTabAppearsInRightEnd) {
			if ([tabViewItems lastObject] == tabViewItem)
				return NO;
		} else {
			if ([tabViewItems indexOfObjectIdenticalTo:tabViewItem] == [tabViewItems indexOfObjectIdenticalTo:_listTab]+1) {
				return NO;
			}
		}
	}
	
	THThreadController *threadController = [self selectedThreadController];
	if (threadController)
		return [threadController validateUIOfAction:action];
	return [_bookmarkController validateUIOfAction:action];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
	if ([super respondsToSelector:aSelector]) return YES;
	
	THThreadController *threadController = [self selectedThreadController];
	if (threadController)
		return [threadController respondsToSelector:aSelector];
	return [_bookmarkController respondsToSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
	THThreadController *threadController = [self selectedThreadController];
	if (threadController)
		[anInvocation invokeWithTarget:threadController];
	else
		[anInvocation invokeWithTarget:_bookmarkController];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
	if ([super respondsToSelector:aSelector]) return [super methodSignatureForSelector:aSelector];
	
	THThreadController *threadController = [self selectedThreadController];
	if (threadController)
		return [threadController methodSignatureForSelector:aSelector];
	return [_bookmarkController methodSignatureForSelector:aSelector];
}

/*
 - (void)windowDidBecomeMain:(NSNotification *)aNotification {
 [self updateMenu];
 }
 */
-(void)updateMenu {
	
	THThreadController *threadController = [self selectedThreadController];
	if (threadController) {
		[[THAppDelegate sharedInstance] setThreadResStyleMenuTitle:
		 [NSString stringWithFormat:NSLocalizedString(@"Style of %@", @"app")
		  ,[[T2PluginManager sharedManager] localizedDescriptionOfExtractPath:
			[[threadController threadView] resExtractPath]]]
														   enabled:YES];
	} else {
		[[THAppDelegate sharedInstance] setThreadResStyleMenuTitle:NSLocalizedString(@"Style", @"doc")
														   enabled:NO];
		T2List *browsingRootList = [_bookmarkController browsingRootList];
		T2List *threadList = [_bookmarkController threadList];
		BOOL setShowArchiveMenuItemIsDefault = YES;
		if (browsingRootList && threadList) {
			if ([[browsingRootList internalPath] hasPrefix:[threadList internalPath]]) {
				setShowArchiveMenuItemIsDefault = NO;
			}
		}
		[[THAppDelegate sharedInstance] setShowArchiveMenuItemIsDefault:setShowArchiveMenuItemIsDefault];
	}
	
	if ([[_tabView tabViewItems] count]>1)
		[[THAppDelegate sharedInstance] setKeyEquivalentForMultipleTabs:YES];
	else
		[[THAppDelegate sharedInstance] setKeyEquivalentForMultipleTabs:NO];
}

#pragma mark -
#pragma mark Methods
-(void)openListWithListFace:(T2ListFace *)listFace {
	[_bookmarkController openListWithListFace:listFace];
	[_tabView selectTabViewItem:_listTab];
}

#pragma mark -
#pragma mark Actions
#pragma mark Tab Actions

-(IBAction)showListTab:(id)sender {
	[_tabView selectTabViewItem:_listTab];
}
-(IBAction)switchToLeftTab:(id)sender {
	NSArray *tabViewItems = [[[_tabBarControl representedTabViewItems] copy] autorelease];
	unsigned index = [tabViewItems indexOfObjectIdenticalTo:[_tabView selectedTabViewItem]];
	if (index == 0) return;
	[_tabView selectTabViewItem:[tabViewItems objectAtIndex:index-1]];
}
-(IBAction)switchToRightTab:(id)sender {
	NSArray *tabViewItems = [[[_tabBarControl representedTabViewItems] copy] autorelease];
	unsigned index = [tabViewItems indexOfObjectIdenticalTo:[_tabView selectedTabViewItem]];
	if (index+1 >= [tabViewItems count]) return;
	[_tabView selectTabViewItem:[tabViewItems objectAtIndex:index+1]];
}
-(IBAction)closeTab:(id)sender {
	NSTabViewItem *tabViewItem = [_tabView selectedTabViewItem];
	if (tabViewItem != _listTab) {
		
		NSArray *tabViewItems = [[[_tabBarControl representedTabViewItems] copy] autorelease];
		unsigned index = [tabViewItems indexOfObjectIdenticalTo:tabViewItem];
		if (!(index == NSNotFound || index+1 >= [tabViewItems count]))
			[_tabView selectTabViewItem:[tabViewItems objectAtIndex:index+1]];
		[_tabView removeTabViewItem:tabViewItem];
		
		if (_maxTabCount > __maxTabCount) {
			--_maxTabCount;
		}
	}
}
-(IBAction)moveTabToRightEnd:(id)sender {
	NSTabViewItem *tabViewItem = [_tabView selectedTabViewItem];
	if (tabViewItem != _listTab) {
		NSArray *tabViewItems = [[[_tabBarControl representedTabViewItems] copy] autorelease];
		unsigned listTabIndex = [tabViewItems indexOfObjectIdenticalTo:_listTab];
		if (listTabIndex == NSNotFound) return;
		
		[tabViewItem retain];
		[_tabView removeTabViewItem:tabViewItem];
		if (__newTabAppearsInRightEnd) {
			[_tabView addTabViewItem:tabViewItem];
		} else {
			[_tabView insertTabViewItem:tabViewItem atIndex:listTabIndex+1];
		}
		[tabViewItem autorelease];
	}
}

#pragma mark -
#pragma mark Document Actions

-(IBAction)activateSearchField:(id)sender {
	NSArray *visibleItems = [_toolbar visibleItems];
	NSEnumerator *visibleItemEnumerator = [visibleItems objectEnumerator];
	NSToolbarItem *toolbarItem;
	while (toolbarItem = [visibleItemEnumerator nextObject]) {
		if ([[toolbarItem itemIdentifier] isEqualToString:THDocSearchFieldItemIdentifier]) {
			[_docWindow makeFirstResponder:[toolbarItem view]];
			return;
		}
	}
	
	if ([_docWindow attachedSheet]) return;
	[THInputWindowController beginSearchInputSheetForWindow:_docWindow defaultString:[_searchField stringValue]
												   delegate:self selector:@selector(didEndSearchInputSheetWithString:)];
}
-(void)didEndSearchInputSheetWithString:(NSString *)string {
	if (!string || [string length]==0) {
		[self clearSearch:nil];
	} else {
		[_searchField setStringValue:string];
		[self search:nil];
	}
}
-(IBAction)search:(id)sender {
	NSString *stringForSearch = [_searchField stringValue];
	THThreadController *threadController = [self selectedThreadController];
	if (threadController) {
		[threadController searchString:stringForSearch];
	} else {
		[_bookmarkController searchString:stringForSearch];
	}
}
-(IBAction)clearSearch:(id)sender {
	[_searchField setStringValue:@""];
	[self search:sender];
}

-(IBAction)openURL:(id)sender {
	
	NSArray *visibleItems = [_toolbar visibleItems];
	NSEnumerator *visibleItemEnumerator = [visibleItems objectEnumerator];
	NSToolbarItem *toolbarItem;
	while (toolbarItem = [visibleItemEnumerator nextObject]) {
		if ([[toolbarItem itemIdentifier] isEqualToString:THDocURLFieldItemIdentifier]) {
			[_docWindow makeFirstResponder:[toolbarItem view]];
			return;
		}
	}	
	
	if ([_docWindow attachedSheet]) return;
	[THInputWindowController beginURLOpenSheetForWindow:_docWindow defaultString:nil
											   delegate:self selector:@selector(didEndURLOpenSheetWithString:)];
}
-(void)didEndURLOpenSheetWithString:(NSString *)string {
	if (!string || [string length]==0) return;
	[self loadThreadForURLString:string];
}

-(IBAction)loadURL:(id)sender {
	if (_urlField == sender) {
		NSString *URLString = [_urlField stringValue];
		if (!URLString || [URLString length]==0) return;
		[self loadThreadForURLString:URLString];
	}
}

-(IBAction)openNextThread:(id)sender { [_bookmarkController openNextThread:sender]; }
-(IBAction)openNextUpdatedThread:(id)sender { [_bookmarkController openNextUpdatedThread:sender]; }

-(IBAction)dammyAction:(id)sender {}

-(IBAction)writeScreenShot:(id)sender {
	
	NSString *fileName = [NSString stringWithFormat:@"Thousand%d.jpg", NSTimeIntervalSince1970];
	NSString *filePath = [[THDownloadWindowController classDownloadDestinationFolderPath] stringByAppendingPathComponent:fileName];
	[_docWindow writeWindowImageToJPEGFile:filePath
						 compressionFactor:0.5];
}

-(IBAction)runTestOperation:(id)sender {
	THTestOperation *operation = [[[THTestOperation alloc] init] autorelease];
	[operation start];
}
@end
