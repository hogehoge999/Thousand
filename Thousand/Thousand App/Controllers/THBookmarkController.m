//
//  THBookmarkController.m
//  Thousand
//
//  Created by R. Natori on 05/08/01.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "THBookmarkController.h"
#import "THAppDelegate.h"
#import "THDocument.h"
#import "THThreadController.h"
#import "T2FilterArrayController.h"
#import "T2Browser.h"
#import "T2BrowserMatrix.h"
#import "T2TableView.h"
#import "THTableHeaderView.h"
#import "THLocalFileImporter.h"
#import "THAddBookmarkWindowController.h"
#import "THPostingWindowController.h"
#import "T2LabeledCell.h"
#import "THSplitView.h"
#import "THT2ThreadListAdditions.h"
#import "THT2TableViewAdditions.h"
#import "THSaveOperation.h"
#import "THChooseNextThreadWindowController.h"

static NSArray *__sourceTableAcceptablePboardTypes = nil;
static NSArray *__threadTableAcceptablePboardTypes = nil;
static NSArray *__otherThreadTableAcceptablePboardTypes = nil;
static NSArray *__allThreadTableAcceptablePboardTypes = nil;
static NSString *__threadTableDefaultsName = @"threadTable";
static NSString *__threadTableAllowedColumnsChangedNotificationName = @"threadTableAllowedColumnsChangedNotificationName";
static NSString *__sourceTableFontSizeChangedNotificationName = @"sourceTableFontSizeChangedNotificationName";
static NSString *__threadTableFontSizeChangedNotificationName = @"threadTableFontSizeChangedNotificationName";

static THLocalFileImporter *__localFileImporter = nil;

static T2SourceList *__sourceList = nil;
//static unsigned __firstBookmarkIndex = 0;

static NSTimeInterval __nextThreadLoadingInterval = 0.2;

static BOOL __classUseAppleAppLikeSourceTable = YES;
static NSSet *__classThreadTableAllowedColumnsIdentiferSet = nil;

static NSFont * __classSourceTableFont = nil;
static NSFont * __classThreadTableFont = nil;
static float __classSourceTableRowHeight = 17.0;
static float __classThreadTableRowHeight = 17.0;

@implementation THBookmarkController

+(void)initialize {
	if (__sourceTableAcceptablePboardTypes) return;
	__sourceTableAcceptablePboardTypes = [[NSArray arrayWithObjects:
		T2BrowserRowPboardType,
		THBookmarkTableRowPboardType,
		THThreadFacesPboardType,
		NSFilenamesPboardType, nil] retain];
	__threadTableAcceptablePboardTypes = [[NSArray arrayWithObjects:
		THThreadListTableRowPboardType, nil] retain];
	__otherThreadTableAcceptablePboardTypes = [[NSArray arrayWithObjects:
		THThreadFacesPboardType,
		NSFilenamesPboardType, nil] retain];
	__allThreadTableAcceptablePboardTypes = [[NSArray arrayWithObjects:
		THThreadListTableRowPboardType,
		THThreadFacesPboardType,
		NSFilenamesPboardType, nil] retain];
	
	__localFileImporter = (THLocalFileImporter *)[[[T2PluginManager sharedManager] pluginForUniqueName:@"jp_natori_THLocalFileImporter"] retain];
	
	__sourceList = [[T2SourceList sharedSourceList] retain];
	
	__classThreadTableAllowedColumnsIdentiferSet = [[NSSet setWithArray:[NSArray arrayWithObjects:
																		 @"stateImage",
																		 @"title",
																		 @"resCountNew",
																		 @"__variable__", nil]] retain];
	
	__classSourceTableFont = [[NSFont systemFontOfSize:11.0] retain];
	__classThreadTableFont = [[NSFont systemFontOfSize:10.0] retain];
}

+(T2BookmarkList *)addCustomBookmarkListToSourceList {
	if (!__sourceList) return nil;
	T2BookmarkListFace *threadListFace = [T2BookmarkListFace bookmarkListFace];
	[threadListFace setTitle:THBookmarkLocalize(@"Untitled Bookmark")];
	T2BookmarkList *threadList = (T2BookmarkList *)[threadListFace list];
				
	NSMutableArray *tempObjects = [[[__sourceList objects] mutableCopy] autorelease];
	[tempObjects addObject:threadListFace];
	[__sourceList setObjects:tempObjects];
	return threadList;
}

-(id)init {
	self = [super init];
	
	_browsingListArray = [[NSMutableArray alloc] init];
	_browserVisible = YES;
	
	// source
	[self setSourceList:__sourceList];
	
	return self;
}

-(void)dealloc {
	if (_timer) {
		[_timer invalidate];
		[_timer release];
		_timer = nil;
	}
	
	[_browsingRootList release];
	[_browsingListArray release];
	[_lastNextThreadLoadingDate release];
	[_threadTableMenuItems release];
	[_threadTableColumns release];
	
	[_threadList release];
	/*
	[_threadFacesController removeObserver:self forKeyPath:@"selectedObjects"];
	[_threadFacesController release];
	 */
	
	[super dealloc];
}

- (void)awakeFromNib {
	//tables
	[_sourceTable setDelegate:self];
	[_sourceTable setDataSource:self];
	[_sourceTable registerForDraggedTypes:__sourceTableAcceptablePboardTypes];
	[_sourceTable setTarget:self];
	//[_sourceTable setAction:@selector(selectList:)];
	[_sourceTable setDeleteKeyAction:@selector(removeSelectedLists:)];
	//[_sourceTable setRightArrowKeyAction:@selector(selectThreadTable:)];
	
	// Table Fonts
	[self reloadSourceTableFontSize:nil];
	[self reloadThreadTableFontSize:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reloadSourceTableFontSize:)
												 name:__sourceTableFontSizeChangedNotificationName
											   object:[self class]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reloadThreadTableFontSize:)
												 name:__threadTableFontSizeChangedNotificationName
											   object:[self class]];
	
	// Leopard Source Look
	SInt32 MacVersion;
	if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr && __classUseAppleAppLikeSourceTable){
		if (MacVersion >= 0x1050){
			// this call is Leopard only
			[_v1SplitView setUsingOnePixDivider:YES];
			[_h1SplitView setUsingOnePixDivider:YES];
			[_v1SplitView setDelegate:self];
			[_h1SplitView setDelegate:self];
			if ([_sourceTable respondsToSelector:@selector(setSelectionHighlightStyle:)]) {
				objc_msgSend(_sourceTable, @selector(setSelectionHighlightStyle:), 1);
			}
			[_sourceTable setHeaderView:nil];
			[_sourceTable setCornerView:nil];
			
			[[_sourceTable enclosingScrollView] setBorderType:NSNoBorder];
			[[_threadTable enclosingScrollView] setBorderType:NSNoBorder];
			[_listBrowser setBorderType:NSNoBorder];
			[_listBrowser setFocusRingType:NSFocusRingTypeNone];
		}
	}
	
	// Table Headers and Columns
	THTableHeaderView *tableHeaderView = [[[THTableHeaderView alloc]
 initWithFrame:[[_threadTable headerView] frame]] autorelease];
	[tableHeaderView setPopUpButton:_scorerPopUpButton];
	[_threadTable setHeaderView:tableHeaderView];
	
	_threadTableColumns = [[_threadTable tableColumns] copy];
	//[_threadTable setAutosaveTableColumns:YES];
	//[_threadTable setAutosaveName:@"threadList"];
	
	[self reloadTableColumns:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reloadTableColumns:)
												 name:__threadTableAllowedColumnsChangedNotificationName
											   object:[self class]];
	
	[_threadTable setDelegate:self];
	[_threadTable setDataSource:self];
	
	[_threadTable registerForDraggedTypes:__allThreadTableAcceptablePboardTypes];
	[_threadTable setTarget:self];
	[_threadTable setAction:@selector(selectThread:)];
	[_threadTable setDoubleAction:@selector(threadTableDoubleClicked:)];
	[_threadTable setDeleteKeyAction:@selector(removeSelectedThreads:)];
	[_threadTable setOtherMouseAction:@selector(openSelectedThread:)];
	//[_sourceTable setLeftArrowKeyAction:@selector(selectSourceTable:)];
	
	NSMenu *threadMenu = [_threadTable menu];
	_threadTableMenuItems = [[threadMenu itemArray] copy];
	
	// Label
	[self updateLabelMenu];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateLabelMenuWithNotification:)
												 name:T2LabelColorsChangedNotification
											   object:nil];
	
	//browser
	[_listBrowser setMatrixClass:[T2BrowserMatrix class]];
	
	
}
-(void)loadSplitViewPositions {
	//splitView
	[_v1SplitView setPositionAutosaveName:@"doc_bookmark_v1"];
	[_h1SplitView setPositionAutosaveName:@"doc_bookmark_h1"];
}

-(void)documentWillClose {
	[_threadTable saveTHTableViewDefaultsWithName:__threadTableDefaultsName];
	//[self setSourceSelectedIndexes:nil];
	[self setBrowsingRootList:nil];
	[self setThreadList:nil];
	[self setSourceList:nil];
	_document = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:T2LabelColorsChangedNotification
												  object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:__threadTableAllowedColumnsChangedNotificationName
												  object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:__sourceTableFontSizeChangedNotificationName
												  object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:__threadTableFontSizeChangedNotificationName
												  object:nil];
}

#pragma mark -
#pragma mark Accessors

+(void)setClassUseAppleAppLikeSourceTable:(BOOL)aBool { 
	__classUseAppleAppLikeSourceTable = aBool;
}
+(BOOL)classUseAppleAppLikeSourceTable {
	return __classUseAppleAppLikeSourceTable;
}

+(void)setClassVisibleOfThreadTableColumnForIdentifier:(NSString *)identifier visible:(BOOL)visible {
	[T2TableView setVisible:visible ofTableColumnWithIdentifier:identifier inDefaultsName:__threadTableDefaultsName];
	[[NSNotificationCenter defaultCenter] postNotificationName:__threadTableAllowedColumnsChangedNotificationName
														object:self];
}
+(BOOL)classVisibleOfThreadTableColumnForIdentifier:(NSString *)identifier {
	return [T2TableView visibleOfTableColumnWithIdentifier:identifier inDefaultsName:__threadTableDefaultsName];
}

+(void)setClassSourceTableFont:(NSFont *)font {
	setObjectWithRetain(__classSourceTableFont, font);
	[[NSNotificationCenter defaultCenter] postNotificationName:__sourceTableFontSizeChangedNotificationName
														object:self];
}
+(NSFont *)classSourceTableFont {
 return __classSourceTableFont; }

+(void)setClassThreadTableFont:(NSFont *)font {
	setObjectWithRetain(__classThreadTableFont, font);
	[[NSNotificationCenter defaultCenter] postNotificationName:__threadTableFontSizeChangedNotificationName
														object:self];
}
+(NSFont *)classThreadTableFont {
 return __classThreadTableFont; }
+(void)setClassSourceTableRowHeight:(float)rowHeight {
	__classSourceTableRowHeight = rowHeight;
	[[NSNotificationCenter defaultCenter] postNotificationName:__sourceTableFontSizeChangedNotificationName
														object:self];
}
+(float)classSourceTableRowHeight { return __classSourceTableRowHeight; }
+(void)setClassThreadTableRowHeight:(float)rowHeight {
	__classThreadTableRowHeight = rowHeight;
	[[NSNotificationCenter defaultCenter] postNotificationName:__threadTableFontSizeChangedNotificationName
														object:self];
}
+(float)classThreadTableRowHeight { return __classThreadTableRowHeight; }

-(void)setSourceList:(T2List *)sourceList {
	setObjectWithRetain(_sourceList, sourceList);
}
-(T2List *)sourceList {
	return _sourceList;
}

-(void)setSelectedListInternalPath:(NSString *)selectedListInternalPath {
	int index = 0;
	if ([selectedListInternalPath hasPrefix:@"unidentified"]) {
		index = [[selectedListInternalPath lastPathComponent] intValue];
		
	} else {
		unsigned i;
		//T2ListFace *listFace;
		NSArray *objects = [_sourceList objects];
		for (i=0; i<[objects count]; i++) {
			NSString *internalPath = [(T2ListFace *)[objects objectAtIndex:i] internalPath];
			if ([internalPath isEqualToString:selectedListInternalPath]) {
				index = i;
				break;
			}
		}
	}
	[_sourceTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index]
			  byExtendingSelection:NO];
}
-(NSString *)selectedListInternalPath {
	NSUInteger selectionIndex = [_sourceFacesController selectionIndex];
	if (selectionIndex == NSNotFound) {
		return @"unidentified/0";
	}
	T2ListFace *listFace = [[_sourceList objects] objectAtIndex:selectionIndex];
	NSString *internalPath = [listFace internalPath];
	if (!internalPath) {
		internalPath = [NSString stringWithFormat:@"unidentified/%ld", (unsigned long)selectionIndex];
	}
	return internalPath;
}

-(void)setBrowsingRootList:(T2List *)browsingRootList {
	setObjectWithRetain(_browsingRootList, browsingRootList);
	if (_browsingRootList) {
		[self setBrowsingListArray:[NSArray arrayWithObject:_browsingRootList]];
	} else {
		[self setBrowsingListArray:nil];
	}
	[_listBrowser loadColumnZero];
}
-(T2List *)browsingRootList { return _browsingRootList; }

-(void)setBrowsingListArray:(NSArray *)listArray {
	if (listArray == _browsingListArray) return;
	
	NSEnumerator *enumerator = [_browsingListArray objectEnumerator];
	T2List *list;
	while (list = [enumerator nextObject]) {
		[list removeObserver:self forKeyPath:@"objects"];
	}
	
	setObjectWithRetain(_browsingListArray, listArray);
	if (![_document selectedThreadController]) {
		[_document setProgressProvider:[_browsingListArray lastObject]];
	}
	
	enumerator = [_browsingListArray objectEnumerator];
	while (list = [enumerator nextObject]) {
		[list addObserver:self forKeyPath:@"objects" options:0 context:NULL];
	}
	
}
-(NSArray *)browsingListArray { return _browsingListArray; }

/*
-(void)setSourceSelectedIndexes:(NSIndexSet *)indexSet { //source selection
	
	if (indexSet == _sourceSelectedIndexes) return;
	if ([indexSet isEqualToIndexSet:_sourceSelectedIndexes]) return;
	setObjectWithRetain(_sourceSelectedIndexes, indexSet);
	
	unsigned i,maxCount = [_browsingListArray count];
	for (i=0; i<maxCount; i++) {
		[[_browsingListArray objectAtIndex:i] removeObserver:self forKeyPath:@"objects"];
	}
	[_browsingListArray removeAllObjects];
	if (!_sourceSelectedIndexes || [indexSet count]==0) return;
	
	T2ListFace *nextListFace = [[__sourceList objects] objectAtIndex:[indexSet firstIndex]];
	T2List *nextList = [nextListFace list];
	if (nextList) {
		[nextList load];
		if ([nextList isKindOfClass:[T2ThreadList class]]) { //direct thread list
			[self setThreadList:(T2ThreadList *)nextList];
			[self setVisibleOfBrowser:NO];
		}
		else { //intermediate list browsing
			[self setThreadList:nil];
			[nextList addObserver:self forKeyPath:@"objects" options:0 context:[[NSNumber numberWithInt:0] retain]];
			
			[_browsingListArray addObject:nextList];
			[self setVisibleOfBrowser:YES];
		}
		[_h1SplitView resizeSubviewsWithOldSize:[_h1SplitView bounds].size];
	}
	[_listBrowser loadColumnZero];
}
-(NSIndexSet *)sourceSelectedIndexes { return _sourceSelectedIndexes; }
 */

-(void)setThreadList:(T2ThreadList *)list {
	// old list
	if (_threadList && _threadList != list) {
		[_threadList cancelLoading];
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:T2ListDidEndLoadingNotification
													  object:_threadList];
		
		NSArray *sortDescriptors = [_threadTable sortDescriptors];
		if (sortDescriptors && [sortDescriptors count] >= 1) {
			NSSortDescriptor *sortDescriptor = [sortDescriptors objectAtIndex:0];
			if (sortDescriptor) [_threadList setSortDescriptor:sortDescriptor];
		}
		[_threadList setVariableKey:[self scorerKey]];
		
		[[THAppDelegate sharedInstance] cacheThreadList:_threadList];
	}
	setObjectWithRetain(_threadList, list);
	if (![_document selectedThreadController]) {
		[_document setProgressProvider:_threadList];
	}
	
	//new list
	if (_threadList) {
		NSString *variableKey = [_threadList variableKey];
		if (variableKey) {
			[self setScorerKey:variableKey];
		}
		
		NSString *sortDescriptorKey = [_threadList sortDescriptorKey];
		if (sortDescriptorKey) {
			if (![sortDescriptorKey isKindOfClass:[NSString class]]) {
				[_threadList setSortDescriptorKey:@"state"];
				sortDescriptorKey = [_threadList sortDescriptorKey];
				NSLog(@"sortDescriptorKey of board %@ fixed", [_threadList title]);
			}
			
			if (!variableKey) {
				[self setScorerKey:sortDescriptorKey];
			}
			[_threadTable setSortDescriptors:[NSArray arrayWithObject:[_threadList sortDescriptor]]];
		}
		[(T2ListHistory *)[T2ListHistory listHistoryForKey:@"threadListHistory"] addHistory:[_threadList listFace]];
		
		// register Notification
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(threadListLoaded:)
													 name:T2ListDidEndLoadingNotification object:_threadList];
	}
	
	//[self setThreadSelectedIndexes:nil];
	if ([_document selectedThreadController] == nil) {
		
		[_threadFacesController setSearchString:nil];
		[_threadTable scrollRowToVisible:0];
		[_document displayURLString:[_threadList webBrowserURLString]];
		if (_threadList && [_threadList title]) {
			[[_document docWindow] setTitle:[_threadList title]];
		} else {
			[[_document docWindow] setTitle:NSLocalizedString(@"Thousand", nil)];
		}
	}
	
}
-(T2ThreadList *)threadList { 
	return _threadList;
}

-(void)setIsBrowsingListParentOfThreadList:(BOOL)aBool { _isBrowsingListParentOfThreadList = aBool; }
-(BOOL)isBrowsingListParentOfThreadList { return _isBrowsingListParentOfThreadList; }
-(T2List *)browsingList {
	if (_browsingListArray && [_browsingListArray count]>0) {
		if (_isBrowsingListParentOfThreadList && _threadList) {
			return _threadList;
		}
		return [_browsingListArray lastObject];
	}
	return _threadList;
}

/*
-(void)setThreadSelectedIndexes:(NSIndexSet *)indexSet {
	setObjectWithRetain(_threadSelectedIndexes, indexSet);
	[self updateLabelButton];
}
-(NSIndexSet *)threadSelectedIndexes { return _threadSelectedIndexes; }
 */

-(int)labelOfSelectedThreadFaces {
	NSArray *selectedThreadFaces = [_threadFacesController selectedObjects];
	if ([selectedThreadFaces count] > 0) {
		return [(id <T2Labeling>)[selectedThreadFaces objectAtIndex:0] label];
	}
	return -1;
}

-(NSArray *)scorerNames {
	return [[T2PluginManager sharedManager] threadFaceScoreLocalizedNames];
}
-(void)setScorerKey:(NSString *)scorerKey {
	NSArray *scorerKeys = [[T2PluginManager sharedManager] threadFaceScoreKeys];
	NSUInteger index = [scorerKeys indexOfObject:scorerKey];
	if (index == NSNotFound) index = 0;
	[self setSelectedScorerIndex:index];
}
-(NSString *)scorerKey {
	NSArray *scorerKeys = [[T2PluginManager sharedManager] threadFaceScoreKeys];
	if (_selectedScorerIndex > -1 && _selectedScorerIndex < [scorerKeys count]) {
		return [scorerKeys objectAtIndex:_selectedScorerIndex];
	} 
	return @"state";
}
-(void)setSelectedScorerIndex:(int)anInt {
	_selectedScorerIndex = anInt;
	if (!_threadList) return;
	
	NSArray *scoreKeys = [[T2PluginManager sharedManager] threadFaceScoreKeys];
	NSString *scoreKey = [scoreKeys objectAtIndex:_selectedScorerIndex];
	NSString *scoreStringKey = [scoreKey stringByAppendingString:@"String"];
	
	[_scoreColumn unbind:@"value"];
	
	if (![[T2PluginManager sharedManager] threadFaceScoringPluginForKey:scoreStringKey]) 
		scoreStringKey = scoreKey;
	NSString *bindingKeyPath = [@"arrangedObjects." stringByAppendingString:scoreStringKey];
	[_scoreColumn bind:@"value" toObject:_threadFacesController withKeyPath:bindingKeyPath options:nil];
	
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:scoreKey ascending:NO] autorelease];
	[_scoreColumn setSortDescriptorPrototype:sortDescriptor];
	
	[_threadTable setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
}
-(int)selectedScorerIndex { return _selectedScorerIndex; }

/*
-(void)setShouldSendWholeSearchString:(BOOL)aBool { 
	_shouldSendWholeSearchString = aBool;
	[[_searchField cell] setSendsWholeSearchString:_shouldSendWholeSearchString];
}
-(BOOL)shouldSendWholeSearchString { return _shouldSendWholeSearchString; }
 */

#pragma mark -
#pragma mark Utilities
-(void)setVisibleOfBrowser:(BOOL)aBool {
	if (_browserVisible == aBool) return;
	_browserVisible = aBool;
	if (_browserVisible) {
		[_h1SplitView setFrame:[_threadTableViewScrollView frame]];
		//[_threadTableViewScrollView removeFromSuperviewWithoutNeedingDisplay];
		//[_v1SplitView addSubview:_h1SplitView];
		[_v1SplitView replaceSubview:_threadTableViewScrollView with:_h1SplitView];
		
		[_threadTableViewScrollView setFrame:[_threadTableViewPlaceHolder frame]];
		//[_threadTableViewPlaceHolder removeFromSuperviewWithoutNeedingDisplay];
		//[_h1SplitView addSubview:_threadTableViewScrollView];
		[_h1SplitView replaceSubview:_threadTableViewPlaceHolder with:_threadTableViewScrollView];
	} else {
		[_threadTableViewPlaceHolder setFrame:[_threadTableViewScrollView frame]];
		//[_threadTableViewScrollView removeFromSuperviewWithoutNeedingDisplay];
		//[_h1SplitView addSubview:_threadTableViewPlaceHolder];
		[_h1SplitView replaceSubview:_threadTableViewScrollView with:_threadTableViewPlaceHolder];
		
		[_threadTableViewScrollView setFrame:[_h1SplitView frame]];
		//[_h1SplitView removeFromSuperviewWithoutNeedingDisplay];
		//[_v1SplitView addSubview:_threadTableViewScrollView];
		[_v1SplitView replaceSubview:_h1SplitView with:_threadTableViewScrollView];
	}
	[_h1SplitView setNeedsDisplay:YES];
}

-(void)searchString:(NSString *)aString {
	T2PluginManager *pluginManager = [T2PluginManager sharedManager];
	
	T2List *list = [self browsingList];
	if (!list) return;
	
	if ([list isKindOfClass:[T2ThreadList class]]) {
		if ([pluginManager isSearchList:list]) {
			[pluginManager setSearchString:aString forList:list];
			return;
		}
		[_threadFacesController setSearchString:aString];
		[_threadFacesController rearrangeObjects];
	} else {
		T2List *lastList = [_browsingListArray lastObject];
		if ([pluginManager isSearchList:lastList]) {
			[pluginManager setSearchString:aString forList:lastList];
			return;
		}
	}
}

-(BOOL)canOpenNextThread {
	if (_lastNextThreadLoadingDate) {
		NSDate *now = [NSDate date];
		if ([now timeIntervalSinceDate:_lastNextThreadLoadingDate] > __nextThreadLoadingInterval) {
			[_lastNextThreadLoadingDate release];
			_lastNextThreadLoadingDate = [now retain];
			return YES;
		}
		return NO;
	}
	_lastNextThreadLoadingDate = [[NSDate date] retain];
	return YES;
}
/*
-(void)setShouldSendWholeSearchStringByThreadList {
	T2PluginManager *pluginManager = [T2PluginManager sharedManager];
	if (_threadList) {
		if ([pluginManager isSearchList:_threadList]) {
			[self setShouldSendWholeSearchString:[pluginManager shouldSendWholeSearchStringForList:_threadList]];
			return;
		}
	}
	[self setShouldSendWholeSearchString:NO];
}
-(void)setShouldSendWholeSearchStringByBrowsingList {
	T2PluginManager *pluginManager = [T2PluginManager sharedManager];
	if (_browsingListArray && [_browsingListArray count]>0) {
		T2List *lastList = [_browsingListArray lastObject];
		if ([pluginManager isSearchList:lastList]) {
			[self setShouldSendWholeSearchString:[pluginManager shouldSendWholeSearchStringForList:lastList]];
			return;
		} 
	}
	[self setShouldSendWholeSearchString:NO];
}
 */

-(NSString *)filterSearchString {
	return [_threadFacesController searchString];
}

-(void)openListWithListFace:(T2ListFace *)listFace {
	NSArray *sourceListFaces = [__sourceList objects];
	NSUInteger index = [sourceListFaces indexOfObjectIdenticalTo:listFace];
	if (index != NSNotFound) {
		[_sourceTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	} else {
		NSArray *newSourceListFaces = [sourceListFaces arrayByAddingObject:listFace];
		[__sourceList setObjects:newSourceListFaces];
		[_sourceTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[sourceListFaces count]] byExtendingSelection:NO];
	}
	
}

#pragma mark -
#pragma mark NSSplitView delegate methods
- (NSRect)splitView:(NSSplitView *)splitView effectiveRect:(NSRect)proposedEffectiveRect
	   forDrawnRect:(NSRect)drawnRect ofDividerAtIndex:(NSInteger)dividerIndex {
	NSRect resultRect = proposedEffectiveRect;
	if (proposedEffectiveRect.size.width <=1) {
		resultRect.size.width = 9;
		resultRect.origin.x -= 4;
	}
	if (proposedEffectiveRect.size.height <=1) {
		resultRect.size.height = 9;
		resultRect.origin.y -= 4;
	}
	return resultRect;
}

#pragma mark -
#pragma mark NSTableView dataSource methods

// Start Dragging
- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard {
	NSString *pBoardType;
	NSMutableIndexSet *selectedRowIndexes = [NSMutableIndexSet indexSet];
	NSEnumerator *rowNumberEnumerator = [rows objectEnumerator];
	NSNumber *rowNumber;
	while (rowNumber = [rowNumberEnumerator nextObject]) {
		[selectedRowIndexes addIndex:[rowNumber unsignedIntValue]];
	}
	
	if (tableView == _sourceTable) {
		if ([selectedRowIndexes intersectsIndexesInRange:NSMakeRange(0,[__sourceList firstBookmarkIndex])]) {
			return NO;
		}
		NSData *data = [NSArchiver archivedDataWithRootObject:selectedRowIndexes];
		[pboard declareTypes:[NSArray arrayWithObject:THBookmarkTableRowPboardType] owner:nil];
		[pboard setData:data forType:THBookmarkTableRowPboardType];
		
	} else if (tableView == _threadTable) {
		
		//THThreadFacesPboardType
		NSArray *draggingThreadFaces = [[_threadFacesController arrangedObjects] objectsAtIndexes_panther:selectedRowIndexes];
		NSMutableArray *pboardTypes = [NSMutableArray arrayWithObjects:THThreadFacesPboardType, nil];
		
		//NSFilenamesPboardType
		NSMutableArray *fileNames = [NSMutableArray array];
		NSEnumerator *enumerator = [draggingThreadFaces objectEnumerator];
		T2ThreadFace *threadFace;
		while (threadFace = [enumerator nextObject]) {
			NSString *fileName = [threadFace logFilePath];
			if (fileName) [fileNames addObject:fileName];
		}
		if ([fileNames count] > 0) {
			[pboardTypes addObject:NSFilenamesPboardType];
		} else fileNames = nil;
		
		//NSURLPboardType
		NSString *urlString = nil;
		if ([draggingThreadFaces count] > 0) {
			threadFace = [draggingThreadFaces objectAtIndex:0];
			urlString = [[threadFace thread] webBrowserURLString];
			if (urlString) {
				[pboardTypes addObject:NSURLPboardType];
			}
		}
		
		//THThreadListTableRowPboardType
		NSData *rowData = nil;
		NSArray *sortDescriptors = [_threadTable sortDescriptors];
		rowData = [NSArchiver archivedDataWithRootObject:selectedRowIndexes];
		[pboardTypes addObject:THThreadListTableRowPboardType];
		
		// write
		[pboard declareTypes:pboardTypes owner:nil];
		if (draggingThreadFaces)	[pboard setPropertyList:[draggingThreadFaces encodedDictionary] forType:THThreadFacesPboardType];
		if (fileNames)		[pboard setPropertyList:fileNames forType:NSFilenamesPboardType];
		if (urlString)		[[NSURL URLWithString:urlString] writeToPasteboard:pboard];
		if (rowData)		[pboard setData:[NSArchiver archivedDataWithRootObject:selectedRowIndexes] forType:THThreadListTableRowPboardType];
	}
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info 
				 proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
	
	NSPasteboard *draggingPasteboard = [info draggingPasteboard];
	
	if (tableView == _sourceTable) {
		id draggingSource = [info draggingSource];
		if (!(draggingSource == _sourceTable
			  || draggingSource == _threadTable
			  || draggingSource == nil)) {
			if ([draggingSource isKindOfClass:[T2BrowserMatrix class]]) {
				if ([(T2BrowserMatrix *)draggingSource window] != [_threadTable window])
					return NSDragOperationNone;
			} else {
				return NSDragOperationNone;
			}
		}
		NSString *pBoardType = [draggingPasteboard availableTypeFromArray:__sourceTableAcceptablePboardTypes];
		if (operation == NSTableViewDropAbove) {
			if (row < [__sourceList firstBookmarkIndex]) {
				return NSDragOperationNone;
			}
			if (pBoardType) return NSDragOperationEvery;
		}
		else if (operation == NSTableViewDropOn) {
			if (row < [__sourceList firstBookmarkIndex]) return NSDragOperationNone;
			if ([pBoardType isEqualToString:THThreadFacesPboardType]) {
				T2ListFace *dropTargetListFace = [[__sourceList objects] objectAtIndex:row];
				if ([dropTargetListFace isKindOfClass:[T2BookmarkListFace class]]) {
					return NSDragOperationEvery;
				} else {
					[tableView setDropRow:row dropOperation:NSTableViewDropAbove];
					return NSDragOperationEvery;
				}
			} else if ([pBoardType isEqualToString:NSFilenamesPboardType]) {
				[tableView setDropRow:row dropOperation:NSTableViewDropAbove];
				return NSDragOperationEvery;
			}
		}
	} else if (tableView == _threadTable) {
		if (operation == NSTableViewDropOn || !_threadList) return NSDragOperationNone;
		if ([_threadList allowsEditingObjects] && [[_threadList objects] count] == [[_threadFacesController arrangedObjects] count]) {
			NSString *pBoardType = [draggingPasteboard availableTypeFromArray:__threadTableAcceptablePboardTypes];
			if (pBoardType) return NSDragOperationEvery;
		}
	}
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info
			  row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
	NSPasteboard *draggingPasteboard = [info draggingPasteboard];
	
	if (tableView == _sourceTable) {
		NSString *pBoardType = [draggingPasteboard availableTypeFromArray:__sourceTableAcceptablePboardTypes];
		
		NSArray *sourceListObjects = [__sourceList objects];
		if ([pBoardType isEqualToString:T2BrowserRowPboardType])
			// Drag from Browser
		{
			NSDictionary *columnAndRow = [draggingPasteboard propertyListForType:T2BrowserRowPboardType];
			NSNumber *srowNumber = [columnAndRow objectForKey:@"row"];
			NSNumber *scolNumber = [columnAndRow objectForKey:@"column"];
			
			if (!srowNumber || !scolNumber) return NO;
			int srow = [srowNumber intValue];
			int scol = [scolNumber intValue];
			
			NSArray *selectedColumnsArray = [(T2List *)[_browsingListArray objectAtIndex:scol] objects];
			T2ListFace *selectedListFace = [[selectedColumnsArray objectAtIndex:srow] retain];
			
			if (!selectedListFace) return NO;
			[__sourceList insertObject:selectedListFace atIndex:row];
			[__sourceList saveToFile];
			
			[selectedListFace autorelease];
			return YES;
			
		} else if ([pBoardType isEqualToString:THBookmarkTableRowPboardType])
			 // Drag from self
		{
			NSIndexSet *draggedRowsIndexSet = [NSUnarchiver unarchiveObjectWithData:[draggingPasteboard dataForType:THBookmarkTableRowPboardType]];
			
			if ([draggedRowsIndexSet indexGreaterThanIndex:row] == NSNotFound) {
				row -= [draggedRowsIndexSet count];
				if (row < [__sourceList firstBookmarkIndex]) return NO;
			} else if ([draggedRowsIndexSet indexLessThanOrEqualToIndex:row] != NSNotFound) {
				return NO;
			}
			
			NSArray *movingListFaces = [sourceListObjects objectsAtIndexes_panther:draggedRowsIndexSet];
			
			[__sourceList removeObjectsAtIndexes:draggedRowsIndexSet];
			[__sourceList insertObjects:movingListFaces atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, [draggedRowsIndexSet count])]];
			[__sourceList saveToFile];
			//[self saveSourceList];
			return YES;
			
		} else if ([pBoardType isEqualToString:THThreadFacesPboardType])
			 // Drag from Thread List
		{
			NSArray *movingThreadFaces = (NSArray *)[NSObject objectWithDictionary:[draggingPasteboard propertyListForType:THThreadFacesPboardType]];
			if (operation == NSTableViewDropAbove) {
				T2BookmarkListFace *threadListFace = [T2BookmarkListFace bookmarkListFace];
				[threadListFace setTitle:THBookmarkLocalize(@"Untitled Bookmark")];
				T2BookmarkList *threadList = (T2BookmarkList *)[threadListFace list];
				[threadList setObjects:movingThreadFaces];
				
				[__sourceList insertObject:threadListFace atIndex:row];
				[__sourceList saveToFile];
				
				return YES;
			} else if (operation == NSTableViewDropOn) {
				T2ListFace *threadListFace = [sourceListObjects objectAtIndex:row];
				T2List *threadList = [threadListFace list];
				if ([threadList allowsEditingObjects]) {
					[threadList addObjects:movingThreadFaces];
					[__sourceList saveToFile];
					return YES;
				}
			}
		} else if ([pBoardType isEqualToString:NSFilenamesPboardType] && __localFileImporter)
			// Drag from Files or Folders
		{
			NSMutableArray *listFacesForFolders = [NSMutableArray array];
			NSArray *fileNames = [draggingPasteboard propertyListForType:NSFilenamesPboardType];
			NSEnumerator *fileNamesEnumerator = [fileNames objectEnumerator];
			NSString *fileName;
			NSFileManager *fileManager = [NSFileManager defaultManager];
			BOOL isFolder;
			while (fileName = [fileNamesEnumerator nextObject]) {
				if ([fileManager fileExistsAtPath:fileName isDirectory:&isFolder]) {
					if (isFolder) {
						T2ListFace *threadListFace = [T2ListFace listFaceWithInternalPath:[[__localFileImporter importableRootPath] stringByAppendingString:fileName]
																					title:[fileName lastPathComponent]
																					image:nil];
						[threadListFace setImageByListImporter];
						if (threadListFace) {
							[listFacesForFolders addObject:threadListFace];
						}
					}
				}
			}
			
			if (operation == NSTableViewDropAbove) {
				[__sourceList insertObjects:listFacesForFolders atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, [listFacesForFolders count])]];
				[__sourceList saveToFile];
				return YES;
			}
		}
	} else if (tableView == _threadTable) {
		
		NSString *pBoardType;
		id draggingSource = [info draggingSource];
		if (draggingSource == _threadTable)
			pBoardType = [draggingPasteboard availableTypeFromArray:__threadTableAcceptablePboardTypes];
		else
			pBoardType = [draggingPasteboard availableTypeFromArray:__otherThreadTableAcceptablePboardTypes];
		
		if ([pBoardType isEqualToString:THThreadListTableRowPboardType])
			// Drag from self
		{
			NSIndexSet *draggedRowsIndexSet = [NSUnarchiver unarchiveObjectWithData:[draggingPasteboard dataForType:THThreadListTableRowPboardType]];
			
			NSInteger minDraggedRow = [draggedRowsIndexSet indexLessThanIndex:row];
			while (minDraggedRow != NSNotFound) {
				row--;
				minDraggedRow = [draggedRowsIndexSet indexLessThanIndex:minDraggedRow];
			}
			
			NSArray *movingThreadFaces = [[_threadFacesController arrangedObjects] objectsAtIndexes_panther:draggedRowsIndexSet];
			
			NSMutableArray *tempThreadList = [[[_threadFacesController arrangedObjects] mutableCopy] autorelease];
			[tempThreadList removeObjectsAtIndexes_panther:draggedRowsIndexSet];
			[tempThreadList insertObjects_panther:movingThreadFaces atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, [draggedRowsIndexSet count])]];
			[_threadList setObjects:tempThreadList];
			
			//NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"voidProperty" ascending:NO] autorelease];
			[_threadTable setSortDescriptors:nil];
			return YES;
			
		} else if ([pBoardType isEqualToString:THThreadFacesPboardType])
			// Drag from Other Thread List
		{
			NSArray *movingThreadFaces = (NSArray *)[NSObject objectWithDictionary:[draggingPasteboard propertyListForType:THThreadFacesPboardType]];
			if (operation == NSTableViewDropAbove) {
				[_threadList insertObjects:movingThreadFaces atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, [movingThreadFaces count])]];
				
				//NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"voidProperty" ascending:NO] autorelease];
				[_threadTable setSortDescriptors:nil];
				
				[__sourceList saveToFile];
				return YES;
			}
		}	
	}
	return NO;
}
/*
- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
	if (_threadTable == aTableView) {
		NSArray *sortDescriptors = [_threadTable sortDescriptors];
		if (sortDescriptors && [sortDescriptors count] >= 1) {
			NSSortDescriptor *sortDescriptor = [sortDescriptors objectAtIndex:0];
			if (sortDescriptor) [_threadList setSortDescriptor:sortDescriptor];
		}
		[_threadList setVariableKey:[self scorerKey]];	
	}
}
 */
#pragma mark NSTableView delegate methods

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell 
   forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if (_threadTable == aTableView) {
		if ([aCell conformsToProtocol:@protocol(T2Labeling)]) {
			NSArray *threadFaces = [_threadFacesController arrangedObjects];
			[(id <T2Labeling>)aCell setLabel:[(T2ThreadFace *)[threadFaces objectAtIndex:rowIndex] label]];
		}
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	NSTableView *sender = [aNotification object];
	if (sender == _sourceTable) {
		T2ListFace *selectedListFace = [[_sourceFacesController selectedObjects] lastObject];
		if (!selectedListFace) return;
		
		T2List *selectedList = [selectedListFace list];
		
		if ([selectedList isKindOfClass:[T2ThreadList class]]) {
			[self setBrowsingRootList:nil];
			[self setThreadList:(T2ThreadList *)selectedList];
			[self setVisibleOfBrowser:NO];
		} else {
			[self setBrowsingRootList:selectedList];
			[self setVisibleOfBrowser:YES];
		}
		[self setIsBrowsingListParentOfThreadList:NO];
		//[[_searchField cell] setSendsWholeSearchString:[self shouldSendWholeSearchString]];
		
		[_h1SplitView resizeSubviewsWithOldSize:[_h1SplitView bounds].size];
		
		T2PluginManager *pluginManager = [T2PluginManager sharedManager];
		if (![pluginManager isSearchList:selectedList]) {
			[selectedList load];
		}
				
	} else {
		[self updateLabelButton];
	}
}

#pragma mark -
#pragma mark NSBrowser delegate methods
- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)column {
	T2List *listWillExpand = [_browsingListArray objectAtIndex:column];
	T2ListFace *listFace = [[listWillExpand objects] objectAtIndex:row];
	//T2List *list = [listFace list];
	
	[(NSBrowserCell *)cell setLeaf:[listFace isLeaf]];
	[(NSBrowserCell *)cell setTitle:[listFace title]];
	
}
//- (BOOL)browser:(NSBrowser *)sender selectRow:(int)row inColumn:(int)column {
-(IBAction)selectActionInBrowser:(id)sender {
	int column = [_listBrowser selectedColumn];
	int row = [_listBrowser selectedRowInColumn:column];
	[self browserSelectRow:row inColumn:column];
	//[_listBrowser selectRow:row inColumn:column];
	[[_listBrowser window] makeFirstResponder:[_listBrowser matrixInColumn:column]];
}
- (BOOL)browserSelectRow:(int)row inColumn:(int)column {
	if (column<0 || row<0) return 0; 
	if ([_browsingListArray count]>(column+1)) {
		// remove far column's lists
		unsigned i,maxCount = [_browsingListArray count];
		
		NSArray *listArray = [_browsingListArray subarrayWithRange:NSMakeRange(0, column+1)];
		[self setBrowsingListArray:listArray];
	}
	T2List *currentList = [_browsingListArray objectAtIndex:column];
	T2ListFace *selectedListFace = [[currentList objects] objectAtIndex:row];
	T2List *selectedList = [selectedListFace list];
	
	if ([selectedList isKindOfClass:[T2ThreadList class]]) {
		[self setThreadList:(T2ThreadList *)selectedList];
		[self setIsBrowsingListParentOfThreadList:YES];
	}
	else {
		NSArray *listArray = [_browsingListArray arrayByAddingObject:selectedList];
		[self setBrowsingListArray:listArray];
		[_listBrowser validateVisibleColumns];
		[_listBrowser reloadColumn:column+1];
		[self setIsBrowsingListParentOfThreadList:NO];
	}
	//[[_searchField cell] setSendsWholeSearchString:[self shouldSendWholeSearchString]];
	T2PluginManager *pluginManager = [T2PluginManager sharedManager];
	if (![pluginManager isSearchList:selectedList]) {
		[selectedList load];
	}
	return YES;
}
- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column {
	if (column<0) return 0;
	
	if ([_browsingListArray count] > column) {
		int i = [[(T2List *)[_browsingListArray objectAtIndex:column] objects] count];
		return i;
	}
	else return 0;
}
- (BOOL)browser:(NSBrowser *)sender isColumnValid:(int)column {
	if (column<0) return NO; 
	if ([_browsingListArray count] > column) {
		
		NSMatrix *matrix = [_listBrowser matrixInColumn:column];
		NSSize cellSize = [matrix cellSize];
		cellSize.height = __classSourceTableRowHeight;
		[matrix setCellSize:cellSize];
		return YES;
	}
	else return NO;
}

#pragma mark -
#pragma mark Notification
-(void)threadListLoaded:(NSNotification *)notification {
	if ([notification object] != _threadList) return;
	[(THSaveOperation *)[THSaveOperation saveOperationWithIdentifiedObjects:[NSArray arrayWithObject:_threadList]] start];
	
	if (_timer) {
		[_timer invalidate];
		[_timer release];
		_timer = nil;
	}
	_timer = [[NSTimer scheduledTimerWithTimeInterval:0.1
											   target:self selector:@selector(prefetchTimerFired:)
											 userInfo:nil repeats:NO] retain];
	
}
-(void)prefetchTimerFired:(NSTimer *)timer {
	[timer invalidate];
	[_timer release];
	_timer = nil;
	
	// Prefetch Threads (3000 Res)
	NSArray *arrangedObjects = [_threadFacesController arrangedObjects];
	NSEnumerator *arrangedObjectEnumerator = [arrangedObjects objectEnumerator];
	T2ThreadFace *threadFace;
	NSMutableArray *threadFacesToPrefetch = [[[NSMutableArray alloc] initWithCapacity:3] autorelease];
	unsigned threadFacesToPrefetchCount = 0;
	unsigned threadFacesCount = 0;
	while (threadFace = [arrangedObjectEnumerator nextObject]) {
		threadFacesCount++;
		unsigned resCount = [threadFace resCount];
		if ([threadFace state] == T2ThreadFaceStateUpdated
			&& resCount > 50) {
			[threadFacesToPrefetch addObject:threadFace];
			threadFacesToPrefetchCount++;
			if (threadFacesToPrefetchCount >= 5) break;
		}
		
		if (threadFacesCount >= 200) break;
	}
	//[(THAppDelegate *)[NSApp delegate] prefetchThreadWithThreadFaces:threadFacesToPrefetch];
}

#pragma mark -
#pragma mark NSKeyValueObserving
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"selectedObjects"]) {
		[self updateLabelButton];
	} else if ([keyPath isEqualToString:@"objects"]) {
		NSUInteger i = [_browsingListArray indexOfObjectIdenticalTo:object];
		if (i != NSNotFound) {
			[_listBrowser reloadColumn:i];
		}
	}
}

#pragma mark -
#pragma mark Menu And Toolbar item Validation
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	return [self validateUIOfAction:[(NSMenuItem *)menuItem action]];
}
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
	return [self validateUIOfAction:[theItem action]];
}
-(BOOL)validateUIOfAction:(SEL)action {
	
	if (action == @selector(removeSelectedThreads:)) {
		
		NSArray *selectedThreadFaces = [_threadFacesController selectedObjects];
		NSEnumerator *threadFacesEnumerator = [selectedThreadFaces objectEnumerator];
		T2ThreadFace *threadFace;
		if ([_threadList allowsRemovingObjects]) {
			return NO;
		} else if ([_threadList isKindOfClass:[T2ThreadHistory class]]) {
			return NO;
		} else {
			while (threadFace = [threadFacesEnumerator nextObject]) {
				if ([threadFace logFilePath]) return YES;
			}
			return NO;
		}
	} else if (action == @selector(addToBookmark:) ||
			   action == @selector(findNextThread:) ||
			   action == @selector(openParentThreadList:)) {
		NSArray *selectedThreadFaces = [_threadFacesController selectedObjects];
		if (!(selectedThreadFaces && [selectedThreadFaces count]>0)) return NO;
		
	} else if (action == @selector(openUsingWebBrowser:) ||
			   action == @selector(copyURL:) || 
			   action == @selector(copyTitleAndURL:)) {
		if (![_threadList webBrowserURLString]) return NO;
	} else if (action == @selector(openUsingOreyon:)) {
		if (![THDocument oreyonPath]) return NO;
		NSArray *selectedThreadFaces = [_threadFacesController selectedObjects];
		if (selectedThreadFaces && [selectedThreadFaces count]) {
			T2ThreadFace *threadFace = [selectedThreadFaces objectAtIndex:0];
			if ([threadFace logFilePath]) return YES;
		}
		return NO;
		
	} else if (action == @selector(postThread:)) {
		if (_threadList &&
			[[T2PluginManager sharedManager] canPostThreadToThreadList:_threadList])
			return YES;
		else return NO;
	} else if (action == @selector(revealLogFileInFinder:)) {
		NSArray *selectedThreadFaces = [_threadFacesController selectedObjects];
		if (selectedThreadFaces && [selectedThreadFaces count]) {
			T2ThreadFace *threadFace = [selectedThreadFaces objectAtIndex:0];
			if ([threadFace logFilePath]) return YES;
		}
		return NO;
	} else if (action == @selector(showFallenThreadArchives:)) {
		if (!_threadList) return NO;
		NSString *internalPath = [_threadList internalPath];
		NSArray *internalPathComponents = [internalPath pathComponents];
		if (![[internalPath firstPathComponent] isEqualToString:@"2ch BBS"]) return NO;
		
	}
	return YES;	
}

-(void)updateLabelButton {
	if ([_document selectedThreadController]) return; // WARNING !! BUG IN HERE!!
	NSArray *selectedThreadFaces = [_threadFacesController selectedObjects];
	if ([selectedThreadFaces count]>0) {
		[_document setLabel:[(T2ThreadFace *)[selectedThreadFaces objectAtIndex:0] label]];
	} else {
		[_document setLabel:-1];
	}
}
-(void)updateLabelMenu {
	NSMenu *threadMenu = [_threadTable menu];
	unsigned availableMenuItemCount = [threadMenu numberOfItems];
	unsigned defaultMenuItemCount = [_threadTableMenuItems count];
	
	if (availableMenuItemCount > defaultMenuItemCount) {
		unsigned i;
		for (i=defaultMenuItemCount; i<availableMenuItemCount; i++) {
			[threadMenu removeItemAtIndex:defaultMenuItemCount];
		}
	}
	
	NSArray *labelMenuItems = [[T2LabeledCellManager sharedManager] menuItems];
	NSEnumerator *menuItemEnumerator = [labelMenuItems objectEnumerator];
	NSMenuItem *menuItem;
	[threadMenu addItem:[NSMenuItem separatorItem]];
	[threadMenu addItem:
	 [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Label",@"Bookmark")
								 action:NULL
						  keyEquivalent:@""] autorelease]
	];
	while (menuItem = [menuItemEnumerator nextObject]) {
		[menuItem setIndentationLevel:1];
		[threadMenu addItem:menuItem];
	}
	[_threadTable setNeedsDisplay:YES];
}
-(void)updateLabelMenuWithNotification:(NSNotification *)notification {
	[self updateLabelMenu];
}
-(void)reloadTableColumns:(NSNotification *)notification {
	[_threadTable loadTHTableViewDefaultsWithName:__threadTableDefaultsName];
	[(THTableHeaderView *)[_threadTable headerView] fitPopUpButton];
}
-(void)reloadSourceTableFontSize:(NSNotification *)notification {
	[_sourceTable setRowHeight:__classSourceTableRowHeight];
	
	NSFont *font = __classSourceTableFont;
	
	NSArray *tableColumns = [_sourceTable initialTableColumns];
	NSEnumerator *tableColumnEnumerator = [tableColumns objectEnumerator];
	NSTableColumn *tableColumn;
	while (tableColumn = [tableColumnEnumerator nextObject]) {
		NSCell *dataCell = [tableColumn dataCell];
		[dataCell setFont:font];
		[tableColumn setDataCell:dataCell];
	}
	[_sourceTable setNeedsDisplay:YES];
	
	[_listBrowser setRowFont:font];
	[_listBrowser setRowHeight:__classSourceTableRowHeight];
}
-(void)reloadThreadTableFontSize:(NSNotification *)notification {
	[_threadTable setRowHeight:__classThreadTableRowHeight];
	
	NSArray *tableColumns = [_threadTable initialTableColumns];
	NSEnumerator *tableColumnEnumerator = [tableColumns objectEnumerator];
	NSTableColumn *tableColumn;
	while (tableColumn = [tableColumnEnumerator nextObject]) {
		NSCell *dataCell = [tableColumn dataCell];
		[dataCell setFont:__classThreadTableFont];
		[tableColumn setDataCell:dataCell];
	}
	[_threadTable setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark Actions Internal
/*
-(IBAction)selectSourceTable:(id)sender {
	[[_sourceTable window] makeFirstResponder:_sourceTable];
}
-(IBAction)selectThreadTable:(id)sender {
	[[_threadTable window] makeFirstResponder:_threadTable];
}
 */

#pragma mark -
#pragma mark Actions
-(IBAction)reloadView:(id)sender {
	if (_threadList) [_threadList load];
}
-(IBAction)cancelLoading:(id)sender {
	if (_threadList) [_threadList cancelLoading];
}


-(IBAction)removeSelectedLists:(id)sender {
	NSIndexSet *indexes = [_sourceFacesController selectionIndexes];
	if (!indexes) return;
	//NSMutableArray *sourceArray = [[[__sourceList objects] mutableCopy] autorelease];
	unsigned i = [indexes firstIndex];
	unsigned selection = i;
	if (i >= [__sourceList firstBookmarkIndex]) {
		unsigned count = [[__sourceList objects] count];
		if (i >= count-1) selection = i-1;
		else selection = i;
		
		//[self setSourceSelectedIndexes:[NSIndexSet indexSetWithIndex:selection]];
		
		NSMutableArray *objects = [[[_sourceList objects] mutableCopy] autorelease];
		[[[objects objectAtIndex:i] list] cancelLoading];
		[objects removeObjectAtIndex:i];
		
		[_sourceList setObjects:objects];
		//[self saveSourceList];
		[self setThreadList:nil];
		[self setBrowsingRootList:nil];
	}
}

-(IBAction)threadTableDoubleClicked:(id)sender {
	NSEvent *currentEvent = [NSApp currentEvent];
	if ([currentEvent type] == NSLeftMouseUp) {
		NSPoint location = [_threadTable convertPoint:[currentEvent locationInWindow] fromView:nil] ;
		if (location.y >= 0) {
			[self openSelectedThread:sender];
		}
	} else {
		[self openSelectedThread:sender];
	}
}

-(IBAction)openSelectedThread:(id)sender {
	NSArray *selectedObjects = [_threadFacesController selectedObjects];
	if (!selectedObjects || [selectedObjects count]==0) return;
	
	// T2ThreadFace *threadFace = [selectedObjects objectAtIndex:0];
	if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) {
		[_document loadThreadsForThreadFaces:selectedObjects activateTab:NO];
	} else {
		[_document loadThreadsForThreadFaces:selectedObjects activateTab:YES];
	}
}
-(IBAction)openSelectedThreadWithoutActivate:(id)sender {
	NSArray *selectedObjects = [_threadFacesController selectedObjects];
	if (!selectedObjects || [selectedObjects count]==0) return;
	
	[_document loadThreadsForThreadFaces:selectedObjects activateTab:NO];
}

-(IBAction)selectThread:(id)sender {
	if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) {
		NSArray *selectedObjects = [_threadFacesController selectedObjects];
		if (!selectedObjects || [selectedObjects count]==0) return;
		T2ThreadFace *threadFace = [selectedObjects objectAtIndex:0];
		[_document loadThreadForThreadFace:threadFace activateTab:NO];
	}
}

-(IBAction)removeSelectedThreads:(id)sender {
	if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) {
		[self removeSelectedThreadsImmediately:sender];
		return;
	}
	
	NSArray *selectedThreadFaces = [_threadFacesController selectedObjects];
	//NSEnumerator *threadFacesEnumerator = [selectedThreadFaces objectEnumerator];
	//T2ThreadFace *threadFace;
	if ([_threadList allowsEditingObjects]) {
		[_threadList removeObjects:selectedThreadFaces];
		/*
		while (threadFace = [threadFacesEnumerator nextObject]) {
			[_threadList removeObject:threadFace];
		}
		 */
	} else {
		NSAlert *alertPanel = [[NSAlert alertWithMessageText:THBookmarkLocalize(@"Move Log Files to Trash")
											   defaultButton:THBookmarkLocalize(@"OK")
											 alternateButton:THBookmarkLocalize(@"Cancel")
												 otherButton:nil
								   informativeTextWithFormat:@"%@", THBookmarkLocalize(@"Are you sure to move log files to Trash?")] retain];
		
		[alertPanel beginSheetModalForWindow:[_threadTable window]
							   modalDelegate:self
							  didEndSelector:@selector(deleteLogAlertDidEnd:returnCode:contextInfo:)
								 contextInfo:NULL];
	}
	
}
- (void)deleteLogAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	
	if (returnCode != NSOKButton) {
		[alert release];
		return;
	}
	
	NSArray *selectedThreadFaces = [_threadFacesController selectedObjects];
	[_document deleteLogFilesWithThreadFaces:selectedThreadFaces];
	
	[alert release];
}

-(IBAction)removeSelectedThreadsImmediately:(id)sender {
	NSArray *selectedThreadFaces = [_threadFacesController selectedObjects];
	if ([_threadList allowsEditingObjects]) {
		[_threadList removeObjects:selectedThreadFaces];
	} else {
		[_document deleteLogFilesWithThreadFaces:selectedThreadFaces];
	}
}

-(IBAction)removeFallenThreads:(id)sender {
	NSEnumerator *threadFaceEnumerator = [[_threadList objects] objectEnumerator];
	T2ThreadFace *threadFace;
	
	if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) { // OptionKey Pressed
		NSMutableArray *fallenThreadFace = [NSMutableArray array];
		while (threadFace = [threadFaceEnumerator nextObject]) {
			int state = [threadFace state];
			if (state == T2ThreadFaceStateFallen || state == T2ThreadFaceStateFallenNoLog) {
				[fallenThreadFace addObject:threadFace];
			}
		}
		[_document deleteLogFilesWithThreadFaces:fallenThreadFace];
		if ([_threadList allowsEditingObjects]) {
			[_threadList removeObjects:fallenThreadFace];
		}
		return;
		
	} else {
		while (threadFace = [threadFaceEnumerator nextObject]) {
			int state = [threadFace state];
			if (state == T2ThreadFaceStateFallen || state == T2ThreadFaceStateFallenNoLog) {
                //NSAlert *alertPanel = [[NSAlert alloc] init];
                //[alertPanel informativeText messageText:THBookmarkLocalize(@"Move Log Files to Trash")];
				NSAlert *alertPanel2 = [[NSAlert alertWithMessageText:THBookmarkLocalize(@"Move Log Files to Trash")
													   defaultButton:THBookmarkLocalize(@"OK")
													 alternateButton:THBookmarkLocalize(@"Cancel")
														 otherButton:nil
										   informativeTextWithFormat:@"%@", THBookmarkLocalize(@"Are you sure to move fallen threads log files to Trash?")] retain];
				
				[alertPanel2 beginSheetModalForWindow:[_threadTable window]
									   modalDelegate:self
									  didEndSelector:@selector(deleteFallenThreadLogAlertDidEnd:returnCode:contextInfo:)
										 contextInfo:NULL];
				return;
			}
		}
	}
}
- (void)deleteFallenThreadLogAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	
	if (returnCode != NSOKButton) {
		[alert release];
		return;
	}
	
	NSMutableArray *fallenThreadFace = [NSMutableArray array];
	NSEnumerator *threadFaceEnumerator = [[_threadList objects] objectEnumerator];
	T2ThreadFace *threadFace;
	while (threadFace = [threadFaceEnumerator nextObject]) {
		int state = [threadFace state];
		if (state == T2ThreadFaceStateFallen || state == T2ThreadFaceStateFallenNoLog) {
			[fallenThreadFace addObject:threadFace];
		}
	}
	[_document deleteLogFilesWithThreadFaces:fallenThreadFace];
	if ([_threadList allowsEditingObjects]) {
		[_threadList removeObjects:fallenThreadFace];
	}
	
	[alert release];
}

-(IBAction)revealLogFileInFinder:(id)sender {
	NSArray *selectedThreadFaces = [_threadFacesController selectedObjects];
	if ([selectedThreadFaces count] == 0) return;
	NSString *path = [(T2ThreadFace *)[selectedThreadFaces objectAtIndex:0] logFilePath];
	if (!path) return;
	NSWorkspace *sharedWorkspace = [NSWorkspace sharedWorkspace];
	[sharedWorkspace selectFile:path
	   inFileViewerRootedAtPath:[path stringByDeletingLastPathComponent]];
}

-(IBAction)openNextThread:(id)sender {
	if (![self canOpenNextThread]) return;
	NSArray *arrangedThreadFaces = [_threadFacesController arrangedObjects];
	NSUInteger selectionIndex = [_threadFacesController selectionIndex];
	if (selectionIndex != NSNotFound && [arrangedThreadFaces count]-1 > selectionIndex) {
		selectionIndex++;
		[_threadFacesController setSelectionIndex:selectionIndex];
		[_document loadThreadForThreadFace:[arrangedThreadFaces objectAtIndex:selectionIndex] activateTab:YES];
	}
}
-(IBAction)openNextUpdatedThread:(id)sender {
	if (![self canOpenNextThread]) return;
	NSArray *threadFaces = [_threadList objects];
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"resCountGap" ascending:NO] autorelease];
	NSArray *arrangedThreadFaces = [threadFaces sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	NSEnumerator *threadFaceEnumerator = [arrangedThreadFaces objectEnumerator];
	T2ThreadFace *threadFace;
	while (threadFace = [threadFaceEnumerator nextObject]) {
		if ([threadFace resCountGap]>0 && [threadFace state]==T2ThreadFaceStateUpdated) {
			[_document loadThreadForThreadFace:threadFace activateTab:YES];
			return;
		}
	}
	[_document showListTab:nil];
}

-(IBAction)addToBookmark:(id)sender {
	NSArray *selectedThreadFaces = [_threadFacesController selectedObjects];
	if (selectedThreadFaces && [selectedThreadFaces count]>0)
		[THAddBookmarkWindowController beginSheetModalForWindow:[_threadTable window]
												threadFaces:selectedThreadFaces];
}
-(IBAction)selectLabelAction:(id)sender {
	if (![sender isKindOfClass:[NSMenuItem class]]) return;
	NSNumber *number = [(NSMenuItem *)sender representedObject];
	unsigned label = [number unsignedIntValue];
	NSArray *selectedThreadFaces = [_threadFacesController selectedObjects];
	if (selectedThreadFaces && [selectedThreadFaces count]>0) {
		NSEnumerator *threadFaceEnumerator = [selectedThreadFaces objectEnumerator];
		T2ThreadFace *threadFace;
		while (threadFace = [threadFaceEnumerator nextObject]) {
			[threadFace setLabel:label];
		}
		[self updateLabelButton];
		[_threadTable setNeedsDisplay:YES];
	}
}

-(IBAction)openUsingWebBrowser:(id)sender {
	NSString *urlString = [_threadList webBrowserURLString];
	if (urlString) [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}
-(IBAction)openUsingOreyon:(id)sender {
	NSArray *selectedThreadFaces = [_threadFacesController selectedObjects];
	if (selectedThreadFaces && [selectedThreadFaces count]>0) {
		T2ThreadFace *threadFace = [selectedThreadFaces objectAtIndex:0];
		NSString *filePath = [threadFace logFilePath];
		if (filePath) {
			[[NSWorkspace sharedWorkspace] openFile:filePath
									withApplication:@"Oreyon"];
		}
	}
}

-(IBAction)postThread:(id)sender {
	if (_threadList)
		[[THPostingWindowController threadPostingWindowForThreadList:_threadList] retain];
}

-(IBAction)findNextThread:(id)sender {
	NSArray *selectedThreadFaces = [_threadFacesController selectedObjects];
	if (selectedThreadFaces && [selectedThreadFaces count]==1) {
		T2ThreadFace *threadFace = [selectedThreadFaces objectAtIndex:0];
		[[THChooseNextThreadWindowController beginSheetModalForWindow:[_sourceTable window]
													withOldThreadFace:threadFace
														newThreadFace:nil
															 delegate:self
													   didEndSelector:@selector(nextThreadFound:)] retain];
	}
}
-(void)nextThreadFound:(T2ThreadFace *)threadFace {
	if (!threadFace) return;
	[_document loadThreadForThreadFace:threadFace activateTab:YES];
}

-(IBAction)openParentThreadList:(id)sender {
	NSArray *selectedThreadFaces = [_threadFacesController selectedObjects];
	if (selectedThreadFaces && [selectedThreadFaces count]==1) {
		T2ThreadFace *threadFace = [selectedThreadFaces objectAtIndex:0];
		T2ListFace *listFace = [threadFace threadListFace];
		if (listFace) {
			[self openListWithListFace:listFace];
		}
	}
}

-(IBAction)copyURL:(id)sender {
	NSString *urlString = [_threadList webBrowserURLString];
	if (!urlString) return;
	NSURL *url = [NSURL URLWithString:urlString];
	
	NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
	[pasteBoard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, NSURLPboardType, nil]
					   owner:nil];
	[pasteBoard setString:urlString forType:NSStringPboardType];
	[url writeToPasteboard:pasteBoard];
}
-(IBAction)copyTitleAndURL:(id)sender {
	NSString *urlString = [_threadList webBrowserURLString];
	if (!urlString) return;
	NSURL *url = [NSURL URLWithString:urlString];
	urlString = [NSString stringWithFormat:@"%@\n%@", [_threadList title], urlString];
	
	NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
	[pasteBoard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, NSURLPboardType, nil]
					   owner:nil];
	[pasteBoard setString:urlString forType:NSStringPboardType];
	[url writeToPasteboard:pasteBoard];
}

-(IBAction)copyThreadsURL:(id)sender {
	
	NSArray *selectedThreadFaces = [_threadFacesController selectedObjects];
	if (!selectedThreadFaces || [selectedThreadFaces count] == 0) return;
	NSEnumerator *threadFaceEnumerator = [selectedThreadFaces objectEnumerator];
	T2ThreadFace *threadFace;
	NSMutableArray *strings = [NSMutableArray array];
	
	while (threadFace = [threadFaceEnumerator nextObject]) {
		NSString *urlString = [[threadFace thread] webBrowserURLString];
		if (urlString) {
			[strings addObject:urlString];
		}
	}
	NSString *resultString = [strings componentsJoinedByString:@"\n"];
	
	NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
	if ([selectedThreadFaces count] > 1) {
		[pasteBoard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil]
						   owner:nil];
		[pasteBoard setString:resultString forType:NSStringPboardType];
		
	} else {
		NSURL *url = [NSURL URLWithString:[strings lastObject]];
		if (url) {
			[pasteBoard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, NSURLPboardType, nil]
							   owner:nil];
			[pasteBoard setString:resultString forType:NSStringPboardType];
			[url writeToPasteboard:pasteBoard];
		}
	}	
}
-(IBAction)copyThreadsTitleAndURL:(id)sender {
	
	NSArray *selectedThreadFaces = [_threadFacesController selectedObjects];
	if (!selectedThreadFaces || [selectedThreadFaces count] == 0) return;
	NSEnumerator *threadFaceEnumerator = [selectedThreadFaces objectEnumerator];
	T2ThreadFace *threadFace;
	NSMutableArray *strings = [NSMutableArray array];
	
	while (threadFace = [threadFaceEnumerator nextObject]) {
		NSString *title = [threadFace title];
		NSString *urlString = [[threadFace thread] webBrowserURLString];
		if (title && urlString) {
			[strings addObject:title];
			[strings addObject:urlString];
		}
	}
	NSString *resultString = [strings componentsJoinedByString:@"\n"];
	
	NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
	if ([selectedThreadFaces count] > 1) {
		[pasteBoard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil]
						   owner:nil];
		[pasteBoard setString:resultString forType:NSStringPboardType];
		
	} else {
		NSURL *url = [NSURL URLWithString:[strings lastObject]];
		if (url) {
			[pasteBoard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, NSURLPboardType, nil]
							   owner:nil];
			[pasteBoard setString:resultString forType:NSStringPboardType];
			[url writeToPasteboard:pasteBoard];
		}
	}
}
-(IBAction)openThreadsUsingWebBrowser:(id)sender {
	
	NSArray *selectedThreadFaces = [_threadFacesController selectedObjects];
	if (!selectedThreadFaces || [selectedThreadFaces count] == 0) return;
	NSEnumerator *threadFaceEnumerator = [selectedThreadFaces objectEnumerator];
	T2ThreadFace *threadFace;
	NSMutableArray *strings = [NSMutableArray array];
	
	while (threadFace = [threadFaceEnumerator nextObject]) {
		NSString *urlString = [[threadFace thread] webBrowserURLString];
		NSURL *url = [NSURL URLWithString:urlString];
		if (url) {
			[[NSWorkspace sharedWorkspace] openURL:url];
		}
	}	
}

-(IBAction)showFallenThreadArchives:(id)sender {
	T2List *browsingRootList = _browsingRootList;
	T2List *threadList = _threadList;
	
	
	BOOL setShowArchiveMenuItemIsDefault = YES;
	if (browsingRootList && threadList) {
		NSArray *pathComponents = [[browsingRootList internalPath] pathComponents];
		if ([pathComponents count] >= 3) {
			if ([[pathComponents objectAtIndex:0] isEqualToString:@"2ch BBS"]
				&& [[pathComponents objectAtIndex:2] isEqualToString:@"kako"]) {
				setShowArchiveMenuItemIsDefault = NO;
			}
		}
	}	
	
	if (setShowArchiveMenuItemIsDefault) {
		
		if (!_threadList) return;
		NSString *internalPath = [_threadList internalPath];
		NSArray *internalPathComponents = [internalPath pathComponents];
		if (([internalPathComponents count] > 2) || ![[internalPath firstPathComponent] isEqualToString:@"2ch BBS"]) return;
		
		NSString *archiveInternalPath = [[@"2ch BBS" stringByAppendingPathComponent:[internalPathComponents lastObject]] stringByAppendingPathComponent:@"kako"];
		T2ListFace *archiveListFace = [T2ListFace listFaceWithInternalPath:archiveInternalPath
																	 title:nil
																	 image:nil];
		T2List *archiveList = [archiveListFace list];
		if (archiveList) {
			[self setBrowsingRootList:archiveList];
			[self setVisibleOfBrowser:YES];
			[archiveList load];
			
			[[THAppDelegate sharedInstance] setShowArchiveMenuItemIsDefault:NO];
		}
	} else {
		if (browsingRootList && threadList && ![[browsingRootList internalPath] hasPrefix:[threadList internalPath]]) {
			NSArray *pathComponents = [[browsingRootList internalPath] pathComponents];
			if ([pathComponents count] >= 3) {
				NSString *internalPath = [[pathComponents objectAtIndex:0] stringByAppendingPathComponent:[pathComponents objectAtIndex:1]];
				T2ListFace *listFace = [T2ListFace listFaceWithInternalPath:internalPath
																	  title:nil image:nil];
				T2List *list = [listFace list];
				if ([list isKindOfClass:[T2ThreadList class]]) {
					[self setThreadList:(T2ThreadList *)list];
				}
			}
		}	
		
		[self setVisibleOfBrowser:NO];
		[self setBrowsingRootList:nil];
		[[THAppDelegate sharedInstance] setShowArchiveMenuItemIsDefault:YES];
		
	}
}

-(IBAction)repairBoardData:(id)sender {
	if (!_threadList) return;
	
	NSString *internalPath = [_threadList internalPath];
	if ([internalPath hasPrefix:@"History"] ||
		[internalPath hasPrefix:@"Find2ch"] ||
		[internalPath hasPrefix:@"Local File"] ||
		[internalPath hasPrefix:@"webPage"]) return;
	/*
	
	NSString *folderPath = [[NSString appLogFolderPath] stringByAppendingPathComponent:internalPath];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	NSArray *files = [fileManager directoryContentsAtPath:folderPath];
	NSArray *logFiles = [files pathsMatchingExtensions:[NSArray arrayWithObjects:@"dat", @"gz", nil]];
	NSArray *plistFiles = [files pathsMatchingExtensions:[NSArray arrayWithObjects:@"plist",nil]];
	NSString *logFile;
	NSEnumerator *logFileEnumerator = [logFiles objectEnumerator];
	
	int missingDatCount = 0;
	
	while (logFile = [logFileEnumerator nextObject]) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSString *threadInternalName = logFile;
		if ([logFile hasSuffix:@"gz"]) threadInternalName = [logFile stringByDeletingPathExtension];
		NSString *threadInternalPath = [internalPath stringByAppendingPathComponent:threadInternalName];
		T2ThreadFace *threadFace = [T2ThreadFace threadFaceWithInternalPath:threadInternalPath];
		if ([threadFace resCount] == 0) {
			[threadFace thread];
			[_threadList addObject:threadFace];
			missingDatCount++;
		}
		[pool release];
	}
	
	int missingPlistCount = 0;
	
	logFileEnumerator = [plistFiles objectEnumerator];
	while (logFile = [logFileEnumerator nextObject]) {
		if (![logFile hasPrefix:@"threadList"]) {
			NSString *datFilePath = [[logFile stringByDeletingPathExtension] stringByAppendingPathExtension:@"dat"];
			NSString *datGzFilePath = [datFilePath stringByAppendingPathExtension:@"gz"];
			if (!([[folderPath stringByAppendingPathComponent:datFilePath] isExistentPath]) &&
				!([[folderPath stringByAppendingPathComponent:datGzFilePath] isExistentPath]) ) {
				[[folderPath stringByAppendingPathComponent:logFile] recycleFileAtPath];
				missingPlistCount++;
			}
		}
	}
	*/
	int result = [_threadList repairWithLogFolderContents];
	
	[[NSAlert alertWithMessageText:NSLocalizedString(@"Board Repaired",@"Bookmark")
					defaultButton:NSLocalizedString(@"OK",@"Bookmark")
				  alternateButton:nil
					  otherButton:nil
		informativeTextWithFormat:NSLocalizedString(@"%d missing files found.",@"Bookmark")
		,result] runModal];
}
@end
