//
//  T2PluginManager.h
//  Thousand
//
//  Created by R. Natori on 05/06/26.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "T2PluginProtocols.h"

@class T2Thread, T2List, T2ListFace, T2ThreadList, T2ThreadFace, T2WebData;

@interface T2PluginManager : NSObject {
	// all Plugins Dictionary
	NSMutableDictionary 	*_allPluginDic;
	NSMutableArray			*_allPlugins;
	
	// Plugin Prefs
	NSDictionary 			*_pluginOldPrefDic;
	NSDictionary			*_pluginKeysDic;
	NSMutableDictionary		*_pluginModifiedDic;
	
	// List Importer
	NSMutableArray 			*_listImporterPlugins;
	NSMutableDictionary 	*_listImporterPluginDic;
	
	// SearchList Importer
	NSMutableArray 			*_searchListImporterPlugins;
	
	// Listitem Scorer and Filter
	NSMutableDictionary 	*_threadFaceScorerPluginDic;
	NSMutableArray 			*_threadFaceScoreKeyArray;
	NSMutableArray 			*_threadFaceScoreLocalizedNameArray;
	
	NSMutableDictionary 	*_threadFaceFilterPluginDic;
	NSMutableArray 			*_threadFaceFilterNameArray;
	NSMutableArray 			*_threadFaceFilterLocalizedNameArray;
	
	// Thread Importer
	NSMutableDictionary 	*_threadImporterPluginDic;
	NSMutableArray 			*_threadExporterPlugins;
	
	// Res Extractor
	NSMutableDictionary		*_extractorPluginDic;
	NSMutableArray 			*_extractorPlugins;
	NSArray 				*_defaultExtractPaths;
	NSArray 				*_localizedDefaultExtractPaths;
	
	// Processor and Styler
	NSMutableArray 			*_threadProcessorPlugins;
	NSMutableArray 			*_HTMLProcessorPlugins;
	
	// Thread Viewer
	NSMutableArray 			*_partialHTMLExporterPlugins;
	id <T2ThreadPartialHTMLExporting_v100> _viewPartialHtmlPlug;
	NSMutableArray 			*_viewHtmlPlugins;
	NSMutableArray 			*_threadViewerPlugins;
	
	// URL Previewer
	NSMutableDictionary		*_hostPreviewerPluginDic;
	NSMutableDictionary		*_extensionPreviewerPluginDic;
	NSMutableArray			*_previewerPlugins;
	
	// Posting (Modern)
	NSMutableDictionary		*_postingPluginDic;
	// Res Posting
	NSMutableDictionary		*_resPostingPluginDic;
	// Thread Posting
	NSMutableDictionary		*_threadPostingPluginDic;
	
	// Res Posting (WebView)
	NSMutableDictionary		*_webResPostingPluginDic;
	// Thread Posting (WebView)
	NSMutableDictionary		*_webThreadPostingPluginDic;
	
	unsigned _viewHtmlPlugIndex;
}

#pragma mark -
#pragma mark Class Methods
+(void)setClassPluginFolderPaths:(NSArray *)anArray ;
+(void)setClassEmbeddedPluginClasses:(NSArray *)anArray ;
+(void)setClassPluginPrefFolderPath:(NSString *)path ;
+(void)setClassForbiddenPluginBundleIdentifiers:(NSArray *)bundleIdentifiers ;
+(T2PluginManager *)sharedManager ;

#pragma mark -
#pragma mark Genaral Plugin Management
-(void)loadAllPlugins ;
-(void)unloadAllPlugins ;
-(NSArray *)allPlugins ;
-(NSDictionary *)pluginDictionary ;
-(id <T2PluginInterface_v100>)pluginForUniqueName:(NSString *)uniqueName ;

-(void)loadPluginPrefs ;
-(void)savePluginPrefs ;

#pragma mark -
#pragma mark T2ListImporting_v100
-(NSArray *)listImporterPlugins ;
-(NSArray *)rootListFaces ;
-(id <T2ListImporting_v100>)listImporterForInternalPath:(NSString *)internalPath ;
-(T2List *)listForListFace:(T2ListFace *)listFace ;
-(NSImage *)imageForListFace:(T2ListFace *)listFace ;
-(NSString *)listInternalPathForProposedURLString:(NSString *)URLString ;

#pragma mark -
#pragma mark T2SearchListImporting_v100
-(NSArray *)searchListImporterPlugins ;
-(NSArray *)searchListRootListFaces ;
-(BOOL)isSearchList:(T2List *)list ;
-(void)setSearchString:(NSString *)searchString forList:(T2List *)list ;
-(NSString *)searchStringForList:(T2List *)list ;
-(BOOL)shouldSendWholeSearchStringForList:(T2List *)list ;
-(T2ListFace *)persistentListFaceFromList:(T2List *)list ;

#pragma mark -
#pragma mark T2ThreadImporting_v100
-(NSArray *)threadImporterPlugins ;
-(id <T2ThreadImporting_v100>)threadImporterForInternalPath:(NSString *)internalPath ;
-(T2Thread *)threadForThreadFace:(T2ThreadFace *)threadFace ;

-(NSString *)threadLogFilePathForInternalPath:(NSString *)internalPath ;
-(NSString *)threadInternalPathForProposedURLString:(NSString *)URLString ;
-(NSString *)resExtractPatnForProposedURLString:(NSString *)URLString ;

#pragma mark -
#pragma mark T2ThreadFaceScoring_v100
-(NSArray *)threadFaceScorerPlugins ;
-(NSArray *)threadFaceScoreKeys ;
-(NSArray *)threadFaceScoreLocalizedNames ;
-(id <T2ThreadFaceScoring_v100>)threadFaceScoringPluginForKey:(NSString *)key ;

#pragma mark -
#pragma mark T2ThreadFaceFiltering_v100
-(NSArray *)threadFaceFilterPlugins ;
-(NSArray *)threadFaceFilterNames ;
-(NSArray *)threadFaceScoreLocalizedNames ;
-(id <T2ThreadFaceFiltering_v100>)threadFaceFilteringPluginForName:(NSString *)name ;

#pragma mark -
#pragma mark T2ThreadProcessing_v100
-(NSArray *)threadProcessorPlugins ;
-(void)processThread:(T2Thread *)thread appendingIndex:(unsigned)index;

#pragma mark -
#pragma mark T2ResExtracting_v100
-(NSArray *)resExtractorPlugins ;
-(id <T2ResExtracting_v100>)resExtractorForKey:(NSString *)key ;
-(NSIndexSet *)extractResIndexesInThread:(T2Thread *)thread forPath:(NSString *)path ;
-(NSString *)localizedDescriptionOfExtractPath:(NSString *)path ;

-(NSArray *)defaultExtractPaths ;
-(NSArray *)localizedDefaultExtractPaths ;
-(NSArray *)defautlExtractPathMenuItems ; //selectResExtractPathAction:

#pragma mark -
#pragma mark T2ThreadHTMLProcessing_v100
-(NSArray *)HTMLProcessorPlugins ;
-(NSString *)processedHTML:(NSString *)htmlString ofRes:(T2Res *)res inThread:(T2Thread *)thread ;

#pragma mark -
#pragma mark T2ThreadPartialHTMLExporting_v100
-(NSArray *)partialHTMLExporterPlugins ;
-(void)setPartialHTMLExporterPlugin:(id <T2ThreadPartialHTMLExporting_v100>)partialHTMLExporterPlugin ;
-(id <T2ThreadPartialHTMLExporting_v100>)partialHTMLExporterPlugin ;

#pragma mark -
#pragma mark T2ThreadHTMLExporting_v100
-(NSArray *)HTMLExporterPlugins ;
-(id <T2ThreadHTMLExporting_v100>)HTMLExporterPlugin ;
-(NSArray *)HTMLExporterMenuItems ; //selectHTMLExporterAction:

#pragma mark -
#pragma mark Thread Viewer (View)
-(NSArray *)threadViewerPlugins ;
-(NSArray *)threadViewerMenuItems ; //selectThreadViewerAction:


#pragma mark -
#pragma mark T2URLPreviewing_v100
-(NSArray *)URLpreviewerPlugins ;
-(id <T2URLPreviewing_v100>)URLPreviewerForURLString:(NSString *)urlString ;
-(BOOL)isPreviewableURLString:(NSString *)urlString type:(T2PreviewType)type ;
-(NSString *)partialHTMLforPreviewingURLString:(NSString *)urlString type:(T2PreviewType)type minSize:(NSSize *)minSize;

#pragma mark -
#pragma mark T2Posting_v200
-(NSArray *)postingPlugins ;
-(id <T2Posting_v200>)postingPluginForInternalPath:(NSString *)path ;

#pragma mark -
#pragma mark T2ResPosting_v100
-(NSArray *)resPostingPlugins ;
-(id <T2ResPosting_v100>)resPostingPluginForInternalPath:(NSString *)path ;
-(BOOL)canPostResToThread:(T2Thread *)thread ;
#pragma mark T2ResPostingUsingWebView_v100
-(NSArray *)webResPostingPlugins ;
-(id <T2ResPostingUsingWebView_v100>)webResPostingPluginForInternalPath:(NSString *)path ;
//-(BOOL)canPostResToThread:(T2Thread *)thread ;

#pragma mark -
#pragma mark T2ThreadPosting_v100
-(NSArray *)threadPostingPlugins ;
-(id <T2ThreadPosting_v100>)threadPostingPluginForInternalPath:(NSString *)path ;
-(BOOL)canPostThreadToThreadList:(T2ThreadList *)threadList ;
#pragma mark T2ThreadPostingUsingWebView_v100
-(NSArray *)webThreadPostingPlugins ;
-(id <T2ThreadPostingUsingWebView_v100>)webThreadPostingPluginForInternalPath:(NSString *)path ;
//-(BOOL)canPostThreadToThreadList:(T2ThreadList *)threadList ;
@end
