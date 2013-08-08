//
//  THAppDelegate.h
//  Thousand
//
//  Created by R. Natori on 05/08/07.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <Thousand2ch/Thousand2ch.h>

@class THLoadListOperation, THLoadThreadOperation;

@interface THAppDelegate : NSObject {
	NSString		*_thousandAppSupportFolderPath;
	NSString		*_logFolderPath;
	NSString		*_pluginPrefFolderPath;
	
	BOOL			_enableThreadListCache;
	BOOL			_enablePrefetchThread;
	THLoadListOperation		*_loadListOperation;
	THLoadThreadOperation	*_loadThreadOperation ;
	NSMutableArray	*_threadListCache ;
	//NSTimer			*_cacheReleaseTimer ;
	NSTimeInterval	_prevSavedTimeInterval;
	
	BOOL _keyEquivalentForMultipleTabs;
	
	//IBOutlet T2PluginPrefView	*_threadProcessorPluginsView;
	//IBOutlet NSArrayController	*_threadProcessorPluginsController;
	
	//Outlet for Source Window
	IBOutlet NSWindow			*_sourceWindow;
	IBOutlet NSTextView			*_sourceTextView;
	
	//Outlet for Dynamic Menus
	
	IBOutlet NSMenu				*_fileMenu;
	IBOutlet NSMenuItem			*_closeWindowMenuItem;
	IBOutlet NSMenuItem			*_closeTabMenuItem;
	IBOutlet NSMenuItem			*_showArchiveMenuItem;
	
	IBOutlet NSMenuItem			*_threadResStyleMenuItem;
	IBOutlet NSMenuItem			*_threadResTraceMenuItem;
	IBOutlet NSMenuItem			*_threadLabelMenuItem;
	IBOutlet NSMenuItem			*_threadDisplayMenuItem;
	
	IBOutlet NSMenuItem			*_debugMenuItem;
}

#pragma mark -
#pragma mark Class
+(THAppDelegate *)sharedInstance ;


#pragma mark -
#pragma mark  Accessors
-(void)setEnableThreadListCache:(BOOL)aBool;
-(BOOL)enableThreadListCache ;
-(void)setEnablePrefetchThread:(BOOL)aBool;
-(BOOL)enablePrefetchThread ;

#pragma mark -
#pragma mark  Methods
-(void)showSourceWindowWithString:(NSString *)aString ;
-(void)prefetchThreadWithThreadFaces:(NSArray *)threadFaces ;
-(void)cacheThreadList:(T2ThreadList *)threadList ;
-(void)openURLString:(NSString *)URLString ;

#pragma mark -
#pragma mark  Dynamic Menu
-(void)setThreadResStyleMenuTitle:(NSString *)aString enabled:(BOOL)aBool;
-(void)setThreadResTraceMenuTitle:(NSString *)aString enabled:(BOOL)aBool;

-(void)updateLabelMenu ;
-(void)updateLabelMenuWithNotification:(NSNotification *)notification ;
-(NSMenuItem *)labelMenuItem ;

-(void)setKeyEquivalentForMultipleTabs:(BOOL)aBool ;
- (void)windowDidBecomeKey:(NSNotification *)aNotification ;

-(void)setShowArchiveMenuItemIsDefault:(BOOL)aBool ;

#pragma mark -
#pragma mark  Actions
-(IBAction)showPrefWindow:(id)sender ;
-(IBAction)showDownloadWindow:(id)sender ;
-(IBAction)showCrashLogWindow:(id)sender ;
-(IBAction)showCookiesWindow:(id)sender ;
-(IBAction)saveBookmarksAndHistory:(id)sender ;
-(IBAction)openURL:(id)sender ;
-(void)didEndInputSheetWithString:(NSString *)URLString ;
@end
