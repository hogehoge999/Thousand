//
//  THPrefWindowController.m
//  Thousand
//
//  Created by R. Natori on 06/10/21.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "THPrefWindowController.h"
#import "THMetalWindow.h"
#import "THAppDelegate.h"
#import "THDocument.h"
#import "THPostingWindowController.h"
#import "THBookmarkController.h"
#import "THThreadController.h"
#import "THStandardViewPlug.h"
#import "THDownloadWindowController.h"
#import "THWebDownloader.h"
#import "T2LabeledCell.h"
#import "THFontWell.h"

#define THFontDisplayName(font)			([NSString stringWithFormat:@"%@ - %.1f", [font displayName], [font pointSize]])
#define THPrefToolBarLocalize(string)	(NSLocalizedString(string, @"Pref ToolBar"))

static NSString *__appDelegatePrefKey 		= @"appDelegatePref";

static id __sharedPrefWindowController;

@implementation THPrefWindowController
#pragma mark -
#pragma mark T2DictionaryConverting
// keys for saving
-(NSArray *)dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use {
	return [NSArray arrayWithObjects:
			@"browserMetal", @"useAppleAppLikeSourceTable",
			@"maxThreadTabCount", @"iconSetName", @"resPopUpWindowWidth", @"usedNames",
			@"usedMails", @"newTabLocationType", @"popUpDelaySeconds",
			@"downloadInThreadFolder", @"downloadWhenFilesExist", @"downloadDestinationFolderPath",
			@"labelDictionary",
			@"popUpResPreviewActionIndex", @"popUpURLPreviewActionIndex", @"clickResPreviewActionIndex", @"clickURLPreviewActionIndex",
			@"defaultExtractPathIndex",
			@"sourceTableRowHeight", @"threadTableRowHeight",
			@"allowsTypeToJump", @"typeWait",
			@"logFolderPath",
			//@"abbreviatedLogFolderPath",
			@"abbreviatedDownloadDestinationFolderPath",
			@"safari2Debug", @"enableThreadListCache", @"enablePrefetchThread",
            @"useProxy", @"proxyHost",
			nil];
}

+(void)initialize {
	NSArray *keys = [NSArray arrayWithObject:@"threadTableAllowedColumnIdentifers"];
	NSArray *dependentKeys = [NSArray arrayWithObjects:
							  @"visibleOfThreadTableColumn_stateImage",
							  @"visibleOfThreadTableColumn_resCountNew",
							  @"visibleOfThreadTableColumn_resCount",
							  @"visibleOfThreadTableColumn_resCountGap",
							  @"visibleOfThreadTableColumn_order",
							  @"visibleOfThreadTableColumn_createdDate",
							  @"visibleOfThreadTableColumn_labelScore",
							  @"visibleOfThreadTableColumn_velocity",
							  @"visibleOfThreadTableColumn_valiable", nil];
	NSEnumerator *enumerator = [dependentKeys objectEnumerator];
	NSString *dependentKey;
	while (dependentKey = [enumerator nextObject]) {
		[self setKeys:keys triggerChangeNotificationsForDependentKey:dependentKey];
	}
	
	[self setKeys:dependentKeys triggerChangeNotificationsForDependentKey:@"threadTableAllowedColumnIdentifers"];
}

//+ (NSSet *) keyPathsForValuesAffectingValueForKey:(NSString *)key
//{
//	NSSet *keys = nil;
//	if ([key isEqualToString:@"threadTableAllowedColumnIdentifers"]) {
//		keys=[NSSet setWithObjects:
//              @"visibleOfThreadTableColumn_stateImage",
//              @"visibleOfThreadTableColumn_resCountNew",
//              @"visibleOfThreadTableColumn_resCount",
//              @"visibleOfThreadTableColumn_resCountGap",
//              @"visibleOfThreadTableColumn_order",
//              @"visibleOfThreadTableColumn_createdDate",
//              @"visibleOfThreadTableColumn_labelScore",
//              @"visibleOfThreadTableColumn_velocity",
//              @"visibleOfThreadTableColumn_valiable", nil];
//
//	}
//	return keys;
//}

+(id)sharedPrefWindowController {
	if (!__sharedPrefWindowController)
		__sharedPrefWindowController = [[self alloc] initPrefWindowController];
	return __sharedPrefWindowController;
}
+(void)releaseSharedPrefWindowController {
	[__sharedPrefWindowController saveAllPrefs];
	[__sharedPrefWindowController release];
	__sharedPrefWindowController = nil;
}

-(id)initPrefWindowController {
	
	if (__sharedPrefWindowController) {
		[self autorelease];
		return __sharedPrefWindowController;
	}
	self = [super initWithWindowNibName:@"THPrefWindow"];
	_prefWindow = [self window];
	
	NSDictionary *appDelegatePrefDic = [[NSUserDefaults standardUserDefaults] dictionaryForKey:__appDelegatePrefKey];
	if (appDelegatePrefDic) [self setValuesWithEncodedDictionary:appDelegatePrefDic];
	
	
	// icon set names
	[self willChangeValueForKey:@"iconSetNames"];
	[self willChangeValueForKey:@"iconSetSelectable"];
	_iconSetNames = [[[T2ResourceManager sharedManager] iconSetNames] retain];
	[self didChangeValueForKey:@"iconSetNames"];
	[self didChangeValueForKey:@"iconSetSelectable"];
	
	// init Web Prefs
	_webPreferences = [[WebPreferences alloc] initWithIdentifier:@"ThousandWebPreferences"];
	[_webPreferences setPlugInsEnabled:YES];
	
	_postingWebPreferences = [[WebPreferences alloc] initWithIdentifier:@"ThousandPostingWebPreferences"];
	[_postingWebPreferences setPlugInsEnabled:NO];
	
	// load Font
	[self loadFont];
	
	// label
	T2LabeledCellManager *labelManager = [T2LabeledCellManager sharedManager];
	NSArray *colors = [labelManager labelColors];
	NSArray *names = [labelManager labelNames];
	NSMutableDictionary *labelDictionary = [NSMutableDictionary dictionary];
	unsigned i, colorsCount = [colors count];
	for (i=0; i<colorsCount; i++) {
		[labelDictionary setObject:[colors objectAtIndex:i] forKey:[NSString stringWithFormat:@"labelColor%d", i+1]];
		[labelDictionary setObject:NSLocalizedString([names objectAtIndex:i+1], @"Colors") forKey:[NSString stringWithFormat:@"labelName%d", i+1]];
	}
	[self setLabelDictionary:labelDictionary];
	
	_isLoaded = YES;
	
	return self;
}
-(void)dealloc {
	
	[_allPluginsView unbind:@"plugin"];
	[_listImporterPluginsView unbind:@"plugin"];
	[_HTMLPluginsView unbind:@"plugin"];
	[_selfController setContent:nil];
	
	
	[super dealloc];
}

-(void)windowDidLoad {
	
	
	// window frame
	[self setWindowFrameAutosaveName:@"appPreferences"];
	
	// make ToolBar
	NSToolbar *toolbar=[[[NSToolbar alloc] initWithIdentifier:THPrefToolBarIdentifier] autorelease];
	[toolbar setDelegate:self];
	[toolbar setAllowsUserCustomization:NO];
	[toolbar setAutosavesConfiguration: NO]; 
	[toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
	[[self window] setToolbar:toolbar];
	
	
	// Plugin Prefs
	T2PluginManager *sharedManager = [T2PluginManager sharedManager];
	
	NSArray *allPlugins = [sharedManager allPlugins];
	if ([allPlugins count]>0)
		[self setSelectedPlugin:[allPlugins objectAtIndex:0]];
	
	NSArray *listImporterPlugins = [sharedManager listImporterPlugins];
	if ([listImporterPlugins count]>0)
		[self setSelectedListImporterPlugin:[listImporterPlugins objectAtIndex:0]];
	
	NSArray *partialHTMLExporterPlugins = [sharedManager partialHTMLExporterPlugins];
	if ([partialHTMLExporterPlugins count]>0)
		[self setSelectedPartialHTMLExporterPlugin:[partialHTMLExporterPlugins objectAtIndex:0]];
		
	NSArray *HTMLExporterPlugins = [sharedManager HTMLExporterPlugins];
	if ([HTMLExporterPlugins count]>0)
		[self setSelectedHTMLExporterPlugin:[HTMLExporterPlugins objectAtIndex:0]];
	
	NSArray *URLpreviewerPlugins = [sharedManager URLpreviewerPlugins];
	if ([URLpreviewerPlugins count]>0)
		[self setSelectedURLPreviewerPlugin:[URLpreviewerPlugins objectAtIndex:0]];
	
	// plugin pref GUI
	if (_allPluginsView) {
		[_allPluginsView setDisplayInfo:YES];
		[_allPluginsView bind:@"plugin" toObject:_selfController withKeyPath:@"selection.selectedPlugin" options:nil];
	}
	if (_listImporterPluginsView) 
		[_listImporterPluginsView bind:@"plugin" toObject:_selfController withKeyPath:@"selection.selectedListImporterPlugin" options:nil];
	if (_HTMLPluginsView) 
		[_HTMLPluginsView bind:@"plugin" toObject:_selfController withKeyPath:@"selection.selectedHTMLExporterPlugin" options:nil];
	if (_URLPreviewerPluginsView) 
		[_URLPreviewerPluginsView bind:@"plugin" toObject:_selfController withKeyPath:@"selection.selectedURLPreviewerPlugin" options:nil];
	
	id the2chPlugin = [sharedManager pluginForUniqueName:@"jp_natori_Thousand_2chImporter"];
	if (the2chPlugin) {
		[_2chPlugController setContent:the2chPlugin];
	}
	
	//Font Mode
	[_webStandardFontWell setValidModeMask:NSFontPanelCollectionModeMask | NSFontPanelSizeModeMask];
	[_webFixedFontWell setValidModeMask:NSFontPanelCollectionModeMask | NSFontPanelSizeModeMask];
	[_sourceListFontWell setValidModeMask:NSFontPanelCollectionModeMask | NSFontPanelFaceModeMask | NSFontPanelSizeModeMask];
	[_threadListFontWell setValidModeMask:NSFontPanelCollectionModeMask | NSFontPanelFaceModeMask | NSFontPanelSizeModeMask];
	[_draftFontWell setValidModeMask:NSFontPanelCollectionModeMask | NSFontPanelFaceModeMask | NSFontPanelSizeModeMask];
	
	//Default Tab
	[_prefTabView selectTabViewItemWithIdentifier:THPrefAppearanceItemIdentifier];
	[toolbar setSelectedItemIdentifier:THPrefAppearanceItemIdentifier];
}

#pragma mark -
#pragma mark NSToolBar delegate method
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
	NSArray *defaultItems = [NSArray arrayWithObjects:
							 //THPrefGeneralItemIdentifier,
							 THPrefAppearanceItemIdentifier,
							 THPrefFontAndColorItemIdentifier,
							 //THPrefBookmarkViewItemIdentifier,
							 THPrefWebViewItemIdentifier,
							 THPrefPreviewItemIdentifier,
							 THPref2chItemIdentifier,
							 THPrefPluginItemIdentifier,
							 THPrefAdvancedItemIdentifier,
							 nil];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"showsDebugMenu"]) {
		defaultItems = [defaultItems arrayByAddingObject:THPrefDebugItemIdentifier];
	}
	return defaultItems;
}
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
	return [self toolbarAllowedItemIdentifiers:toolbar];
}
- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
	return [self toolbarAllowedItemIdentifiers:toolbar];
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
	
	// Tab switcher
	if ([itemIdentifier isEqualToString:THPrefGeneralItemIdentifier]) {
		label = THPrefToolBarLocalize(@"General");
		image = [NSImage imageNamed:@"TH32_PrefPane"];
		action = @selector(switchPrefTab:);
	} else if ([itemIdentifier isEqualToString:THPrefAppearanceItemIdentifier]) {
		label = THPrefToolBarLocalize(@"Appearance");
		image = [NSImage imageNamed:@"TH32_Appearance"];
		action = @selector(switchPrefTab:);
	} else if ([itemIdentifier isEqualToString:THPrefFontAndColorItemIdentifier]) {
		label = THPrefToolBarLocalize(@"Fonts and Colors");
		image = [NSImage imageNamed:@"TH32_FontAndColor"];
		action = @selector(switchPrefTab:);
	} else if ([itemIdentifier isEqualToString:THPrefBookmarkViewItemIdentifier]) {
		label = THPrefToolBarLocalize(@"List");
		image = [NSImage imageNamed:@"TH32_BookmarkView"];
		action = @selector(switchPrefTab:);
	} else if ([itemIdentifier isEqualToString:THPref2chItemIdentifier]) {
		label = THPrefToolBarLocalize(@"2ch");
		image = [NSImage imageNamed:@"TH32_2chPref"];
		action = @selector(switchPrefTab:);
	} else if ([itemIdentifier isEqualToString:THPrefWebViewItemIdentifier]) {
		label = THPrefToolBarLocalize(@"Web View");
		image = [NSImage imageNamed:@"TH32_WebView"];
		action = @selector(switchPrefTab:);
		/*
	} else if ([itemIdentifier isEqualToString:THPref2chItemIdentifier]) {
		label = THPrefToolBarLocalize(@"2ch Settings");
		image = [NSImage imageNamed:@"TH32_2chPref"];
		action = @selector(switchPrefTab:);
		*/
	} else if ([itemIdentifier isEqualToString:THPrefPreviewItemIdentifier]) {
		label = THPrefToolBarLocalize(@"Preview");
		image = [NSImage imageNamed:@"TH32_Preview"];
		action = @selector(switchPrefTab:);
	} else if ([itemIdentifier isEqualToString:THPrefPluginItemIdentifier]) {
		label = THPrefToolBarLocalize(@"Plugin");
		image = [NSImage imageNamed:@"TH32_PlugIn"];
		action = @selector(switchPrefTab:);
	} else if ([itemIdentifier isEqualToString:THPrefAdvancedItemIdentifier]) {
		label = THPrefToolBarLocalize(@"Advanced");
		image = [NSImage imageNamed:@"TH32_Advanced"];
		action = @selector(switchPrefTab:);
	} else if ([itemIdentifier isEqualToString:THPrefDebugItemIdentifier]) {
		label = THPrefToolBarLocalize(@"Debug");
		image = [NSImage imageNamed:@"TH32_Debug"];
		action = @selector(switchPrefTab:);
		/*
	} else if ([itemIdentifier isEqualToString:THPrefProcessorsViewItem]) {
		label = THPrefToolBarLocalize(@"Processors");
		image = [NSImage imageNamed:@"TH32_PlugIn"];
		action = @selector(switchPrefTab:);
		*/
	}
	
	// Set item attributes
	if (label) [tempItem setLabel:label];
	if (image) [tempItem setImage:image];
	if (action) [tempItem setAction:action];
	if (paletteLabel) [tempItem setPaletteLabel:paletteLabel];
	else if (label) [tempItem setPaletteLabel:label];
	return tempItem;	
	
}

#pragma mark -
#pragma mark NSWindow Delegate Methods
- (void)windowDidBecomeKey:(NSNotification *)notification {
	NSURLCache *cache = [NSURLCache sharedURLCache];
	int diskCapacity = [cache diskCapacity];
	int diskUsage = [cache currentDiskUsage];
	double usage = (double)diskUsage / (double)diskCapacity;
	double usageMB = (double)diskUsage / (1024*1024);
	double capacityMB = (double)diskCapacity / (1024*1024);
	NSString *usageString = [NSString stringWithFormat:@"%#.1fMB / %#.1fMB", usageMB, capacityMB];
	[self setWebCacheUsage:usage];
	[self setWebCacheUsageString:usageString];
}
- (void)windowDidResignKey:(NSNotification *)notification {
	[_prefWindow endEditingFor:nil];
}

#pragma mark -
#pragma mark Accessors

-(NSDictionary *)pluginDictionary {
	return [[T2PluginManager sharedManager] pluginDictionary];
}

-(T2PluginManager *)pluginManager { return [T2PluginManager sharedManager]; }

-(void)setSelectedPlugin:(id)plugin { _selectedPlugin = plugin; }
-(id)selectedPlugin { return _selectedPlugin; }
-(void)setSelectedListImporterPlugin:(id)plugin { _selectedListImporterPlugin = plugin; }
-(id)selectedListImporterPlugin { return _selectedListImporterPlugin; }
	//-(NSArray *)partialHTMLExporterPlugins ;
	//-(void)setSelectedThreadProcessorPlugin:(id)plugin { 
	//-(id)selectedThreadProcessorPlugin ;

-(void)setSelectedPartialHTMLExporterPlugin:(id)plugin { _selectedPartialHTMLPlugin = plugin; }
-(id)selectedPartialHTMLExporterPlugin { return _selectedPartialHTMLPlugin; }

-(void)setSelectedHTMLExporterPlugin:(id)plugin { _selectedHTMLExporterPlugin = plugin; }
-(id)selectedHTMLExporterPlugin { return _selectedHTMLExporterPlugin; }
	
-(void)setSelectedURLPreviewerPlugin:(id)plugin { _selectedURLPreviewerPlugin = plugin; }
-(id)selectedURLPreviewerPlugin { return _selectedURLPreviewerPlugin; }


#pragma mark -
#pragma mark Font Prefs
-(void)loadFont {
	NSArray *fontKeys = [NSArray arrayWithObjects:
						 @"webStandardFont",
						 @"webFixedFont",
						 @"sourceListFont",
						 @"threadListFont",
						 @"draftFont",
						 nil];
	NSEnumerator *fontKeyEnumerator = [fontKeys objectEnumerator];
	NSString *fontKey;
	while (fontKey = [fontKeyEnumerator nextObject]) {
		NSFont *font = [self fontFromPref:[fontKey stringByAppendingString:@"_Name"]
									 size:[fontKey stringByAppendingString:@"_Size"]];
		if (!font) font = [NSFont systemFontOfSize:12];
		[self setValue:font forKey:fontKey];
	}
}
-(void)saveFont {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSArray *fontKeys = [NSArray arrayWithObjects:
						 @"webStandardFont",
						 @"webFixedFont",
						 @"sourceListFont",
						 @"threadListFont",
						 //@"draftFont",
						 nil];
	NSEnumerator *fontKeyEnumerator = [fontKeys objectEnumerator];
	NSString *fontKey;
	while (fontKey = [fontKeyEnumerator nextObject]) {
		NSFont *font = [self valueForKey:fontKey];
		if (font) {
			[userDefaults setObject:[font fontName] 
							 forKey:[fontKey stringByAppendingString:@"_Name"]];
			[userDefaults setFloat:[font pointSize] 
							forKey:[fontKey stringByAppendingString:@"_Size"]];
		}
	}
}
-(NSFont *)fontFromPref:(NSString *)nameKey size:(NSString *)sizeKey {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *fontName = [userDefaults stringForKey:nameKey];
	float fontSize = [userDefaults floatForKey:sizeKey];
	if (!fontName || !fontSize) {
		if ([nameKey hasPrefix:@"web"] || [nameKey hasPrefix:@"draft"]) {
			return [NSFont systemFontOfSize:12.0];
		} else {
			return [NSFont systemFontOfSize:10.0];
		}
	}
	else return [NSFont fontWithName:fontName size:fontSize];
}
/*
-(void)changeFont:(id)sender {
	switch (_changingFont) {
		case 1:[self setWebStandardFont:[sender convertFont:_webStandardFont]]; break;
		case 2:[self setWebFixedFont:[sender convertFont:_webFixedFont]]; break;
	}
}
-(IBAction)registerChangingFont:(id)sender {
	_changingFont = [(NSControl *)sender tag];
	NSFont *tempFont = nil;
	switch (_changingFont) {
		case 1:tempFont = _webStandardFont; break;
		case 2:tempFont = _webFixedFont; break;
	}
	[_prefWindow makeFirstResponder:_prefWindow];
    [[NSFontManager sharedFontManager] setSelectedFont:tempFont isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
}
 }*/

#pragma mark -
-(void)setWebStandardFont:(NSFont *)aFont {
	setObjectWithRetain(_webStandardFont, aFont);
	/*
	[self willChangeValueForKey:@"webStandardFontDisplayName"];
	[aFont retain];
	[_webStandardFont release];
	_webStandardFont = aFont;
	[self didChangeValueForKey:@"webStandardFontDisplayName"];
	 */
	
	[_webPreferences setStandardFontFamily:[_webStandardFont familyName]];
	[_webPreferences setDefaultFontSize:(int)[_webStandardFont pointSize]];
	
	[_postingWebPreferences setStandardFontFamily:[_webStandardFont familyName]];
	[_postingWebPreferences setDefaultFontSize:(int)[_webStandardFont pointSize]];
}
-(NSFont *)webStandardFont { return _webStandardFont; }
-(NSString *)webStandardFontDisplayName { return THFontDisplayName(_webStandardFont); }
-(void)setWebFixedFont:(NSFont *)aFont {
	setObjectWithRetain(_webFixedFont, aFont);
	/*
	[self willChangeValueForKey:@"webFixedFontDisplayName"];
	[aFont retain];
	[_webFixedFont release];
	_webFixedFont = aFont;
	[self didChangeValueForKey:@"webFixedFontDisplayName"];
	 */
	
	[_webPreferences setFixedFontFamily:[_webFixedFont familyName]];
	[_webPreferences setDefaultFixedFontSize:(int)[_webFixedFont pointSize]];
	
	[_postingWebPreferences setFixedFontFamily:[_webFixedFont familyName]];
	[_postingWebPreferences setDefaultFixedFontSize:(int)[_webFixedFont pointSize]];
}
-(NSFont *)webFixedFont { return _webFixedFont; }
-(NSString *)webFixedFontDisplayName { return THFontDisplayName(_webFixedFont); }

-(void)setSourceListFont:(NSFont *)sourceListFont {
	setObjectWithRetain(_sourceListFont, sourceListFont);
	[THBookmarkController setClassSourceTableFont:sourceListFont];
	if (_isLoaded) {
		[self setSourceTableRowHeight:[sourceListFont pointSize]+5];
	}
}
-(NSFont *)sourceListFont { return _sourceListFont; }
-(void)setThreadListFont:(NSFont *)threadListFont {
	setObjectWithRetain(_threadListFont, threadListFont);
	[THBookmarkController setClassThreadTableFont:threadListFont];
	if (_isLoaded) {
		[self setThreadTableRowHeight:[threadListFont pointSize]+5];
	}
}
-(NSFont *)threadListFont { return _threadListFont; }
-(void)setDraftFont:(NSFont *)draftFont {
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSFont *font = draftFont;
	if (font) {
		[userDefaults setObject:[font fontName] 
						 forKey:@"draftFont_Name"];
		[userDefaults setFloat:[font pointSize] 
						forKey:@"draftFont_Size"];
	}
	
	setObjectWithRetain(_draftFont, draftFont);
}
-(NSFont *)draftFont { return _draftFont; }

#pragma mark -

-(void)setSourceTableFontSize:(float)fontSize {
}
-(float)sourceTableFontSize {return 11.0; }
-(void)setThreadTableFontSize:(float)fontSize {
}
-(float)threadTableFontSize {return 10.0; }
 
-(void)setSourceTableRowHeight:(float)rowHeight { [THBookmarkController setClassSourceTableRowHeight:rowHeight]; }
-(float)sourceTableRowHeight { return [THBookmarkController classSourceTableRowHeight]; }
-(void)setThreadTableRowHeight:(float)rowHeight { [THBookmarkController setClassThreadTableRowHeight:rowHeight]; }
-(float)threadTableRowHeight { return [THBookmarkController classThreadTableRowHeight]; }

#pragma mark -
#pragma mark Label Pref
-(void)setLabelDictionary:(NSMutableDictionary *)labelDictionary {
	if ([labelDictionary isKindOfClass:[NSMutableDictionary class]]) {
		setObjectWithRetain(_labelDictionary, labelDictionary);
	} else if ([labelDictionary isKindOfClass:[NSDictionary class]]) {
		setObjectWithRetain(_labelDictionary, [[labelDictionary mutableCopy] autorelease]);
	}
	[self updateLabels];
}
-(NSMutableDictionary *)labelDictionary {
	return _labelDictionary;
}
-(void)updateLabels {
	T2LabeledCellManager *labeledCellManager = [T2LabeledCellManager sharedManager];
	NSArray *oldColors = [labeledCellManager labelColors];
	NSArray *oldNames = [labeledCellManager labelNames];
	
	NSMutableArray *colors = [NSMutableArray array];
	NSMutableArray *names = [NSMutableArray array];
	[names addObject:NSLocalizedString(@"None", @"Colors")];
	
	unsigned i, maxCount = [_labelDictionary count];
	for (i=0; i<maxCount; i++) {
		NSString *colorKey = [NSString stringWithFormat:@"labelColor%d", i+1];
		NSString *nameKey = [NSString stringWithFormat:@"labelName%d", i+1];
		[self willChangeValueForKey:colorKey];
		[self willChangeValueForKey:nameKey];
		NSColor *color = [_labelDictionary objectForKey:colorKey];
		NSString *name = [_labelDictionary objectForKey:nameKey];
		if (color && name) {
			[colors addObject:color];
			[names addObject:name];
		}
		[self didChangeValueForKey:colorKey];
		[self didChangeValueForKey:nameKey];
	}
	/*
	maxCount = [colors count];
	if ([oldColors count] > maxCount) {
		NSArray *unchangedOldColors = [oldColors subarrayWithRange:NSMakeRange(maxCount, [oldColors count]-maxCount)];
		NSArray *unchangedOldNames = [oldNames subarrayWithRange:NSMakeRange(maxCount, [oldColors count]-maxCount)];
		[colors addObjectsFromArray:unchangedOldColors];
		[names addObjectsFromArray:unchangedOldNames];
	}
	 */
	[labeledCellManager setLabelColors:colors labelNames:names];
}


#pragma mark -
#pragma mark Appearance Pref
-(BOOL)laterThanLeopard {
	SInt32 MacVersion;
	if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr){
		if (MacVersion >= 0x1050){
			return YES;
		}
	}
	return NO;
}
-(BOOL)laterThanTiger {
	SInt32 MacVersion;
	if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr){
		if (MacVersion >= 0x1040){
			return YES;
		}
	}
	return NO;
}

-(void)setBrowserMetal:(BOOL)aBool {
	[THMetalWindow setClassTexturedBackground:aBool];
}
-(BOOL)browserMetal { return [THMetalWindow classTexturedBackground]; }

-(void)setUseAppleAppLikeSourceTable:(BOOL)aBool {
	[THBookmarkController setClassUseAppleAppLikeSourceTable:aBool];
}
-(BOOL)useAppleAppLikeSourceTable { return [THBookmarkController classUseAppleAppLikeSourceTable]; }

-(BOOL)runningOnLeopard {
	return [self laterThanLeopard];
}

-(NSArray *)iconSetNames { return _iconSetNames; }
-(BOOL)iconSetSelectable { 
	if ([_iconSetNames count] > 1) return YES;
	return NO;
}
-(void)setIconSetName:(NSString *)aString {
	setObjectWithRetain(_iconSetName, aString);
}
-(NSString *)iconSetName { return _iconSetName; }

#pragma mark -
#pragma mark Thread Table Pref
/*
-(void)setThreadTableAllowedColumnIdentifers:(NSArray *)identifers {
	NSSet *set = [NSSet setWithArray:identifers];
	[THBookmarkController setClassThreadTableAllowedColumnsIdentiferSet:set];
}
-(NSArray *)threadTableAllowedColumnIdentifers {
	NSSet *set = [THBookmarkController classThreadTableAllowedColumnsIdentiferSet];
	return [set allObjects];
}
 */
-(void)setClassVisibleOfThreadTableColumnForIdentifier:(NSString *)identifier visible:(BOOL)visible {
	[THBookmarkController setClassVisibleOfThreadTableColumnForIdentifier:identifier visible:visible];
}
-(BOOL)classVisibleOfThreadTableColumnForIdentifier:(NSString *)identifier {
	return [THBookmarkController classVisibleOfThreadTableColumnForIdentifier:identifier];
}

-(void)setVisibleOfThreadTableColumn_stateImage:(BOOL)visible {
	[self setClassVisibleOfThreadTableColumnForIdentifier:@"stateImage" visible:visible];
}
-(BOOL)visibleOfThreadTableColumn_stateImage {
	return [self classVisibleOfThreadTableColumnForIdentifier:@"stateImage"];
}
-(void)setVisibleOfThreadTableColumn_resCountNew:(BOOL)visible {
	[self setClassVisibleOfThreadTableColumnForIdentifier:@"resCountNew" visible:visible];
}
-(BOOL)visibleOfThreadTableColumn_resCountNew {
	return [self classVisibleOfThreadTableColumnForIdentifier:@"resCountNew"];
}
-(void)setVisibleOfThreadTableColumn_resCount:(BOOL)visible {
	[self setClassVisibleOfThreadTableColumnForIdentifier:@"resCount" visible:visible];
}
-(BOOL)visibleOfThreadTableColumn_resCount {
	return [self classVisibleOfThreadTableColumnForIdentifier:@"resCount"];
}
-(void)setVisibleOfThreadTableColumn_resCountGap:(BOOL)visible {
	[self setClassVisibleOfThreadTableColumnForIdentifier:@"resCountGap" visible:visible];
}
-(BOOL)visibleOfThreadTableColumn_resCountGap {
	return [self classVisibleOfThreadTableColumnForIdentifier:@"resCountGap"];
}
-(void)setVisibleOfThreadTableColumn_order:(BOOL)visible {
	[self setClassVisibleOfThreadTableColumnForIdentifier:@"order" visible:visible];
}
-(BOOL)visibleOfThreadTableColumn_order {
	return [self classVisibleOfThreadTableColumnForIdentifier:@"order"];
}
-(void)setVisibleOfThreadTableColumn_createdDate:(BOOL)visible {
	[self setClassVisibleOfThreadTableColumnForIdentifier:@"createdDate" visible:visible];
}
-(BOOL)visibleOfThreadTableColumn_createdDate {
	return [self classVisibleOfThreadTableColumnForIdentifier:@"createdDate"];
}
-(void)setVisibleOfThreadTableColumn_labelScore:(BOOL)visible {
	[self setClassVisibleOfThreadTableColumnForIdentifier:@"labelScore" visible:visible];
}
-(BOOL)visibleOfThreadTableColumn_labelScore {
	return [self classVisibleOfThreadTableColumnForIdentifier:@"labelScore"];
}
-(void)setVisibleOfThreadTableColumn_velocity:(BOOL)visible {
	[self setClassVisibleOfThreadTableColumnForIdentifier:@"velocity" visible:visible];
}
-(BOOL)visibleOfThreadTableColumn_velocity {
	return [self classVisibleOfThreadTableColumnForIdentifier:@"velocity"];
}
-(void)setVisibleOfThreadTableColumn_valiable:(BOOL)visible {
	[self setClassVisibleOfThreadTableColumnForIdentifier:@"__variable__" visible:visible];
}
-(BOOL)visibleOfThreadTableColumn_valiable {
	return [self classVisibleOfThreadTableColumnForIdentifier:@"__variable__"];
}

#pragma mark -
#pragma mark General Pref
-(NSArray *)localizedDefaultExtractPaths {
	return [[T2PluginManager sharedManager] localizedDefaultExtractPaths];
}
-(void)setDefaultExtractPathIndex:(int)index {
	NSArray *defaultExtractPaths = [[T2PluginManager sharedManager] defaultExtractPaths];
	if (index >= [defaultExtractPaths count]) index = 0;
	NSString *path = [defaultExtractPaths objectAtIndex:index];
	[THThreadController setClassDefaultResExtractPath:path];
}
-(int)defaultExtractPathIndex {
	NSArray *defaultExtractPaths = [[T2PluginManager sharedManager] defaultExtractPaths];
	NSString *path = [THThreadController classDefaultResExtractPath];
	NSUInteger index = [defaultExtractPaths indexOfObject:path];
	if (index == NSNotFound) index = 0;
	return index;
}

/*
 typedef enum {
 THPreviewNone = 0,
 THPreviewInPopUp,
 THPreviewInline,
 THPreviewMove,
 THPreviewInNewTab,
 THPreviewDownload,
 THPreviewWebBrowser
 } THPreviewActionType;
 */

-(NSArray *)popUpPreviewActionNames {
	if (!_popUpPreviewActionNames) {
		_popUpPreviewActionNames = [[NSArray arrayWithObjects:
									 NSLocalizedString(@"THPreviewNone", @"App"),
									 NSLocalizedString(@"THPreviewInPopUp", @"App"),
									 nil] retain];
	}
	return _popUpPreviewActionNames;
}
-(void)setPopUpPreviewActionIndex:(int)index {
}
	
-(int)popUpPreviewActionIndex {
}

-(void)setPopUpResPreviewActionIndex:(int)index {
	THPreviewActionType action;
	switch (index) {
		case 0: {	action = THPreviewNone;		break;	}
		case 1: {	action = THPreviewInPopUp;	break;	}
	}
	[THThreadController setClassPopUpResAnchorElementActionType:action];
}
-(int)popUpResPreviewActionIndex {
	THPreviewActionType action = [THThreadController classPopUpResAnchorElementActionType];
	switch (action) {
		case THPreviewNone:		return 0;
		case THPreviewInPopUp:	return 1;
        default:
            break;
	}
	return 0;
}
-(void)setPopUpURLPreviewActionIndex:(int)index {
	THPreviewActionType action;
	switch (index) {
		case 0: {	action = THPreviewNone;		break;	}
		case 1: {	action = THPreviewInPopUp;	break;	}
        default:
            break;
	}
	[THThreadController setClassPopUpOtherAnchorElementActionType:action];
}
-(int)popUpURLPreviewActionIndex {
	THPreviewActionType action = [THThreadController classPopUpOtherAnchorElementActionType];
	switch (action) {
		case THPreviewNone:		return 0;
		case THPreviewInPopUp:	return 1;
        default:
            break;
	}
	return 0;
}

-(NSArray *)clickResPreviewActionNames {
	if (!_clickResPreviewActionNames) {
		_clickResPreviewActionNames = [[NSArray arrayWithObjects:
										NSLocalizedString(@"THPreviewNone", @"App"),
										NSLocalizedString(@"THPreviewInPopUp", @"App"),
										NSLocalizedString(@"THPreviewInline", @"App"),
										NSLocalizedString(@"THPreviewMove", @"App"),
										NSLocalizedString(@"THPreviewInNewTab", @"App"),
										nil] retain];
	}
	return _clickResPreviewActionNames;
}
-(void)setClickResPreviewActionIndex:(int)index {
	THPreviewActionType action;
	switch (index) {
		case 0: {	action = THPreviewNone;		break;	}
		case 1: {	action = THPreviewInPopUp;	break;	}
		case 2: {	action = THPreviewInline;	break;	}
		case 3: {	action = THPreviewMove;		break;	}
		case 4: {	action = THPreviewInNewTab;	break;	}
	}
	[THThreadController setClassClickResAnchorElementActionType:action];
}
-(int)clickResPreviewActionIndex {
	THPreviewActionType action = [THThreadController classResClickAnchorElementActionType];
	switch (action) {
		case THPreviewNone:		return 0;
		case THPreviewInPopUp:	return 1;
		case THPreviewInline:	return 2;
		case THPreviewMove:		return 3;
		case THPreviewInNewTab:	return 4;
        default:
            break;
	}
	return 0;
}

-(NSArray *)clickURLPreviewActionNames {
	if (!_clickURLPreviewActionNames) {
		_clickURLPreviewActionNames = [[NSArray arrayWithObjects:
										NSLocalizedString(@"THPreviewNone", @"App"),
										NSLocalizedString(@"THPreviewInPopUp", @"App"),
										NSLocalizedString(@"THPreviewInline", @"App"),
										NSLocalizedString(@"THPreviewWebBrowser", @"App"),
										nil] retain];
	}
	return _clickURLPreviewActionNames;
}
-(void)setClickURLPreviewActionIndex:(int)index {
	THPreviewActionType action;
	switch (index) {
		case 0: {	action = THPreviewNone;				break;	}
		case 1: {	action = THPreviewInPopUp;			break;	}
		case 2: {	action = THPreviewInline;			break;	}
		case 3: {	action = THPreviewWebBrowser;		break;	}
	}
	[THThreadController setClassClickOtherAnchorElementActionType:action];
}
-(int)clickURLPreviewActionIndex {
	THPreviewActionType action = [THThreadController classOtherClickAnchorElementActionType];
	switch (action) {
		case THPreviewNone:				return 0;
		case THPreviewInPopUp:			return 1;
		case THPreviewInline:			return 2;
		case THPreviewWebBrowser:		return 3;
        default:
            break;
	}
	return 0;
}

-(void)setMaxThreadTabCount:(int)anInt {
	[THDocument setClassMaxThreadTabCount:anInt];
}
-(int)maxThreadTabCount { return [THDocument classMaxThreadTabCount]; }

-(void)setResPopUpWindowWidth:(float)width {
	[T2ThreadView setClassResPopUpWindowWidth:width];
}
-(float)resPopUpWindowWidth { return [T2ThreadView classResPopUpWindowWidth]; }


-(void)setPopUpDelaySeconds:(float)delaySeconds {
	[T2ThreadView setClassPopUpWait:delaySeconds];
}
-(float)popUpDelaySeconds {
	return [T2ThreadView classPopUpWait];
}

-(void)setNewTabLocationType:(int)type {
	if (type == 0)
		[THDocument setClassNewTabAppearsInRightEnd:YES];
	else
		[THDocument setClassNewTabAppearsInRightEnd:NO];
}
-(int)newTabLocationType {
	if ([THDocument classNewTabAppearsInRightEnd])
		return 0;
	else
		return 1;
}

#pragma mark -

-(void)setUsedNames:(NSArray *)array {
	[THPostingWindowController setClassUsedNames:array];
}
-(NSArray *)usedNames { return [THPostingWindowController classUsedNames]; }
-(void)setUsedMails:(NSArray *)array {
	[THPostingWindowController setClassUsedMails:array];
}
-(NSArray *)usedMails { return [THPostingWindowController classUsedMails]; }


#pragma mark -
-(void)setAllowsTypeToJump:(BOOL)aBool { [T2ThreadView setClassAllowsTypeToJump:aBool]; }
-(BOOL)allowsTypeToJump { return ([T2ThreadView classAllowsTypeToJump] && [self laterThanTiger]); }
-(void)setTypeWait:(float)aFloat { [T2ThreadView setClassTypeWait:aFloat]; }
-(float)typeWait { return [T2ThreadView classTypeWait]; }

#pragma mark -
#pragma mark Advanced Pref

-(void)setAbbreviatedLogFolderPath:(NSString *)path {
	[self setLogFolderPath:[path stringByExpandingTildeInPath]];
}
-(NSString *)abbreviatedLogFolderPath {
	return [[NSString appLogFolderPath] stringByAbbreviatingWithTildeInPath];
}

-(void)setLogFolderPath:(NSString *)path {
	if (!path || ![path isExistentPath]) return;
	
	if (![[path lastPathComponent] isEqualToString:@"Log files"]) {
		path = [path stringByAppendingPathComponent:@"Log files"];
		[path prepareFoldersInPath];
	}
	if ([path isEqualToString:[NSString appLogFolderPath]]) return;
	
	[[T2ThreadHistory threadHistoryForKey:@"threadHistory"] saveToFile];
	[[T2ThreadHistory threadHistoryForKey:@"resPostedThreadHistory"] saveToFile];
	[[T2ListHistory listHistoryForKey:@"threadListHistory"] saveToFile];
	[[T2SourceList sharedSourceList] saveToFile];
	
	[NSString setAppLogFolderPath:path];
	
	[[T2ThreadHistory threadHistoryForKey:@"threadHistory"] loadFromFile];
	[[T2ThreadHistory threadHistoryForKey:@"resPostedThreadHistory"] loadFromFile];
	[[T2ListHistory listHistoryForKey:@"threadListHistory"] loadFromFile];
	[[T2SourceList sharedSourceList] loadFromFile];
}
-(NSString *)logFolderPath { return [NSString appLogFolderPath]; }

-(void)setDownloadInThreadFolder:(BOOL)aBool { [THDownloadWindowController setClassDownloadInThreadFolder:aBool]; }
-(BOOL)downloadInThreadFolder { return [THDownloadWindowController classDownloadInThreadFolder]; }
-(void)setDownloadWhenFilesExist:(BOOL)aBool { [THWebDownloader setClassDownloadWhenFilesExist:aBool]; }
-(BOOL)downloadWhenFilesExist { return [THWebDownloader classDownloadWhenFilesExist]; }

-(void)setAbbreviatedDownloadDestinationFolderPath:(NSString *)path {
	[self setDownloadDestinationFolderPath:[path stringByExpandingTildeInPath]];
}
-(NSString *)abbreviatedDownloadDestinationFolderPath {
	return [[THDownloadWindowController classDownloadDestinationFolderPath] stringByAbbreviatingWithTildeInPath];
}
-(void)setDownloadDestinationFolderPath:(NSString *)path {
	[THDownloadWindowController setClassDownloadDestinationFolderPath:path];
}
-(NSString *)downloadDestinationFolderPath { return [THDownloadWindowController classDownloadDestinationFolderPath]; }

-(void)setWebCacheUsageString:(NSString *)aString { setObjectWithRetain(_webCacheUsageString, aString); }
-(NSString *)webCacheUsageString { return _webCacheUsageString; }
-(void)setWebCacheUsage:(double)aDouble {
	_webCacheUsage = aDouble;
	if (_webCacheIndicator) {
		[_webCacheIndicator setDoubleValue:_webCacheUsage];
	}
}
-(double)webCacheUsage { return _webCacheUsage; }

-(void)setShowsDebugMenu:(BOOL)aBool { _showsDebugMenu = aBool; }
-(BOOL)showsDebugMenu { return _showsDebugMenu; }

-(void)setSafari2Debug:(BOOL)aBool { [T2ThreadView setClassSafari2Debug:aBool]; }
-(BOOL)safari2Debug { return [T2ThreadView classSafari2Debug]; }

-(void)setEnableThreadListCache:(BOOL)aBool { [[THAppDelegate sharedInstance] setEnableThreadListCache:aBool]; }
-(BOOL)enableThreadListCache { [[THAppDelegate sharedInstance] enableThreadListCache]; }
-(void)setEnablePrefetchThread:(BOOL)aBool { [[THAppDelegate sharedInstance] setEnablePrefetchThread:aBool]; }
-(BOOL)enablePrefetchThread { return [[THAppDelegate sharedInstance] enablePrefetchThread]; }

-(BOOL)useProxy { return _useProxy; }
-(void)setUseProxy:(BOOL)aBool { _useProxy = aBool; }
-(void)setProxyHost:(NSString *)host {}
-(NSString *)proxyHost { return @"test"; }


#pragma mark -
#pragma mark KVC
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
	if ([key hasPrefix:@"labelName"] || [key hasPrefix:@"labelColor"]) {
		[_labelDictionary setValue:value forKey:key];
		[self updateLabels];
	} else {
		[super setValue:value forUndefinedKey:key];
	}
}
- (id)valueForUndefinedKey:(NSString *)key {
	if ([key hasPrefix:@"labelName"] || [key hasPrefix:@"labelColor"]) {
		return [_labelDictionary valueForKey:key];
	} else {
		return [super valueForUndefinedKey:key];
	}	
}

#pragma mark -
#pragma mark Methods
-(void)saveAllPrefs {
	[self saveFont];
	NSDictionary *appDelegatePrefDic = [self encodedDictionary];
	[[NSUserDefaults standardUserDefaults] setObject:appDelegatePrefDic forKey:__appDelegatePrefKey];
}

- (IBAction)checkUseProxy:(id)sender {
}

#pragma mark -
#pragma mark Actions

-(IBAction)switchPrefTab:(id)sender {
	[_prefWindow endEditingFor:nil];
	[_prefTabView selectTabViewItemWithIdentifier:[(NSToolbarItem *)sender itemIdentifier]];
}
-(IBAction)clearNameAndMailHistory:(id)sender {
	[self setUsedNames:nil];
	[self setUsedMails:nil];
}

-(IBAction)reloadSkins:(id)sender {
	THStandardViewPlug *viewPlug = (THStandardViewPlug *)[[T2PluginManager sharedManager] pluginForUniqueName:@"jp_natori_Thousand_standardHTMLView"];
	if (viewPlug) {
		[viewPlug loadTemplateList];
		[viewPlug loadTemplate];
	}
}

-(IBAction)selectLogFolderPath:(id)sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanCreateDirectories:YES];
	NSString *filePath = [self logFolderPath];
	NSWindow *window = nil;
	if ([sender isKindOfClass:[NSView class]]) {
		window = [(NSView *)sender window];
	}
    // beginSheetForDirectoryがdepricateなのでそのうち下に差し替え
//    [openPanel setNameFieldStringValue:filePath];
//    [openPanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
//        if (result == NSFileHandlingPanelOKButton) {
//            NSURL* theDoc = [[openPanel URLs] objectAtIndex:0];
//            if ([[theDoc filePath] isExistentPath])
//            {
//                [self setLogFolderPath:[theDoc filePath]];
//            }
//        }
//    }];
	[openPanel beginSheetForDirectory:filePath
								 file:filePath
								types:nil
					   modalForWindow:window
						modalDelegate:self
					   didEndSelector:@selector(openLogFolderPanelDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
}
- (void)openLogFolderPanelDidEnd:(NSOpenPanel *)panel
									  returnCode:(int)returnCode  contextInfo:(void  *)contextInfo {
	if (returnCode != NSOKButton) return;
	NSString *filePath = [[panel URL] filePath];
	if ([filePath isExistentPath])
		[self setLogFolderPath:filePath];
	
}

-(IBAction)selectDownloadDestinationFolderPath:(id)sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanCreateDirectories:YES];
	NSString *filePath = [self downloadDestinationFolderPath];
	NSWindow *window = nil;
	if ([sender isKindOfClass:[NSView class]]) {
		window = [(NSView *)sender window];
	}
	[openPanel beginSheetForDirectory:filePath
								 file:filePath
								types:nil
					   modalForWindow:window
						modalDelegate:self
					   didEndSelector:@selector(openDownloadDestinationFolderPanelDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];

}
- (void)openDownloadDestinationFolderPanelDidEnd:(NSOpenPanel *)panel
									  returnCode:(int)returnCode  contextInfo:(void  *)contextInfo {
	if (returnCode != NSOKButton) return;
	NSString *filePath = [panel filename];
	if ([filePath isExistentPath])
		[self setDownloadDestinationFolderPath:filePath];
	
}
-(IBAction)clearWebCache:(id)sender {
	[[NSURLCache sharedURLCache] removeAllCachedResponses];
	[self windowDidBecomeKey:nil];
}
/*
-(IBAction)sourceTableFontSizeEntered:(id)sender {
	float fontSize = [_sourceListFontSizeComboBox floatValue];
	if (fontSize == [self sourceTableFontSize])
		return;
	[self willChangeValueForKey:@"sourceTableFontSize"];
	[THBookmarkController setClassSourceTableFontSize:fontSize];
	[self didChangeValueForKey:@"sourceTableFontSize"];
	[self setSourceTableRowHeight:fontSize+5];
}
-(IBAction)threadTableFontSizeEntered:(id)sender {
	float fontSize = [_threadListFontSizeComboBox floatValue];
	if (fontSize == [self threadTableFontSize])
		return;
	[self willChangeValueForKey:@"threadTableFontSize"];
	[THBookmarkController setClassThreadTableFontSize:fontSize];
	[self didChangeValueForKey:@"threadTableFontSize"];
	[self setThreadTableRowHeight:fontSize+5];
}
 */
-(IBAction)reloadMasterList:(id)sender {
	id the2chPlugin = [[T2PluginManager sharedManager] pluginForUniqueName:@"jp_natori_Thousand_2chImporter"];
	if (the2chPlugin) {
		[the2chPlugin reloadMasterList:sender];
	}
}
-(IBAction)logoutViewer:(id)sender {
	id the2chPlugin = [[T2PluginManager sharedManager] pluginForUniqueName:@"jp_natori_Thousand_2chImporter"];
	if (the2chPlugin) {
		[the2chPlugin logoutViewer:sender];
	}
}
-(IBAction)loginViewer:(id)sender {
	id the2chPlugin = [[T2PluginManager sharedManager] pluginForUniqueName:@"jp_natori_Thousand_2chImporter"];
	if (the2chPlugin) {
		[the2chPlugin loginViewer:sender];
	}
}
-(IBAction)loginP2:(id)sender {
	id the2chPlugin = [[T2PluginManager sharedManager] pluginForUniqueName:@"jp_natori_Thousand_2chImporter"];
	if (the2chPlugin) {
		[the2chPlugin loginP2:sender];
	}
}
-(IBAction)logoutP2:(id)sender {
	id the2chPlugin = [[T2PluginManager sharedManager] pluginForUniqueName:@"jp_natori_Thousand_2chImporter"];
	if (the2chPlugin) {
		[the2chPlugin logoutP2:sender];
	}
}
-(IBAction)loginBe:(id)sender {
	id the2chPlugin = [[T2PluginManager sharedManager] pluginForUniqueName:@"jp_natori_Thousand_2chImporter"];
	if (the2chPlugin) {
		[the2chPlugin loginBe:sender];
	}
}
-(IBAction)logoutBe:(id)sender {
	id the2chPlugin = [[T2PluginManager sharedManager] pluginForUniqueName:@"jp_natori_Thousand_2chImporter"];
	if (the2chPlugin) {
		[the2chPlugin logoutBe:sender];
	}
}	
@end
