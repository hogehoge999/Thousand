//
//  T2Posting.m
//  Thousand
//
//  Created by R. Natori on 平成22/04/05.
//  Copyright 2010 R. Natori. All rights reserved.
//

#import "T2Posting.h"
#import "T2Res.h"
#import "T2Thread.h"
#import "T2ThreadList.h"
#import "T2WebConnector.h"
#import "T2WebData.h"
#import "T2WebForm.h"
#import "T2PluginManager.h"
#import "T2PluginProtocols.h"

NSString *T2PostingDidStartLoadingNotification = @"T2PostingDidStartLoadingNotification";
NSString *T2PostingDidProgressLoadingNotification = @"T2PostingDidProgressLoadingNotification";
NSString *T2PostingDidEndLoadingNotification = @"T2PostingDidEndLoadingNotification";
static NSMutableDictionary *__instancesDictionary = nil;

@implementation T2Posting
+(void)initialize {
	if (__instancesDictionary) return;
	__instancesDictionary = [self createMutableDictionaryForIdentify];
}
+(NSMutableDictionary *)dictionaryForIndentify {
	return __instancesDictionary;
}
-(NSMutableDictionary *)dictionaryForIndentify {
	return __instancesDictionary;
}

#pragma mark -
#pragma mark init and Factory
+(id)postingToThread:(T2Thread *)thread  res:(T2Res *)res {
	return [[[self alloc] initWithThread:thread res:res] autorelease];
}
+(id)postingToThreadList:(T2ThreadList *)threadList res:(T2Res *)res threadTitle:(NSString *)threadTitle {
	return [[[self alloc] initWithThreadList:threadList res:res threadTitle:threadTitle] autorelease];
}
-(id)initWithThread:(T2Thread *)thread res:(T2Res *)res {
	NSString *internalPath = [thread internalPath];
	if (internalPath) {
		self = [super initWithInternalPath:internalPath];
	} else {
		self = [super init];
	}
	
	if (self) {
		_type = T2PostingTypeRes;
		_thread = [thread retain];
		_res = [res retain];
	}
	return self;
}
-(id)initWithThreadList:(T2ThreadList *)threadList res:(T2Res *)res threadTitle:(NSString *)threadTitle {
	NSString *internalPath = [threadList internalPath];
	if (internalPath) {
		self = [super initWithInternalPath:internalPath];
	} else {
		self = [super init];
	}
	
	if (self) {
		_type = T2PostingTypeThread;
		_threadList = [threadList retain];
		_res = [res retain];
		_threadTitle = [threadTitle retain];
	}
	return self;
}

-(void)dealloc {
	[_res release];
	[_thread release];
	[_threadTitle release];
	[_threadList release];
	
	[_message release];
	[_confirmButtonTitle release];
	[_additionalRequest release];
	[_responseWebData release];
	[_progressInfo release];
	
	[self setWebConnector:nil];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors
-(void)setType:(T2PostingType)type { _type = type; }
-(T2PostingType)type { return _type; }
-(void)setRes:(T2Res *)res {
	setObjectWithRetain(_res, res);
}
-(T2Res *)res { return _res; }

-(void)setThread:(T2Thread *)thread {
	setObjectWithRetain(_thread, thread);
}
-(T2Thread *)thread { return _thread; }

-(void)setThreadList:(T2ThreadList *)threadList {
	setObjectWithRetain(_threadList, threadList);
}
-(T2ThreadList *)threadList { return _threadList; }

-(void)setThreadTitle:(NSString *)threadTitle { setObjectWithRetain(_threadTitle, threadTitle); }
-(NSString *)threadTitle { return _threadTitle; }

-(void)setMessage:(NSString *)message { setObjectWithRetain(_message, message); }
-(NSString *)message { return _message; }
-(void)setConfirmButtonTitle:(NSString *)confirmButtonTitle { setObjectWithRetain(_confirmButtonTitle, confirmButtonTitle); }
-(NSString *)confirmButtonTitle { return _confirmButtonTitle; }
-(void)setAdditionalRequest:(NSURLRequest *)additionalRequest { setObjectWithRetain(_additionalRequest, additionalRequest); }
-(NSURLRequest *)additonalRequest { return _additionalRequest; }

-(void)setWebConnector:(T2WebConnector *)webConnector {
	@synchronized(self) {
		if (_connector) {
			[_connector cancelLoading];
			[_connector release];
			_connector = nil;
		}
		if (webConnector) {
			_connector = [webConnector retain];
		}
	}
}
-(T2WebConnector *)webConnector {
	return _connector;
}
-(void)setResponseWebData:(T2WebData *)responseWebData { setObjectWithRetain(_responseWebData, responseWebData); }
-(T2WebData *)responseWebData { return _responseWebData; }
-(T2WebForm *)responseWebFormWithEncoding:(NSStringEncoding)encoding {
	if (!_responseWebData) return nil;
	NSData *data = [_responseWebData contentData];
	if (!data) return nil;
	NSString *dataString = [NSString stringUsingIconvWithData:data encoding:encoding];
	if (!dataString) return nil;
	return [T2WebForm webFormWithHTMLString:dataString baseURLString:[_responseWebData URLString]];
}
-(void)setLoadingResult:(T2LoadingResult)loadingResult { _loadingResult = loadingResult; }
-(T2LoadingResult)loadingResult { return _loadingResult; }

#pragma mark -
#pragma mark Posting <T2AsynchronousLoading>
-(void)load {
	
	@synchronized(self) {
		if (_isLoading
			|| !_internalPath
			|| _connector) return;
		
		NSURLRequest *request = nil;
		NSObject <T2PluginInterface_v100> *plugin = nil;
		if (_additionalRequest) {
			request = _additionalRequest;
		} else {
			T2PluginManager *pluginManager = [T2PluginManager sharedManager];
			plugin = [pluginManager postingPluginForInternalPath:_internalPath];
			if (plugin) {
				request = [(id <T2Posting_v200>)plugin URLRequestForPosting:self];
			}
			if (!plugin) {
				if (_type == T2PostingTypeRes) {
					plugin = [pluginManager resPostingPluginForInternalPath:_internalPath];
					request = [(id <T2ResPosting_v100>)plugin URLRequestForPostingRes:_res
																			   thread:_thread];
				} else if (_type == T2PostingTypeThread) {
					plugin = [pluginManager threadPostingPluginForInternalPath:_internalPath];
					request = [(id <T2ThreadPosting_v100>)plugin URLRequestForPostingFirstRes:_res
																				  threadTitle:_threadTitle
																				 toThreadList:_threadList] ;
				}
			}
		}
		if (plugin) _plugin = plugin;
		if (request) {
			
			request = [request requestByAddingUserAgentAndImporterName:[plugin uniqueName]];
			/*
			if (!_shouldUseSharedCookies) {
				request = [request requestByAddingCookies];
			}
			 */
			
			[self setIsLoading:YES];
			[self setProgress:0];
			[self setProgressInfo:[[request URL] absoluteString]];
			
			[[NSNotificationCenter defaultCenter] postNotificationName:T2PostingDidStartLoadingNotification
																object:self
															  userInfo:nil];
			T2WebConnector *webConnector = [T2WebConnector connectorWithURLRequest:request
																		  delegate:self
																		 inContext:nil
															shouldUseSharedCookies:_shouldUseSharedCookies];
			[self setWebConnector:webConnector];
		}
	}
}
-(void)cancelLoading {
	@synchronized(self) {
		if (_connector) {
			[_connector cancelLoading];
			[self setWebConnector:nil];
			[self setIsLoading:NO];
		}
		[self setProgress:0];
		[self setProgressInfo:nil];
	}
}
-(void)setIsLoading:(BOOL)aBool { _isLoading = aBool; }
-(BOOL)isLoading { return _isLoading; }

-(void)setProgress:(float)aFloat { _progress = aFloat; }
-(float)progress { return _progress; }
-(void)setProgressInfo:(NSString *)aString { setObjectWithRetainSynchronized(_progressInfo, aString); }
-(NSString *)progressInfo { return _progressInfo; }

#pragma mark -
#pragma mark T2WebConnector delegate
-(void)connector:(T2WebConnector *)connector
		   ofURL:(NSString *)urlString
		progress:(float)progress
	   inContext:(id)contextObject {
	[self setProgress:progress];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:T2PostingDidProgressLoadingNotification
														object:self
													  userInfo:nil];
}
-(void)connector:(T2WebConnector *)connector
		   ofURL:(NSString *)urlString
didReceiveWebData:(T2WebData *)webData
	   inContext:(id)contextObject {
	
	NSString *internalPath = [self internalPath];
	setObjectWithRetain(_responseWebData, webData);
	
	[self setProgress:0];
	[self setProgressInfo:[connector status]];
	[self setIsLoading:NO];
	[_connector release];
	_connector = nil;
	
	NSString *confirmationMessage = nil;
	NSString *confirmationButtonTitle = nil;
	NSURLRequest *additionalRequest = nil;
	
	if (_responseWebData && internalPath) {
		if ([_plugin conformsToProtocol:@protocol(T2Posting_v200)]) {
			_loadingResult = [(id <T2Posting_v200>)_plugin didEndPosting:self forWebData:_responseWebData];
			if (_loadingResult == T2RetryLoading) {
				if (!_message && _retryCount<10) {
					_retryCount++;
					[self load];
					return;
				}
			}
			
		} else if (_type == T2PostingTypeRes && [_plugin conformsToProtocol:@protocol(T2ResPosting_v100)]) {
			_loadingResult = [(id <T2ResPosting_v100>)_plugin didEndPostingResForWebData:_responseWebData
																			confirmationMessage:&confirmationMessage
																		confirmationButtonTitle:&confirmationButtonTitle
																			  additionalRequest:&additionalRequest];
			if (_loadingResult == T2RetryLoading) {
				_retryCount++;
				[self setMessage:confirmationMessage];
				[self setConfirmButtonTitle:confirmationButtonTitle];
				[self setAdditionalRequest:additionalRequest];
			}
		} else if (_type == T2PostingTypeThread && [_plugin conformsToProtocol:@protocol(T2ThreadPosting_v100)]) {
			_loadingResult = [(id <T2ThreadPosting_v100>)_plugin didEndPostingThreadForWebData:_responseWebData
																   confirmationMessage:&confirmationMessage
															   confirmationButtonTitle:&confirmationButtonTitle
																	 additionalRequest:&additionalRequest];
					  
			if (_loadingResult == T2RetryLoading) {
				_retryCount++;
				[self setMessage:confirmationMessage];
				[self setConfirmButtonTitle:confirmationButtonTitle];
				[self setAdditionalRequest:additionalRequest];
			}
		}

	}
	
	_retryCount = 0;
	[[NSNotificationCenter defaultCenter] postNotificationName:T2PostingDidEndLoadingNotification
														object:self
													  userInfo:nil];
}
@end
