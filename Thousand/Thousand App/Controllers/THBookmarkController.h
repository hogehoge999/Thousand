//
//  THBookmarkController.h
//  Thousand
//
//  Created by R. Natori on 05/08/01.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>

#define THBookmarkLocalize(string) (NSLocalizedString(string, @"Bookmark"))

static NSString *THBookmarkTableRowPboardType =		@"THBookmarkTableRowPboardType";
static NSString *THThreadListTableRowPboardType =	@"THThreadListTableRowPboardType";
static NSString *THThreadFacesPboardType =		@"THThreadFacesPboardType";

@class THSplitView, T2Browser, T2TableView, THThreadController, T2FilterArrayController, THDocument;

@interface THBookmarkController : NSObject<NSTableViewDelegate,NSTableViewDataSource,NSSplitViewDelegate> {
	T2List *_sourceList;
	//NSIndexSet *_sourceSelectedIndexes;
	
	T2List *_browsingRootList;
	NSArray *_browsingListArray;
	T2ThreadList *_threadList;
	BOOL _isBrowsingListParentOfThreadList;
	
	int _selectedScorerIndex;
	BOOL _browserVisible;
	NSDate *_lastNextThreadLoadingDate;
	NSTimer *_timer;
	
	IBOutlet NSMenu *_threadTableMenu;
	NSArray *_threadTableMenuItems;
	
	IBOutlet T2TableView *_sourceTable;
	IBOutlet T2TableView *_threadTable;
	NSArray *_threadTableColumns;
	IBOutlet T2Browser *_listBrowser;
	
	IBOutlet NSPopUpButton *_scorerPopUpButton;
	IBOutlet NSTableColumn *_scoreColumn;
	
	IBOutlet NSSearchField 	*_searchField;
	//BOOL _shouldSendWholeSearchString;
	
	IBOutlet THSplitView *_v1SplitView;
	IBOutlet THSplitView *_h1SplitView;
	IBOutlet NSScrollView *_threadTableViewScrollView;
	IBOutlet NSView *_threadTableViewPlaceHolder;
	
	IBOutlet NSArrayController *_sourceFacesController;
	IBOutlet T2FilterArrayController *_threadFacesController;
	
	IBOutlet THDocument *_document;
}

+(T2BookmarkList *)addCustomBookmarkListToSourceList ;
-(void)documentWillClose ;
-(void)loadSplitViewPositions ;

#pragma mark -
#pragma mark Accessors

+(void)setClassUseAppleAppLikeSourceTable:(BOOL)aBool ;
+(BOOL)classUseAppleAppLikeSourceTable ;
+(void)setClassVisibleOfThreadTableColumnForIdentifier:(NSString *)identifier visible:(BOOL)visible ;
+(BOOL)classVisibleOfThreadTableColumnForIdentifier:(NSString *)identifier ;
+(void)setClassSourceTableFont:(NSFont *)font ;
+(NSFont *)classSourceTableFont ;
+(void)setClassThreadTableFont:(NSFont *)font ;
+(NSFont *)classThreadTableFont ;
+(void)setClassSourceTableRowHeight:(float)rowHeight ;
+(float)classSourceTableRowHeight ;
+(void)setClassThreadTableRowHeight:(float)rowHeight ;
+(float)classThreadTableRowHeight ;

-(void)setSourceList:(T2List *)sourceList ;
-(T2List *)sourceList ;

-(void)setSelectedListInternalPath:(NSString *)selectedListInternalPath ;
-(NSString *)selectedListInternalPath ;

-(void)setBrowsingRootList:(T2List *)browsingRootList ;
-(T2List *)browsingRootList ;

-(void)setBrowsingListArray:(NSArray *)listArray ;
-(NSArray *)browsingListArray ;

//-(void)setSourceSelectedIndexes:(NSIndexSet *)indexSet ;
//-(NSIndexSet *)sourceSelectedIndexes ;

-(void)setThreadList:(T2ThreadList *)list ;
-(T2ThreadList *)threadList;

-(void)setIsBrowsingListParentOfThreadList:(BOOL)aBool ;
-(BOOL)isBrowsingListParentOfThreadList ;
-(T2List *)browsingList ;

//-(void)setThreadSelectedIndexes:(NSIndexSet *)indexSet ;
//-(NSIndexSet *)threadSelectedIndexes ;


-(int)labelOfSelectedThreadFaces ;

-(NSArray *)scorerNames ;
-(void)setScorerKey:(NSString *)scorerKey ;
-(NSString *)scorerKey ;
-(void)setSelectedScorerIndex:(int)anInt ;
-(int)selectedScorerIndex ;

//-(void)setShouldSendWholeSearchString:(BOOL)aBool ;
//-(BOOL)shouldSendWholeSearchString ;

#pragma mark -
#pragma mark Utilities
-(void)setVisibleOfBrowser:(BOOL)aBool ;
-(void)searchString:(NSString *)aString ;
-(BOOL)canOpenNextThread ;
//-(void)setShouldSendWholeSearchStringByThreadList ;
//-(void)setShouldSendWholeSearchStringByBrowsingList ;
-(NSString *)filterSearchString ;
-(void)openListWithListFace:(T2ListFace *)listFace ;

#pragma mark -
#pragma mark Menu And Toolbar item Validation
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem ;
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem ;
-(BOOL)validateUIOfAction:(SEL)action ;


#pragma mark -
#pragma mark Label and Font Update Preference 
-(void)updateLabelButton ;
-(void)updateLabelMenu ;
-(void)updateLabelMenuWithNotification:(NSNotification *)notification ;
-(void)reloadTableColumns:(NSNotification *)notification ;
-(void)reloadSourceTableFontSize:(NSNotification *)notification ;
-(void)reloadThreadTableFontSize:(NSNotification *)notification ;


#pragma mark -
#pragma mark Actions Internal
-(IBAction)selectActionInBrowser:(id)sender ;
- (BOOL)browserSelectRow:(int)row inColumn:(int)column ;
/*
-(IBAction)selectSourceTable:(id)sender ;
-(IBAction)selectThreadTable:(id)sender ;
 */
#pragma mark -
#pragma mark Actions
-(IBAction)reloadView:(id)sender ;
-(IBAction)cancelLoading:(id)sender ;

//-(IBAction)selectList:(id)sender ;
-(IBAction)removeSelectedLists:(id)sender ;

-(IBAction)selectThread:(id)sender ;
-(IBAction)openSelectedThread:(id)sender ;
-(IBAction)openSelectedThreadWithoutActivate:(id)sender ;
-(IBAction)removeSelectedThreads:(id)sender ;
-(IBAction)removeSelectedThreadsImmediately:(id)sender ;
-(IBAction)removeFallenThreads:(id)sender ;

-(IBAction)revealLogFileInFinder:(id)sender ;
//-(IBAction)removeSelectedThreadAndLogFiles:(id)sender ;

-(IBAction)openNextThread:(id)sender ;
-(IBAction)openNextUpdatedThread:(id)sender ;

-(IBAction)addToBookmark:(id)sender ;
-(IBAction)selectLabelAction:(id)sender ;

-(IBAction)openUsingWebBrowser:(id)sender ;
-(IBAction)openUsingOreyon:(id)sender ;
-(IBAction)findNextThread:(id)sender ;
-(IBAction)openParentThreadList:(id)sender ;

-(IBAction)postThread:(id)sender ;

-(IBAction)copyURL:(id)sender ;
-(IBAction)copyTitleAndURL:(id)sender ;
-(IBAction)copyThreadsURL:(id)sender ;
-(IBAction)copyThreadsTitleAndURL:(id)sender ;
-(IBAction)openThreadsUsingWebBrowser:(id)sender ;

-(IBAction)showFallenThreadArchives:(id)sender ;

-(IBAction)repairBoardData:(id)sender ;
@end
