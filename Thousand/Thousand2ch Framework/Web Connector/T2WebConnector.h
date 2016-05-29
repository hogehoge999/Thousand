//
//  T2WebConnector.h
//  Thousand
//
//  Created by R. Natori on 05/07/10.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class T2WebConnector, T2WebData;
// this class manage HTTP connection, return data and response.

// informal protocol
@interface NSObject ( T2WebConnectorDelegate )

// this message will be sent when loading finished.
-(void)connector:(T2WebConnector *)connector
		   ofURL:(NSString *)urlString
didReceiveWebData:(T2WebData *)webData
	   inContext:(id)contextObject;

// this message notify progress.
-(void)connector:(T2WebConnector *)connector
		   ofURL:(NSString *)urlString
		progress:(float)progress
	   inContext:(id)contextObject;

@end

@interface T2WebConnector : NSObject<NSURLSessionDelegate>  {
	NSString *_urlString;
	NSString *_redirectedUrlString;
	NSString *_status;
	NSString *_charset;
	float _progress;
	float _length;
	int _objectType;
	
	id _delegate;
	id _context;
	
    //NSURLConnection *_myConnection;
    NSURLSessionDataTask *_myConnection;
	NSMutableData *_receivedData;
	NSHTTPURLResponse *_receivedResponse;
	
	BOOL _shouldUseSharedCookies;
}

+(T2WebConnector *)connectorWithURLString:(NSString *)urlString delegate:(id)anObject inContext:(id)contextObject shouldUseSharedCookies:(BOOL)shouldUseSharedCookies;
+(T2WebConnector *)connectorWithURLRequest:(NSURLRequest *)urlRequest delegate:(id)anObject inContext:(id)contextObject shouldUseSharedCookies:(BOOL)shouldUseSharedCookies;
+(T2WebConnector *)connectorWithURLString:(NSString *)urlString delegate:(id)anObject inContext:(id)contextObject ;
+(T2WebConnector *)connectorWithURLRequest:(NSURLRequest *)urlRequest delegate:(id)anObject inContext:(id)contextObject ;
//+(void)removeConnectorOfURL:(NSString *)urlString ;
//+(void)cancelURL:(NSString *)urlString byDelegate:(id)anObject;

-(id)initWithURLRequest:(NSURLRequest *)urlRequest
			   delegate:(id)anObject
			  inContext:(id)contextObject
 shouldUseSharedCookies:(BOOL)shouldUseSharedCookies;

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler;
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data;
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error;


//-(BOOL)addDelegate:(id)anObject inContext:(id)contextObject ;
//-(void)removeDelegate:(id)anObject ;
-(void)cancelLoading ;
-(void)returnData ;
-(void)returnEmptyData ;
-(NSString *)urlString ;
-(NSString *)redirectedUrlString ;
-(void)setStatus:(NSString *)aString ;
-(NSString *)status ;
-(unsigned)dataLength ;

-(void)setShouldUseSharedCookies:(BOOL)aBool ;
-(BOOL)shouldUseSharedCookies ;
@end
