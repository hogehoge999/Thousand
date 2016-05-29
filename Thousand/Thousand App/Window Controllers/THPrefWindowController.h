//
//  THPrefWindowController.h
//  Thousand
//
//  Created by R. Natori on 06/10/21.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>
#import <AppKit/NSToolbar.h>

//Pref ToolBar
static NSString *THPrefToolBarIdentifier 			= @"THPrefToolBar";
static NSString *THPrefGeneralItemIdentifier 		= @"THPrefGeneralItem";
static NSString *THPrefAppearanceItemIdentifier 	= @"THPrefAppearanceItem";
static NSString *THPrefFontAndColorItemIdentifier 	= @"THPrefFontAndColorItem";
static NSString *THPrefBookmarkViewItemIdentifier 	= @"THPrefBookmarkViewItem";
static NSString *THPrefWebViewItemIdentifier 		= @"THPrefWebViewItem";
static NSString *THPref2chItemIdentifier 			= @"THPref2chItem";
static NSString *THPrefPreviewItemIdentifier 		= @"THPrefPreviewItem";
static NSString *THPrefPluginItemIdentifier 		= @"THPrefPluginItem";
static NSString *THPrefAdvancedItemIdentifier 		= @"THPrefAdvancedItem";
static NSString *THPrefDebugItemIdentifier 			= @"THPrefDebugItem";
//static NSString *THPrefProcessorsViewItem			= @"THPrefProcessorsViewItem";

@class THFontWell;

@interface THPrefWindowController : NSWindowController <T2DictionaryConverting,NSToolbarDelegate> {
	NSArray			*_plugins;
	//int				_pluginSelectedIndex;
	//NSArray			*_pluginViews;
	id				_selectedPlugin;
	id				_selectedListImporterPlugin;
	id				_selectedPartialHTMLPlugin;
	id				_selectedHTMLExporterPlugin;
	id				_selectedURLPreviewerPlugin;
	
	BOOL _isLoaded;
	
	// Font
	unsigned _changingFont;
	NSFont *_webStandardFont;
	NSFont *_webFixedFont;
	NSFont *_sourceListFont;
	NSFont *_threadListFont;
	NSFont *_draftFont;
	
	// Label
	NSMutableDictionary *_labelDictionary;
	
	// Pref
	BOOL _showsDebugMenu;
	
	// Popup and Preview
	NSArray *_popUpPreviewActionNames;
	NSArray *_clickResPreviewActionNames;
	NSArray *_clickURLPreviewActionNames;
	
	// Icon Set
	NSDictionary *_iconSetFolderDic;
	NSArray *_iconSetNames;
	NSString *_iconSetName;
	
	// WebPref
	WebPreferences *_webPreferences;
	WebPreferences *_postingWebPreferences;
    BOOL _useProxy;
	
	// Advanced
	NSString *_webCacheUsageString;
	double _webCacheUsage;
	IBOutlet NSProgressIndicator *_webCacheIndicator;
	
	// Outlet for Pref Window
	IBOutlet NSObjectController	*_selfController;
	IBOutlet NSObjectController	*_2chPlugController;
	
	NSWindow					*_prefWindow;
	IBOutlet NSTabView			*_prefTabView;
	
	IBOutlet T2PluginPrefView	*_allPluginsView;
	IBOutlet T2PluginPrefView	*_listImporterPluginsView;
	IBOutlet T2PluginPrefView	*_HTMLPluginsView;
	IBOutlet T2PluginPrefView	*_URLPreviewerPluginsView;
	
	IBOutlet NSComboBox *_sourceListFontSizeComboBox;
	IBOutlet NSComboBox *_threadListFontSizeComboBox;
	
	IBOutlet THFontWell *_webStandardFontWell;
	IBOutlet THFontWell *_webFixedFontWell;
	IBOutlet THFontWell *_sourceListFontWell;
	IBOutlet THFontWell *_threadListFontWell;
	IBOutlet THFontWell *_draftFontWell;
}
#pragma mark -
#pragma mark Factory and Init
+(id)sharedPrefWindowController ;
+(void)releaseSharedPrefWindowController ;
-(id)initPrefWindowController ;

#pragma mark -
#pragma mark Accessors

-(T2PluginManager *)pluginManager ;
-(void)setSelectedPlugin:(id)plugin ;
-(id)selectedPlugin ;
-(void)setSelectedListImporterPlugin:(id)plugin ;
-(id)selectedListImporterPlugin ;

-(void)setSelectedPartialHTMLExporterPlugin:(id)plugin ;
-(id)selectedPartialHTMLExporterPlugin ;

-(void)setSelectedHTMLExporterPlugin:(id)plugin ;
-(id)selectedHTMLExporterPlugin ;
-(void)setSelectedURLPreviewerPlugin:(id)plugin ;
-(id)selectedURLPreviewerPlugin ;

#pragma mark -
#pragma mark  Font Pref
-(void)loadFont ;
-(void)saveFont ;
-(NSFont *)fontFromPref:(NSString *)nameKey size:(NSString *)sizeKey ;
//-(void)changeFont:(id)sender ;
//-(IBAction)registerChangingFont:(id)sender ;

-(void)setWebStandardFont:(NSFont *)aFont ;
-(NSFont *)webStandardFont ;
//-(NSString *)webStandardFontDisplayName ;
-(void)setWebFixedFont:(NSFont *)aFont ;
-(NSFont *)webFixedFont ;
//-(NSString *)webFixedFontDisplayName ;
-(void)setSourceListFont:(NSFont *)sourceListFont ;
-(NSFont *)sourceListFont ;
-(void)setThreadListFont:(NSFont *)threadListFont ;
-(NSFont *)threadListFont ;
-(void)setDraftFont:(NSFont *)draftFont ;
-(NSFont *)draftFont ;


//-(void)setSourceTableFontSize:(float)fontSize ;
//-(float)sourceTableFontSize ;
//-(void)setThreadTableFontSize:(float)fontSize ;
//-(float)threadTableFontSize ;
-(void)setSourceTableRowHeight:(float)rowHeight ;
-(float)sourceTableRowHeight ;
-(void)setThreadTableRowHeight:(float)rowHeight ;
-(float)threadTableRowHeight ;

#pragma mark -
#pragma mark Label Pref
-(void)setLabelDictionary:(NSMutableDictionary *)labelDictionary ;
-(NSMutableDictionary *)labelDictionary ;
-(void)updateLabels ;

#pragma mark -
#pragma mark Appearance Pref

-(BOOL)laterThanLeopard ;
-(BOOL)laterThanTiger ;

-(void)setBrowserMetal:(BOOL)aBool ;
-(BOOL)browserMetal ;

-(void)setUseAppleAppLikeSourceTable:(BOOL)aBool ;
-(BOOL)useAppleAppLikeSourceTable ;

-(BOOL)runningOnLeopard ;

-(NSArray *)iconSetNames ;
-(BOOL)iconSetSelectable ;
-(void)setIconSetName:(NSString *)aString ;
-(NSString *)iconSetName ;

#pragma mark -
#pragma mark Thread Table Pref

-(void)setClassVisibleOfThreadTableColumnForIdentifier:(NSString *)identifier visible:(BOOL)visible ;
-(BOOL)classVisibleOfThreadTableColumnForIdentifier:(NSString *)identifier ;

-(void)setVisibleOfThreadTableColumn_stateImage:(BOOL)visible ;
-(BOOL)visibleOfThreadTableColumn_stateImage ;
-(void)setVisibleOfThreadTableColumn_resCountNew:(BOOL)visible ;
-(BOOL)visibleOfThreadTableColumn_resCountNew ;
-(void)setVisibleOfThreadTableColumn_resCount:(BOOL)visible ;
-(BOOL)visibleOfThreadTableColumn_resCount ;
-(void)setVisibleOfThreadTableColumn_resCountGap:(BOOL)visible ;
-(BOOL)visibleOfThreadTableColumn_resCountGap ;
-(void)setVisibleOfThreadTableColumn_order:(BOOL)visible ;
-(BOOL)visibleOfThreadTableColumn_order ;
-(void)setVisibleOfThreadTableColumn_createdDate:(BOOL)visible ;
-(BOOL)visibleOfThreadTableColumn_createdDate ;
-(void)setVisibleOfThreadTableColumn_labelScore:(BOOL)visible ;
-(BOOL)visibleOfThreadTableColumn_labelScore ;
-(void)setVisibleOfThreadTableColumn_velocity:(BOOL)visible ;
-(BOOL)visibleOfThreadTableColumn_velocity ;
-(void)setVisibleOfThreadTableColumn_valiable:(BOOL)visible ;
-(BOOL)visibleOfThreadTableColumn_valiable ;

#pragma mark -
#pragma mark General Pref

-(NSArray *)localizedDefaultExtractPaths ;
-(void)setDefaultExtractPathIndex:(int)index ;
-(int)defaultExtractPathIndex ;

-(NSArray *)popUpPreviewActionNames ;
-(void)setPopUpResPreviewActionIndex:(int)index ;
-(int)popUpResPreviewActionIndex ;
-(void)setPopUpURLPreviewActionIndex:(int)index ;
-(int)popUpURLPreviewActionIndex ;

-(NSArray *)clickResPreviewActionNames ;
-(void)setClickResPreviewActionIndex:(int)index ;
-(int)clickResPreviewActionIndex ;

-(NSArray *)clickURLPreviewActionNames ;
-(void)setClickURLPreviewActionIndex:(int)index ;
-(int)clickURLPreviewActionIndex ;

-(void)setMaxThreadTabCount:(int)anInt ;
-(int)maxThreadTabCount ;

-(void)setResPopUpWindowWidth:(float)width ;
-(float)resPopUpWindowWidth ;

-(void)setPopUpDelaySeconds:(float)delaySeconds ;
-(float)popUpDelaySeconds ;

-(void)setNewTabLocationType:(int)type ;
-(int)newTabLocationType ;

-(void)setUsedNames:(NSArray *)array ;
-(NSArray *)usedNames ;
-(void)setUsedMails:(NSArray *)array ;
-(NSArray *)usedMails ;


-(void)setAllowsTypeToJump:(BOOL)aBool ;
-(BOOL)allowsTypeToJump ;
-(void)setTypeWait:(float)aFloat ;
-(float)typeWait ;

#pragma mark -
#pragma mark Advanced Pref

-(void)setAbbreviatedLogFolderPath:(NSString *)path ;
-(NSString *)abbreviatedLogFolderPath ;
-(void)setLogFolderPath:(NSString *)path ;
-(NSString *)logFolderPath ;

-(void)setDownloadInThreadFolder:(BOOL)aBool ;
-(BOOL)downloadInThreadFolder ;
-(void)setDownloadWhenFilesExist:(BOOL)aBool ;
-(BOOL)downloadWhenFilesExist ;
-(void)setAbbreviatedDownloadDestinationFolderPath:(NSString *)path ;
-(NSString *)abbreviatedDownloadDestinationFolderPath ;
-(void)setDownloadDestinationFolderPath:(NSString *)path ;
-(NSString *)downloadDestinationFolderPath ;

-(void)setWebCacheUsageString:(NSString *)aString ;
-(NSString *)webCacheUsageString ;
-(void)setWebCacheUsage:(double)aDouble ;
-(double)webCacheUsage ;

-(void)setShowsDebugMenu:(BOOL)aBool ;
-(BOOL)showsDebugMenu ;
-(void)setSafari2Debug:(BOOL)aBool ;
-(BOOL)safari2Debug ;

-(void)setEnableThreadListCache:(BOOL)aBool;
-(BOOL)enableThreadListCache ;
-(void)setEnablePrefetchThread:(BOOL)aBool;
-(BOOL)enablePrefetchThread ;

-(BOOL)useProxy;
-(void)setUseProxy:(BOOL)aBool;
-(void)setProxyHost:(NSString *)host;
-(NSString *)proxyHost;


#pragma mark -
#pragma mark Methods
-(void)saveAllPrefs ;

- (IBAction)checkUseProxy:(id)sender;
#pragma mark -
#pragma mark  Actions
-(IBAction)switchPrefTab:(id)sender ;
-(IBAction)clearNameAndMailHistory:(id)sender ;
-(IBAction)reloadSkins:(id)sender ;
-(IBAction)selectLogFolderPath:(id)sender ;
-(IBAction)selectDownloadDestinationFolderPath:(id)sender ;
-(IBAction)clearWebCache:(id)sender ;
//-(IBAction)sourceTableFontSizeEntered:(id)sender ;
//-(IBAction)threadTableFontSizeEntered:(id)sender ;
-(IBAction)reloadMasterList:(id)sender ;
-(IBAction)logoutViewer:(id)sender ;
-(IBAction)loginViewer:(id)sender ;
-(IBAction)loginP2:(id)sender ;
-(IBAction)logoutP2:(id)sender ;
-(IBAction)loginBe:(id)sender ;
-(IBAction)logoutBe:(id)sender ;
@end
