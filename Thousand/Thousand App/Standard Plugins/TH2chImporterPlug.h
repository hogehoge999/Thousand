//
//  TH2chImporterPlug.h
//  Thousand
//
//  Created by R. Natori on 05/06/27.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <Thousand2ch/Thousand2ch.h>

@interface TH2chImporterPlug : NSObject <T2PluginInterface_v100, T2DictionaryConverting, 
T2ThreadImporting_v100, T2ListImporting_v100,
T2Posting_v200,
//T2ResPosting_v100, T2ThreadPosting_v100,
T2ResPostingUsingWebView_v100, T2ThreadPostingUsingWebView_v100>
{
//
	NSBundle	*_selfBundle;
	
	NSString	*_bbsmenuURLString;
	NSString	*_bbsmenuDateString;
	
	BOOL		_useGZIP;
	BOOL		_useOldDate;
	
	NSString	*_beMail;
	NSString	*_beCode;
	BOOL		_isBeActive;
	BOOL		_beSaveInKeychain;
	BOOL		_autoLoginBe;
	NSString	*_beStatusString;
	NSHTTPCookie *_beMDMD;
	NSHTTPCookie *_beDMDM;
	
	NSString	*_viewerID;
	NSString	*_viewerPS;
	NSString	*_viewerSUA;
	NSString	*_viewerSID;
	BOOL		_isViewerActive;
	BOOL		_saveInKeychain;
	BOOL		_autoLoginViewer;
	NSDate		*_lastViewerLoginDate;
	NSString	*_statusString;
	
	NSString	*_P2URLString;
	NSString	*_P2ID;
	NSString	*_P2PS;
	BOOL		_isP2Active;
	BOOL		_P2SaveInKeychain;
	BOOL		_autoLoginP2;
	BOOL		_retryAfterLoginP2;
	NSDate		*_lastP2LoginDate;
	NSString	*_P2StatusString;
	T2WebConnector *_p2Connector;

    BOOL		_threadTitleReplace;
    
	NSDictionary	*_masterListNG;
	NSDictionary	*_boardDictionary;
	//NSDictionary *_boardNameDictionary;
	//NSDictionary *_categoryDictionary;
	//NSMutableDictionary	*_oldServersDictionary;
	
	NSArray		*_lists;
	T2ListFace	*_rootListFace;
		
	//T2List *_rootList;
	
	NSSet		*_liveBoardKeys;
	NSMutableDictionary *_movingDictionary;
	NSMutableArray *_movingBoardConnecors;
	
	NSString *_threadInternalPathToLoadAfterRelogin;
	NSString *_postingInternalPathToLoadAfterRelogin;
}

-(void)setBBSMenuURLString:(NSString *)urlString ;
-(NSString *)BBSMenuURLString ;
-(void)setUseGZIP:(BOOL)aBool ;
-(BOOL)useGZIP ;
-(void)setUseOldDate:(BOOL)aBool ;
-(BOOL)useOldDate ;
-(void)setBBSMenuDateString:(NSString *)aString ;
-(NSString *)BBSMenuDateString ;

#pragma mark -
#pragma mark Be2ch
-(void)setBeMail:(NSString *)aString ;
-(NSString *)beMail ;
-(void)setBeCode:(NSString *)aString ;
-(NSString *)beCode ;
-(void)setIsBeActive:(BOOL)aBool ;
-(BOOL)isBeActive ;
-(void)setBeSaveInKeychain:(BOOL)aBool ;
-(BOOL)beSaveInKeychain ;
-(void)setAutoLoginBe:(BOOL)aBool ;
-(BOOL)autoLoginBe ;

-(void)setBeMDMD:(NSHTTPCookie *)aCookie ;
-(NSHTTPCookie *)beMDMD ;
-(void)setBeDMDM:(NSHTTPCookie *)aCookie ;
-(NSHTTPCookie *)beDMDM ;
-(BOOL)beCookieExists ;
/*
-(void)setLastViewerLoginDate:(NSDate *)aDate ;
-(NSDate *)lastViewerLoginDate ;
 */
-(void)setBeStatusString:(NSString *)aString ;
-(NSString *)beStatusString ;
-(void)setEmbedBeIcon:(BOOL)aBool ;
-(BOOL)embedBeIcon ;

#pragma mark -
#pragma mark 2chViewer
-(void)setViewerID:(NSString *)aString ;
-(NSString *)viewerID ;
/*
-(void)setViewerPS:(NSString *)aString ;
-(NSString *)viewerPS ;
 */
-(void)setViewerSUA:(NSString *)aString ;
-(NSString *)viewerSUA ;
-(void)setViewerSID:(NSString *)aString ;
-(NSString *)viewerSID ;
-(void)setIsViewerActive:(BOOL)aBool ;
-(BOOL)isViewerActive ;
-(void)setSaveInKeychain:(BOOL)aBool ;
-(BOOL)saveInKeychain ;
-(void)setAutoLoginViewer:(BOOL)aBool ;
-(BOOL)autoLoginViewer ;
-(void)setLastViewerLoginDate:(NSDate *)aDate ;
-(NSDate *)lastViewerLoginDate ;
-(void)setStatusString:(NSString *)aString ;
-(NSString *)statusString ;

#pragma mark -
#pragma mark offcial P2
-(void)setP2URLString:(NSString *)aString ;
-(NSString *)P2URLString ;
-(void)setP2ID:(NSString *)aString ;
-(NSString *)P2ID ;
/*
-(void)setP2PS:(NSString *)aString ;
-(NSString *)P2PS ;
 */
-(void)setIsP2Active:(BOOL)aBool ;
-(BOOL)isP2Active ;
-(void)setP2SaveInKeychain:(BOOL)aBool ;
-(BOOL)P2SaveInKeychain ;
-(void)setAutoLoginP2:(BOOL)aBool ;
-(BOOL)autoLoginP2 ;
-(void)setLastP2LoginDate:(NSDate *)aDate ;
-(NSDate *)lastP2LoginDate ;
-(void)setP2StatusString:(NSString *)aString ;
-(NSString *)P2StatusString ;
/*
-(void)setBoardDictionary:(NSDictionary *)dic ;
-(NSDictionary *)boardDictionary ;
-(void)setBoardNameDictionary:(NSDictionary *)dic ;
-(NSDictionary *)boardNameDictionary ;
-(void)setCategoryDictionary:(NSDictionary *)dic ;
-(NSDictionary *)categoryDictionary ;
-(void)setLiveBoardKeys:(NSSet *)set ;
-(NSSet *)liveBoardKeys ;
*/
-(void)setAdditionalBoardString:(NSString *)aString ;
-(NSString *)additionalBoardString ;

-(void)setThreadTitleReplace:(BOOL)aBool ;
-(BOOL)threadTitleReplace;

//-(void)setOldServersDictionary:(NSDictionary *)oldServersDictionary ;
//-(NSDictionary *)oldServersDictionary ;

#pragma mark -
#pragma mark protocol T2PluginInterface_v100
+(NSArray *)pluginInstances ;
-(NSString *)uniqueName ;
-(NSString *)localizedName ;
-(NSString *)localizedPluginInfo ;
-(T2PluginType)pluginType ;
-(int)pluginOrder ;

-(NSArray *)preferenceItems ;

#pragma mark -
#pragma mark protocol T2ThreadImporting_v100
-(NSString *)importableRootPath ;
-(T2Thread *)threadForThreadFace:(T2ThreadFace *)threadFace ;
-(NSURLRequest *)URLRequestForThread:(T2Thread *)thread ;
-(T2LoadingResult)buildThread:(T2Thread *)thread withWebData:(T2WebData *)webData ;

-(NSArray *)importableTypes ;
-(NSString *)threadLogFilePathForInternalPath:(NSString *)internalPath ;
-(NSString *)threadInternalPathForProposedURLString:(NSString *)URLString ;
-(NSString *)resExtractPatnForProposedURLString:(NSString *)URLString ;

#pragma mark -
// thread importing internal
-(void)buildThread:(T2Thread *)thread withErrorHTMLString:(NSString *)srcString ;
-(void)buildThread:(T2Thread *)thread withSrcString:(NSString *)srcString appending:(BOOL)appending ;
T2Res* resWith_ResNum_Name_Mail_DateAndOther_content_thread(int resNumber, NSString *namePart, NSString *mailPart,
														 NSString *dateAndOtherPart, NSString *contentPart, T2Thread *thread) ;
-(void)removeLogFileAtPath:(NSString *)path ;
-(void)resetThread:(T2Thread *)thread ;
-(void)registerViewerRequiredThreadForInternalPath:(NSString *)internalPath ;

#pragma mark -
#pragma mark protocol T2ListImporting_v100
-(NSString *)importableRootPath ;
-(T2List *)listForListFace:(T2ListFace *)listFace ;

-(NSURLRequest *)URLRequestForList:(T2List *)list ;
-(T2LoadingResult)buildList:(T2List *)list withWebData:(T2WebData *)webData ;
-(NSArray *)rootListFaces ;
-(NSString *)listInternalPathForProposedURLString:(NSString *)URLString ;
-(NSImage *)imageForListFace:(T2ListFace *)listFace ;

#pragma mark -
//list importing internal
-(void)loadMasterListWithWebData:(T2WebData *)webData ;
-(NSArray *)boardFacesInCategoryString:(NSString *)src
					   boardDictionary:(NSMutableDictionary *)boardDictionary
						 liveBoardKeys:(NSMutableSet *)liveBoardKeys ;
				//	  categoryName:(NSString *)categoryName
				//	   boardDictionary:(NSMutableDictionary *)boardDictionary
				//   boardNameDictionary:(NSMutableDictionary *)boardNameDictionary ;
-(BOOL)isMasterListNG:(NSString *)aString ;

-(void)buildOldDateList:(T2List *)list WithWebData:(T2WebData *)webData ;
-(void)buildOldThreadList:(T2ThreadList *)threadList WithWebData:(T2WebData *)webData boardKey:(NSString *)boardKey ;

-(BOOL)buildThreadList:(T2ThreadList *)threadList WithWebData:(T2WebData *)webData boardKey:(NSString *)boardKey ;
-(void)registerMovedServerForInternalPath:(NSString *)internalPath ; 

-(void)registerOldServerDomain:(NSString *)domainName forBoardKey:(NSString *)boardKey ;
-(NSArray *)oldServerDomainsForBoardKey:(NSString *)boardKey ;

#pragma mark -
#pragma mark protocol T2Posting_v200
-(NSString *)postableRootPath;
-(BOOL)canPostResToThread:(T2Thread *)thread ;
-(BOOL)canPostThreadToThreadList:(T2ThreadList *)threadList ;
-(T2Posting *)postingToThread:(T2Thread *)thread res:(T2Res *)res ;
-(T2Posting *)postingToThreadList:(T2ThreadList *)threadList res:(T2Res *)res threadTitle:(NSString *)threadTitle ;
-(NSURLRequest *)URLRequestForPosting:(T2Posting *)posting ;
-(T2LoadingResult)didEndPosting:(T2Posting *)posting forWebData:(T2WebData *)webData ;

#pragma mark -
#pragma mark protocol T2ResPosting_v100
//-(NSString *)postableRootPath;
//-(BOOL)canPostResToThread:(T2Thread *)thread ;
-(NSURLRequest *)URLRequestForPostingRes:(T2Res *)tempRes thread:(T2Thread *)thread ;
-(T2LoadingResult)didEndPostingResForWebData:(T2WebData *)webData 
						 confirmationMessage:(NSString **)confirmationMessage
					 confirmationButtonTitle:(NSString **)confirmationButtonTitle
						   additionalRequest:(NSURLRequest **)additionalRequest;
-(T2WebForm *)webFormForAdditionalConfirmation:(NSString *)source baseURLString:(NSString *)baseURLString;
-(NSURLRequest *)requestForConfirmationWebForm:(T2WebForm *)webForm ;
#pragma mark protocol T2ResPostingUsingWebView_v100
-(T2LoadingResult)didEndPostingResForSource:(NSString *)source ;
//-(NSArray *)accessoryPreferenceItems ;

#pragma mark -
#pragma mark T2ThreadPosting_v100
//-(NSString *)postableRootPath;
//-(BOOL)canPostThreadToThreadList:(T2ThreadList *)threadList ;
-(NSURLRequest *)URLRequestForPostingFirstRes:(T2Res *)tempRes threadTitle:(NSString *)threadTitle
						   toThreadList:(T2ThreadList *)threadList ;
-(T2LoadingResult)didEndPostingThreadForWebData:(T2WebData *)webData 
							confirmationMessage:(NSString **)confirmationMessage
						confirmationButtonTitle:(NSString **)confirmationButtonTitle
							  additionalRequest:(NSURLRequest **)additionalRequest;
#pragma mark T2ThreadPostingUsingWebView_v100
-(T2LoadingResult)didEndPostingThreadForSource:(NSString *)source ;
//-(NSArray *)accessoryPreferenceItems ;

#pragma mark -
#pragma mark Actions
-(IBAction)reloadMasterList:(id)sender ;
-(IBAction)logoutViewer:(id)sender ;
-(IBAction)loginViewer:(id)sender ;
-(void)loginViewerOnWindow:(NSWindow *)docWindow ;
-(IBAction)buyViewer:(id)sender ;

-(IBAction)loginP2:(id)sender ;
-(IBAction)logoutP2:(id)sender ;
-(IBAction)aboutP2:(id)sender ;

-(IBAction)loginBe:(id)sender ;
-(IBAction)logoutBe:(id)sender ;
-(IBAction)aboutBe:(id)sender ;

@end