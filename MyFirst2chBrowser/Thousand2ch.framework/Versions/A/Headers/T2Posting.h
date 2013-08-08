//
//  T2Posting.h
//  Thousand
//
//  Created by R. Natori on 平成22/04/05.
//  Copyright 2010 R. Natori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "T2IdentifiedObject.h"
#import "T2UtilityHeader.h"
#import "T2Protocols.h"
#import "T2PluginProtocols.h"

@class T2Res, T2Thread, T2ThreadList, T2WebConnector, T2WebData, T2WebForm;

extern NSString *T2PostingDidStartLoadingNotification;
extern NSString *T2PostingDidProgressLoadingNotification;
extern NSString *T2PostingDidEndLoadingNotification;

typedef enum {
	T2PostingTypeOther = -1,
	T2PostingTypeRes = 0,
	T2PostingTypeThread,
	T2PostingTypeList
} T2PostingType;

@interface T2Posting : T2IdentifiedObject <T2AsynchronousLoading> {
	T2PostingType _type;
	BOOL _shouldUseSharedCookies;
	T2Res *_res;
	T2Thread *_thread;
	NSString *_threadTitle;
	T2ThreadList *_threadList;
	
	NSString *_message;
	NSString *_confirmButtonTitle;
	NSURLRequest *_additionalRequest;
	
	NSObject *_plugin;
	T2WebConnector	*_connector;
	T2WebData *_responseWebData;
	id _delegate;
	
	BOOL		_isLoading;
	float		_progress;
	NSString	*_progressInfo;
	unsigned		_retryCount;
	T2LoadingResult _loadingResult;
}

//init and Factory
+(id)postingToThread:(T2Thread *)thread  res:(T2Res *)res ;
+(id)postingToThreadList:(T2ThreadList *)threadList res:(T2Res *)res threadTitle:(NSString *)threadTitle ;
-(id)initWithThread:(T2Thread *)thread res:(T2Res *)res ;
-(id)initWithThreadList:(T2ThreadList *)threadList res:(T2Res *)res threadTitle:(NSString *)threadTitle ;

//Accessors
-(void)setType:(T2PostingType)type ;
-(T2PostingType)type ;
-(void)setRes:(T2Res *)res ;
-(T2Res *)res ;
-(void)setThread:(T2Thread *)thread ;
-(T2Thread *)thread ;
-(void)setThreadList:(T2ThreadList *)threadList ;
-(T2ThreadList *)threadList ;
-(void)setThreadTitle:(NSString *)threadTitle ;
-(NSString *)threadTitle ;

-(void)setMessage:(NSString *)message ;
-(NSString *)message ;
-(void)setConfirmButtonTitle:(NSString *)confirmButtonTitle ;
-(NSString *)confirmButtonTitle ;
-(void)setAdditionalRequest:(NSURLRequest *)additionalRequest ;
-(NSURLRequest *)additonalRequest ;

-(void)setWebConnector:(T2WebConnector *)webConnector ;
-(T2WebConnector *)webConnector ;
-(void)setResponseWebData:(T2WebData *)responseWebData ;
-(T2WebData *)responseWebData ;
-(T2WebForm *)responseWebFormWithEncoding:(NSStringEncoding)encoding ;
-(void)setLoadingResult:(T2LoadingResult)loadingResult;
-(T2LoadingResult)loadingResult;

#pragma mark -
#pragma mark protocol T2AsynchronousLoading
-(void)load ;
-(void)cancelLoading ;

-(void)setIsLoading:(BOOL)aBool ;
-(BOOL)isLoading ;
-(void)setProgress:(float)aFloat ;
-(float)progress ;
-(void)setProgressInfo:(NSString *)aString ; 
-(NSString *)progressInfo ;
@end
