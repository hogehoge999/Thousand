//
//  TH2chImporterPlug.m
//  Thousand
//
//  Created by R. Natori on 05/06/27.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

// Thread Path = 2ch BBS/Board ID/Thread ID
// Board Path = 2ch BBS/Board ID
// Old Log List Path = 2ch BBS/Board ID/kako/Server Domain
// Old Thread Path = 2ch BBS/Board ID/kako/Server Domain/Thread ID

#import "TH2chImporterPlug.h"
#import "T2UtilityHeader.h"
#import "TH2chViewerLoginWindowController.h"

#define plugLocalizedString(aString) ([_selfBundle localizedStringForKey:aString value:aString table:@"StandardPlugLocalizable"])

static NSString *__uniqueName = @"jp_natori_Thousand_2chImporter";

static NSString *__datType 			= @"dat";
static NSString *__rootPath 		= @"2ch BBS";
static NSString *__categoryPrefix 	= @"Category_";
static NSString *__oldLogPath 		= @"kako";
static NSString *__fileSchemePrefix = @"file://";

static NSString *__rootListImageName 	= @"TH16_2ch BBS";
static NSString *__boardImageName 		= @"TH16_2ch Board";
static NSString *__categoryImageName 	= @"TH16_2ch Category";

static NSImage *__rootListImage 	= nil;
static NSImage *__boardImage 		= nil;
static NSImage *__categoryImage 	= nil;

static NSString *__bbsmenuURLString = @"http://menu.2ch.net/bbsmenu.html";
static NSString *__2chViewerCGIURLString = @"https://2chv.tora3.net/futen.cgi";
static NSString *__2chViewerServiceName = @"2ch Viewer";

static NSString *__tripPrefix = nil;
static NSCharacterSet *__whitespaceAndNewlineCharacterSet 	= nil;
static NSCharacterSet *__digitCharacterSet 					= nil;
static NSCharacterSet *__controlCharacterSet 				= nil;

static NSString *__liveCategoryString = nil;
static NSString *__resPostingSubmit = nil;
static NSString *__threadPostingSubmit = nil;
static NSString *__2chViewerRequiresRelogin = nil;
static NSString *__missingBoardOrThread = nil;

static BOOL	__embedBeIcon;

void stampList(T2List *list) {
	if ([list image]) return;
	NSString *internalPath = [list internalPath];
	if ([[internalPath lastPathComponent] hasPrefix:__categoryPrefix])
		[list setImage:__categoryImage];
	else
		[list setImage:__boardImage];
}

@implementation TH2chImporterPlug

#pragma mark -
#pragma mark Protocol T2DictionaryConverting
-(NSArray *)dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use {
	return [NSArray arrayWithObjects:@"BBSMenuURLString",
			@"useGZIP",
			@"useOldDate",
			@"BBSMenuDateString",
			@"beMail",
			@"embedBeIcon",
			@"isBeActive",
			@"beSaveInKeychain",
			@"autoLoginBe",
			@"beMDMD",
			@"beDMDM",
			
			@"viewerID",
			@"viewerSID",
			@"isViewerActive",
			@"saveInKeychain",
			@"autoLoginViewer",
			@"lastViewerLoginDate",
			
			@"P2URLString",
			@"P2ID",
			@"isP2Active",
			@"P2SaveInKeychain",
			@"autoLoginP2",
			@"lastP2LoginDate",
			
			nil];
}

#pragma mark -
#pragma mark Protocol Object Initialize
-(id)init {
	self = [super init];
	_selfBundle = [[NSBundle bundleForClass:[self class]] retain];
	NSDictionary *tempDic = [NSDictionary dictionaryWithContentsOfFile:[_selfBundle pathForResource:@"Thousand2chSettings" ofType:@"plist"]];
	_masterListNG = [[tempDic objectForKey:@"MasterListNG"] retain];
	_bbsmenuURLString = [[tempDic objectForKey:@"bbsmenuURLString"] retain];
	_P2URLString = [[tempDic objectForKey:@"P2URLString"] retain];
	
	__embedBeIcon = YES;
	
	__rootListImage = [[NSImage imageNamed:__rootListImageName orInBundle:_selfBundle] retain];
	__boardImage 	= [[NSImage imageNamed:__boardImageName orInBundle:_selfBundle] retain];
	__categoryImage = [[NSImage imageNamed:__categoryImageName orInBundle:_selfBundle] retain];
	
	__tripPrefix = [plugLocalizedString(@"tripDelimiterString") retain];
	__whitespaceAndNewlineCharacterSet =	[[NSCharacterSet whitespaceAndNewlineCharacterSet] retain];
	__digitCharacterSet =					[[NSCharacterSet decimalDigitCharacterSet] retain];
	__controlCharacterSet =					[[NSCharacterSet controlCharacterSet] retain];
	
	__liveCategoryString = [[tempDic objectForKey:@"LIVE_CATEGORY_STRING"] retain];
	__resPostingSubmit = [[tempDic objectForKey:@"RES_POSTING_SUBMIT"] retain];
	__threadPostingSubmit = [[tempDic objectForKey:@"THREAD_POSTING_SUBMIT"] retain];
	__2chViewerRequiresRelogin = [[tempDic objectForKey:@"2CH_VIEWER_REQUIRES_RELOGIN"] retain];
	__missingBoardOrThread = [[tempDic objectForKey:@"MISSING_BOARD_OR_THREAD"] retain];
	
	//_oldServersDictionary = [[NSMutableDictionary alloc] init];
	
	[self loadMasterListWithWebData:nil];
	return self;
}

-(void)dealloc {
	[_bbsmenuURLString release];
	[_bbsmenuDateString release];
	
	[_beMail release];
	[_beCode release];
	
	[_masterListNG release];
	[_boardDictionary release];
	
	[_lists release];
	[_rootListFace release];
	
	[_liveBoardKeys release];
	//[_oldServersDictionary release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors

-(void)setBBSMenuURLString:(NSString *)urlString {
	if (!urlString) return;
	if (_bbsmenuURLString != urlString && ![_bbsmenuURLString isEqualToString:urlString]) {
		setObjectWithRetain(_bbsmenuURLString, urlString);
		if (_bbsmenuURLString) {
			[self reloadMasterList:nil];
		}
	}
}
-(NSString *)BBSMenuURLString { return _bbsmenuURLString; }

-(void)setUseGZIP:(BOOL)aBool { _useGZIP = aBool; }
-(BOOL)useGZIP { return _useGZIP; }
-(void)setUseOldDate:(BOOL)aBool { _useOldDate = aBool; }
-(BOOL)useOldDate { return _useOldDate; }

-(void)setBBSMenuDateString:(NSString *)aString {
	setObjectWithRetain(_bbsmenuDateString, aString);
}
-(NSString *)BBSMenuDateString { return _bbsmenuDateString; }

-(void)setBeMail:(NSString *)aString {
	setObjectWithRetain(_beMail, aString);
	if (!_beMail || [_beMail length] == 0)
		[self setIsBeActive:NO];
}
-(NSString *)beMail { return _beMail; }
-(void)setBeCode:(NSString *)aString {
	setObjectWithRetain(_beCode, aString);
	if (!_beCode || [_beCode length] == 0)
		[self setIsBeActive:NO];
}
-(NSString *)beCode { return _beCode; }
-(void)setIsBeActive:(BOOL)aBool {
	_isBeActive = aBool;
	
	T2HTTPCookieStorage *sharedHTTPCookieStorage = [T2HTTPCookieStorage sharedHTTPCookieStorage];
	NSArray *cookies = [sharedHTTPCookieStorage cookiesForURL:[NSURL URLWithString:@"http://be.2ch.net/"]];
	if (_isBeActive) {
		if (_beMDMD && _beDMDM) {
			[sharedHTTPCookieStorage setCookie:_beMDMD];
			[sharedHTTPCookieStorage setCookie:_beDMDM];
		}
	} else {
		if (cookies && ([cookies count] > 0)) {
			NSEnumerator *cookieEnumerator = [cookies objectEnumerator];
			NSHTTPCookie *cookie;
			BOOL mailFound = NO;
			BOOL codeFound = NO;
			while (cookie = [cookieEnumerator nextObject]) {
				if ([[cookie name] isEqualToString:@"MDMD"] || [[cookie name] isEqualToString:@"DMDM"]) {
					[sharedHTTPCookieStorage deleteCookie:cookie];
				}
			}
		}
	}
}
-(BOOL)isBeActive {
	return _isBeActive;
}
-(void)setBeSaveInKeychain:(BOOL)aBool { _beSaveInKeychain = aBool; }
-(BOOL)beSaveInKeychain { return _beSaveInKeychain; }
-(void)setAutoLoginBe:(BOOL)aBool { _autoLoginBe = aBool; }
-(BOOL)autoLoginBe { return _autoLoginBe; }

-(void)setBeMDMD:(NSHTTPCookie *)aCookie { setObjectWithRetain(_beMDMD, aCookie); }
-(NSHTTPCookie *)beMDMD { return _beMDMD; }
-(void)setBeDMDM:(NSHTTPCookie *)aCookie { setObjectWithRetain(_beDMDM, aCookie); }
-(NSHTTPCookie *)beDMDM { return _beDMDM; }
-(BOOL)beCookieExists {
	T2HTTPCookieStorage *sharedHTTPCookieStorage = [T2HTTPCookieStorage sharedHTTPCookieStorage];
	NSArray *cookies = [sharedHTTPCookieStorage cookiesForURL:[NSURL URLWithString:@"http://be.2ch.net/"]];
	BOOL oneFound = NO;
	if (_isBeActive) {
		if (cookies && ([cookies count] >= 2)) {
			NSEnumerator *cookieEnumerator = [cookies objectEnumerator];
			NSHTTPCookie *cookie;
			BOOL mailFound = NO;
			BOOL codeFound = NO;
			while (cookie = [cookieEnumerator nextObject]) {
				NSString *cookieName = [cookie name];
				if ([cookieName isEqualToString:@"DMDM"] || [cookieName isEqualToString:@"MDMD"]) {
					if (oneFound) {
						return YES;
					} else {
						oneFound = YES;
					}
				}
			}
		}
	}
	return NO;				
}
/*
 -(void)setLastViewerLoginDate:(NSDate *)aDate ;
 -(NSDate *)lastViewerLoginDate ;
 */
-(void)setBeStatusString:(NSString *)aString { setObjectWithRetain(_beStatusString, aString); }
-(NSString *)beStatusString { return _beStatusString; }

-(void)setEmbedBeIcon:(BOOL)aBool { __embedBeIcon = aBool; }
-(BOOL)embedBeIcon { return __embedBeIcon; }

#pragma mark -
-(void)setViewerID:(NSString *)aString { setObjectWithRetain(_viewerID, aString); }
-(NSString *)viewerID { return _viewerID; }
/*
-(void)setViewerPS:(NSString *)aString { setObjectWithRetain(_viewerPS, aString); }
-(NSString *)viewerPS { return _viewerPS; }
 */
-(void)setViewerSUA:(NSString *)aString { setObjectWithRetain(_viewerSUA, aString); }
-(NSString *)viewerSUA { return _viewerSUA; }
-(void)setViewerSID:(NSString *)aString {
	setObjectWithRetain(_viewerSID, aString);
	if (_viewerSID) {
		[self setStatusString:plugLocalizedString(@"Log-in.")];
		
		int location = [_viewerSID rangeOfString:@":" options:NSLiteralSearch].location;
		if (location != NSNotFound) {
			NSString *viewerSUA = [_viewerSID substringToIndex:location];
			
			NSBundle *appBundle = [NSBundle mainBundle];
			NSString *appName = [[appBundle executablePath] lastPathComponent];
			//NSString *appVersion = [appBundle objectForInfoDictionaryKey:@"CFBundleVersion"] ;
			
			viewerSUA = [viewerSUA stringByAppendingFormat:@" (%@/1.00)", appName];
			 
			[self setViewerSUA:viewerSUA];
			return;
		}
	}
	[self setViewerSUA:nil];
}
-(NSString *)viewerSID { return _viewerSID; }
-(void)setIsViewerActive:(BOOL)aBool { _isViewerActive = aBool; }
-(BOOL)isViewerActive { return _isViewerActive; }
-(void)setSaveInKeychain:(BOOL)aBool { _saveInKeychain = aBool; }
-(BOOL)saveInKeychain { return _saveInKeychain; }
-(void)setAutoLoginViewer:(BOOL)aBool { _autoLoginViewer = aBool; }
-(BOOL)autoLoginViewer { return _autoLoginViewer; }
-(void)setLastViewerLoginDate:(NSDate *)aDate { setObjectWithRetain(_lastViewerLoginDate, aDate); }
-(NSDate *)lastViewerLoginDate { return _lastViewerLoginDate; }

-(void)setStatusString:(NSString *)aString { setObjectWithRetain(_statusString, aString); }
-(NSString *)statusString { return _statusString; }


#pragma mark -
#pragma mark offcial P2

-(void)setP2URLString:(NSString *)aString {
	if (![aString hasSuffix:@"/"]) {
		aString = [aString stringByAppendingString:@"/"];
	}
	setObjectWithRetain(_P2URLString, aString);
}
-(NSString *)P2URLString { return _P2URLString; }

-(void)setP2ID:(NSString *)aString { setObjectWithRetain(_P2ID, aString); }
-(NSString *)P2ID { return _P2ID; }
-(void)setP2PS:(NSString *)aString { setObjectWithRetain(_P2PS, aString); }
-(NSString *)P2PS { return _P2PS; }
-(void)setIsP2Active:(BOOL)aBool { _isP2Active = aBool; }
-(BOOL)isP2Active { return _isP2Active; }
-(void)setP2SaveInKeychain:(BOOL)aBool { _P2SaveInKeychain = aBool; }
-(BOOL)P2SaveInKeychain { return _P2SaveInKeychain; }
-(void)setAutoLoginP2:(BOOL)aBool { _autoLoginP2 = aBool; }
-(BOOL)autoLoginP2 { return _autoLoginP2; }
-(void)setLastP2LoginDate:(NSDate *)aDate { setObjectWithRetain(_lastP2LoginDate, aDate); }
-(NSDate *)lastP2LoginDate { return _lastP2LoginDate; }
-(void)setP2StatusString:(NSString *)aString { setObjectWithRetain(_P2StatusString, aString); }
-(NSString *)P2StatusString { return _P2StatusString; }

#pragma mark -

-(void)setAdditionalBoardString:(NSString *)aString {
	
}
-(NSString *)additionalBoardString { return nil; }
/*
-(void)setOldServersDictionary:(NSDictionary *)oldServersDictionary {
	if (oldServersDictionary) [_oldServersDictionary setDictionary:oldServersDictionary];
}
-(NSDictionary *)oldServersDictionary {
	return _oldServersDictionary;
}
*/


#pragma mark -
#pragma mark Protocol T2PluginInterface_v100

+(NSArray *)pluginInstances {
	return [NSArray arrayWithObject:[[[self alloc] init] autorelease]];
}
-(NSString *)uniqueName { return __uniqueName; }
-(NSString *)localizedName { return plugLocalizedString(__uniqueName) ; }
-(NSString *)localizedPluginInfo { return plugLocalizedString([__uniqueName stringByAppendingString:@"_info"]) ; }
-(T2PluginType)pluginType { return T2EmbeddedPlugin; }

-(int)pluginOrder { return T2PluginOrderFirst; }

-(NSArray *)preferenceItems {
	return [NSArray arrayWithObjects:
			[T2PreferenceItem topTitleItemWithTitle:plugLocalizedString(@"BBS Menu Settings") info:nil],
			[T2PreferenceItem stringItemWithKey:@"BBSMenuURLString"
										  title:plugLocalizedString(@"BBS Menu URL")
										   info:plugLocalizedString(@"location of 2ch-BBS list")],
			
			[T2PreferenceItem buttonItemWithAction:@selector(reloadMasterList:) target:self 
											 title:plugLocalizedString(@"Reload Master List")
											  info:nil],
			[T2PreferenceItem separateLineItem],
			
			[T2PreferenceItem topTitleItemWithTitle:plugLocalizedString(@"Be@2ch Settings") info:nil],
			[T2PreferenceItem stringItemWithKey:@"beMail"
										  title:plugLocalizedString(@"be mail")
										   info:nil],
			[T2PreferenceItem stringItemWithKey:@"beCode"
										  title:plugLocalizedString(@"be code")
										   info:nil],
			
			[T2PreferenceItem boolItemWithKey:@"embedBeIcon"
										title:plugLocalizedString(@"Display Be Icon")
										 info:plugLocalizedString(@"Replace sssp:// link with icon.")],
			
			
			[T2PreferenceItem separateLineItem],
			[T2PreferenceItem topTitleItemWithTitle:plugLocalizedString(@"be.2ch.net Settings") info:nil],
			
			[T2PreferenceItem labelItemWithKey:@"beStatusString"],
			
			[T2PreferenceItem buttonItemWithAction:@selector(loginBe:) target:self 
											 title:plugLocalizedString(@"Log-in Be")
											  info:nil],
			[T2PreferenceItem buttonItemWithAction:@selector(logoutBe:) target:self 
											 title:plugLocalizedString(@"Log-Out Be")
											  info:nil],
			[T2PreferenceItem boolItemWithKey:@"autoLoginBe"
										title:plugLocalizedString(@"Auto Log-in")
										 info:nil],
			[T2PreferenceItem separateLineItem],
			[T2PreferenceItem topTitleItemWithTitle:plugLocalizedString(@"About be.2ch.net") info:nil],
			
			[T2PreferenceItem buttonItemWithAction:@selector(aboutBe:) target:self 
											 title:plugLocalizedString(@"be.2ch.net")
											  info:nil],			
			// 2ch Viewer
			
			
			[T2PreferenceItem separateLineItem],
			[T2PreferenceItem topTitleItemWithTitle:plugLocalizedString(@"2ch Viewer Settings") info:nil],
			
			[T2PreferenceItem labelItemWithKey:@"statusString"],
			
			[T2PreferenceItem buttonItemWithAction:@selector(loginViewer:) target:self 
											 title:plugLocalizedString(@"Log-in Viewer")
											  info:nil],
			[T2PreferenceItem buttonItemWithAction:@selector(logoutViewer:) target:self 
											 title:plugLocalizedString(@"Log-Out Viewer")
											  info:nil],
			[T2PreferenceItem boolItemWithKey:@"autoLoginViewer"
										title:plugLocalizedString(@"Auto Log-in")
										 info:nil],
			
			[T2PreferenceItem separateLineItem],
			[T2PreferenceItem topTitleItemWithTitle:plugLocalizedString(@"Buy 2ch Viewer") info:nil],
			
			[T2PreferenceItem buttonItemWithAction:@selector(buyViewer:) target:self 
											 title:plugLocalizedString(@"Buy 2ch Viewer")
											  info:nil],
			
			
			[T2PreferenceItem separateLineItem],
			[T2PreferenceItem topTitleItemWithTitle:plugLocalizedString(@"p2.2ch.net Settings") info:nil],
			
			[T2PreferenceItem labelItemWithKey:@"P2StatusString"],
			
			[T2PreferenceItem stringItemWithKey:@"P2URLString"
										  title:plugLocalizedString(@"P2 Server URL")
										   info:nil],
			
			[T2PreferenceItem buttonItemWithAction:@selector(loginP2:) target:self 
											 title:plugLocalizedString(@"Log-in P2")
											  info:nil],
			[T2PreferenceItem buttonItemWithAction:@selector(logoutP2:) target:self 
											 title:plugLocalizedString(@"Log-Out P2")
											  info:nil],
			[T2PreferenceItem boolItemWithKey:@"autoLoginP2"
										title:plugLocalizedString(@"Auto Log-in")
										 info:nil],
			[T2PreferenceItem separateLineItem],
			[T2PreferenceItem topTitleItemWithTitle:plugLocalizedString(@"About p2.2ch.net") info:nil],
			
			[T2PreferenceItem buttonItemWithAction:@selector(aboutP2:) target:self 
											 title:plugLocalizedString(@"p2.2ch.net")
											  info:nil],
			/*
			[T2PreferenceItem buttonItemWithAction:@selector(logoutViewer:) target:self 
											 title:plugLocalizedString(@"Log-Out Viewer")
											  info:nil],
			 */
			nil];
}

#pragma mark -
#pragma mark Protocol T2ThreadImporting_v100

-(NSString *)importableRootPath { return __rootPath; }
-(T2Thread *)threadForThreadFace:(T2ThreadFace *)threadFace {
	T2Thread *thread = [T2Thread threadWithThreadFace:threadFace];
	
	NSString *internalPath = [threadFace internalPath];
	NSArray *pathComponents = [internalPath pathComponents];
	if (![[pathComponents objectAtIndex:0] isEqualToString:__rootPath]) return nil;
	NSString *boardKey = [pathComponents objectAtIndex:1];
	NSString *threadKey = [[pathComponents lastObject] stringByDeletingPathExtension];
	
	NSString *path = [_boardDictionary objectForKey:boardKey];
	if (!path) return nil;
	
	[thread setShouldSaveFile:YES];
	if ([_liveBoardKeys containsObject:[__rootPath stringByAppendingPathComponent:boardKey]])
		[thread setLoadingInterval:0.0];
	else
		[thread setLoadingInterval:5.0];
	
	//NSString *URLString = [NSString stringWithFormat:@"%@dat/%@.dat", path, threadKey];
	NSString *browserURLString = [NSString stringWithFormat:@"http://%@/test/read.cgi/%@/%@/", [path pathComponentAtIndex:1], boardKey, threadKey];
	[thread setWebBrowserURLString:browserURLString];
	
	//NSString *remoteLastModifiedDate = [thread valueForKey:@"remoteLastModifiedDate"];
	//NSNumber *datLengthNumber = [thread valueForKey:@"datLength"];
	//unsigned datLength = 0;
	
	NSData *localDatData = [NSData dataWithContentsOfGZipFile:[[NSString appLogFolderPath] stringByAppendingPathComponent:internalPath]];
	if (localDatData) {
		NSNumber *datLengthNumber = [NSNumber numberWithUnsignedInt:[localDatData length]];
		[thread setValue:datLengthNumber forKey:@"datLength"];
		
		NSString *srcString = [NSString stringUsingIconvWithData:localDatData encoding:NSShiftJISStringEncoding];
        //NSString *srcString = [[NSString alloc] initWithData:localDatData encoding:NSShiftJISStringEncoding];
		if (srcString) {
            NSLog(@"size = %ld", (unsigned long)[srcString length]);
			[self buildThread:thread withSrcString:srcString appending:NO];
			NSArray *resArray = [thread resArray];
			[thread setNewResIndex:[resArray count]];
		}
	}
	return thread;
}

-(NSString *)importableType { return __datType; }
-(NSURLRequest *)URLRequestForThread:(T2Thread *)thread {
	NSString *internalPath = [thread internalPath];
	NSArray *pathComponents = [internalPath pathComponents];
	if (![[pathComponents objectAtIndex:0] isEqualToString:__rootPath]) return nil;
	
	
	NSString *boardKey = [pathComponents objectAtIndex:1];
	NSString *threadKey = [[pathComponents lastObject] stringByDeletingPathExtension];
	
	NSString *path = [_boardDictionary objectForKey:boardKey];
	if (!path) return nil;
	
	T2ThreadFace *threadFace = [thread threadFace];
	
	if ([[thread valueForKey:@"2chViewer"] isEqualToString:@"datCheck"]) {
		// fallen dat check
		NSString *tempURLString = [NSString stringWithFormat:@"%@dat/%@.dat", path, threadKey];
		NSMutableURLRequest *mutableRequest = [[[NSURLRequest requestWith2chURL:[NSURL URLWithString:tempURLString]
																ifModifiedSince:nil
																		  range:0] mutableCopy] autorelease];
		[mutableRequest setHTTPMethod:@"HEAD"];
		return mutableRequest;
		
	} else if (([threadFace state] >= T2ThreadFaceStateFallen || [pathComponents count]>3) && _viewerSUA && _viewerSID) {
		if ([[thread valueForKey:@"2chViewer"] isEqualToString:@"end"]) {
			return nil;
		} else if ([[thread valueForKey:@"2chViewer"] isEqualToString:@"offlaw"] || [pathComponents count]>3) {
			// 2ch Viewer Available !
			
			if ([pathComponents count]>3 && [[pathComponents objectAtIndex:2] isEqualToString:__oldLogPath]) {
				// Old Logs on old servers
				[thread setValue:@"offlaw" forKey:@"2chViewer"];
				path = [pathComponents objectAtIndex:3];
			} else {
				// Current Servers
				path = [[path pathComponents] objectAtIndex:1];
			}
			
			NSString *URLString = [NSString stringWithFormat:@"http://%@/test/offlaw.cgi/%@/%@/?raw=0.0&sid=%@", path, boardKey, threadKey, [_viewerSID stringByAddingSJISPercentEscapesForce]];
			NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
			[request setValue:_viewerSUA forHTTPHeaderField:@"User-Agent"];
			[request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
			
			return request;
		}
	}  
	NSString *URLString = [NSString stringWithFormat:@"%@dat/%@.dat", path, threadKey];
	
	NSString *remoteLastModifiedDate = [thread valueForKey:@"remoteLastModifiedDate"];
	
	unsigned datLength;
	NSNumber *datLengthNumber = [thread valueForKey:@"datLength"];
	if (datLengthNumber && [datLengthNumber unsignedIntValue] > 0) {
		/*
		unsigned resCountNew = [threadFace resCountNew];
		if (resCountNew > 100 && ((float)[threadFace resCountGap]/(float)resCountNew > 0.5)) {
			[thread setValue:[NSNumber numberWithUnsignedInt:0] forKey:@"datLength"];
			datLength = 0;
		} else { */
			datLength = [datLengthNumber unsignedIntValue]-1;
		//}
	} else {
		datLength = 0;
	}
	
	[thread setNewResIndex:[[thread resArray] count]];
	return [NSURLRequest requestWith2chURL:[NSURL URLWithString:URLString]
						   ifModifiedSince:remoteLastModifiedDate
									 range:datLength];
}
-(T2LoadingResult)buildThread:(T2Thread *)thread withWebData:(T2WebData *)webData {
	T2ThreadFace *threadFace = [thread threadFace];
	NSString *internalPath = [thread internalPath];
	int code = [webData code];
	//NSLog(@"Thread:%@\nHTTP: %d\nHeaders: %@", internalPath, code, [webData headers]);
	
	// HTTP Error
	switch (code) {
		case 416: { // Invalid Range
			if ([threadFace state] == T2ThreadFaceStateFallen && [threadFace resCount] > 0)
				return T2LoadingFailed;
			[self resetThread:thread];
			[thread setProgressInfo:plugLocalizedString(@"DAT modified.")];
			return T2RetryLoading;
			break;
		}
		case 304: { // Not Modified
			if (_viewerSUA && _viewerSID) {
				if ([threadFace state] == T2ThreadFaceStateFallen
					&& (![[thread valueForKey:@"2chViewer"] isEqualToString:@"end"])) {
					[thread setValue:@"offlaw" forKey:@"2chViewer"];
					return T2RetryLoading;
				} else {
					[thread setValue:@"datCheck" forKey:@"2chViewer"];
					return T2RetryLoading;
				}
			}
			return T2LoadingSucceed;
			break;
		}
	
		case 302: { // Found (in 2ch, Fallen Threads)
			[threadFace setState:T2ThreadFaceStateFallenNoLog];
			if (_viewerSUA && _viewerSID) {
				if (![[thread valueForKey:@"2chViewer"] isEqualToString:@"offlaw"]) {
					// Retry using 2chViwer
					[thread setValue:@"offlaw" forKey:@"2chViewer"];
					return T2RetryLoading;
				} else {
					[thread setValue:@"error" forKey:@"2chViewer"];
				}
			}
			return T2LoadingFailed;
			break;
		}
		
		default:
			break;
	}
	
	
	if ([[thread valueForKey:@"2chViewer"] isEqualToString:@"datCheck"]) {
		[thread setValue:@"" forKey:@"2chViewer"];
		NSString *contentType = [webData headerForKey:@"Content-Type"];
		if ([contentType rangeOfString:@"text/html"].location != NSNotFound) {
			[thread setProgressInfo:plugLocalizedString(@"DAT fallen.")];
			return T2LoadingFailed;
		} else {
			[thread setProgressInfo:plugLocalizedString(@"Not modified")];
			return T2LoadingFailed;
		}
	}
	
	NSData *contentData = [webData contentData];
	if (!contentData) return T2LoadingFailed;
	//NSString *encodingName = [webData charsetName];
	
	NSString *srcString = [NSString stringUsingIconvWithData:contentData encoding:NSShiftJISStringEncoding];
	if (!srcString) return T2LoadingFailed;
	
	// 2ch Error
	NSString *contentType = [webData headerForKey:@"Content-Type"];
	if ([contentType rangeOfString:@"text/html"].location != NSNotFound) {
		
		[[thread threadFace] setState:T2ThreadFaceStateFallenNoLog];
		if (_viewerSUA && _viewerSID) {
			if (![[thread valueForKey:@"2chViewer"] isEqualToString:@"offlaw"]) {
				// Retry using 2chViwer
				[thread setValue:@"offlaw" forKey:@"2chViewer"];
				return T2RetryLoading;
			} else {
				[thread setValue:@"error" forKey:@"2chViewer"];
			} 
		} else if (_autoLoginViewer) {
			// auto login 2chViewer 
			[self registerViewerRequiredThreadForInternalPath:internalPath];
			[self performSelector:@selector(loginViewerOnWindow:)
					   withObject:nil
					   afterDelay:0.01];
			return T2LoadingFailed;
		}
		
		[self buildThread:thread withErrorHTMLString:srcString];
		return T2LoadingFailed;
		
	} else if ([srcString hasPrefix:@"-ERR"]) {
		NSLog(@"%@", srcString);
		if ([srcString rangeOfString:__missingBoardOrThread].location == NSNotFound
			&& [[thread valueForKey:@"2chViewer"] isEqualToString:@"offlaw"]) {
			// 2chViewer session expired
			[self registerViewerRequiredThreadForInternalPath:internalPath];
			
			[self performSelector:@selector(loginViewerOnWindow:)
					   withObject:nil
					   afterDelay:0.01];
			return T2LoadingFailed;
		} else {
			// Other Error
			[self buildThread:thread withErrorHTMLString:srcString];
			return T2LoadingFailed;
		}
	}
	
	NSString *savePath = [[NSString appLogFolderPath] stringByAppendingPathComponent:internalPath];
	NSData *saveData ;
	
	if ([[thread valueForKey:@"2chViewer"] isEqualToString:@"offlaw"]) {
		// fallen dat with 2chViewer
		[thread setProgressInfo:plugLocalizedString(@"DAT fallen.")];
		[thread setValue:@"end" forKey:@"2chViewer"];
		[self buildThread:thread withSrcString:srcString appending:NO];
		[[thread threadFace] setState:T2ThreadFaceStateFallen];
		NSArray *pathComponents = [internalPath pathComponents];
		if ([pathComponents count] >= 2) {
			if ([pathComponents count] >= 4) {
				// register old servers
				[self registerOldServerDomain:[pathComponents objectAtIndex:3] forBoardKey:[pathComponents objectAtIndex:1]];
			}
			
			T2ListFace *threadListFace = [T2ListFace listFaceWithInternalPath:[[pathComponents objectAtIndex:0] stringByAppendingPathComponent:[pathComponents objectAtIndex:1]]
																		title:nil image:nil];
			[[T2AddMissingThreadOperation addMissingThreadOperationWithThreadFace:[thread threadFace] threadListFace:threadListFace] start];
		}
		
		saveData = contentData;
	} else {
	//local dat available and status 206
		if (code == 206) {
			NSMutableData *localDatData = [NSMutableData dataWithContentsOfGZipFile:savePath];
			if (localDatData) {
				if (![localDatData isKindOfClass:[NSMutableData class]]) localDatData = [[localDatData mutableCopy] autorelease];
				
				[thread setValue:nil forKey:@"localDatData"];
				if (![[srcString substringToIndex:1] isEqualToString:@"\n"]) { // abone ?
					
					NSLog(@"Appending Failed:%@",[srcString substringToIndex:1]);
					
					[self resetThread:thread];
					return T2RetryLoading;
				}
				[self buildThread:thread withSrcString:srcString appending:YES];
				[localDatData setLength:([localDatData length]-1)];
				[localDatData appendData:contentData];
			
				saveData = localDatData;
			} else {
				NSLog(@"Missing local dat");
				
				[self resetThread:thread];
				return T2RetryLoading;
			}
		} else {
			[self buildThread:thread withSrcString:srcString appending:NO];
			saveData = contentData;
		}
	}
	
	NSTimeInterval timeInterval = [[internalPath lastPathComponent] intValue];
	[[thread threadFace] setCreatedDate:[NSDate dateWithTimeIntervalSince1970:timeInterval]];
	
	NSString *remoteLastModifiedDate = [webData headerForKey:@"Last-Modified"];
	if (remoteLastModifiedDate) [thread setValue:remoteLastModifiedDate forKey:@"remoteLastModifiedDate"];
	
	[thread setValue:[NSNumber numberWithUnsignedInt:[saveData length]] forKey:@"datLength"];
	//saving dat
	if ([[internalPath firstPathComponent] isEqualToString:__rootPath]) {
		[savePath prepareFoldersInPath];
		[saveData writeToGZipFile:savePath];
	}
	
	return T2LoadingSucceed;
}

-(NSArray *)importableTypes { return [NSArray arrayWithObject:@"dat"]; }

-(NSString *)threadLogFilePathForInternalPath:(NSString *)internalPath {
	NSString *logFilePath = [[NSString appLogFolderPath] stringByAppendingPathComponent:internalPath];
	if ([logFilePath isExistentPath]) return logFilePath;
	
	logFilePath = [logFilePath stringByAppendingPathExtension:@"gz"];
	if ([logFilePath isExistentPath]) return logFilePath;
	else return nil;
}
-(NSString *)threadInternalPathForProposedURLString:(NSString *)URLString {
	if ([[URLString pathExtension] isEqualToString:@"dat"]) return URLString;
	
	unsigned quoteLocation = [URLString rangeOfString:@"?" options:NSLiteralSearch].location;
	if (quoteLocation != NSNotFound) {
		URLString = [URLString substringToIndex:quoteLocation];
	}
	
	NSScanner *urlScanner = [NSScanner scannerWithString:URLString];
	BOOL isThreadURL = YES;
	NSString *threadURLKey = @"/test/read.cgi/";
	NSString *threadURLKey2 = @"/test/read.html/";
	NSString *serverName = nil;
	NSString *boardName = nil;
	NSString *threadID = nil;
	isThreadURL = [urlScanner scanUpToString:threadURLKey intoString:&serverName] && [urlScanner scanString:threadURLKey intoString:NULL]; //&serverName
	if (!isThreadURL || !serverName) {
		[urlScanner setScanLocation:0];
		isThreadURL = [urlScanner scanUpToString:threadURLKey2 intoString:&serverName] && [urlScanner scanString:threadURLKey2 intoString:NULL];
		if (!isThreadURL || !serverName) return nil;
	}
	
	[urlScanner scanString:threadURLKey intoString:NULL];
	isThreadURL = isThreadURL && [urlScanner scanUpToString:@"/" intoString:&boardName];
	[urlScanner scanString:@"/" intoString:NULL];
	
	NSString *boardURLString = [_boardDictionary objectForKey:boardName];
	if (!boardURLString) return nil;
	if ([serverName rangeOfString:@".2ch."].location == NSNotFound
		&& [serverName rangeOfString:@".bbspink."].location == NSNotFound) return nil;
	
	isThreadURL = isThreadURL && [urlScanner scanUpToString:@"/" intoString:&threadID];
	isThreadURL = isThreadURL && ([threadID intValue] > 0);
	if (isThreadURL) {
		if ([boardURLString rangeOfString:[serverName lastPathComponent]].location == NSNotFound) {
			// Old Servers
			return [NSString stringWithFormat:@"%@/%@/%@/%@/%@.dat", __rootPath, boardName, __oldLogPath, [serverName lastPathComponent], threadID];
		} else {
			// Current Servers
			return [NSString stringWithFormat:@"%@/%@/%@.dat", __rootPath, boardName, threadID];
		}
	}
	return nil;
}
-(NSString *)resExtractPatnForProposedURLString:(NSString *)URLString {
	unsigned quoteLocation = [URLString rangeOfString:@"?" options:NSLiteralSearch].location;
	if (quoteLocation != NSNotFound) {
		URLString = [URLString substringToIndex:quoteLocation];
	}
	
	NSScanner *urlScanner = [NSScanner scannerWithString:URLString];
	BOOL isThreadURL = YES;
	NSString *threadURLKey = @"/test/read.cgi/";
	NSString *threadURLKey2 = @"/test/read.html/";
	//NSString *serverName = nil;
	NSString *boardName = nil;
	NSString *threadID = nil;
	isThreadURL = [urlScanner scanUpToString:threadURLKey intoString:NULL] && [urlScanner scanString:threadURLKey intoString:NULL]; //&serverName
	if (!isThreadURL) {
		[urlScanner setScanLocation:0];
		isThreadURL = [urlScanner scanUpToString:threadURLKey2 intoString:NULL] && [urlScanner scanString:threadURLKey2 intoString:NULL];
		if (!isThreadURL) return nil;
	}
	
	NSString *pathInfo = [URLString substringFromIndex:[urlScanner scanLocation]];
	NSArray *pathIndoComponents = [pathInfo pathComponents];
	if ([pathIndoComponents count] < 3) return nil;
	
	NSString *resInfo = [pathIndoComponents objectAtIndex:2];
	if ([resInfo hasPrefix:@"l"]) return nil;
	NSIndexSet *resIndexes = [NSIndexSet indexSetWithString:resInfo];
	if (resIndexes) {
		return [NSString stringWithFormat:@"resNumber/%@", resInfo];
	}
	return nil;
	
}

#pragma mark -
-(void)buildThread:(T2Thread *)thread withErrorHTMLString:(NSString *)srcString {
	[thread setShouldSaveFile:NO];
	
	NSRange titleStartRange = [srcString rangeOfString:@"<title>"];
	NSRange titleEndRange = [srcString rangeOfString:@"</title>"];
	if (titleStartRange.location == NSNotFound || titleEndRange.location == NSNotFound) {
		return;
	}
	NSString *title = [srcString substringWithRange:NSMakeRange(titleStartRange.location+titleStartRange.length
																, titleEndRange.location-(titleStartRange.location+titleStartRange.length))];
	NSString *error = [srcString stringFromHTML]; //plugLocalizedString(@"Thread Loading Failed");
	T2Res *res = [T2Res resWithResNumber:1
									name:title
									mail:nil
									date:nil
							  identifier:nil
								 content:error
								  thread:thread];
	[thread setResArray:[NSArray arrayWithObject:res]];
	// [thread setTitle:title];
}

-(void)buildThread:(T2Thread *)thread withSrcString:(NSString *)srcString appending:(BOOL)appending {
	NSScanner *srcScanner = [NSScanner scannerWithString:srcString];
	[srcScanner setCharactersToBeSkipped:[NSCharacterSet controlCharacterSet]];
	__block NSMutableArray *resArray = [NSMutableArray array];
	//NSString *resString;
	__block NSString *threadTitle = nil;
	//T2Res *tempRes;
	NSAutoreleasePool *myPool;
	__block NSInteger i=0;
	
	NSArray *oldResArray = [thread resArray];
	if (appending && oldResArray && [oldResArray count]>0) {
		[resArray addObjectsFromArray:oldResArray];
		i = [oldResArray count];
	}

    [srcString enumerateLinesUsingBlock:^(NSString *resString, BOOL *stop) {
	//while ([srcScanner scanUpToString:@"\n" intoString:&resString]) {
		//myPool = [[NSAutoreleasePool alloc] init];
        T2Res *tempRes;

		if ([resString length]>1) {
			NSArray *partStringArray = [resString componentsSeparatedByString:@"<>"];
			NSInteger partStringCount = [partStringArray count];
			
			if (partStringCount > 3) {
				if (partStringCount > 4 && i==0) {
					threadTitle = [[partStringArray objectAtIndex:4] retain];
				}
				tempRes = resWith_ResNum_Name_Mail_DateAndOther_content_thread(i+1,
																			   [partStringArray objectAtIndex:0],
																			   [partStringArray objectAtIndex:1],
																			   [partStringArray objectAtIndex:2],
																			   [partStringArray objectAtIndex:3],
																			   thread);
				if (tempRes) [resArray addObject:tempRes];
				i++;
			}
		}
		
		//[myPool release];
	}];
	[thread setResArray:resArray];
	if (threadTitle) [thread setTitle:[threadTitle stringByReplacingCharacterReferences]];
	[threadTitle release];
}
T2Res* resWith_ResNum_Name_Mail_DateAndOther_content_thread(int resNumber, NSString *namePart, NSString *mailPart,
															NSString *dateAndOtherPart, NSString *contentPart, T2Thread *thread) {
	
	NSString *trip = nil, *identifier = nil, *dateString = nil, *beString = nil;
	NSCalendarDate *date = nil;
	//scan trip
	if (__tripPrefix) {
		NSRange tripRange = [namePart rangeOfString:__tripPrefix];
		if (tripRange.location+11 <= [namePart length]) 
			trip = [namePart substringWithRange:(NSRange){tripRange.location+1, 10}];
	}
	
	//replace </b><b>
	NSMutableString *mutableNamePart = [[namePart mutableCopy] autorelease];
	[mutableNamePart replaceOccurrencesOfString:@"</b>"
									 withString:@"<em>"
										options:NSLiteralSearch
										  range:NSMakeRange(0,[mutableNamePart length])];
	[mutableNamePart replaceOccurrencesOfString:@"<b>"
									 withString:@"</em>"
										options:NSLiteralSearch
										  range:NSMakeRange(0,[mutableNamePart length])];
	namePart = [[mutableNamePart copy] autorelease];
	
	//scan date
	NSString *datePrefix;
	int dateDigits[6]; // year/month/day 
	unsigned j;
	NSScanner *resDateScanner = [NSScanner scannerWithString:dateAndOtherPart];
	dateDigits[2] = -1;
	for (j=0; j<6; j++) {
		dateDigits[j] = -1;
		if (j == 0) {
			datePrefix = nil;
			[resDateScanner scanUpToCharactersFromSet:__digitCharacterSet intoString:&datePrefix];
			if (datePrefix) {
				[resDateScanner scanUpToString:@"," intoString:NULL];
				if ([resDateScanner isAtEnd]) {
					dateDigits[0] = 2005; //CAUTION!! 2005 April Fool
					[resDateScanner setScanLocation:0];
					[resDateScanner scanUpToString:@"/" intoString:NULL];
				} else {
					[resDateScanner scanString:@"," intoString:NULL];
					[resDateScanner scanInt:&(dateDigits[j])];
				}
			} else {
				[resDateScanner scanInt:&(dateDigits[j])];
				if (dateDigits[j]<0) {
					dateDigits[0] = 2005; //CAUTION!! 2005 April Fool
					[resDateScanner setScanLocation:0];
					[resDateScanner scanUpToString:@"/" intoString:NULL];
				}
			}
		}
		else {
			[resDateScanner scanUpToCharactersFromSet:__digitCharacterSet intoString:NULL];
			[resDateScanner scanInt:&(dateDigits[j])];
		}
		if ([resDateScanner isAtEnd]) break;
	}
	if (dateDigits[0] < 100) {
		if (dateDigits[0] < 50) dateDigits[0] += 2000;
		else dateDigits[0] += 1900;
	}
	if (dateDigits[2] <= 0)
		date = nil;
	else {
		if (dateDigits[5] <= 0)
			dateDigits[5] = 0;
		date = [[NSCalendarDate dateWithYear:dateDigits[0]
									   month:dateDigits[1] day:dateDigits[2]
										hour:dateDigits[3] minute:dateDigits[4] second:dateDigits[5]
									timeZone:[NSTimeZone localTimeZone]] retain];
	}
	
	// scan ID
	NSString **hasID = &dateString;
	[resDateScanner setScanLocation:0];
	[resDateScanner scanUpToString:@"ID:" intoString:&dateString];
	if ([resDateScanner scanString:@"ID:" intoString:NULL]) {
		hasID = NULL;
		[resDateScanner scanUpToCharactersFromSet:__whitespaceAndNewlineCharacterSet
									   intoString:&identifier];
		if ([identifier length]<=4) identifier = nil;
	}
	// scan BE
	[resDateScanner setScanLocation:0];
	[resDateScanner scanUpToString:@"BE:" intoString:hasID];
	if ([resDateScanner scanString:@"BE:" intoString:NULL]) {
		[resDateScanner scanUpToString:@"<>" intoString:&beString];
	}
	
	// cut <a> tag in contentPart
	NSMutableString *contentPartResult = [NSMutableString string];
	NSScanner *contentPartScanner = [NSScanner scannerWithString:contentPart];
	[contentPartScanner setCharactersToBeSkipped:__controlCharacterSet];
	NSString *appendingPart = nil;
	BOOL ssspFound = NO;
	
	while (![contentPartScanner isAtEnd]) {
		if (__embedBeIcon && !ssspFound) {
			// replace "sssp://img.2ch.net/ico/XXX"
			[contentPartScanner scanUpToString:@"sssp://img.2ch.net/ico/" intoString:&appendingPart];
			if ([contentPartScanner scanString:@"sssp://img.2ch.net/ico/" intoString:NULL]) {
				NSString *beIconFileName = nil;
				[contentPartScanner scanUpToCharactersFromSet:__whitespaceAndNewlineCharacterSet
												   intoString:&beIconFileName];
				if (beIconFileName) {
					
					if (appendingPart) [contentPartResult appendString:appendingPart];
					[contentPartResult appendFormat:@"<img src=\"http://img.2ch.net/ico/%@\">", beIconFileName];
					ssspFound = YES;
				}
			}
			if (!ssspFound) {
				[contentPartScanner setScanLocation:0];
				ssspFound = YES;
			}
		}
		if (![contentPartScanner scanString:@"<a href=" intoString:NULL]) {
			[contentPartScanner scanUpToString:@"<a href=" intoString:&appendingPart];
		}
		[contentPartScanner scanUpToString:@">" intoString:NULL];
		[contentPartScanner scanString:@">" intoString:NULL];
		if (appendingPart) [contentPartResult appendString:appendingPart];
	}
	
	[contentPartResult replaceOccurrencesOfString:@"</a>"
									   withString:@""
										  options:NSLiteralSearch
											range:NSMakeRange(0,[contentPartResult length])];
	
	
	// result
	T2Res *tempRes = [T2Res resWithResNumber:resNumber name:namePart mail:mailPart
										date:date identifier:identifier content:contentPartResult
									  thread:thread];
	[tempRes setDateString:dateString];
	if (trip) [tempRes setTrip:trip];
	if (beString) [tempRes setBeString:beString];
	[date release];
	return tempRes;
}

-(void)removeLogFileAtPath:(NSString *)path {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *gzipPath = [path stringByAppendingPathExtension:@"gz"];
	if ([fileManager fileExistsAtPath:gzipPath])
		[fileManager removeItemAtPath:gzipPath error:nil];
	if ([fileManager fileExistsAtPath:path])
		[fileManager removeItemAtPath:path error:nil];
}
-(void)resetThread:(T2Thread *)thread {
	NSString *internalPath = [thread internalPath];
	NSString *path = [[NSString appLogFolderPath] stringByAppendingPathComponent:internalPath];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *gzipPath = [path stringByAppendingPathExtension:@"gz"];
	if ([fileManager fileExistsAtPath:gzipPath])
		[fileManager removeItemAtPath:gzipPath error:nil];
	if ([fileManager fileExistsAtPath:path])
		[fileManager removeItemAtPath:path error:nil];
	
	[thread setValue:nil forKey:@"datLength"];
	[thread setValue:nil forKey:@"remoteLastModifiedDate"];
}
-(void)registerViewerRequiredThreadForInternalPath:(NSString *)internalPath {
	[_threadInternalPathToLoadAfterRelogin release];
	_threadInternalPathToLoadAfterRelogin = [internalPath retain];
}

#pragma mark -
#pragma mark Protocol T2ListImporting_v100

//-(NSString *)importableRootPath { return __rootPath; }
-(T2List *)listForListFace:(T2ListFace *)listFace {
	NSString *internalPath = [listFace internalPath];
	NSArray *pathComponents = [internalPath pathComponents];
	unsigned pathComponentsCount = [pathComponents count];
	if (![(NSString *)[[internalPath pathComponents] objectAtIndex:0] isEqualToString:__rootPath]) return nil;
	
	switch (pathComponentsCount) {
		case 1: { // root list
			if (!_bbsmenuURLString) {
				[self setBBSMenuURLString:__bbsmenuURLString];
			}
			T2List *list = [T2List listWithListFace:listFace];
			[list setTitle:plugLocalizedString(__rootPath)];
			[list setLoadingInterval:3600];
			return list;
		}
		case 2: { // category or board
			NSString *key = [pathComponents objectAtIndex:1];
			if ([key hasPrefix:__categoryPrefix]) { // category
				T2List *list = [T2List listWithListFace:listFace];
				if ([key hasSuffix:__oldLogPath]) {
					T2List *allBoardList = [T2List availableObjectWithInternalPath:[__rootPath stringByAppendingPathComponent:[__categoryPrefix stringByAppendingString:@"All_Boards"]]];
					if (allBoardList) {
						NSMutableArray *oldListFaces = [NSMutableArray array];
						NSEnumerator *boardEnumerator = [[allBoardList objects] objectEnumerator];
						T2ListFace *boardListFace;
						while (boardListFace = [boardEnumerator nextObject]) {
							if (![[boardListFace title] hasSuffix:@"headline"]) {
								T2ListFace *oldListFace = 
								[T2ListFace listFaceWithInternalPath:[[boardListFace internalPath] stringByAppendingPathComponent:__oldLogPath]
															   title:[[boardListFace title] stringByAppendingString:plugLocalizedString(@" (Old)")]
															   image:__categoryImage];
								if (oldListFace)
									[oldListFaces addObject:oldListFace];
							}
						}
						[list setObjects:oldListFaces];
					}
				}
				return list;
			} else { // board
				T2ThreadList *threadList = [T2ThreadList listWithListFace:listFace];
				NSString *path = [_boardDictionary objectForKey:key];
				if (path) {
					[threadList setWebBrowserURLString:path];
					if ([_liveBoardKeys containsObject:key])
						[threadList setLoadingInterval:1.0];
					else
						[threadList setLoadingInterval:10.0];
					[threadList setShouldSaveFile:YES];
					return threadList;
				}
			}
		}
		case 3: { // old logs
			T2List *list = [T2List listWithListFace:listFace];
			[list setLoadingInterval:3600];
			[list setShouldSaveFile:YES];
			return list;
		}
		case 4: {
			if ([[pathComponents objectAtIndex:3] rangeOfString:@".2ch."].location == NSNotFound) {
				T2ThreadList *threadList = [T2ThreadList listWithListFace:listFace];
				[threadList setLoadingInterval:3600];
				[threadList setShouldSaveFile:YES];
				return threadList;
			} else {
				T2List *list = [T2List listWithListFace:listFace];
				[list setLoadingInterval:3600];
				[list setShouldSaveFile:YES];
				return list;
			}
		}
		case 5: {
			T2ThreadList *threadList = [T2ThreadList listWithListFace:listFace];
			[threadList setLoadingInterval:3600];
			[threadList setShouldSaveFile:YES];
			return threadList;
		}
	}
	return nil;
}

-(NSURLRequest *)URLRequestForList:(T2List *)list {
	NSString *internalPath = [list internalPath];
	NSArray *pathComponents = [internalPath pathComponents];
	unsigned pathComponentsCount = [pathComponents count];
	
	if (![(NSString *)[[internalPath pathComponents] objectAtIndex:0] isEqualToString:__rootPath]) return nil;
	
	switch (pathComponentsCount) {
		case 1: {// main list
			return [NSURLRequest requestWith2chURL:[NSURL URLWithString:_bbsmenuURLString]
								   ifModifiedSince:_bbsmenuDateString
											 range:0];
			
		}
		case 2: { // category or board
			NSString *key = [pathComponents objectAtIndex:1];
			if (![key hasPrefix:__categoryPrefix]) { // thread list
				NSString *path = [_boardDictionary objectForKey:key];
				NSString *remoteLastModifiedDate = [list valueForKey:@"remoteLastModifiedDate"];
				if (path) {
					return [NSURLRequest requestWith2chURL:[NSURL URLWithString:[path stringByAppendingString:@"subject.txt"]]
										   ifModifiedSince:remoteLastModifiedDate
													 range:0];
				}
			}
		}
		case 3: { // old logs date list
			NSString *key = [pathComponents objectAtIndex:1];
			NSString *path = [_boardDictionary objectForKey:key];
			if (!path) return nil;
			path = [path stringByAppendingString:@"kako/subject.txt"];
			NSString *remoteLastModifiedDate = [list valueForKey:@"remoteLastModifiedDate"];
			return [NSURLRequest requestWith2chURL:[NSURL URLWithString:path]
								   ifModifiedSince:remoteLastModifiedDate
											 range:0];
		}
		case 4: {
			if ([[pathComponents objectAtIndex:3] rangeOfString:@".2ch."].location == NSNotFound) {
				// old logs on current server thread list
				NSString *key = [pathComponents objectAtIndex:1];
				NSString *path = [_boardDictionary objectForKey:key];
				if (!path) return nil;
				path = [path stringByAppendingFormat:@"kako/%@/subject.txt", [pathComponents objectAtIndex:3]];
				NSString *remoteLastModifiedDate = [list valueForKey:@"remoteLastModifiedDate"];
				return [NSURLRequest requestWith2chURL:[NSURL URLWithString:path]
									   ifModifiedSince:remoteLastModifiedDate
												 range:0];
			} else {
				// old logs on old servers date list
				NSString *path = [NSString stringWithFormat:@"http://%@/%@/kako/subject.txt", [pathComponents objectAtIndex:3], [pathComponents objectAtIndex:1]];
				NSString *remoteLastModifiedDate = [list valueForKey:@"remoteLastModifiedDate"];
				return [NSURLRequest requestWith2chURL:[NSURL URLWithString:path]
									   ifModifiedSince:remoteLastModifiedDate
												 range:0];
			}
		}
		case 5: {
			// old logs on current server thread list
			//NSString *key = [pathComponents objectAtIndex:1];
			
			NSString *path = [NSString stringWithFormat:@"http://%@/%@/kako/%@/subject.txt", [pathComponents objectAtIndex:3], [pathComponents objectAtIndex:1], [pathComponents objectAtIndex:4]];
			NSString *remoteLastModifiedDate = [list valueForKey:@"remoteLastModifiedDate"];
			return [NSURLRequest requestWith2chURL:[NSURL URLWithString:path]
								   ifModifiedSince:remoteLastModifiedDate
											 range:0];
		}
	}
	return nil;	
}
-(T2LoadingResult)buildList:(T2List *)list withWebData:(T2WebData *)webData {
	if (!webData || ![webData contentData]) return T2LoadingFailed;
	
	NSString *internalPath = [list internalPath];
	NSArray *pathComponents = [internalPath pathComponents];
	unsigned pathComponentsCount = [pathComponents count];
	
	switch (pathComponentsCount) {
		case 1: { // root list
			[self loadMasterListWithWebData:webData];
			return T2LoadingSucceed;
		}
		case 2: { // board
			if ([[webData contentData] length] == 0) {
				[self registerMovedServerForInternalPath:[list internalPath]];
				return T2LoadingFailed;
			}
			
			NSString *key = [pathComponents objectAtIndex:1];
			if (!key) return T2LoadingFailed;
			if ([self buildThreadList:(T2ThreadList *)list WithWebData:webData boardKey:key]) {
				return T2LoadingSucceed;
			}
			return T2LoadingFailed;
		}
		case 3: { //old logs date list
			[self buildOldDateList:list WithWebData:webData];
			// append old servers
			NSArray *oldServers = [self oldServerDomainsForBoardKey:[pathComponents objectAtIndex:1]];
			if (oldServers) {
				NSMutableArray *objects = [[[list objects] mutableCopy] autorelease];
				NSEnumerator *oldServerEnumerator = [oldServers objectEnumerator];
				NSString *oldServer = nil;
				while (oldServer = [oldServerEnumerator nextObject]) {
					T2ListFace *listFace = [T2ListFace listFaceWithInternalPath:[internalPath stringByAppendingPathComponent:oldServer]
																		  title:oldServer image:__categoryImage];
					if (listFace) [objects addObject:listFace];
				}
				[list setObjects:objects];
			}
			return T2LoadingSucceed;
		}
		case 4: { // old logs Thread list
			if ([[pathComponents objectAtIndex:3] rangeOfString:@".2ch."].location == NSNotFound) {
				// old logs on current server
				NSString *key = [[internalPath pathComponents] objectAtIndex:1];
				if (!key) return T2LoadingFailed;
				[self buildOldThreadList:(T2ThreadList *)list WithWebData:webData boardKey:key];
				return T2LoadingSucceed;
			} else {
				//old logs on old servers date list
				[self buildOldDateList:list WithWebData:webData];
				return T2LoadingSucceed;
			}
		}
		case 5: { // old logs on old server Thread list
			NSString *key = [[internalPath pathComponents] objectAtIndex:1];
			if (!key) return T2LoadingFailed;
			[self buildOldThreadList:(T2ThreadList *)list WithWebData:webData boardKey:key];
			return T2LoadingSucceed;
		}
	}
	return T2LoadingFailed;
}
-(NSArray *)rootListFaces {
	return [NSArray arrayWithObject:_rootListFace];
}
-(NSString *)listInternalPathForProposedURLString:(NSString *)URLString {
	NSArray *components = [URLString pathComponents];
	if ([components count] < 3) return nil;
	
	//NSScanner *urlScanner = [NSScanner scannerWithString:URLString];
	
	NSString *serverName = [components objectAtIndex:1];
	NSString *boardName = [components objectAtIndex:2];
	
	NSString *boardURLString = [_boardDictionary objectForKey:boardName];
	if (!boardURLString) return nil;
	if ([serverName rangeOfString:@".2ch."].location == NSNotFound
		&& [serverName rangeOfString:@".bbspink."].location == NSNotFound) return nil;
	
	
	if ([boardURLString rangeOfString:[serverName lastPathComponent]].location == NSNotFound) {
		// Old Servers
		return [NSString stringWithFormat:@"%@/%@/%@", __rootPath, boardName, __oldLogPath];
	} else {
		// Current Servers
		return [NSString stringWithFormat:@"%@/%@", __rootPath, boardName];
	}
	return nil;
}
-(NSImage *)imageForListFace:(T2ListFace *)listFace {
	NSString *internalPath = [listFace internalPath];
	NSArray *pathComponents = [internalPath pathComponents];
	if (![(NSString *)[[internalPath pathComponents] objectAtIndex:0] isEqualToString:__rootPath]) 
		return nil;
	
	if ([pathComponents count] == 1) { // main list
		return __rootListImage;
		
	} else { // category or board
		NSString *key = [pathComponents objectAtIndex:1];
		if ([key hasPrefix:__categoryPrefix]) { // category
			return __categoryImage;
			
		} else { // thread list		
			return __boardImage;
		}
	}
	return nil;
}


#pragma mark -
#pragma mark Internal Methods
-(void)loadMasterListWithWebData:(T2WebData *)webData {
	NSData *srcData = [webData contentData];
	NSString *srcString;
	NSString *localMenuFilePath = [[[NSString appLogFolderPath] stringByAppendingPathComponent:__rootPath] stringByAppendingPathComponent:@"bbsmenu.html"];
	if (srcData) {
		[localMenuFilePath prepareFoldersInPath];
		[srcData writeToGZipFile:localMenuFilePath];
		srcString = [webData decodedString];
	} else {
		srcData = [NSData dataWithContentsOfGZipFile:localMenuFilePath];
		srcString = [NSString stringUsingIconvWithData:srcData encoding:NSShiftJISStringEncoding];
	}
	if (!srcString) return;
	
	NSMutableArray *lists = [NSMutableArray array];
	NSMutableArray *allBoardFaces = [NSMutableArray array];
	NSMutableArray *allCategoryFaces = [NSMutableArray array];
	NSMutableSet *liveBoardKeys = [NSMutableSet set];
	
	NSMutableDictionary *boardDictionary = [NSMutableDictionary dictionary];
	
	// make categorys
	
	NSArray *categoryStringArray = [srcString componentsSeparatedByString:@"<B>"]; //split text by <B> tag
	NSEnumerator *categoryStringEnumerator = [categoryStringArray objectEnumerator];
	NSString *categoryString;
	
	NSAutoreleasePool *myPool;
	while (categoryString = [categoryStringEnumerator nextObject]) {
		myPool = [[NSAutoreleasePool alloc] init];
		
		unsigned categoryNameLocation = [categoryString rangeOfString:@"</B>"].location;
		if (categoryNameLocation != NSNotFound && categoryNameLocation < 32) {
			NSString *categoryName = [categoryString substringToIndex:categoryNameLocation];
			NSString *categoryNameWithPrefix = [__categoryPrefix stringByAppendingString:categoryName];
			if (categoryName && ![self isMasterListNG:categoryNameWithPrefix]) {
				
				NSArray *boardFaces;
				if ([categoryName rangeOfString:__liveCategoryString options:NSLiteralSearch].location != NSNotFound) {
					boardFaces = [self boardFacesInCategoryString:categoryString
												  boardDictionary:boardDictionary
													liveBoardKeys:liveBoardKeys];
				} else {
					boardFaces = [self boardFacesInCategoryString:categoryString
												  boardDictionary:boardDictionary
													liveBoardKeys:nil];
				}
				
				if (boardFaces) {
					T2ListFace *categoryFace = [T2ListFace listFaceWithInternalPath:[__rootPath stringByAppendingPathComponent:categoryNameWithPrefix]
																			  title:categoryName
																			  image:__categoryImage];
					T2List *category = [T2List listWithListFace:categoryFace
														objects:boardFaces];
					
					[allCategoryFaces addObject:categoryFace];
					[lists addObject:category];
					[allBoardFaces addObjectsFromArray:boardFaces];
				}
			}
		}
		
		[myPool release];
	}
	
	// Additional Boards
	NSDictionary *tempDic = [NSDictionary dictionaryWithContentsOfFile:[_selfBundle pathForResource:@"Thousand2chSettings" ofType:@"plist"]];
	
	NSArray *additionalBoards = [tempDic objectForKey:@"MasterListAdditions"];
	NSEnumerator *additionalBoardEnumerator = [additionalBoards objectEnumerator];
	NSDictionary *additionalBoardDic = nil;
	while (additionalBoardDic = [additionalBoardEnumerator nextObject]) {
		NSString *title = [additionalBoardDic objectForKey:@"title"];
		NSString *URLString = [additionalBoardDic objectForKey:@"URLString"];
		NSArray *pathComponents = [URLString pathComponents];
		if ([pathComponents count] >=3) {
			NSString *boardKey = [pathComponents objectAtIndex:2];
			if (boardKey) {
				T2ListFace *boardFace = [T2ListFace listFaceWithInternalPath:[__rootPath stringByAppendingPathComponent:boardKey]
														   title:title
														   image:__boardImage];
				[boardFace setLeaf:YES];
				[allBoardFaces addObject:boardFace];
				
				[boardDictionary setObject:URLString forKey:boardKey];
			}
		}
	}
	
	// make "All Boards" category
	T2ListFace *allBoardListFace = [T2ListFace listFaceWithInternalPath:
									[__rootPath stringByAppendingPathComponent:[__categoryPrefix stringByAppendingString:@"All_Boards"]]
																  title:plugLocalizedString(@"All_Boards")
																  image:__categoryImage];
	T2List *allBoardList = [T2List listWithListFace:allBoardListFace
											objects:allBoardFaces];
	
	// make "Old" category
	T2ListFace *oldBoardListFace = [T2ListFace listFaceWithInternalPath:
									[__rootPath stringByAppendingPathComponent:[__categoryPrefix stringByAppendingString:__oldLogPath]]
																  title:plugLocalizedString(@"Old Logs")
																  image:__categoryImage];
	
	[allCategoryFaces insertObject:allBoardListFace atIndex:0];
	[allCategoryFaces insertObject:oldBoardListFace atIndex:1];
	[lists addObject:allBoardList];
	
	
	// make root list
	T2ListFace *rootListFace = [T2ListFace listFaceWithInternalPath:__rootPath
															  title:plugLocalizedString(__rootPath)
															  image:__rootListImage];
	T2List *rootList = [T2List listWithListFace:rootListFace
										objects:allCategoryFaces];
	[rootList setLoadingInterval:3600];
	[lists addObject:rootList];
	
	
	setObjectWithRetain(_lists, lists);
	setObjectWithRetain(_liveBoardKeys, liveBoardKeys);
	setObjectWithRetain(_boardDictionary, boardDictionary);
	setObjectWithRetain(_rootListFace, rootListFace);
}
-(NSArray *)boardFacesInCategoryString:(NSString *)src
					   boardDictionary:(NSMutableDictionary *)boardDictionary
						 liveBoardKeys:(NSMutableSet *)liveBoardKeys {
	
	NSMutableArray *resultArray = [NSMutableArray array];
	NSScanner *boardScanner = [NSScanner scannerWithString:src];
	NSString *tempBoardName = nil;
	NSString *tempBoardURL = nil;
	NSString *boardKey;
	T2ListFace *boardFace;
	
	while (![boardScanner isAtEnd]) {
		if ([boardScanner scanUpToString:@"<A HREF=" intoString:NULL]
			&& [boardScanner scanString:@"<A HREF=" intoString:NULL]
			&& [boardScanner scanUpToString:@">" intoString:&tempBoardURL]
			&& [boardScanner scanString:@">" intoString:NULL]
			&& [boardScanner scanUpToString:@"</A>" intoString:&tempBoardName])
		{
			if (![self isMasterListNG:[NSString stringWithFormat:@"URL:%@",tempBoardURL]]) {
				NSArray *pathComponents = [tempBoardURL pathComponents];
				if ([pathComponents count] >=3) {
					boardKey = [pathComponents objectAtIndex:2];
					if (boardKey) {
						boardFace = [T2ListFace listFaceWithInternalPath:[__rootPath stringByAppendingPathComponent:boardKey]
																   title:tempBoardName
																   image:__boardImage];
						[boardFace setLeaf:YES];
						[resultArray addObject:boardFace];
						//[boardNameDictionary setObject:tempBoardName forKey:boardKey];
						[boardDictionary setObject:tempBoardURL forKey:boardKey];
						if (liveBoardKeys)
							[liveBoardKeys addObject:boardKey];
					}
				}
				
			}
		}
	}
	return resultArray;
}
-(BOOL)isMasterListNG:(NSString *)aString {
	if (!_masterListNG) return NO;
	if ([_masterListNG objectForKey:aString]) {
		return YES;
	}
	else {
		return NO;
	}
}

#pragma mark -

-(void)buildOldDateList:(T2List *)list WithWebData:(T2WebData *)webData {
	
	// read boardName/kako/subject.txt
	NSAutoreleasePool *myPool;
	NSString *srcString = [webData decodedString];
	NSScanner *srcScanner = [NSScanner scannerWithString:srcString];
	
	NSMutableArray *newDateList = [NSMutableArray array];

	
	while (![srcScanner isAtEnd]) {
		myPool = [[NSAutoreleasePool alloc] init];
		
		NSString *tempDateName = nil;
		NSString *dateName = nil;
		NSString *tempDateFolderName = nil;
		NSString *dateKey;
		unsigned threadCountDelimiterLocation;
		NSString *tempThreadCountString = nil;
		int tempThreadCount = 0;
		
		NSString *calendarFormat = plugLocalizedString(@"%Y/%m/%d %H:%M-");
		NSString *threadCountFormat = plugLocalizedString(@" (%d Threads)");
		
		if ([srcScanner scanUpToString:@"<>" intoString:&tempDateFolderName]
			&& [srcScanner scanString:@"<>" intoString:NULL]
			&& [srcScanner scanUpToString:@"\n" intoString:&tempDateName])
		{
			threadCountDelimiterLocation = [tempDateName rangeOfLastString:@"(" options:NSLiteralSearch].location;
			tempThreadCountString = [tempDateName substringFromIndex:threadCountDelimiterLocation+1];
			tempThreadCount = [tempThreadCountString intValue];
			
			dateName = [tempDateFolderName substringFromIndex:1];
			int dateNameInt = [dateName intValue];
			if (dateNameInt > 0) { //1228012172
				NSTimeInterval timeInterval = dateNameInt*1000000;
				NSCalendarDate *date = [NSCalendarDate dateWithTimeIntervalSince1970:timeInterval];
				dateName = [date descriptionWithCalendarFormat:calendarFormat];
				
			}
			dateName = [dateName stringByAppendingFormat:threadCountFormat, tempThreadCount];
			T2ListFace *listFace = [T2ListFace listFaceWithInternalPath:[[list internalPath] stringByAppendingPathComponent:tempDateFolderName]
																  title:dateName 
																  image:__categoryImage];
			[listFace setLeaf:YES];
			
			[newDateList addObject:listFace];
			[srcScanner scanString:@"\n" intoString:NULL];
		}
		[myPool release];
	}
	
	[list setObjects:newDateList];
}

-(void)buildOldThreadList:(T2ThreadList *)threadList WithWebData:(T2WebData *)webData boardKey:(NSString *)boardKey {
	
	// read subject.txt
	NSAutoreleasePool *myPool;
	NSString *srcString = [webData decodedString];
	
	NSString *boardInternalPath = [__rootPath stringByAppendingPathComponent:boardKey];
	NSArray *internalPathComponents = [[threadList internalPath] pathComponents];
	//NSString *serverURLString = [[_boardDictionary objectForKey:boardKey] stringByDeletingLastPathComponent];
	
	if ([internalPathComponents count] == 5) { // old servers
		boardInternalPath = [threadList internalPath];
		//serverURLString = [NSString stringWithFormat:@"http://%@/%@/kako/%@/", [internalPathComponents objectAtIndex:3], [internalPathComponents objectAtIndex:1], [internalPathComponents objectAtIndex:4]];
	}
	
	NSMutableArray *newThreadList = [NSMutableArray array];
	NSScanner *boardScanner = [NSScanner scannerWithString:srcString];
	NSString *tempThreadName = nil;
	NSString *threadName = nil;
	NSString *tempThreadFileName = nil;
	NSString *threadKey;
	unsigned resCountDelimiterLocation;
	NSString *tempResCountString = nil;
	int tempThreadResCount = 0;
	int tempThreadOrder = 1;
	
	while (![boardScanner isAtEnd]) {
		myPool = [[NSAutoreleasePool alloc] init];
		
		if ([boardScanner scanUpToString:@"<>" intoString:&tempThreadFileName]
			&& [boardScanner scanString:@"<>" intoString:NULL]
			&& [boardScanner scanUpToString:@"\n" intoString:&tempThreadName])
		{
			resCountDelimiterLocation = [tempThreadName rangeOfLastString:@"(" options:NSLiteralSearch].location;
			threadName = [tempThreadName substringToIndex:resCountDelimiterLocation];
			if ([threadName hasSuffix:@" "] && [threadName length] > 1) threadName = [threadName substringToIndex:[threadName length]-1];
			
			tempResCountString = [tempThreadName substringFromIndex:resCountDelimiterLocation+1];
			tempThreadResCount = [tempResCountString intValue];
			threadKey = [tempThreadFileName stringByDeletingPathExtension];
			
			T2ThreadFace *threadFace = [T2ThreadFace threadFaceWithInternalPath:[boardInternalPath stringByAppendingPathComponent:tempThreadFileName]
															title:[threadName stringByReplacingCharacterReferences]
															order:tempThreadOrder
														 resCount:-1
													  resCountNew:tempThreadResCount];
			
			if ([threadFace state] == T2ThreadFaceStateNew)
				[threadFace setState:T2ThreadFaceStateFallenNoLog];
			
			NSTimeInterval timeInterval = [threadKey intValue];
			[threadFace setCreatedDate:[NSDate dateWithTimeIntervalSince1970:timeInterval]];
			
			[newThreadList addObject:threadFace];
			
			[boardScanner scanString:@"\n" intoString:NULL];
			tempThreadOrder++ ;
		}
		[myPool release];
	}
	
	[threadList setObjects:newThreadList];
	stampList(threadList);
}

-(BOOL)buildThreadList:(T2ThreadList *)threadList WithWebData:(T2WebData *)webData boardKey:(NSString *)boardKey {
	
	NSArray *oldTthreadList = [threadList objects];
	NSEnumerator *threadFaceEnumerator = [oldTthreadList objectEnumerator];
	T2ThreadFace *threadFace;
	
	// mark known threads
	if (oldTthreadList) {
		while (threadFace = [threadFaceEnumerator nextObject]) {
			[threadFace setOrder:10000];
			[threadFace setState:T2ThreadFaceStateNone];
		}
	}
	
	// read subject.txt
	NSAutoreleasePool *myPool;
	NSString *srcString = [webData decodedString];
	NSString *boardInternalPath = [__rootPath stringByAppendingPathComponent:boardKey];
	NSString *serverURLString = [[_boardDictionary objectForKey:boardKey] stringByDeletingLastPathComponent];
	NSDate *tempModifiedDate = [webData lastModified];
	
	// is it Error html?
	if ([srcString rangeOfString:@"<html>"].location != NSNotFound) {
		[self registerMovedServerForInternalPath:boardInternalPath];
		return;
	}
	
	NSMutableArray *newThreadList = [NSMutableArray array];
	NSScanner *boardScanner = [NSScanner scannerWithString:srcString];
	NSString *tempThreadName = nil;
	NSString *threadName = nil;
	NSString *tempThreadFileName = nil;
	NSString *threadKey;
	unsigned resCountDelimiterLocation;
	NSString *tempResCountString = nil;
	int tempThreadResCount = 0;
	int tempThreadOrder = 1;
	
	while (![boardScanner isAtEnd]) {
		myPool = [[NSAutoreleasePool alloc] init];
		
		if ([boardScanner scanUpToString:@"<>" intoString:&tempThreadFileName]
			&& [boardScanner scanString:@"<>" intoString:NULL]
			&& [boardScanner scanUpToString:@"\n" intoString:&tempThreadName])
		{
			resCountDelimiterLocation = [tempThreadName rangeOfLastString:@"(" options:NSLiteralSearch].location;
			if (resCountDelimiterLocation != NSNotFound) {
				threadName = [tempThreadName substringToIndex:resCountDelimiterLocation];
				if ([threadName hasSuffix:@" "] && [threadName length] > 1) threadName = [threadName substringToIndex:[threadName length]-1];
				
				tempResCountString = [tempThreadName substringFromIndex:resCountDelimiterLocation+1];
				tempThreadResCount = [tempResCountString intValue];
				threadKey = [tempThreadFileName stringByDeletingPathExtension];
				
				threadFace = [T2ThreadFace threadFaceWithInternalPath:[boardInternalPath stringByAppendingPathComponent:tempThreadFileName]
																title:[threadName stringByReplacingCharacterReferences]
																order:tempThreadOrder
															 resCount:-1
														  resCountNew:tempThreadResCount];
				
				[threadFace setStateFromResCount];
				
				NSTimeInterval timeInterval = [threadKey intValue];
				[threadFace setCreatedDate:[NSDate dateWithTimeIntervalSince1970:timeInterval]];
				[threadFace setModifiedDate:tempModifiedDate];
				
				[newThreadList addObject:threadFace];
			} else {
				NSLog(@"subject.txt broken: \"%@\"", tempThreadName);
			}
			
			[boardScanner scanString:@"\n" intoString:NULL];
			tempThreadOrder++ ;
		}
		[myPool release];
	}
	if ([newThreadList count] < 3) {
		[self registerMovedServerForInternalPath:[threadList internalPath]];
		//return NO;
	}
	
	// remove unread fallen threads, and mark read fallen threads
	threadFaceEnumerator = [oldTthreadList objectEnumerator];
	if (oldTthreadList) {
		while (threadFace = [threadFaceEnumerator nextObject]) {
			int order = [threadFace order];
			if (order == 10000 && [threadFace resCount] > 0) {
				[threadFace setState:T2ThreadFaceStateFallen];
				[newThreadList addObject:threadFace];
			}
		}
	}
	[threadList setObjects:newThreadList];
	stampList(threadList);
	return YES;
}
-(void)registerMovedServerForInternalPath:(NSString *)internalPath {
	if (!_movingDictionary)
		_movingDictionary = [[NSMutableDictionary alloc] init];
	if (!_movingBoardConnecors)
		_movingBoardConnecors = [[NSMutableArray alloc] init];
	
	NSString *boardKey = [internalPath pathComponentAtIndex:1];
	if ([_movingDictionary objectForKey:boardKey]) return;
	[_movingDictionary setObject:internalPath forKey:boardKey];
	
	NSString *path = [_boardDictionary objectForKey:boardKey];
	if (!path) return;
	T2WebConnector *connector = [T2WebConnector connectorWithURLString:path
															  delegate:self inContext:boardKey];
	if (connector) {
		[_movingBoardConnecors addObject:connector];
	}
}
-(void)connector:(T2WebConnector *)connector ofURL:(NSString *)urlString didReceiveWebData:(T2WebData *)webData
	   inContext:(id)contextObject {
	if ([urlString isEqualToString:__2chViewerCGIURLString]) {
		// 2ch Viewer Login
		
		if (webData) {
			NSString *src = [webData decodedString];
			
			if ([src rangeOfString:@"SESSION-ID=ERROR"].location == NSNotFound) {
				NSScanner *scanner = [NSScanner scannerWithString:src];
				[scanner scanString:@"SESSION-ID=" intoString:NULL];
				NSString *sessionID = NULL;
				[scanner scanUpToString:@"\n" intoString:&sessionID];
				[self setViewerSID:sessionID];
				
				// load registered thread
				if (_threadInternalPathToLoadAfterRelogin) {
					T2Thread *thread = [T2Thread availableObjectWithInternalPath:_threadInternalPathToLoadAfterRelogin];
					if (thread) [thread load];
					
					[_threadInternalPathToLoadAfterRelogin release];
					_threadInternalPathToLoadAfterRelogin = nil;
				}
			} else {
				[self setViewerSID:nil];
				[self setStatusString:plugLocalizedString(@"Login Failed.")];
			}
		}
	} else if ([urlString isEqualToString:@"http://p2.2ch.net/p2/"]) {
			if (![webData contentData]) return;
			T2WebForm *webForm = [T2WebForm webFormWithHTMLString:[NSString stringWithData:[webData contentData]
																			 iconvEncoding:@"SHIFT-JIS"] 
													baseURLString:@"http://p2.2ch.net/p2/"];
			
		if (webForm) {
			[webForm setFormValue:_P2ID forKey:@"form_login_id"];
			[webForm setFormValue:_P2PS forKey:@"form_login_pass"];
			[webForm setFormValue:@"1" forKey:@"regist_cookie"];
			
			NSURLRequest *urlRequest = [webForm formRequestUsingEncoding:NSShiftJISStringEncoding];
			T2WebConnector *webConnector = [T2WebConnector connectorWithURLRequest:urlRequest
																		  delegate:self
																		 inContext:nil];
			setObjectWithRetain(_p2Connector, webConnector);
			
		} else {
			[self setP2StatusString:plugLocalizedString(@"Log-in.")];
		}
	} else {
		// Track Missing Board
		if (webData) {
			NSString *src = [webData decodedString];
			
			if ([src rangeOfString:@"<title>2chbbs..</title>"].location != NSNotFound) {
				NSScanner *scanner = [NSScanner scannerWithString:src];
				[scanner scanUpToString:@"href=\"" intoString:NULL];
				[scanner scanString:@"href=\"" intoString:NULL];
				NSString *newPath = nil;
				[scanner scanUpToString:@"\"" intoString:&newPath];
				
				if (newPath) {
					// Register Old Server
					NSString *oldServer = [[_boardDictionary objectForKey:contextObject] pathComponentAtIndex:1];
					if (oldServer) {
						[self registerOldServerDomain:oldServer forBoardKey:contextObject];
					}
					
					// Register New Server
					NSMutableDictionary *newBoardDictionary = [[_boardDictionary mutableCopy] autorelease];
					[newBoardDictionary setObject:newPath forKey:contextObject];
					setObjectWithRetain(_boardDictionary, [[newBoardDictionary copy] autorelease]);
					
					NSString *internalPath = [_movingDictionary objectForKey:contextObject];
					if ([[internalPath pathComponents] count] > 2) {
						T2Thread *thread = [T2Thread availableObjectWithInternalPath:internalPath];
						if (thread) [thread load];
					} else {
						T2List *list = [T2List availableObjectWithInternalPath:internalPath];
						if (list) [list load];
					}
				}
			}
		}
		[_movingDictionary removeObjectForKey:contextObject];
		[_movingBoardConnecors removeObject:connector];
	}
}

-(void)registerOldServerDomain:(NSString *)domainName forBoardKey:(NSString *)boardKey {
	NSString *kakoFolderPath = [[NSString appLogFolderPath] stringByAppendingPathComponent:__rootPath];
	kakoFolderPath = [[kakoFolderPath stringByAppendingPathComponent:boardKey] stringByAppendingPathComponent:__oldLogPath];
	kakoFolderPath = [kakoFolderPath stringByAppendingPathComponent:domainName];
	if (![kakoFolderPath isExistentPath])
		[[kakoFolderPath stringByAppendingPathComponent:@"dummy"] prepareFoldersInPath];
}
-(NSArray *)oldServerDomainsForBoardKey:(NSString *)boardKey {
	NSString *kakoFolderPath = [[NSString appLogFolderPath] stringByAppendingPathComponent:__rootPath];
	kakoFolderPath = [[kakoFolderPath stringByAppendingPathComponent:boardKey] stringByAppendingPathComponent:__oldLogPath];
	
	if (![kakoFolderPath isExistentPath]) return nil;
	NSArray *oldServerDomains = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:kakoFolderPath error:nil];
	NSEnumerator *oldServerEnumerator = [oldServerDomains objectEnumerator];
	NSString *oldServerDomain = nil;
	NSMutableArray *results = [NSMutableArray array];
	while (oldServerDomain = [oldServerEnumerator nextObject]) {
		if ([oldServerDomain rangeOfString:@".2ch."].location != NSNotFound) {
			[results addObject:oldServerDomain];
		}
	}
	return results;
}

#pragma mark -
#pragma mark protocol T2Posting_v200
-(NSString *)postableRootPath { return __rootPath; }
-(BOOL)canPostResToThread:(T2Thread *)thread {
	NSString *internalPath = [thread internalPath];
	if ([internalPath hasPrefix:__rootPath] &&
		[[thread threadFace] state] != T2ThreadFaceStateFallen &&
		[[thread resArray] count] < 1001) {
		return YES;
	}
	return NO;
}
-(BOOL)canPostThreadToThreadList:(T2ThreadList *)threadList {
	if ([[threadList internalPath] hasPrefix:__rootPath])
		return YES;
	return NO;
}
-(T2Posting *)postingToThread:(T2Thread *)thread res:(T2Res *)res {
	return [[[T2Posting alloc] initWithThread:thread res:res] autorelease];
}
-(T2Posting *)postingToThreadList:(T2ThreadList *)threadList res:(T2Res *)res threadTitle:(NSString *)threadTitle {
	return [[[T2Posting alloc] initWithThreadList:threadList res:res threadTitle:threadTitle] autorelease];
}
-(NSURLRequest *)URLRequestForPosting:(T2Posting *)posting {
	T2Res *tempRes = [posting res];
	T2Thread *thread = [posting thread];
	T2ThreadList *threadList = [posting threadList];
	
	// prepare basic 
	NSString *internalPath;
	NSString *threadKey = nil;
	if (thread) {
		internalPath = [thread internalPath];
	} else {
		internalPath = [threadList internalPath];
	}
	
	NSArray *pathComponents = [internalPath pathComponents];
	NSString *boardKey = [pathComponents objectAtIndex:1];
	NSString *boardURLString = [_boardDictionary objectForKey:boardKey];
	NSString *serverName = [boardURLString pathComponentAtIndex:1];
	if (thread) {
		threadKey = [[pathComponents objectAtIndex:2] stringByDeletingPathExtension];
	}
	
	// delete no-domain HAP
	/*
	NSString *tempPath = [NSString stringWithFormat:@"http://%@/test/bbs.cgi",serverName];
	T2HTTPCookieStorage *sharedHTTPCookieStorage = [T2HTTPCookieStorage sharedHTTPCookieStorage];
	NSArray *cookies = [[[sharedHTTPCookieStorage cookiesForURL:[NSURL URLWithString:tempPath]] copy] autorelease];
	NSEnumerator *cookieEnumerator = [cookies objectEnumerator];
	NSHTTPCookie *cookie;
	while (cookie = [cookieEnumerator nextObject]) {
		if ([[cookie name] isEqualToString:@"HAP"] && [[cookie value] hasPrefix:@"FOXdayo"]) {
			if (![[cookie domain] isEqualToString:@".2ch.net"]) {
				[sharedHTTPCookieStorage deleteCookie:cookie];
			}
		}
	}
	 */
	
	if (_isP2Active) {
		//if (![posting responseWebData]) {
		NSString *p2Path = nil;
		if (threadList) {
			if ([[posting threadTitle] length] == 0) return nil;
			p2Path = [NSString stringWithFormat:@"%@post_form.php?host=%@&bbs=%@&newthread=1",
								_P2URLString, serverName, boardKey];
		} else if (thread) {
			p2Path = [NSString stringWithFormat:@"%@post_form.php?host=%@&bbs=%@&key=%@",
								_P2URLString, serverName, boardKey, threadKey];
		} else {
			return nil;
		}
		NSURL *p2URL = [NSURL URLWithString:p2Path];
		NSURLRequest *request = [NSURLRequest requestWithURL:p2URL];
		return request;
		/*
		} else {
			T2WebForm *p2form = [posting responseWebFormWithEncoding:NSShiftJISStringEncoding];
			if (!p2form) return nil;
			
			NSURLRequest *request;
			NSDictionary *p2defaultParam = [p2form parameterDictionary];
			if (![p2defaultParam objectForKey:@"MESSAGE"]) {
				
				NSString *name = [tempRes name]; if (!name) name = @"";
				NSString *mail = [tempRes mail]; if (!mail) name = @"";
				NSString *content = [tempRes content]; if (!content) return nil;
				NSDictionary *p2param = [NSDictionary dictionaryWithObjectsAndKeys:
										 name, @"FROM",
										 mail, @"mail",
										 content, @"MESSAGE", nil];
				request = [p2form formRequestWithParameterDictionary:p2param
															encoding:NSShiftJISStringEncoding];
			} else {
				request = [p2form formRequestWithParameterDictionary:nil
															encoding:NSShiftJISStringEncoding];
			}
			return request;
		}
		 */
		
	} else {
		// 2ch Viewer Login
		if (_isViewerActive) {
			if (!_viewerSID || !_lastViewerLoginDate ||
				([[NSDate date] timeIntervalSinceDate:_lastViewerLoginDate] > 24*60*60)) {
				
				setObjectWithRetain(_postingInternalPathToLoadAfterRelogin, [posting internalPath]);
				[self performSelector:@selector(loginViewerOnWindow:)
						   withObject:nil
						   afterDelay:0.01];
				return nil;
			}
		}
		
		if (_isBeActive) {
			if (![self beCookieExists] && (!_beMDMD || !_beDMDM)) {
				
				setObjectWithRetain(_postingInternalPathToLoadAfterRelogin, [posting internalPath]);
				[self performSelector:@selector(loginBe:)
						   withObject:nil
						   afterDelay:0.01];
				return nil;
			}
		}
		
		//NSDate *lastLoadingDate = [thread lastLoadingDate];
		NSString *time = @"1";
		if (threadList) {
			NSDate *lastLoadingDate = [threadList lastLoadingDate];
			if (!lastLoadingDate) {
				lastLoadingDate = [NSDate date];
			}
			time = [NSString stringWithFormat:@"%d",(int)([lastLoadingDate timeIntervalSince1970])-60*60]; //2038 issue
		}
		NSString *cgiPath = [NSString stringWithFormat:@"http://%@/test/bbs.cgi",serverName];
		
		// make request and header
		NSURL *cgiURL = [NSURL URLWithString:cgiPath];
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:cgiURL];
		[request setHTTPMethod:@"POST"];
		
		// make body
		NSString *name = [[tempRes name] stringByAddingSJISPercentEscapesForce];
		NSString *mail = [[tempRes mail] stringByAddingSJISPercentEscapesForce];
		NSString *content = [[tempRes content] stringByAddingSJISPercentEscapesForce];
		if (!content) return nil;
		
		NSMutableString *bodyString = [NSMutableString string];
		[bodyString appendFormat:@"bbs=%@", boardKey];
		if (!threadList) {
			[bodyString appendFormat:@"&key=%@", threadKey];
			[bodyString appendFormat:@"&submit=%@", [__resPostingSubmit stringByAddingSJISPercentEscapesForce]];
		} else {
			[bodyString appendFormat:@"&submit=%@", [__threadPostingSubmit stringByAddingSJISPercentEscapesForce]];
		}
		[bodyString appendFormat:@"&FROM=%@", name];
		[bodyString appendFormat:@"&mail=%@", mail];
		[bodyString appendFormat:@"&MESSAGE=%@", content];
		
		if (threadList) {
			NSString *title = [posting threadTitle];
			if (!title) return nil;
			title = [title stringByAddingSJISPercentEscapesForce];
			[bodyString appendFormat:@"&subject=%@", title];
		}
		[bodyString appendFormat:@"&time=%@", time];
		
		// 2ch Viewer
		if (_isViewerActive && _viewerSUA && _viewerSID) {
			[bodyString appendFormat:@"&sid=%@", [_viewerSID stringByAddingSJISPercentEscapesForce]];
			[request setValue:_viewerSUA forHTTPHeaderField:@"User-Agent"];
		}
		
		NSData *bodyData = [bodyString dataUsingEncoding:NSASCIIStringEncoding];
		
		[request setHTTPBody:bodyData];
		
		[request setValue:[NSString stringWithFormat:@"%ld",(unsigned long)[bodyData length]] forHTTPHeaderField:@"Content-length"];
		[request setValue:boardURLString forHTTPHeaderField:@"Referer"];
		
		return request;
	}
	return nil;
}
-(T2LoadingResult)didEndPosting:(T2Posting *)posting forWebData:(T2WebData *)webData {
	NSData *srcData = [webData contentData];
	if (!srcData) return T2LoadingFailed;
	
	// delete no-domain HAP
	/*
	T2HTTPCookieStorage *sharedHTTPCookieStorage = [T2HTTPCookieStorage sharedHTTPCookieStorage];
	NSArray *cookies = [[[sharedHTTPCookieStorage cookiesForURL:[NSURL URLWithString:[webData URLString]]] copy] autorelease];
	NSEnumerator *cookieEnumerator = [cookies objectEnumerator];
	NSHTTPCookie *cookie;
	while (cookie = [cookieEnumerator nextObject]) {
		if ([[cookie name] isEqualToString:@"HAP"] && [[cookie value] hasPrefix:@"FOXdayo"]) {
			if (![[cookie domain] isEqualToString:@".2ch.net"]) {
				[sharedHTTPCookieStorage deleteCookie:cookie];
			}
		}
	}
	 */
	
	NSString *source = [NSString stringUsingIconvWithData:srcData encoding:NSShiftJISStringEncoding];
	if ([source rangeOfString:@"http-equiv=refresh"].location != NSNotFound) {
		return T2LoadingSucceed;
	} else if ([source rangeOfString:@"http-equiv=\"refresh\""].location != NSNotFound) {
		return T2LoadingSucceed;
	}
	
	T2WebForm *webForm = [T2WebForm webFormWithHTMLString:source
											baseURLString:[webData URLString]];
	
	if (_isP2Active) {
		if (webForm) {
			NSArray *p2defaultParams = [webForm parameterkeys];
			if ([p2defaultParams containsObject:@"form_login_pass"]) {
				if (_retryAfterLoginP2) {
					[self setAutoLoginP2:NO];
				}
				setObjectWithRetain(_postingInternalPathToLoadAfterRelogin, [posting internalPath]);
				_retryAfterLoginP2 = YES;
				[self performSelector:@selector(loginP2:)
						   withObject:nil
						   afterDelay:0.01];
				return T2LoadingFailed;
			} else if ([p2defaultParams containsObject:@"FROM"]) {
				_retryAfterLoginP2 = NO;
				T2Res *tempRes = [posting res];
				NSString *name = [tempRes name]; if (!name) name = @"";
				NSString *mail = [tempRes mail]; if (!mail) name = @"";
				NSString *content = [tempRes content]; if (!content) return nil;
				
				[webForm setFormValue:name forKey:@"FROM"];
				[webForm setFormValue:mail forKey:@"mail"];
				[webForm setFormValue:content forKey:@"MESSAGE"];
				
				if ([posting type] == T2PostingTypeThread) {
					NSString *threadTitle = [posting threadTitle];
					[webForm setFormValue:threadTitle forKey:@"subject"];
				}
				
				if ([[webForm submitDictionary] objectForKey:@"submit_beres"]) {
					if (_isBeActive) {
						[webForm setSubmitKey:@"submit_beres"];
					} else {
						[webForm setSubmitKey:@"submit"];
					}
				}
				if ([[webForm parameterkeys] containsObject:@"maru_kakiko"]) {
					if (_isViewerActive) {
						[webForm setFormValue:@"1" forKey:@"maru_kakiko"];
					} else {
						[webForm setFormValue:@"" forKey:@"maru_kakiko"];
					}
				}
				
				NSMutableURLRequest *urlRequest = [[[webForm formRequestUsingEncoding:NSShiftJISStringEncoding] mutableCopy] autorelease];
				[urlRequest setValue:[webData URLString] forHTTPHeaderField:@"Referer"];
				[posting setMessage:nil];
				[posting setAdditionalRequest:urlRequest];
				
				return T2RetryLoading;
			} else {
				[posting setMessage:[source stringFromHTML]];
				[posting setConfirmButtonTitle:[webForm submitValue]];
				NSMutableURLRequest *urlRequest = [[[webForm formRequestUsingEncoding:NSShiftJISStringEncoding] mutableCopy] autorelease];
				[urlRequest setValue:[webData URLString] forHTTPHeaderField:@"Referer"];
				[posting setAdditionalRequest:urlRequest];
				return T2RetryLoading;
			}
		}
		[posting setMessage:[source stringFromHTML]];
		[posting setConfirmButtonTitle:nil];
		[posting setAdditionalRequest:nil];
		return T2RetryLoading;
		
	} else {
		if (webForm) {
			[posting setMessage:[source stringFromHTML]];
			[posting setConfirmButtonTitle:[webForm submitValue]];
			
			NSMutableURLRequest *urlRequest = [[[webForm formRequestUsingEncoding:NSShiftJISStringEncoding] mutableCopy] autorelease];
			[urlRequest setValue:[webData URLString] forHTTPHeaderField:@"Referer"];
			
			if (urlRequest && _isViewerActive && _viewerSUA && _viewerSID) {
				NSMutableData *bodyData = [[[urlRequest HTTPBody] mutableCopy] autorelease];
				NSData *sidData = [[NSString stringWithFormat:@"&sid=%@", [_viewerSID stringByAddingSJISPercentEscapesForce]]
								   dataUsingEncoding:NSASCIIStringEncoding];
				if (sidData)
					[bodyData appendData:sidData];
				[urlRequest setHTTPBody:bodyData];
				
				[urlRequest setValue:_viewerSUA forHTTPHeaderField:@"User-Agent"];
				[urlRequest setValue:[NSString stringWithFormat:@"%ld",(unsigned long)[bodyData length]] forHTTPHeaderField:@"Content-length"];
			}
			
			[posting setAdditionalRequest:urlRequest];
			return T2RetryLoading;
		} else {
			if ([source rangeOfString:__2chViewerRequiresRelogin].location != NSNotFound) {
				
				setObjectWithRetain(_postingInternalPathToLoadAfterRelogin, [posting internalPath]);
				[self performSelector:@selector(loginViewerOnWindow:)
						   withObject:nil
						   afterDelay:0.01];
				return T2LoadingFailed;
			}
		}
		[posting setMessage:[source stringFromHTML]];
		[posting setConfirmButtonTitle:nil];
		[posting setAdditionalRequest:nil];
		return T2RetryLoading;
	}
	return T2LoadingFailed;
}

#pragma mark -
#pragma mark protocol T2ResPosting_v100

-(NSURLRequest *)URLRequestForPostingRes:(T2Res *)tempRes thread:(T2Thread *)thread {
	
	// prepare basic 
	NSString *internalPath = [thread internalPath];
	NSArray *pathComponents = [internalPath pathComponents];
	NSString *boardKey = [pathComponents objectAtIndex:1];
	NSString *boardURLString = [_boardDictionary objectForKey:boardKey];
	//NSRange boardRange = [boardURLString rangeOfString:[NSString stringWithFormat:@"/%@/",boardKey]];
	NSString *serverName = [boardURLString pathComponentAtIndex:1];
	NSString *threadKey = [[pathComponents objectAtIndex:2] stringByDeletingPathExtension];
	NSDate *lastLoadingDate = [thread lastLoadingDate];
	NSString *time = @"1";
	/*
	 if (!lastLoadingDate || _useOldDate)
	 time = @"1";
	 else
	 time = [NSString stringWithFormat:@"%f",[[thread lastLoadingDate] timeIntervalSince1970]];
	 */
	NSString *cgiPath = [NSString stringWithFormat:@"http://%@/test/bbs.cgi",serverName];
	
	// make request and header
	NSURL *cgiURL = [NSURL URLWithString:cgiPath];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:cgiURL];
	[request setHTTPMethod:@"POST"];
	
	// make body
	NSString *name = [[tempRes name] stringByAddingSJISPercentEscapesForce];
	NSString *mail = [[tempRes mail] stringByAddingSJISPercentEscapesForce];
	NSString *content = [[tempRes content] stringByAddingSJISPercentEscapesForce];
	if (!content) return nil;
	
	NSMutableString *bodyString = [NSMutableString string];
	[bodyString appendFormat:@"bbs=%@", boardKey];
	[bodyString appendFormat:@"&key=%@", threadKey];
	[bodyString appendFormat:@"&time=%@", time];
	[bodyString appendFormat:@"&submit=%@", [__resPostingSubmit stringByAddingSJISPercentEscapesForce]];
	[bodyString appendFormat:@"&FROM=%@", name];
	[bodyString appendFormat:@"&mail=%@", mail];
	[bodyString appendFormat:@"&MESSAGE=%@", content];
	
	// 2ch Viewer
	if (_isViewerActive && _viewerSUA && _viewerSID) {
		[bodyString appendFormat:@"&sid=%@", [_viewerSID stringByAddingSJISPercentEscapesForce]];
		[request setValue:_viewerSUA forHTTPHeaderField:@"User-Agent"];
	}
	
	NSData *bodyData = [bodyString dataUsingEncoding:NSASCIIStringEncoding];
	
	[request setHTTPBody:bodyData];
	
	[request setValue:[NSString stringWithFormat:@"%ld",(unsigned long)[bodyData length]] forHTTPHeaderField:@"Content-length"];
	[request setValue:boardURLString forHTTPHeaderField:@"Referer"];
	
	return request;
}

-(T2LoadingResult)didEndPostingResForWebData:(T2WebData *)webData 
						 confirmationMessage:(NSString **)confirmationMessage
					 confirmationButtonTitle:(NSString **)confirmationButtonTitle
						   additionalRequest:(NSURLRequest **)additionalRequest {
	NSData *srcData = [webData contentData];
	if (!srcData) return T2LoadingFailed;
	
	NSString *source = [NSString stringUsingIconvWithData:srcData encoding:NSShiftJISStringEncoding];
	if ([source rangeOfString:@"http-equiv=refresh"].location != NSNotFound) {
		return T2LoadingSucceed;
	} else if ([source rangeOfString:@"http-equiv=\"refresh\""].location != NSNotFound) {
		return T2LoadingSucceed;
	}
	
	T2WebForm *webForm = [T2WebForm webFormWithHTMLString:source
											baseURLString:[webData URLString]];
	if (webForm) {
		*confirmationMessage =  [source stringFromHTML];
		*confirmationButtonTitle = [webForm submitValue];
		
		NSMutableURLRequest *urlRequest = [[[webForm formRequestUsingEncoding:NSShiftJISStringEncoding] mutableCopy] autorelease];
		[urlRequest setValue:[webData URLString] forHTTPHeaderField:@"Referer"];
		
		if (urlRequest && _isViewerActive && _viewerSUA && _viewerSID) {
			NSMutableData *bodyData = [[[urlRequest HTTPBody] mutableCopy] autorelease];
			NSData *sidData = [[NSString stringWithFormat:@"&sid=%@", [_viewerSID stringByAddingSJISPercentEscapesForce]]
							   dataUsingEncoding:NSASCIIStringEncoding];
			if (sidData)
				[bodyData appendData:sidData];
			[urlRequest setHTTPBody:bodyData];
			
			[urlRequest setValue:_viewerSUA forHTTPHeaderField:@"User-Agent"];
			[urlRequest setValue:[NSString stringWithFormat:@"%ld",(unsigned long)[bodyData length]] forHTTPHeaderField:@"Content-length"];
		}
		
		*additionalRequest = urlRequest;
		return T2RetryLoading;
	} else {
		if ([source rangeOfString:__2chViewerRequiresRelogin].location != NSNotFound) {
			
			[self performSelector:@selector(loginViewerOnWindow:)
					   withObject:nil
					   afterDelay:0.01];
			return T2LoadingFailed;
		}
	}
	*confirmationMessage =  [source stringFromHTML];
	return T2RetryLoading;
}
-(NSArray *)accessoryPreferenceItems {
	NSMutableArray *resultArray = [NSMutableArray array];
	if (_beMail && _beCode) {
		[resultArray addObject:[T2PreferenceItem boolItemWithKey:@"isBeActive"
														   title:plugLocalizedString(@"Login Be")
															info:nil]];
	} 
	if (_viewerSUA && _viewerSID) {
		
		[resultArray addObject:[T2PreferenceItem boolItemWithKey:@"isViewerActive"
														   title:plugLocalizedString(@"Activate 2ch Viewer")
															info:nil]];
	}
	if ([resultArray count]>0) return resultArray;
	return nil;
}


-(T2LoadingResult)didEndPostingResForSource:(NSString *)source {
	if ([source rangeOfString:@"http-equiv=refresh"].location != NSNotFound) {
		return T2LoadingSucceed;
	} else if ([source rangeOfString:@"http-equiv=\"refresh\""].location != NSNotFound) {
		return T2LoadingSucceed;
	}
	return T2RetryLoading;
}

-(T2WebForm *)webFormForAdditionalConfirmation:(NSString *)source baseURLString:(NSString *)baseURLString {
	T2WebForm *webForm = [T2WebForm webFormWithHTMLString:source baseURLString:baseURLString];
	return webForm;
}
-(NSURLRequest *)requestForConfirmationWebForm:(T2WebForm *)webForm {
	//NSLog(@"%@", [webForm allFormDictionary]);
	return [webForm formRequestUsingEncoding:NSShiftJISStringEncoding];
}

-(NSURLRequest *)webViewWillSendPostingRequest:(NSURLRequest *)urlRequest {
	if (_isViewerActive && _viewerSUA && _viewerSID) {
		NSMutableURLRequest *request = [[urlRequest mutableCopy] autorelease];
		NSMutableData *bodyData = [[[urlRequest HTTPBody] mutableCopy] autorelease];
		NSData *sidData = [[NSString stringWithFormat:@"&sid=%@", [_viewerSID stringByAddingSJISPercentEscapesForce]]
						   dataUsingEncoding:NSASCIIStringEncoding];
		if (sidData)
			[bodyData appendData:sidData];
		[request setHTTPBody:bodyData];
		
		//NSLog(@"%@", [[[NSString alloc] initWithData:[request HTTPBody] encoding:NSASCIIStringEncoding] autorelease]);
		
		[request setValue:_viewerSUA forHTTPHeaderField:@"User-Agent"];
		[request setValue:[NSString stringWithFormat:@"%ld",(unsigned long)[bodyData length]] forHTTPHeaderField:@"Content-length"];
		return request;
	}
	return urlRequest;
}


#pragma mark -
#pragma mark T2ThreadPosting_v100
//-(NSString *)postableRootPath;

-(NSURLRequest *)URLRequestForPostingFirstRes:(T2Res *)tempRes threadTitle:(NSString *)threadTitle
								 toThreadList:(T2ThreadList *)threadList {
	
	// prepare basic 
	NSString *internalPath = [threadList internalPath];
	NSArray *pathComponents = [internalPath pathComponents];
	NSString *boardKey = [pathComponents objectAtIndex:1];
	NSString *boardURLString = [_boardDictionary objectForKey:boardKey];
	//NSRange boardRange = [boardURLString rangeOfString:[NSString stringWithFormat:@"/%@/",boardKey]];
	NSString *serverName = [boardURLString pathComponentAtIndex:1];
	NSString *time = [NSString stringWithFormat:@"%f",[[threadList lastLoadingDate] timeIntervalSince1970]];
	NSString *cgiPath = [NSString stringWithFormat:@"http://%@/test/bbs.cgi",serverName];
	
	// make body
	NSString *title = [threadTitle stringByAddingSJISPercentEscapesForce];
	NSString *name = [[tempRes name] stringByAddingSJISPercentEscapesForce];
	NSString *mail = [[tempRes mail] stringByAddingSJISPercentEscapesForce];
	NSString *content = [[tempRes content] stringByAddingSJISPercentEscapesForce];
	if (!content) return nil;
	
	NSMutableString *bodyString = [NSMutableString string];
	[bodyString appendFormat:@"bbs=%@", boardKey];
	[bodyString appendFormat:@"&time=%@", time];
	[bodyString appendFormat:@"&submit=%@", [__threadPostingSubmit stringByAddingSJISPercentEscapesForce]];
	[bodyString appendFormat:@"&subject=%@", title];
	[bodyString appendFormat:@"&FROM=%@", name];
	[bodyString appendFormat:@"&mail=%@", mail];
	[bodyString appendFormat:@"&MESSAGE=%@", content];
	NSData *bodyData = [bodyString dataUsingEncoding:NSASCIIStringEncoding];
	
	// make request and header
	NSURL *cgiURL = [NSURL URLWithString:cgiPath];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:cgiURL];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:bodyData];
	
	[request setValue:[NSString stringWithFormat:@"%ld",(unsigned long)[bodyData length]] forHTTPHeaderField:@"Content-length"];
	[request setValue:boardURLString forHTTPHeaderField:@"Referer"];
	
	return request;
}
-(T2LoadingResult)didEndPostingThreadForWebData:(T2WebData *)webData 
							confirmationMessage:(NSString **)confirmationMessage
						confirmationButtonTitle:(NSString **)confirmationButtonTitle
							  additionalRequest:(NSURLRequest **)additionalRequest {
	return [self didEndPostingResForWebData:webData
						confirmationMessage:confirmationMessage
					confirmationButtonTitle:confirmationButtonTitle
						  additionalRequest:additionalRequest];
}

-(T2LoadingResult)didEndPostingThreadForSource:(NSString *)source {
	if ([source rangeOfString:@"http-equiv=refresh"].location != NSNotFound) {
		return T2LoadingSucceed;
	} else if ([source rangeOfString:@"http-equiv=\"refresh\""].location != NSNotFound) {
		return T2LoadingSucceed;
	}
	return T2RetryLoading;
}


#pragma mark -
#pragma mark Actions
-(IBAction)reloadMasterList:(id)sender {
	[[_rootListFace list] load];
}
-(IBAction)logoutViewer:(id)sender {
	[self setViewerSID:nil];
	[self setStatusString:plugLocalizedString(@"Log-out.")];
}
-(IBAction)loginViewer:(id)sender {
	/*
	if (_viewerID && _saveInKeychain) {
		_viewerPS = [[[T2KeychainManager sharedManager] genericPasswordForAccountName:_viewerID serviceName:__2chViewerServiceName] retain];
	}
	 */
	
	NSWindow *docWindow = [(NSView *)sender window];
	[self loginViewerOnWindow:docWindow];
}
-(void)loginViewerOnWindow:(NSWindow *)docWindow {
	BOOL autoLogin = (docWindow == nil) && _autoLoginViewer;
	if (!docWindow) {
		docWindow = [NSApp keyWindow];
	}
	[TH2chViewerLoginWindowController beginLoginSheetOnWindow:docWindow
										   defaultAccountName:_viewerID
											  defaultPassword:_viewerPS
										defaultSaveInKeychain:_saveInKeychain
													autoLogin:autoLogin
													 delegate:self];
}

//-(void)loginSheetDidEndWithAccountName:(NSString *)accountName password:(NSString *)password saveInKeychain:(BOOL)saveInKeychain {
-(void)loginSheetDidEndWithAccountName:(NSString *)accountName sessionID:(NSString *)sessionID sessionUA:(NSString *)sessionUA saveInKeychain:(BOOL)saveInKeychain {
	if (!sessionID) {
		[self setAutoLoginViewer:NO];
		return;
	}
	[self setViewerID:accountName];
	[self setLastViewerLoginDate:[NSDate date]];
	setObjectWithRetain(_viewerSID, sessionID);
	setObjectWithRetain(_viewerSUA, sessionUA);
	
	if (_threadInternalPathToLoadAfterRelogin) {
		T2Thread *thread = [T2Thread availableObjectWithInternalPath:_threadInternalPathToLoadAfterRelogin];
		if (thread) [thread load];
		
		[_threadInternalPathToLoadAfterRelogin release];
		_threadInternalPathToLoadAfterRelogin = nil;
	} else if (_postingInternalPathToLoadAfterRelogin) {
		T2Posting *posting = [T2Posting availableObjectWithInternalPath:_postingInternalPathToLoadAfterRelogin];
		if (posting) [posting load];
		
		[_postingInternalPathToLoadAfterRelogin release];
		_postingInternalPathToLoadAfterRelogin = nil;
	}
	[self setSaveInKeychain:saveInKeychain];
	[self setStatusString:plugLocalizedString(@"Log-in.")];
}

-(IBAction)buyViewer:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://2ch.tora3.net/"]];
}

#pragma mark -

-(IBAction)loginP2:(id)sender {
	BOOL autoLogin = (sender == nil) && _autoLoginP2;
	NSWindow *docWindow = [(NSView *)sender window];
	if (!docWindow) {
		docWindow = [NSApp keyWindow];
	}
	[TH2chViewerLoginWindowController beginP2LoginSheetOnWindow:docWindow
											 defaultAccountName:_P2ID
												defaultPassword:nil
										  defaultSaveInKeychain:_P2SaveInKeychain
													  autoLogin:autoLogin
													   delegate:self];
}
-(void)p2loginSheetDidEndWithAccountName:(NSString *)accountName succeed:(BOOL)succeed alreadyLoggedIn:(BOOL)alreadyLoggedIn saveInKeychain:(BOOL)saveInKeychain {
	if (succeed) {
		if (!alreadyLoggedIn) {
			[self setP2ID:accountName];
			[self setLastP2LoginDate:[NSDate date]];
		}
		
		if (_postingInternalPathToLoadAfterRelogin) {
			T2Posting *posting = [T2Posting availableObjectWithInternalPath:_postingInternalPathToLoadAfterRelogin];
			if (posting) {
				[posting load];
			}
			
			[_postingInternalPathToLoadAfterRelogin release];
			_postingInternalPathToLoadAfterRelogin = nil;
		}
		[self setP2SaveInKeychain:saveInKeychain];
		[self setP2StatusString:plugLocalizedString(@"Log-in.")];
		
	} else {
		[self setAutoLoginP2:NO];
	}
	
}

-(IBAction)logoutP2:(id)sender {
	T2HTTPCookieStorage *sharedHTTPCookieStorage = [T2HTTPCookieStorage sharedHTTPCookieStorage];
	NSArray *cookies = [[T2HTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://p2.2ch.net/p2/"]];
	if (cookies && ([cookies count] >= 2)) {
		NSEnumerator *cookieEnumerator = [cookies objectEnumerator];
		NSHTTPCookie *cookie;
		while (cookie = [cookieEnumerator nextObject]) {
			[sharedHTTPCookieStorage deleteCookie:cookie];
		}
	}
	[self setP2StatusString:plugLocalizedString(@"Log-out.")];
	
}

-(IBAction)aboutP2:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://p2.2ch.net/"]];
}

#pragma mark -

-(IBAction)loginBe:(id)sender {
	BOOL autoLogin = (sender == nil) && _autoLoginBe;
	NSWindow *docWindow = [(NSView *)sender window];
	if (!docWindow) {
		docWindow = [NSApp keyWindow];
	}
	[TH2chViewerLoginWindowController beginBeLoginSheetOnWindow:docWindow
											 defaultAccountName:_beMail
												defaultPassword:nil
										  defaultSaveInKeychain:_beSaveInKeychain
													  autoLogin:_autoLoginBe
													   delegate:self];
}
-(void)beloginSheetDidEndWithAccountName:(NSString *)accountName succeed:(BOOL)succeed alreadyLoggedIn:(BOOL)alreadyLoggedIn saveInKeychain:(BOOL)saveInKeychain {
	if (succeed) {
		if (!alreadyLoggedIn) {
			[self setBeMail:accountName];
			//[self setLastP2LoginDate:[NSDate date]];
		}
		T2HTTPCookieStorage *sharedHTTPCookieStorage = [T2HTTPCookieStorage sharedHTTPCookieStorage];
		NSArray *cookies = [[T2HTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://be.2ch.net/"]];
		if (cookies && ([cookies count] >= 2)) {
			NSEnumerator *cookieEnumerator = [cookies objectEnumerator];
			NSHTTPCookie *cookie;
			while (cookie = [cookieEnumerator nextObject]) {
				NSString *cookieName = [cookie name];
				if ([cookieName isEqualToString:@"MDMD"]) {
					[self setBeMDMD:cookie];
				} else if ([cookieName isEqualToString:@"DMDM"]) {
					[self setBeDMDM:cookie];
				}
			}
		}
		
		if (_postingInternalPathToLoadAfterRelogin) {
			T2Posting *posting = [T2Posting availableObjectWithInternalPath:_postingInternalPathToLoadAfterRelogin];
			if (posting) {
				[posting load];
			}
			
			[_postingInternalPathToLoadAfterRelogin release];
			_postingInternalPathToLoadAfterRelogin = nil;
		}
		[self setBeSaveInKeychain:saveInKeychain];
		[self setBeStatusString:plugLocalizedString(@"Log-in.")];
		
	} else {
		[self setAutoLoginBe:NO];
	}
}

-(IBAction)logoutBe:(id)sender {
	[self setBeMDMD:nil];
	[self setBeDMDM:nil];
	T2HTTPCookieStorage *sharedHTTPCookieStorage = [T2HTTPCookieStorage sharedHTTPCookieStorage];
	NSArray *cookies = [[T2HTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://be.2ch.net/"]];
	if (cookies && ([cookies count] >= 2)) {
		NSEnumerator *cookieEnumerator = [cookies objectEnumerator];
		NSHTTPCookie *cookie;
		while (cookie = [cookieEnumerator nextObject]) {
			NSString *cookieName = [cookie name];
			if ([cookieName isEqualToString:@"MDMD"] || [cookieName isEqualToString:@"DMDM"]) {
				[sharedHTTPCookieStorage deleteCookie:cookie];
			}
		}
	}
	[self setBeStatusString:plugLocalizedString(@"Log-out.")];
}
-(IBAction)aboutBe:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://be.2ch.net/"]];
}

@end
