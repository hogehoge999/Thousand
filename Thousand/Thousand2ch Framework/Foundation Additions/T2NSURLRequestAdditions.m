//
//  T2NSURLRequestAdditions.m
//  Thousand
//
//  Created by R. Natori on 06/02/04.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "T2NSURLRequestAdditions.h"
#import "T2HTTPCookieStorage.h"
#import "T2NSStringAdditions.h"

static NSString *__defaultUserAgent = nil;

@implementation NSURLRequest (T2NSURLRequestAdditions)

+(NSURLRequest *)requestUsingGzipWithURL:(NSURL *)URL {
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	[request setValue:@"close" forHTTPHeaderField:@"Connection"];
	[request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	return request;
}

+(NSURLRequest *)requestWith2chURL:(NSURL *)URL ifModifiedSince:(NSString *)dateString 
							 range:(unsigned)length {
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL
														   cachePolicy:NSURLRequestReloadIgnoringCacheData
													   timeoutInterval:30];
	
	[request setValue:@"close" forHTTPHeaderField:@"Connection"];
	if (dateString)
		[request setValue:dateString forHTTPHeaderField:@"If-Modified-Since"];
	if (length > 0) {
		[request setValue:@"identity" forHTTPHeaderField:@"Accept-Encoding"];
		[request setValue:[NSString stringWithFormat:@"bytes=%d-",length] forHTTPHeaderField:@"Range"];
	} else {
		[request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	}
		
		
	return request;
}

-(NSURLRequest *)requestByAddingUserAgentAndImporterName:(NSString *)importerName {
	if (!__defaultUserAgent) {
		NSBundle *appBundle = [NSBundle mainBundle];
		NSString *appName = [[appBundle executablePath] lastPathComponent];
		NSString *appVersion = [appBundle objectForInfoDictionaryKey:@"CFBundleVersion"] ;
		__defaultUserAgent = [[NSString alloc] initWithFormat:@"Monazilla/1.00 %@/%@", appName, appVersion];
	}
	
	NSString *availableUA = [self valueForHTTPHeaderField:@"User-Agent"];
	if (availableUA && [availableUA length]>0) return self;
	
	NSMutableURLRequest *request = [[self mutableCopy] autorelease];
	NSString *userAgentString;
	if (!importerName)
		userAgentString = __defaultUserAgent;
	else
		userAgentString = [NSString stringWithFormat:@"%@ %@", __defaultUserAgent, importerName];
	
	[request setValue:userAgentString forHTTPHeaderField:@"User-Agent"];
	
	return request;
}

-(NSURLRequest *)requestByAddingCookies {
	NSMutableURLRequest *request = [[self mutableCopy] autorelease];
	[request setHTTPShouldHandleCookies:NO];
	[[T2HTTPCookieStorage sharedHTTPCookieStorage] addCookiesToMutableURLRequest:request];
	return request;
}
@end
