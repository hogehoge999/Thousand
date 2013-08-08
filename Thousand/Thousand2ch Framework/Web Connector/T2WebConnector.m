//
//  T2WebConnector.m
//  Thousand
//
//  Created by R. Natori on 05/07/10.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "T2WebConnector.h"
#import "T2WebData.h"
#import "T2NSArrayAdditions.h"
#import "T2HTTPCookieStorage.h"
#import "T2UtilityHeader.h"

static NSMutableDictionary *__connectors = nil;

@implementation T2WebConnector

+(void)initialize {
	if (__connectors) return;
	__connectors = [[NSMutableDictionary alloc] init];
}
+(T2WebConnector *)connectorWithURLString:(NSString *)urlString delegate:(id)anObject inContext:(id)contextObject shouldUseSharedCookies:(BOOL)shouldUseSharedCookies {
	NSURL *tempURL;
	if ([urlString hasPrefix:@"file://"]) {
		tempURL = [NSURL fileURLWithPath:[urlString substringFromIndex:[@"file://" length]]];
	} else tempURL = [NSURL URLWithString:urlString];
	NSURLRequest *tempRequest = [NSURLRequest requestWithURL:tempURL];
	if (tempRequest) return [self connectorWithURLRequest:tempRequest delegate:anObject inContext:contextObject shouldUseSharedCookies:shouldUseSharedCookies];
	else return nil;
}
+(T2WebConnector *)connectorWithURLRequest:(NSURLRequest *)urlRequest delegate:(id)anObject inContext:(id)contextObject shouldUseSharedCookies:(BOOL)shouldUseSharedCookies {
	return [[[self alloc] initWithURLRequest:(NSURLRequest *)urlRequest
									delegate:(id)anObject
								   inContext:(id)contextObject
					  shouldUseSharedCookies:shouldUseSharedCookies] autorelease];
}
+(T2WebConnector *)connectorWithURLString:(NSString *)urlString delegate:(id)anObject inContext:(id)contextObject {
	return [self connectorWithURLString:urlString
							   delegate:anObject inContext:contextObject shouldUseSharedCookies:NO];
}
+(T2WebConnector *)connectorWithURLRequest:(NSURLRequest *)urlRequest delegate:(id)anObject inContext:(id)contextObject {
	return [[[self alloc] initWithURLRequest:(NSURLRequest *)urlRequest
									delegate:(id)anObject
								   inContext:(id)contextObject
					  shouldUseSharedCookies:NO] autorelease];
}

/*
+(void)removeConnectorOfURL:(NSString *)urlString {
	T2WebConnector *tempConnector = [__connectors objectForKey:urlString];
	if (tempConnector) {
		[__connectors removeObjectForKey:urlString];
	}
}
+(void)cancelURL:(NSString *)urlString byDelegate:(id)anObject {
	T2WebConnector *tempConnector = [__connectors objectForKey:urlString];
	if (tempConnector) [tempConnector removeDelegate:anObject];
}
 */

-(id)initWithURLRequest:(NSURLRequest *)urlRequest
			   delegate:(id)anObject
			  inContext:(id)contextObject 
 shouldUseSharedCookies:(BOOL)shouldUseSharedCookies {

	self = [super init];
	_urlString = [[[urlRequest URL] relativeString] retain];
	_shouldUseSharedCookies = shouldUseSharedCookies;
	
	if (!_shouldUseSharedCookies) {
		urlRequest = [urlRequest requestByAddingCookies];
	}
	
	if ([NSURLConnection canHandleRequest:urlRequest]) {
		_delegate = anObject;
		_context = [contextObject retain];
			
		_myConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
		_receivedData = [[NSMutableData alloc] init];
		return self;
	}
	[self release];
	return nil;
}

-(void)dealloc {
	_delegate = nil;
	if (_myConnection) {
		[_myConnection cancel];
		[_myConnection release];
		_myConnection = nil;
	}
	[_urlString release];
	[_redirectedUrlString release];
	
	[_context release];
	[_receivedData release];
	[_receivedResponse release];
	[super dealloc];
}
/*
-(BOOL)addDelegate:(id)anObject inContext:(id)contextObject {
	if ([_delegatesArray indexOfObjectIdenticalTo:anObject] != NSNotFound) return NO;
	[_delegatesArray addObject:anObject];
	
	if (contextObject)
		[_contextsArray addObject:contextObject];
	else
		[_contextsArray addObject:[NSNull null]];
	
	return YES;
}

-(void)removeDelegate:(id)anObject {
	
	unsigned i=NSNotFound;
	i=[_delegatesArray indexOfObjectIdenticalTo:anObject];
	while (i != NSNotFound) {
		[_delegatesArray removeObjectAtIndex:i];
		[_contextsArray removeObjectAtIndex:i];
		i = [_delegatesArray indexOfObjectIdenticalTo:anObject];
	}
	
	if ([_delegatesArray count] == 0) {
		
		if (_myConnection) {
			[_myConnection cancel];
			[_myConnection release];
			_myConnection = nil;
		}
		[T2WebConnector removeConnectorOfURL:_urlString];
		//[self autorelease];
	}
}
 */
-(void)cancelLoading {
	_delegate = nil;
	if (_myConnection) {
		[_myConnection cancel];
		[_myConnection release];
		_myConnection = nil;
	}
}

-(void)returnEmptyData {
	[_receivedData release];
	_receivedData = nil;
	[self returnData];
}
-(void)returnData {
	T2WebData *tempWebData = [T2WebData webDataWithData:_receivedData
											  URLString:_urlString
												headers:[_receivedResponse allHeaderFields]
												   code:[_receivedResponse statusCode]] ;
	if (!_delegate) return;
	if ([_delegate respondsToSelector:@selector(connector:ofURL:didReceiveWebData:inContext:)])
			[_delegate connector:self ofURL:_urlString didReceiveWebData:tempWebData
						inContext:_context];
}
-(void)returnProgress:(float)aFloat {
	if (!_delegate) return;
	if ([_delegate respondsToSelector:@selector(connector:ofURL:progress:inContext:)])
		[_delegate connector:self ofURL:_urlString progress:aFloat
					inContext:_context];}

-(NSString *)urlString {
	return _urlString;
}
-(NSString *)redirectedUrlString {
	return _redirectedUrlString;
}

-(void)setStatus:(NSString *)aString {
	setObjectWithCopy(_status, aString);
}
-(NSString *)status { return _status; }

-(unsigned)dataLength { return _length; }

-(void)setShouldUseSharedCookies:(BOOL)aBool { _shouldUseSharedCookies = aBool; }
-(BOOL)shouldUseSharedCookies { return _shouldUseSharedCookies; }

// delegate methods
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	if (connection != _myConnection) return;
	
	[_receivedData appendData:data];
	if (_length <= 0) return;
	float newProgress = ((float)[_receivedData length] / _length);
	if (0.05 < (newProgress-_progress)) {
		[self returnProgress:newProgress];
		_progress = newProgress;
	}
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	if (connection != _myConnection) return;
	int statusCode;
	if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
		_receivedResponse = [response retain];
		
		if (!_shouldUseSharedCookies) {
			[[T2HTTPCookieStorage sharedHTTPCookieStorage] setCookiesInURLResponse:(NSHTTPURLResponse *)response];
		}
		
		statusCode = [(NSHTTPURLResponse *)response statusCode];
		if (statusCode >= 300) {
			[self setStatus:[NSHTTPURLResponse localizedStringForStatusCode:statusCode]];
			[_myConnection cancel];
			[_myConnection release];
			_myConnection = nil;
			
			[self returnEmptyData];
			return;
		}
	}
	_charset = [response textEncodingName];
	_length = [response expectedContentLength];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
	if (redirectResponse) {
		NSString *urlString = [[request URL] absoluteString];
		setObjectWithCopy(_redirectedUrlString, urlString);
	}
	return request;
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if (connection != _myConnection) return;
	[_myConnection cancel];
	[_myConnection release];
	_myConnection = nil;
	_length = [_receivedData length];
	[self returnProgress:1.0];
	[self returnData];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	if (connection != _myConnection) return;
	
	[self setStatus:[error localizedDescription]];
	[_myConnection cancel];
	[_myConnection release];
	_myConnection = nil;
	
	[self returnEmptyData];
}
@end
