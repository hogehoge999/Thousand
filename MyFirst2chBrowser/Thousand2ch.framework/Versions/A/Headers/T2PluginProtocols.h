
#import <Cocoa/Cocoa.h>
@class T2Res, T2Thread, T2List, T2ListFace, T2ThreadList, T2ThreadFace, T2WebData, T2WebForm, T2Posting, WebView;

//======================================================================================
#pragma mark -
#pragma mark Thousand Plug-in common interface 

typedef enum {
	T2EmbeddedPlugin = 0,
	T2DefaultPlugin,
	T2StandardPlugin,
	T2TestingPlugin
} T2PluginType;

typedef enum {
	T2LoadingFailed = 0,
	T2LoadingSucceed,
	T2RetryLoading
} T2LoadingResult;

enum T2PluginOrder {
	T2PluginOrderFirst = -1000,
	T2PluginOrderMiddle = 0,
	T2PluginOrderLast = 1000
} ;

@protocol T2PluginInterface_v100 <NSObject>
+(NSArray *)pluginInstances ;
-(NSString *)uniqueName ;
-(NSString *)localizedName ;
-(NSString *)localizedPluginInfo ;
-(T2PluginType)pluginType ;
-(int)pluginOrder ;
@end
@interface NSObject (T2PluginInterface_v100)
-(NSArray *)uniqueNamesOfdependingPlugins ;
-(NSArray *)preferenceItems ;
@end


//======================================================================================
#pragma mark -
#pragma mark List Importer

@protocol T2ListImporting_v100 <T2PluginInterface_v100>
-(NSString *)importableRootPath ;
-(T2List *)listForListFace:(T2ListFace *)listFace ;
@end
@interface NSObject (T2ListImporting_v100)
-(NSURLRequest *)URLRequestForList:(T2List *)list ;
-(T2LoadingResult)buildList:(T2List *)list withWebData:(T2WebData *)webData ;
-(NSArray *)rootListFaces ;
-(NSString *)listInternalPathForProposedURLString:(NSString *)URLString ;
-(NSImage *)imageForListFace:(T2ListFace *)listFace ;
@end

//======================================================================================
#pragma mark -
#pragma mark SearchList Importer

@protocol T2SearchListImporting_v100 <T2ListImporting_v100>
-(void)setSearchString:(NSString *)searchString ;
-(NSString *)searchString ;
-(T2ListFace *)persistentListFaceForSearchString:(NSString *)searchString ;
-(BOOL)receivesWholeSearchString ;
@end
@interface NSObject (T2SearchListImporting_v100)
-(void)setTargetList:(T2List *)list ;
-(T2List *)targetList ;
@end

//======================================================================================
#pragma mark -
#pragma mark Thread Scorer and Filter
@protocol T2ThreadFaceScoring_v100 <T2PluginInterface_v100>
-(NSArray *)scoreKeys;
-(NSString *)localizedNameForScoreKey:(NSString *)key;
-(id)scoreValueOfThreadFace:(T2ThreadFace *)threadFace forKey:(NSString *)key;
@end

typedef enum {
	T2FilteringParameterUndefined = -1,
	T2FilteringParameterNone = 0,
	T2FilteringParameterString,
	T2FilteringParameterStringsIndex,
	T2FilteringParameterMenuItemsIndex
} T2FilteringParameterType;

@protocol T2ThreadFaceFiltering_v100 <T2PluginInterface_v100>
-(NSArray *)filterNames;
-(NSString *)localizedNameForFilterName:(NSString *)name;
-(NSArray *)filterOperatorsForFilterName:(NSString *)name;
-(NSString *)localizedDescriptionForFilterOperator:(NSString *)filterOperator;
-(NSString *)localizedAppendixForFilterOperator:(NSString *)filterOperator;
-(T2FilteringParameterType)parameterTypeForFilterName:(NSString *)name;
-(id)parameterInputObjectForFilterName:(NSString *)name;
-(NSArray *)filteredThreadFaces:(NSArray *)threadFaces forFilterName:(NSString *)name 
				filterOperator:(NSString *)filterOperator parameter:(id)parameter;
@end

//======================================================================================
#pragma mark -
#pragma mark Thread Importer
@protocol T2ThreadImporting_v100 <T2PluginInterface_v100>
-(NSString *)importableRootPath ;
-(T2Thread *)threadForThreadFace:(T2ThreadFace *)threadFace ;
@end
@interface NSObject (T2ThreadImporting_v100)
-(NSURLRequest *)URLRequestForThread:(T2Thread *)thread ;
-(T2LoadingResult)buildThread:(T2Thread *)thread withWebData:(T2WebData *)webData ;
-(NSArray *)importableTypes ;
-(NSString *)threadLogFilePathForInternalPath:(NSString *)internalPath ;
-(NSString *)threadInternalPathForProposedURLString:(NSString *)URLString ;
-(NSString *)resExtractPatnForProposedURLString:(NSString *)URLString ;
@end

//======================================================================================
/*
#pragma mark -
#pragma mark Thread Exporter
@protocol T2ThreadExporting_v090 <T2PluginInterface_v100>
-(NSString *)exportableType;
-(BOOL)exportThread:(T2Thread *)thread toPath:(NSString *)filePath ;
@end
*/

//======================================================================================

//======================================================================================
#pragma mark -
#pragma mark Posting
@protocol T2Posting_v200 <T2PluginInterface_v100>
-(NSString *)postableRootPath;
-(BOOL)canPostResToThread:(T2Thread *)thread ;
-(BOOL)canPostThreadToThreadList:(T2ThreadList *)threadList ;
-(T2Posting *)postingToThread:(T2Thread *)thread res:(T2Res *)res ;
-(T2Posting *)postingToThreadList:(T2ThreadList *)threadList res:(T2Res *)res threadTitle:(NSString *)threadTitle ;
-(NSURLRequest *)URLRequestForPosting:(T2Posting *)posting ;
-(T2LoadingResult)didEndPosting:(T2Posting *)posting forWebData:(T2WebData *)webData ;
@end
@interface NSObject (T2Posting_v100)
-(NSArray *)accessoryPreferenceItems ;
@end

//======================================================================================
#pragma mark -
#pragma mark Res Posting
@protocol T2ResPosting_v100 <T2PluginInterface_v100>
-(NSString *)postableRootPath;
-(BOOL)canPostResToThread:(T2Thread *)thread ;
-(NSURLRequest *)URLRequestForPostingRes:(T2Res *)tempRes thread:(T2Thread *)thread;
-(T2LoadingResult)didEndPostingResForWebData:(T2WebData *)webData 
						 confirmationMessage:(NSString **)confirmationMessage
					 confirmationButtonTitle:(NSString **)confirmationButtonTitle
						   additionalRequest:(NSURLRequest **)additionalRequest;
@end
@interface NSObject (T2ResPosting_v100)
-(NSArray *)accessoryPreferenceItems ;
@end
//======================================================================================
#pragma mark -
#pragma mark Thread Posting
@protocol T2ThreadPosting_v100 <T2PluginInterface_v100>
-(NSString *)postableRootPath;
-(BOOL)canPostThreadToThreadList:(T2ThreadList *)threadList ;
-(NSURLRequest *)URLRequestForPostingFirstRes:(T2Res *)tempRes threadTitle:(NSString *)threadTitle
								 toThreadList:(T2ThreadList *)threadList ;
-(T2LoadingResult)didEndPostingThreadForWebData:(T2WebData *)webData 
							confirmationMessage:(NSString **)confirmationMessage
						confirmationButtonTitle:(NSString **)confirmationButtonTitle
							  additionalRequest:(NSURLRequest **)additionalRequest;
@end
@interface NSObject (T2ThreadPosting_v100)
-(NSArray *)accessoryPreferenceItems ;
@end
//======================================================================================
#pragma mark -
#pragma mark Res Posting (WebView)
@protocol T2ResPostingUsingWebView_v100 <T2PluginInterface_v100>
-(NSString *)postableRootPath;
-(BOOL)canPostResToThread:(T2Thread *)thread ;
-(NSURLRequest *)URLRequestForPostingRes:(T2Res *)tempRes thread:(T2Thread *)thread;
-(T2LoadingResult)didEndPostingResForSource:(NSString *)source ;
@end
@interface NSObject (T2ResPostingUsingWebView_v100)
-(NSArray *)accessoryPreferenceItems ;
-(T2WebForm *)webFormForAdditionalConfirmation:(NSString *)source ;
-(NSURLRequest *)requestForConfirmationWebForm:(T2WebForm *)webForm ;
-(NSURLRequest *)webViewWillSendPostingRequest:(NSURLRequest *)urlRequest ;
@end

//======================================================================================
#pragma mark -
#pragma mark Thread Posting (WebView)
@protocol T2ThreadPostingUsingWebView_v100 <T2PluginInterface_v100>
-(NSString *)postableRootPath;
-(BOOL)canPostThreadToThreadList:(T2ThreadList *)threadList ;
-(NSURLRequest *)URLRequestForPostingFirstRes:(T2Res *)tempRes threadTitle:(NSString *)threadTitle
						   toThreadList:(T2ThreadList *)threadList ;
-(T2LoadingResult)didEndPostingThreadForSource:(NSString *)source ;
@end
@interface NSObject (T2ThreadPostingUsingWebView_v100)
-(NSArray *)accessoryPreferenceItems ;
-(T2WebForm *)webFormForAdditionalConfirmation:(NSString *)source baseURLString:(NSString *)baseURLString;
-(NSURLRequest *)requestForConfirmationWebForm:(T2WebForm *)webForm ;
-(NSURLRequest *)webViewWillSendPostingRequest:(NSURLRequest *)urlRequest ;
@end

//======================================================================================
/*
#pragma mark -
#pragma mark Authentication

@protocol T2Authentication_v090 <T2PluginInterface_v100>
-(NSString *)authenticationKey ;
-(NSString *)LocalizedLabelForUserString ;
-(NSString *)LocalizedLabelForPasswordString ;
-(NSURLRequest *)requestForAuthenticationAsUser:(NSString *)user
									   password:(NSString *)password ;
-(T2LoadingResult)authenticationResultForWebData:(T2WebData *)webData ;
-(NSDictionary *)authenticationInfo ;
-(NSURLRequest *)requestForDiscardAuthentication ;
-(T2LoadingResult)DiscardAuthenticationResultForWebData:(T2WebData *)webData ;
@end
*/

//======================================================================================
#pragma mark -
#pragma mark Thread Processor
@protocol T2ThreadProcessing_v100 <T2PluginInterface_v100>
-(void)processThread:(T2Thread *)thread appendingIndex:(unsigned)index ;
@end


//======================================================================================
#pragma mark -
#pragma mark Res Extractor
@protocol T2ResExtracting_v100 <T2PluginInterface_v100>
-(NSArray *)extractKeys ;
-(NSIndexSet *)extractResIndexesInThread:(T2Thread *)thread forKey:(NSString *)key path:(NSString *)path ;
-(NSString *)localizedDescriptionForKey:(NSString *)key path:(NSString *)path ;
@end
@interface NSObject (T2ResExtracting_v100)
-(NSArray *)defaultExtractPaths ;
@end


//======================================================================================
#pragma mark -
#pragma mark ResHTML Processor
@protocol T2ThreadHTMLProcessing_v100 <T2PluginInterface_v100>
-(NSString *)processedHTML:(NSString *)htmlString ofRes:(T2Res *)res inThread:(T2Thread *)thread ;
@end


//======================================================================================
#pragma mark -
#pragma mark Thread Viewer (partial HTML)
@protocol T2ThreadPartialHTMLExporting_v100 <T2PluginInterface_v100>
-(NSString *)headerHTMLWithThread:(T2Thread *)thread baseURL:(NSURL **)baseURL ;
-(NSString *)footerHTMLWithThread:(T2Thread *)thread ;
-(NSString *)resHTMLWithRes:(T2Res *)res ;
-(NSString *)popUpHeaderHTMLWithThread:(T2Thread *)thread baseURL:(NSURL **)baseURL ;
-(NSString *)popUpFooterHTMLWithThread:(T2Thread *)thread ;
@end


//======================================================================================
#pragma mark -
#pragma mark Thread Viewer (HTML)
@protocol T2ThreadHTMLExporting_v100 <T2PluginInterface_v100>
-(NSString *)HTMLWithThread:(T2Thread *)thread baseURL:(NSURL **)baseURL ;
@end

//======================================================================================
#pragma mark -
#pragma mark Thread Viewer (View)
@protocol T2ThreadViewing_v100 <T2PluginInterface_v100>
-(NSView *)viewWithThread:(T2Thread *)thread ;
@end

//======================================================================================
#pragma mark -
#pragma mark Preview

typedef enum {
	T2PreviewInPopUp = 0,
	T2PreviewInline,
	T2PreviewInExternalWindow,
	T2PreviewInFullScreen
} T2PreviewType;

@protocol T2URLPreviewing_v100 <T2PluginInterface_v100>
-(NSArray *)previewableURLHosts;
-(NSArray *)previewableURLExtensions;
-(BOOL)isPreviewableURLString:(NSString *)urlString type:(T2PreviewType)type;
-(NSString *)partialHTMLForPreviewingURLString:(NSString *)urlString
									   type:(T2PreviewType)type
									minSize:(NSSize *)minSize ;
@end
