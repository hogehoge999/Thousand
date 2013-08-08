//
//  MyDocument.h
//  ﾇPROJECTNAMEﾈ
//
//  Created by ﾇFULLUSERNAMEﾈ on ﾇDATEﾈ.
//  Copyright ﾇORGANIZATIONNAMEﾈ ﾇYEARﾈ . All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <Thousand2ch/Thousand2ch.h>
#import "PSMTabBarControl.h"

@class THBookmarkController, THThreadController, THSplitView, THProgressIndicator, THLabelButton, THImagePopUpButton;
/*
static NSString *__HTML_Header 	= nil;
static NSString *__HTML_ResPart	= nil;
static NSString *__HTML_Footer	= nil;
*/
static NSString *THDocToolBarIdentifier 			= @"THDocToolBarIdentifier";
static NSString *THDocShowPrefItemIdentifier 		= @"THDocShowPrefItemIdentifier";
static NSString *THDocShowBookmarkItemIdentifier 	= @"THDocShowBookmarkItemIdentifier";
static NSString *THDocLeftTabItemIdentifier 		= @"THDocLeftTabItemIdentifier";
static NSString *THDocRightTabItemIdentifier 		= @"THDocRightTabItemIdentifier";
static NSString *THDocCloseTabItemIdentifier 		= @"THDocCloseTabItemIdentifier";

static NSString *THDocReloadItemIdentifier 			= @"THDocReloadItemIdentifier";
static NSString *THDocDeleteItemIdentifier 			= @"THDocDeleteItemIdentifier";
static NSString *THDocDeleteSpecialItemIdentifier 	= @"THDocDeleteSpecialItemIdentifier";
static NSString *THDocWriteItemIdentifier 			= @"THDocWriteItemIdentifier";
static NSString *THDocWriteThreadItemIdentifier 	= @"THDocWriteThreadItemIdentifier";
static NSString *THDocAddBookmarkItemIdentifier 	= @"THDocAddBookmarkItemIdentifier";
static NSString *THDocOpenWithOreyonItemIdentifier 	= @"THDocOpenWithOreyonItemIdentifier";
static NSString *THDocLoadNextItemIdentifier 		= @"THDocLoadNextItemIdentifier";
static NSString *THDocDownloadWindowItemIdentifier 	= @"THDocDownloadWindowItemIdentifier";

static NSString *THDocLabelPopUpItemIdentifier 		= @"THDocLabelPopUpItemIdentifier";
static NSString *THDocRangePopUpItemIdentifier 		= @"THDocRangePopUpItemIdentifier";

static NSString *THDocSearchFieldItemIdentifier		= @"THDocSearchFieldItemIdentifier";
static NSString *THDocURLFieldItemIdentifier		= @"THDocURLFieldItemIdentifier";

@interface THDocument : NSDocument
{
	// instances
	id <T2AsynchronousLoading> _progressProvider;
	int _label;
	
	// temp
	T2ThreadFace *_tempThreadFace;
	
	// tab control
	int				_maxTabCount;
	int				_tabIndexToSelect;
	
	NSString		*_listInternalPathToSelect;
	
	NSMutableArray	*_waitingThreadInternalPaths;
	NSTimer			*_waitingTimer;
	
	BOOL			_docWindowSizeLoaded;
	float			_windowWidth;
	NSSize			_listTabSize;
	
	// for toggle
	IBOutlet THSplitView *_h1SplitView;
	IBOutlet NSScrollView *_threadTableViewScrollView;
	IBOutlet NSView *_threadTableViewPlaceHolder;
	
	// for control
	IBOutlet NSWindow				*_docWindow;
	NSToolbar						*_toolbar;
	
	IBOutlet THBookmarkController 	*_bookmarkController;
	IBOutlet NSObjectController		*_bookmarkSelfController;
	//IBOutlet NSSegmentedControl 	*_segmentedControl;
	
	// for TabView
	IBOutlet NSTabView 		*_tabView;
	IBOutlet NSTabViewItem 	*_listTab;
	
	//PSM
	IBOutlet PSMTabBarControl *_tabBarControl;
	
	// for Progress
	IBOutlet THProgressIndicator	*_progressIndicator;
	IBOutlet NSTextField			*_progressInfoField;
	
	// for Toolbar
	THLabelButton *_labelButton;
	THImagePopUpButton *_actionButton;
	IBOutlet NSSearchField 	*_searchField;
	IBOutlet NSTextField 	*_urlField;
}
#pragma mark -
#pragma mark Accessors

-(void)saveOnApplicationTerminate ;

+(void)setClassMaxThreadTabCount:(int)anInt ;
+(int)classMaxThreadTabCount ;

+(void)setClassNewTabAppearsInRightEnd:(BOOL)aBool ;
+(BOOL)classNewTabAppearsInRightEnd ;

+(NSString *)oreyonPath ;
-(void)setProgressProvider:(id <T2AsynchronousLoading>)progressProvider ;
-(id <T2AsynchronousLoading>)progressProvider ;
-(void)setLabel:(int)label ;
-(int)label ;
-(void)setTempThreadFace:(T2ThreadFace *)tempThreadFace ;
-(T2ThreadFace *)tempThreadFace ;
-(void)setTabContentsDictionary:(NSDictionary *)tabContentsDictionary;
-(NSDictionary *)tabContentsDictionary;
-(void)loadTabContents;

-(THBookmarkController *)bookmarkController;

-(NSArray *)threadFaces ;
-(NSArray *)threads ;
-(NSArray *)threadControllers ;
-(THThreadController *)selectedThreadController ;

-(NSWindow *)docWindow ;

#pragma mark -
#pragma mark Tab Control Methods
-(void)loadThreadsForThreadFaces:(NSArray *)threadFaces activateTab:(BOOL)activateTab ;
-(void)loadThreadForThreadFace:(T2ThreadFace *)threadFace activateTab:(BOOL)activateTab ;
-(void)waitingTimerFired:(NSTimer *)timer ;

-(void)loadThread:(T2Thread *)thread resExtractedPath:(NSString *)path;
-(void)loadThreadForURLString:(NSString *)URLString ;
-(void)deleteLogFilesWithThreadFaces:(NSArray *)threadFaces ;

-(void)addTabsForThreadControllers:(NSArray *)threadControllers ;
-(NSTabViewItem *)addTabForThreadController:(THThreadController *)threadController ;

+(void)removeTabsForThreads:(NSArray *)threads ;
-(void)removeTabsForThreads:(NSArray *)threads ;
-(void)removeTabAtEnd ;

-(void)displayTabTitleOfThreadController:(THThreadController *)threadController ;


#pragma mark -
#pragma mark Methods
-(void)displayURLString:(NSString *)aString ;

-(T2ThreadView *)selectedThreadView ;
-(void)selectTabForThread:(T2Thread *)thread ;

-(void)updateMenu ;
- (BOOL)validateUIOfAction:(SEL)action ;

-(void)openListWithListFace:(T2ListFace *)listFace ;

#pragma mark -
#pragma mark Tab Actions
-(IBAction)showListTab:(id)sender ;
-(IBAction)switchToLeftTab:(id)sender ;
-(IBAction)switchToRightTab:(id)sender ;
-(IBAction)closeTab:(id)sender ;
-(IBAction)moveTabToRightEnd:(id)sender ;

#pragma mark -
#pragma mark Document Actions
-(IBAction)activateSearchField:(id)sender ;
-(IBAction)search:(id)sender ;
-(IBAction)clearSearch:(id)sender ;

-(IBAction)openURL:(id)sender ;
-(IBAction)loadURL:(id)sender ;

-(IBAction)openNextThread:(id)sender ;
-(IBAction)openNextUpdatedThread:(id)sender ;

-(IBAction)dammyAction:(id)sender ;

-(IBAction)writeScreenShot:(id)sender ;

-(IBAction)runTestOperation:(id)sender ;
@end
