/* THPostingWindowController.m */

#import "THPostingWindowController.h"
#import "T2PluginPrefView.h"
#import "THSplitView.h"
#import "THAppDelegate.h"

#define THPostingLocalize(string)	(NSLocalizedString(string, @"Posting"))

//static NSMutableSet *__instances = nil;
static NSMutableDictionary *__postingWindowControllerForInternalPath;
static NSMutableArray *__usedNames;
static NSMutableArray *__usedMails;

static NSMutableDictionary *__usedNamesDictionary;
static NSMutableDictionary *__usedMailsDictionary;

@implementation THPostingWindowController

#pragma mark -
#pragma mark Class
+(void)initialize {
	if (__postingWindowControllerForInternalPath) return;
	__postingWindowControllerForInternalPath = [[NSMutableDictionary mutableDictionaryWithoutRetainingValues] retain];
	__usedNames = [[NSMutableArray alloc] init];
	__usedMails = [[NSMutableArray alloc] init];
	
	__usedNamesDictionary = [[NSMutableDictionary alloc] init];
	__usedMailsDictionary = [[NSMutableDictionary alloc] init];
}

+(void)setClassUsedNames:(NSArray *)array {
	[__usedNames setArray:array];
}
+(NSArray *)classUsedNames { return __usedNames; }

+(void)setClassUsedMails:(NSArray *)array {
	[__usedMails setArray:array];
}
+(NSArray *)classUsedMails { return __usedMails; }

#pragma mark -
#pragma mark init

+(id)availableResPostingWindowForThread:(T2Thread *)thread {
	if (!thread || ![thread internalPath]) return nil;
	return [__postingWindowControllerForInternalPath objectForKey:[thread internalPath]];
}

+(id)resPostingWindowForThread:(T2Thread *)thread content:(NSString *)content {
	return [[[self alloc] initResPostingWindowForThread:thread content:content] autorelease];
}
+(id)threadPostingWindowForThreadList:(T2ThreadList *)threadList {
	return [[[self alloc] initThreadPostingWindowForThreadList:threadList] autorelease];
}

-(id)initResPostingWindowForThread:(T2Thread *)thread content:(NSString *)content {
	if (!thread || ![thread internalPath]) return nil;
	@synchronized(__postingWindowControllerForInternalPath) {
		THPostingWindowController *postingWindowController = [__postingWindowControllerForInternalPath objectForKey:[thread internalPath]];
		if (postingWindowController) {
			[self autorelease];
			if (content) {
				[postingWindowController appendContent:content];
			}
			[[postingWindowController window] makeKeyAndOrderFront:nil];
			return [postingWindowController retain];
		}
		self = [self initWithWindowNibName:@"THPostingWindow"];
		[__postingWindowControllerForInternalPath setObject:self forKey:[thread internalPath]];
	}
	_thread = [thread retain];
	if (content) {
		_content = [content retain];
	} else {
		_content = [[thread draft] retain];
	}
	
	// set posting or plugin
	T2Res *res = [T2Res resWithResNumber:0
									name:nil
									mail:nil
									date:nil
							  identifier:nil
								 content:_content
								  thread:_thread];
	_posting = [[_thread postingWithRes:res] retain];
	if (_posting) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(postingStart:)
													 name:T2PostingDidStartLoadingNotification
												   object:_posting];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(postingEnd:)
													 name:T2PostingDidEndLoadingNotification
												   object:_posting];
	} else {
		id <T2ResPostingUsingWebView_v100> webPostingPlug = [[T2PluginManager sharedManager] webResPostingPluginForInternalPath:[thread internalPath]];
		if (webPostingPlug) 
			_webResPostingPlug = [webPostingPlug retain];
	}
	
	[self setShouldCascadeWindows:NO];
	
	[[self window] makeKeyAndOrderFront:nil];
	return self;
}

-(id)initThreadPostingWindowForThreadList:(T2ThreadList *)threadList {
	if (!threadList || ![threadList internalPath]) return nil;
	@synchronized(__postingWindowControllerForInternalPath) {
		THPostingWindowController *postingWindowController = [__postingWindowControllerForInternalPath objectForKey:[threadList internalPath]];
		if (postingWindowController) {
			[self autorelease];
			[[postingWindowController window] makeKeyAndOrderFront:nil];
			return [postingWindowController retain];
		}
		self = [self initWithWindowNibName:@"THPostingWindow"];
		[__postingWindowControllerForInternalPath setObject:self forKey:[threadList internalPath]];
	}
	_threadList = [threadList retain];
	
	//set posting or plugin
	T2Res *res = [T2Res resWithResNumber:0
									name:nil
									mail:nil
									date:nil
							  identifier:nil
								 content:_content
								  thread:_thread];
	_posting = [[_threadList postingWithFirstRes:res threadTitle:nil] retain];
	if (_posting) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(postingStart:)
													 name:T2PostingDidStartLoadingNotification
												   object:_posting];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(postingEnd:)
													 name:T2PostingDidEndLoadingNotification
												   object:_posting];
	} else {
		id <T2ThreadPostingUsingWebView_v100> webPostingPlug = [[T2PluginManager sharedManager] webThreadPostingPluginForInternalPath:[threadList internalPath]];
		if (webPostingPlug) 
			_webThreadPostingPlug = [webPostingPlug retain];
	}
	
	[self setShouldCascadeWindows:NO];
	
	[[self window] makeKeyAndOrderFront:nil];
	return self;
}

-(void)dealloc {
	/*
	@synchronized(__postingWindowControllerForInternalPath) {
		NSString *internalPath;
		if (_thread) internalPath = [_thread internalPath];
		else internalPath = [_threadList internalPath];
		if (internalPath)
			[__postingWindowControllerForInternalPath removeObjectForKey:internalPath];
	}
	[_webView setAllDelegate:nil];
	
	if (_is2ch) {
		[[self plugin] removeObserver:self forKeyPath:@"isViewerActive"];
		[[self plugin] removeObserver:self forKeyPath:@"isBeActive"];
	}
	 
	 */
	if (_webConnector) {
		[_webConnector cancelLoading];
		[_webConnector release];
		_webConnector = nil;
	}
	
	[_boardTextField release];
	
	[_posting release];
	[_content release];
	[_thread release];
	//[_resPostingPlug release];
	[_webResPostingPlug release];
	[_threadList release];
	//[_threadPostingPlug release];
	[_webThreadPostingPlug release];
	[super dealloc];
}


-(void)awakeFromNib {
	// plugin
	NSObject *plugin = nil;
	
	if (_posting) plugin = [[T2PluginManager sharedManager] postingPluginForInternalPath:[_posting internalPath]];
	
	//if (_resPostingPlug) plugin = _resPostingPlug;
	if (_webResPostingPlug) plugin = _webResPostingPlug;
	//else if (_threadPostingPlug) plugin = _threadPostingPlug;
	else if (_webThreadPostingPlug) plugin = _webThreadPostingPlug;
	
	// Window
	[[self window] setFrameUsingName:@"postingWindow"];
	_postingWindowSizeLoaded = YES;
	
	// Toolbar View Items
	/*
	[_2chViewerButton retain];
	[_BeButton retain];
	[_sageButton retain];
	 */
	[_boardTextField retain];
	
	// Bind Checkboxes to 2ch Plugin
	NSString *postableRootPath = [(NSObject <T2ResPosting_v100> *)plugin postableRootPath];
	if (postableRootPath && [postableRootPath isEqualToString:@"2ch BBS"]) {
		/*
		_objectController = [[NSObjectController alloc] initWithContent:plugin];
		[_2chViewerButton bind:@"value" toObject:_objectController
				   withKeyPath:@"content.isViewerActive" options:nil];
		[_BeButton bind:@"value" toObject:_objectController
			withKeyPath:@"content.isBeActive" options:nil];
		 */
		[plugin addObserver:self forKeyPath:@"isViewerActive" options:0 context:NULL];
		[plugin addObserver:self forKeyPath:@"isBeActive" options:0 context:NULL];
		[plugin addObserver:self forKeyPath:@"isP2Active" options:0 context:NULL];
		
		_is2ch = YES;
		[_pluginPrefView removeFromSuperview];
	} else {
		if ([plugin respondsToSelector:@selector(accessoryPreferenceItems)]) {
			NSArray *accessoryPreferenceItems = [plugin accessoryPreferenceItems];
			
			if (accessoryPreferenceItems) {
				[_pluginPrefView setPlugin:plugin];
				[_splitView setPositionAutosaveName:@"postingWindowSplitViewPosition"];
			} else {
				[_pluginPrefView removeFromSuperview];
			}
		} else {
			[_pluginPrefView removeFromSuperview];
		}
	}		
	
	
	// WebView
	[_webView setThousandPostingWebViewDefaultAttributes];
	[_webView setAllDelegate:self];
	
	// PluginPrefView
	NSArray *accessoryPreferenceItems = nil;
	[_pluginPrefView setPreferenceItemsSelector:@selector(accessoryPreferenceItems)];
	
	//NSObject *plugin = _resPostingPlug & _webResPostingPlug & _threadPostingPlug & _webThreadPostingPlug;
	// Res posting or Thread posting
	[_boardTextField setFont:[NSFont boldSystemFontOfSize:[NSFont systemFontSize]]];
	[_titleTextField setFont:[NSFont boldSystemFontOfSize:[NSFont systemFontSize]]];
	if (_thread) { // Res
		[_editableTitleTextField setHidden:YES];
		
		NSString *boardTitle = [_thread threadListTitle];
		NSString *title = [_thread title];
		[_boardTextField setStringValue:boardTitle];
		[_titleTextField setStringValue:title];
		
		[[self window] setTitle:[NSString stringWithFormat:THPostingLocalize(@"Posting to %@ - %@"), boardTitle, title]];
		
	} else if (_threadList) { // Thread
		[_titleTextField setHidden:YES];
		
		NSString *boardTitle = [_threadList title];
		[_boardTextField setStringValue:boardTitle];
		
		[[self window] setTitle:[NSString stringWithFormat:THPostingLocalize(@"New Thread in %@"), boardTitle]];
		
	}
	
	// Name and Mail
	NSString *defaultName = nil;
	NSString *defaultMail = nil;
	if (_thread) {
		defaultName = [_thread valueForKey:@"threadDefaultName"];
		defaultMail = [_thread valueForKey:@"threadDefaultMail"];
		
		if (!defaultName && !defaultMail) {
			T2List *list = [[[_thread threadFace] threadListFace] list];
			if (list) {
				defaultName = [list valueForKey:@"boardDefaultName"];
				defaultMail = [list valueForKey:@"boardDefaultMail"];
			}
		}
	} else if (_threadList && [_threadList internalPath]) {
		defaultName = [_threadList valueForKey:@"boardDefaultName"];
		defaultMail = [_threadList valueForKey:@"boardDefaultMail"];
	}
	
	if (!defaultName) defaultName = @"";
	if (!defaultMail) defaultMail = @"sage";
	/*
	if (!defaultName && [__usedNames count]>0) {
		defaultName = [__usedNames objectAtIndex:0];
	}
	if (!defaultMail && [__usedMails count]>0) {
		defaultMail = [__usedMails objectAtIndex:0];
	}
	 */
	
	[_nameTextField setStringValue:defaultName];
	[_mailTextField setStringValue:defaultMail];
	if ([defaultMail rangeOfString:@"sage"].location != NSNotFound) {
		//[_sageButton setState:NSOnState];
		_isSage = YES;
	}
	
	// Content
	if (_content) {
		[_contentTextView setString:_content];
	}
	
	// make ToolBar
	NSToolbar *toolbar=[[[NSToolbar alloc] initWithIdentifier:THPostingWindowToolBarIdentifier] autorelease];
	//_toolbar = toolbar;
	[toolbar setDelegate:self];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration: YES]; 
	[toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
	[[self window] setToolbar:toolbar];
}

#pragma mark -
#pragma mark Accessors
-(NSArray *)usedNames { return __usedNames; }
-(NSArray *)usedMails { return __usedMails; }

-(id)plugin {
	
	id plugin = nil;
	
	if (_posting) plugin = [[T2PluginManager sharedManager] postingPluginForInternalPath:[_posting internalPath]];
	//if (_resPostingPlug) plugin = _resPostingPlug;
	if (_webResPostingPlug) plugin = _webResPostingPlug;
	//else if (_threadPostingPlug) plugin = _threadPostingPlug;
	else if (_webThreadPostingPlug) plugin = _webThreadPostingPlug;
	return plugin;
}


-(void)setIsP2Active:(BOOL)aBool {
	if (!_is2ch) return;
	if (_isP2Active == aBool) return;
	
	id plugin = [self plugin];
	BOOL isP2Active = [plugin isP2Active];
	
	if (isP2Active != aBool) {
		objc_msgSend(plugin, @selector(setIsP2Active:), aBool);
		aBool = [plugin isP2Active];
	}
	_isP2Active = aBool;
	
	if (!_p2Item) return;
	if (aBool) {
		[_p2Item setImage:[NSImage imageNamed:@"TH32_P2_On"]];
		[_p2Item setLabel:THPostingLocalize(@"P2: Active")];
	} else {
		[_p2Item setImage:[NSImage imageNamed:@"TH32_P2_Off"]];
		[_p2Item setLabel:THPostingLocalize(@"P2: Inactive")];
	}
	
}
-(BOOL)isP2Active {
	if (!_is2ch) return NO;
	id plugin = [self plugin];
	return [plugin isP2Active];
}

-(void)setIsViewerActive:(BOOL)aBool {
	if (!_is2ch) return;
	if (_isViewerActive == aBool) return;
	
	id plugin = [self plugin];
	BOOL isViewerActive = [plugin isViewerActive];
	
	if (isViewerActive != aBool) {
		objc_msgSend(plugin, @selector(setIsViewerActive:), aBool);
		aBool = [plugin isViewerActive];
	}
	_isViewerActive = aBool;
	
	if (!_viewerItem) return;
	if (aBool) {
		[_viewerItem setImage:[NSImage imageNamed:@"TH32_2chViewer_On"]];
		[_viewerItem setLabel:THPostingLocalize(@"2chViewer: Active")];
	} else {
		[_viewerItem setImage:[NSImage imageNamed:@"TH32_2chViewer_Off"]];
		[_viewerItem setLabel:THPostingLocalize(@"2chViewer: Inactive")];
	}
}
-(BOOL)isViewerActive {
	if (!_is2ch) return NO;
	id plugin = [self plugin];
	return [plugin isViewerActive];
}

-(void)setIsBeActive:(BOOL)aBool {
	if (!_is2ch) return;
	if (_isBeActive == aBool) return;
	
	id plugin = [self plugin];
	BOOL isBeActive = [plugin isBeActive];
	
	if (isBeActive != aBool) {
		objc_msgSend(plugin, @selector(setIsBeActive:), aBool);
		aBool = [plugin isBeActive];
	}
	_isBeActive = aBool;
	
	if (!_beItem) return;
	if (aBool) {
		[_beItem setImage:[NSImage imageNamed:@"TH32_Be_On"]];
		[_beItem setLabel:THPostingLocalize(@"Be@2ch: Active")];
	} else {
		[_beItem setImage:[NSImage imageNamed:@"TH32_Be_Off"]];
		[_beItem setLabel:THPostingLocalize(@"Be@2ch: Inactive")];
	}
}
-(BOOL)isBeActive {
	if (!_is2ch) return NO;
	id plugin = [self plugin];
	return [plugin isBeActive];
}
/*
-(void)setWebForm:(T2WebForm *)webForm {
	setObjectWithRetain(_webForm ,webForm);
}
-(T2WebForm *)webForm { return _webForm; }
 */
#pragma mark -
#pragma mark NSToolBar delegate methods
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
	return [NSArray arrayWithObjects:
			THPostingWindowToolBarPostItemIdentifier,
			THPostingWindowToolBarReloadItemIdentifier,
			THPostingWindowToolBarP2ItemIdentifier,
			THPostingWindowToolBar2chViewerItemIdentifier,
			THPostingWindowToolBarBeItemIdentifier,
			THPostingWindowToolBarSageItemIdentifier,
			THPostingWindowToolBarBoardTitleItemIdentifier,
			
			NSToolbarSeparatorItemIdentifier,
			NSToolbarSpaceItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			NSToolbarCustomizeToolbarItemIdentifier,
			nil];
}
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
	return [NSArray arrayWithObjects:
			THPostingWindowToolBarPostItemIdentifier,
			THPostingWindowToolBarReloadItemIdentifier,
			NSToolbarSeparatorItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			THPostingWindowToolBarP2ItemIdentifier,
			THPostingWindowToolBar2chViewerItemIdentifier,
			THPostingWindowToolBarBeItemIdentifier,
			THPostingWindowToolBarSageItemIdentifier,
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
	if ([itemIdentifier isEqualToString:THPostingWindowToolBarPostItemIdentifier]) {
		if (_thread) {
			label = THPostingLocalize(@"Post");
			image = [NSImage imageNamed:@"TH32_Write"];
		} else {
			label = THPostingLocalize(@"New Thread");
			image = [NSImage imageNamed:@"TH32_WriteThread"];
		}
		action = @selector(postRes:);
	}
	
	else if ([itemIdentifier isEqualToString:THPostingWindowToolBarReloadItemIdentifier]) {
		if (_thread) {
			label = THPostingLocalize(@"Reload Thread");
		} else {
			label = THPostingLocalize(@"Reload Board");
		}
		image = [NSImage imageNamed:@"TH32_Reload"];
		action = @selector(reload:);
	}
	
	else if ([itemIdentifier isEqualToString:THPostingWindowToolBarP2ItemIdentifier]) {
		
		if (_is2ch) {
			id plugin = [self plugin];
			_isP2Active = [plugin isP2Active];

			if (_isP2Active) {
				image = [NSImage imageNamed:@"TH32_P2_On"];
				label = THPostingLocalize(@"P2: Active");
			} else {
				image = [NSImage imageNamed:@"TH32_P2_Off"];
				label = THPostingLocalize(@"P2: Inactive");
			}
			action = @selector(p2Checked:);
		} else {
			image = [NSImage imageNamed:@"TH32_P2_Off"];
			label = THPostingLocalize(@"P2: Disabled");
			//[tempItem setAutovalidates:NO];
			[tempItem setEnabled:NO];
		}
	}
	
	else if ([itemIdentifier isEqualToString:THPostingWindowToolBar2chViewerItemIdentifier]) {
		
		if (_is2ch) {
			id plugin = [self plugin];
			_isViewerActive = [plugin isViewerActive];
			//BOOL checked = !((BOOL (*)(id, SEL, id))objc_msgSend)(plugin, @selector(isViewerActive));
			if (_isViewerActive) {
				image = [NSImage imageNamed:@"TH32_2chViewer_On"];
				label = THPostingLocalize(@"2chViewer: Active");
			} else {
				image = [NSImage imageNamed:@"TH32_2chViewer_Off"];
				label = THPostingLocalize(@"2chViewer: Inactive");
			}
			action = @selector(viewerChecked:);
		} else {
			image = [NSImage imageNamed:@"TH32_2chViewer_Off"];
			label = THPostingLocalize(@"2chViewer: Disabled");
			//[tempItem setAutovalidates:NO];
			[tempItem setEnabled:NO];
		}
	}
	
	else if ([itemIdentifier isEqualToString:THPostingWindowToolBarBeItemIdentifier]) {
		if (_is2ch) {
			id plugin = [self plugin];
			_isBeActive = [plugin isBeActive];
			//BOOL checked = ((BOOL (*)(id, SEL, id))objc_msgSend)(plugin, @selector(isBeActive));
			if (_isBeActive) {
				image = [NSImage imageNamed:@"TH32_Be_On"];
				label = THPostingLocalize(@"Be@2ch: Active");
			} else {
				image = [NSImage imageNamed:@"TH32_Be_Off"];
				label = THPostingLocalize(@"Be@2ch: Inactive");
			}
			action = @selector(beChecked:);
		} else {
			image = [NSImage imageNamed:@"TH32_Be_Off"];
			label = THPostingLocalize(@"Be@2ch: Disabled");
			//[tempItem setAutovalidates:NO];
			[tempItem setEnabled:NO];
		}
		//_beItem = [tempItem retain];
		
		/*
		label = THPostingLocalize(@"Be");
		[tempItem setView:_BeButton];
		[tempItem setMaxSize:(NSSize){40,32}];
		[tempItem setMinSize:(NSSize){40,22}];
		
		[_BeButton setEnabled:NO];
		if (_is2ch) {
			id plugin = [self plugin];
			if ([plugin respondsToSelector:@selector(beCode)]) {
				id beCode = [plugin beCode];
				if (beCode && [(NSString *)beCode length] > 0) [_BeButton setEnabled:YES];
			}
		}
		*/
	}
	
	else if ([itemIdentifier isEqualToString:THPostingWindowToolBarSageItemIdentifier]) {
		
		if (_isSage) {
			image = [NSImage imageNamed:@"TH32_Sage_On"];
			label = THPostingLocalize(@"sage");
		} else {
			image = [NSImage imageNamed:@"TH32_Sage_Off"];
			label = THPostingLocalize(@"age");
		}
		action = @selector(sageChecked:);
		//_sageItem = [tempItem retain];
		/*
		label = THPostingLocalize(@"sage");
		[tempItem setView:_sageButton];
		[tempItem setMaxSize:(NSSize){40,32}];
		[tempItem setMinSize:(NSSize){40,22}];
		 */
	}
	
	else if ([itemIdentifier isEqualToString:THPostingWindowToolBarBoardTitleItemIdentifier]) {
		label = THPostingLocalize(@"Board");
		[tempItem setView:_boardTextField];
		[tempItem setMaxSize:(NSSize){128,32}];
		[tempItem setMinSize:(NSSize){128,17}];
	}
	
	// Set item attributes
	if (label) [tempItem setLabel:label];
	if (image) [tempItem setImage:image];
	if (action) [tempItem setAction:action];
	if (paletteLabel) [tempItem setPaletteLabel:paletteLabel];
	else if (label) [tempItem setPaletteLabel:label];
	return tempItem;
}

- (void)toolbarWillAddItem:(NSNotification *)notification {
	NSToolbarItem *item = [[notification userInfo] objectForKey:@"item"];
	NSString *identifier = [item itemIdentifier];
	if ([identifier isEqualToString:THPostingWindowToolBarP2ItemIdentifier]) {
		_p2Item = item;
	} else if ([identifier isEqualToString:THPostingWindowToolBar2chViewerItemIdentifier]) {
		_viewerItem = item;
	} else if ([identifier isEqualToString:THPostingWindowToolBarBeItemIdentifier]) {
		_beItem = item;
	} else if ([identifier isEqualToString:THPostingWindowToolBarSageItemIdentifier]) {
		_sageItem = item;
	}
}

#pragma mark-
#pragma mark NSTextView Delegate Methods
- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector {
	if (aSelector == @selector(insertTab:)) {
		[[aTextView window] selectNextKeyView:aTextView];
		return YES;
	} else if (aSelector == @selector(insertBacktab:)) {
		[[aTextView window] selectPreviousKeyView:aTextView];
		return YES;
	}
	return NO;
}


#pragma mark -
#pragma mark Sheet
/*
-(void)beginSheet {
	[NSApp beginSheet:[self window]
					  modalForWindow:_docWindow
					   modalDelegate:self
					  didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
						 contextInfo:nil];
	if (!__instances) __instances = [[NSMutableSet alloc] init];
	[__instances addObject:self];
}
- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[_webView setAllDelegate:nil];
	[sheet orderOut:self];
	[__instances removeObject:self];
}
*/


- (void)windowWillClose:(NSNotification *)aNotification {
	[_webView stopLoading:nil];
	[_webView setAllDelegate:nil];
	
	if (_thread) {
		if (_postingSucceeded) {
			[_thread setDraft:nil];
		} else {
			[_thread setDraft:[_contentTextView string]];
		}
	}
	@synchronized(__postingWindowControllerForInternalPath) {
		NSString *internalPath;
		if (_thread) internalPath = [_thread internalPath];
		else internalPath = [_threadList internalPath];
		if (internalPath)
			[__postingWindowControllerForInternalPath removeObjectForKey:internalPath];
	}
	
	[_webView setAllDelegate:nil];
	
	if (_is2ch) {
		[[self plugin] removeObserver:self forKeyPath:@"isViewerActive"];
		[[self plugin] removeObserver:self forKeyPath:@"isBeActive"];
		[[self plugin] removeObserver:self forKeyPath:@"isP2Active"];
	}
	[_thread release];
	_thread = nil;
	[self autorelease];
}
- (void)windowDidMove:(NSNotification *)aNotification {
	[[self window] saveFrameUsingName:@"postingWindow"];
}
- (void)windowDidResize:(NSNotification *)aNotification {
	if (_postingWindowSizeLoaded) [[self window] saveFrameUsingName:@"postingWindow"];
}

#pragma mark -
#pragma mark T2Posting Notifications

-(void)postingStart:(NSNotification *)notification {
	[_tabView selectTabViewItem:_postingTab];
	[_progressIndicator startAnimation:self];
}
-(void)postingEnd:(NSNotification *)notification {
	
	_firstRequest = NO;
	[_progressIndicator stopAnimation:self];
	
	T2LoadingResult result = [_posting loadingResult];
	
	switch (result) {
		case T2LoadingSucceed: {
			_postingSucceeded = YES;
			
			if (_thread) {
				NSTimeInterval loadingInterval = [_thread loadingInterval];
				[_thread setLoadingInterval:0];
				[_thread load];
				NSDate *date = [NSDate date];
				if (date)
					[[_thread threadFace] setValue:date forKey:@"lastPostingDate"];
				[(T2ThreadHistory *)[T2ThreadHistory threadHistoryForKey:@"resPostedThreadHistory"] addHistory:[_thread threadFace]];
				[_thread setLoadingInterval:loadingInterval];
				
				[_thread registerPostedMyRes:[_posting res]];
				
			} else if (_threadList) {
				NSTimeInterval loadingInterval = [_threadList loadingInterval];
				[_threadList setLoadingInterval:0];
				[_threadList load];
				[_threadList setLoadingInterval:loadingInterval];
			}
			[self close:nil];
			break;
		}
		case T2LoadingFailed: {
			[self backToDraft:nil];
			break;
		}
		case T2RetryLoading: {
			NSString *confirmationMessage = [_posting message];
			NSString *confirmationButtonTitle = [_posting confirmButtonTitle];
			NSURLRequest *additionalRequest = [_posting additonalRequest];
			if (confirmationMessage) {
				[_messageTextView setString:confirmationMessage];
				if (confirmationButtonTitle && additionalRequest) {
					[self setConfirmButtonTitle:confirmationButtonTitle];
					[_additionalRequest release];
					_additionalRequest = [additionalRequest retain];
				} else {
					[self setConfirmButtonTitle:nil];
				}
			}
			[_tabView selectTabViewItem:_responseTab];
			
			break;
		}
		default:
			break;
	}
	
}

#pragma mark -
#pragma mark T2WebConnector Delegate Methods
/*
-(void)connector:(T2WebConnector *)connector
		   ofURL:(NSString *)urlString
didReceiveWebData:(T2WebData *)webData
	   inContext:(id)contextObject {
	
	_firstRequest = NO;
	[_progressIndicator stopAnimation:self];
	
	T2LoadingResult result = T2LoadingFailed;
	NSString *confirmationMessage = nil;
	NSString *confirmationButtonTitle = nil;
	NSURLRequest *additionalRequest = nil;
	
	if (_resPostingPlug) {
		result = [_resPostingPlug didEndPostingResForWebData:webData
										 confirmationMessage:&confirmationMessage
									 confirmationButtonTitle:&confirmationButtonTitle
										   additionalRequest:&additionalRequest];
	} else {
		result = [_threadPostingPlug didEndPostingThreadForWebData:webData
											   confirmationMessage:&confirmationMessage
										   confirmationButtonTitle:&confirmationButtonTitle
												 additionalRequest:&additionalRequest];
	}
	switch (result) {
		case T2LoadingSucceed: {
			_postingSucceeded = YES;
			
			if (_resPostingPlug && _thread) {
				NSTimeInterval loadingInterval = [_thread loadingInterval];
				[_thread setLoadingInterval:0];
				[_thread load];
				NSDate *date = [NSDate date];
				if (date)
					[[_thread threadFace] setValue:date forKey:@"lastPostingDate"];
				[(T2ThreadHistory *)[T2ThreadHistory threadHistoryForKey:@"resPostedThreadHistory"] addHistory:[_thread threadFace]];
				[_thread setLoadingInterval:loadingInterval];
			} else if (_threadList) {
				NSTimeInterval loadingInterval = [_threadList loadingInterval];
				[_threadList setLoadingInterval:0];
				[_threadList load];
				[_threadList setLoadingInterval:loadingInterval];
			}
			[self close:nil];
			break;
		}
		case T2LoadingFailed: {
			[self backToDraft:nil];
			break;
		}
		case T2RetryLoading: {
			if (confirmationMessage) {
				[_messageTextView setString:confirmationMessage];
				if (confirmationButtonTitle && additionalRequest) {
					[self setConfirmButtonTitle:confirmationButtonTitle];
					[_additionalRequest release];
					_additionalRequest = [additionalRequest retain];
				} else {
					[self setConfirmButtonTitle:nil];
				}
			}
			[_tabView selectTabViewItem:_responseTab];
			
			break;
		}
		default:
			break;
	}
	[_webConnector release];
	_webConnector = nil;
}
 */

#pragma mark -
#pragma mark WebView Delegate Methods
- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request
		 redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource {
	NSObject <T2PluginInterface_v100> *postingPlug = _webResPostingPlug;
	if (!postingPlug) postingPlug = _webThreadPostingPlug;
	
	request = [request requestByAddingUserAgentAndImporterName:[postingPlug uniqueName]];
	
	if (!_firstRequest) {
		if ([[request HTTPMethod] isEqualToString:@"POST"]) {
			if ([postingPlug respondsToSelector:@selector(webViewWillSendPostingRequest:)]) {
				request = [postingPlug webViewWillSendPostingRequest:request];
			}
		}
	}
	
	if (_thread && ![_thread shouldUseSharedCookies]) {
		request = [request requestByAddingCookies];
		return request;
	}
	return request;
}
- (void)webView:(WebView *)sender resource:(id)identifier didReceiveResponse:(NSURLResponse *)response
 fromDataSource:(WebDataSource *)dataSource {
	if (_thread && ![_thread shouldUseSharedCookies] && [response isKindOfClass:[NSHTTPURLResponse class]]) {
		[[T2HTTPCookieStorage sharedHTTPCookieStorage] setCookiesInURLResponse:(NSHTTPURLResponse *)response];
		//NSLog(@"webView Receives:\n %@", [response allHeaderFields]);
	}
}

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
	[_tabView selectTabViewItem:_postingTab];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	_firstRequest = NO;
	[_progressIndicator stopAnimation:self];
	[_tabView selectTabViewItem:_responseTab];
	
	NSString *sourceString = [(DOMHTMLElement *)[[frame DOMDocument] documentElement] outerHTML];
	NSString *sourceURLString = [[[[frame dataSource] request] URL] absoluteString];
	
	T2LoadingResult result;
	if (_webResPostingPlug) {
		result = [_webResPostingPlug didEndPostingResForSource:sourceString];
		if (result == T2LoadingSucceed ) {
			_postingSucceeded = YES;
			NSTimeInterval loadingInterval = [_thread loadingInterval];
			[_thread setLoadingInterval:0];
			[_thread load];
			[(T2ThreadHistory *)[T2ThreadHistory threadHistoryForKey:@"resPostedThreadHistory"] addHistory:[_thread threadFace]];
			[_thread setLoadingInterval:loadingInterval];
			[self close:nil];
		} else if (result == T2LoadingFailed ) {
			[self backToDraft:nil];
		} else {
			[self setConfirmButtonTitle:nil];
			/*
			if ([_webResPostingPlug respondsToSelector:@selector(webFormForAdditionalConfirmation:baseURLString:)]) {
				T2WebForm *webForm = [_webResPostingPlug webFormForAdditionalConfirmation:sourceString baseURLString:sourceURLString];
				NSString *confirmMessage = [webForm submitValue];
				if (webForm && confirmMessage) {
					[self setWebForm:webForm];
					[self setConfirmMessage:confirmMessage];
					return;
				}
			}
			[self setWebForm:nil];
			[self setConfirmMessage:nil];
			 */
		}
	} else {
		result = [_webThreadPostingPlug didEndPostingThreadForSource:sourceString];
		if (result == T2LoadingSucceed ) {
			_postingSucceeded = YES;
			NSTimeInterval loadingInterval = [_threadList loadingInterval];
			[_threadList setLoadingInterval:0];
			[_threadList load];
			[_threadList setLoadingInterval:loadingInterval];
			[self close:nil];
		} else if (result == T2LoadingFailed ) {
			[self backToDraft:nil];
		} else {
			[self setConfirmButtonTitle:nil];
			/*
			if ([_webThreadPostingPlug respondsToSelector:@selector(webFormForAdditionalConfirmation:baseURLString:)]) {
				T2WebForm *webForm = [_webThreadPostingPlug webFormForAdditionalConfirmation:sourceString baseURLString:sourceURLString];
				NSString *confirmMessage = [webForm submitValue];
				if (webForm && confirmMessage) {
					[self setWebForm:webForm];
					[self setConfirmMessage:confirmMessage];
					return;
				}
			}
			[self setWebForm:nil];
			[self setConfirmMessage:nil];
			 */
		}
	}
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
	[_progressIndicator stopAnimation:self];
	[_tabView selectTabViewItem:_responseTab];
}
- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
	[_progressIndicator stopAnimation:self];
	[self backToDraft:nil];
}

#pragma mark -
#pragma mark 2chImporter Plugin Observing
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
						change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"isViewerActive"]) {
		[self setIsViewerActive:[self isViewerActive]];
	} else if ([keyPath isEqualToString:@"isBeActive"]) {
		[self setIsBeActive:[self isBeActive]];
	} else if ([keyPath isEqualToString:@"isP2Active"]) {
		[self setIsP2Active:[self isP2Active]];
	}
}

#pragma mark -
#pragma mark Methods
-(void)appendContent:(NSString *)string {
	NSString *currentContent = [_contentTextView string];
	if (currentContent && string) {
		NSString *newContent = [NSString stringWithFormat:@"%@\n%@", currentContent, string];
		[_contentTextView setString:newContent];
	}
}
-(void)setConfirmButtonTitle:(NSString *)string {
	NSRect confirmButtonFrame = [_confirmButton frame];
	float right = confirmButtonFrame.origin.x + confirmButtonFrame.size.width;
	NSRect backButtonFrame = [_backButton frame];
	
	if (!string || [string length]==0) {
		[_confirmButton setHidden:YES];
		backButtonFrame.origin.x = right-backButtonFrame.size.width;
		[_backButton setFrame:backButtonFrame];
	} else {
		[_confirmButton setHidden:NO];
		[_confirmButton setTitle:string];
		[_confirmButton sizeToFit];
		NSRect newConfirmButtonFrame = [_confirmButton frame];
		
		newConfirmButtonFrame.origin.x = right-newConfirmButtonFrame.size.width;
		[_confirmButton setFrame:newConfirmButtonFrame];
		
		backButtonFrame.origin.x += confirmButtonFrame.size.width-newConfirmButtonFrame.size.width;
		[_backButton setFrame:backButtonFrame];
	}
}

#pragma mark -
#pragma mark Toolbar Item Validation
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
	if ([_tabView selectedTabViewItem] == _draftTab) {
		return YES;
	}
	if (theItem == _p2Item ||
		theItem == _viewerItem ||
		theItem == _beItem ||
		theItem == _sageItem) {
		return NO;
	}
	return YES;
}
/*
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
	NSString *itemIdentifier = [theItem itemIdentifier];
	if ([itemIdentifier isEqualToString:THPostingWindowToolBar2chViewerItemIdentifier]) {
		if (_is2ch) {
			id plugin = [self plugin];
			if ([plugin respondsToSelector:@selector(viewerSID)]) {
				id viewerSID = [plugin viewerSID];
				if (viewerSID) return YES;
			}
		}
		return NO;
		
	} else if ([itemIdentifier isEqualToString:THPostingWindowToolBarBeItemIdentifier]) {
		if (_is2ch) {
			id plugin = [self plugin];
			if ([plugin respondsToSelector:@selector(beCode)]) {
				id beCode = [plugin beCode];
				if (beCode) return YES;
			}
		}
		return NO;
	}
	return YES;
}
 */

#pragma mark -
#pragma mark Actions
- (IBAction)post:(id)sender {
	NSString *title = [_editableTitleTextField stringValue];
	NSString *name = [_nameTextField stringValue];
	NSString *mail = [_mailTextField stringValue];
	NSString *content = [[_contentTextView string] stringByTrimmingInvalidWhiteCharactersBeforeLineBreaks];
	if (!name) name = @"";
	if (!mail) mail = @"";
	if (!content || [content length] == 0) return;
	
	if (_webConnector) {
		[_webConnector cancelLoading];
		[_webConnector release];
		_webConnector = nil;
	}
	
	NSString *boardIdentifier;
	if (_thread) {
		
		NSString *threadDefaultName = [_thread valueForKey:@"threadDefaultName"];
		NSString *threadDefaultMail = [_thread valueForKey:@"threadDefaultMail"];
		NSString *boardDefaultName = nil;
		NSString *boardDefaultMail = nil;
		T2List *threadList = nil;
		
		if ([_thread internalPath]) {
			threadList = [[[_thread threadFace] threadListFace] list];
			if (threadList) {
				boardDefaultName = [threadList valueForKey:@"boardDefaultName"];
				boardDefaultMail = [threadList valueForKey:@"boardDefaultMail"];
			}
		}
		
		if (![threadDefaultName isEqualToString:name]) {
			[_thread setValue:name forKey:@"threadDefaultName"];
			if (![boardDefaultName isEqualToString:name]) {
				if (threadList) [threadList setValue:name forKey:@"boardDefaultName"];
			}
		}
		if (![threadDefaultMail isEqualToString:mail]) {
			[_thread setValue:mail forKey:@"threadDefaultMail"];
			if (![boardDefaultMail isEqualToString:mail]) {
				if (threadList) [threadList setValue:mail forKey:@"boardDefaultMail"];
			}
		}
		
	} else if (_threadList && [_threadList internalPath]) {
		[_threadList setValue:name forKey:@"boardDefaultName"];
		[_threadList setValue:mail forKey:@"boardDefaultMail"];
	}
	
	[__usedNames removeObject:name];
	[__usedNames insertObject:name atIndex:0];
	[__usedMails removeObject:mail];
	[__usedMails insertObject:mail atIndex:0];
	if ([__usedNames count]>5)
		[__usedNames removeObjectsInRange:NSMakeRange(5,[__usedNames count]-5)];
	if ([__usedMails count]>5)
		[__usedMails removeObjectsInRange:NSMakeRange(5,[__usedMails count]-5)];
	/*
	if ([name rangeOfString:@"#/.fEpw:c"].location != NSNotFound)
		name = @"fussiananchatte";
	 */
	
	T2Res *tempRes = [T2Res resWithResNumber:0
										name:name
										mail:mail
										date:nil identifier:nil
									 content:content
									  thread:nil];
	
	if (_posting) {
		[_posting setRes:tempRes];
		if (_threadList) [_posting setThreadTitle:title];
		[_posting load];
		return;
	}
	
	NSURLRequest *request;
	NSString *plugName;
	BOOL shouldUseSharedCookies = NO;
	
	if (_webResPostingPlug) {
		request = [_webResPostingPlug URLRequestForPostingRes:tempRes thread:_thread];
		plugName = [_webResPostingPlug uniqueName];
		shouldUseSharedCookies = [_thread shouldUseSharedCookies];
	} else if (_webThreadPostingPlug) {
		request = [_webThreadPostingPlug URLRequestForPostingFirstRes:tempRes threadTitle:title toThreadList:_threadList];
		plugName = [_webThreadPostingPlug uniqueName];
	}
	if (!request) {
		NSBeep();
		return;
	}
	
	request = [request requestByAddingUserAgentAndImporterName:plugName];
		
	
	[_tabView selectTabViewItem:_postingTab];
	[_progressIndicator startAnimation:self];
	_firstRequest = YES;
	
	[_webView setHidden:NO];
	[[_messageTextView enclosingScrollView] setHidden:YES];
	[[_webView mainFrame] loadRequest:request];
}
- (IBAction)close:(id)sender {
	[[self window] performClose:nil];
}

- (IBAction)backToDraft:(id)sender {
	[_tabView selectTabViewItem:_draftTab];
}
- (IBAction)confirm:(id)sender {
	/*
	if (!_webForm) return;
	NSURLRequest *request = nil;
	if (_webResPostingPlug && [_webResPostingPlug respondsToSelector:@selector(requestForConfirmationWebForm:)]) {
		request = [_webResPostingPlug requestForConfirmationWebForm:_webForm];
		request = [request requestByAddingUserAgentAndImporterName:[_webResPostingPlug uniqueName]];
		if (![_thread shouldUseSharedCookies]) {
			request = [request requestByAddingCookies];
		}
	}
	else if (_webThreadPostingPlug && [_webThreadPostingPlug respondsToSelector:@selector(requestForConfirmationWebForm:)]) {
		request = [_webThreadPostingPlug requestForConfirmationWebForm:_webForm];
		request = [request requestByAddingUserAgentAndImporterName:[_webThreadPostingPlug uniqueName]];
		
		//if (![_threadList shouldUseSharedCookies]) {
			request = [request requestByAddingCookies];
		//}
	}
	if (!request) return;
	
	NSMutableURLRequest *mutableRequest = [[request mutableCopy] autorelease];
	
	NSString *referer = [[[[[_webView mainFrame] dataSource] request] URL] absoluteString];
	[mutableRequest setValue:referer forHTTPHeaderField:@"Referer"];
	 */
	BOOL shouldUseSharedCookies = NO;
	if (_thread) {
		shouldUseSharedCookies = [_thread shouldUseSharedCookies];
	}
	
	if (_posting) {
		[_posting load];
		
		[_tabView selectTabViewItem:_postingTab];
		[_progressIndicator startAnimation:self];
	}
	
}
-(IBAction)p2Checked:(id)sender {
	[self setIsP2Active:![self isP2Active]];
}
-(IBAction)viewerChecked:(id)sender {
	[self setIsViewerActive:![self isViewerActive]];
}
-(IBAction)beChecked:(id)sender {
	[self setIsBeActive:![self isBeActive]];
}
-(IBAction)sageChecked:(id)sender {
	NSString *mail = [_mailTextField stringValue];
	if (!mail) mail = @"";
	
	_isSage = !_isSage;
	
	if (_isSage) {
		if ([mail rangeOfString:@"sage"].location == NSNotFound) {
			if ([mail length] > 0)
				mail = [mail stringByAppendingString:@"sage"];
			else
				mail = @"sage";
		}
		[_sageItem setImage:[NSImage imageNamed:@"TH32_Sage_On"]];
		[_sageItem setLabel:THPostingLocalize(@"sage")];
		
	} else {
		
		NSMutableString *mutableMail = [[mail mutableCopy] autorelease];
		[mutableMail replaceOccurrencesOfString:@"sage"
									 withString:@""
										options:NSCaseInsensitiveSearch
										  range:NSMakeRange(0, [mutableMail length])];
		mail = mutableMail;
		[_sageItem setImage:[NSImage imageNamed:@"TH32_Sage_Off"]];
		[_sageItem setLabel:THPostingLocalize(@"age")];
	}
	
	[_mailTextField setStringValue:mail];
}

-(IBAction)postRes:(id)sender {
	if ([_tabView selectedTabViewItem] == _draftTab) {
		[_posting setMessage:nil];
		[_posting setConfirmButtonTitle:nil];
		[_posting setAdditionalRequest:nil];
		[self post:sender];
	} else if ([_tabView selectedTabViewItem] == _responseTab && _additionalRequest && ![_confirmButton isHidden]) {
		[self confirm:sender];
	}
}

-(IBAction)reload:(id)sender {
	if (_thread) {
		NSString *urlString = [_thread webBrowserURLString];
		if (urlString)
			[[THAppDelegate sharedInstance] openURLString:urlString];
		else
			[_thread load];
		
	} else if (_threadList) {
		[_threadList load];
	}
}
@end
