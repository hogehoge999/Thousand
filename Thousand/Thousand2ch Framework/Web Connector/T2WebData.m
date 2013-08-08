//
//  T2WebData.m
//  Thousand
//
//  Created by R. Natori on 05/07/09.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "T2WebData.h"
#import "T2NSStringAdditions.h"
#import "T2NSCalendarDateAdditions.h"

@implementation T2WebData
+(T2WebData *)webDataWithData:(NSData *)data URLString:(NSString *)urlString headers:(NSDictionary *)dic code:(int)code {
	return [[[self alloc] initWithData:data
							 URLString:urlString
							   headers:dic
								  code:code] autorelease];
}
-(id)initWithData:(NSData *)data URLString:(NSString *)urlString headers:(NSDictionary *)dic code:(int)code {
	self = [super init];
	_contentData = [data retain];
	_urlString = [urlString retain];
	_headers = [dic retain];
	_code = code;
	return self;
}

+(T2WebData *)webDataWithData:(NSData *)data headers:(NSDictionary *)dic code:(int)code {
	return [[[self alloc] initWithData:data URLString:nil headers:dic code:code] autorelease];
}
-(id)initWithData:(NSData *)data headers:(NSDictionary *)dic code:(int)code {
	[super init];
	_contentData = [data retain];
	_headers = [dic retain];
	_code = code;
	return self;
}

-(void)dealloc {
	[_contentData release];
	[_urlString release];
	[_headers release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors
-(void)setURLString:(NSString *)urlString {
	[urlString retain];
	[_urlString release];
	_urlString = urlString;
}
-(NSString *)URLString {
	return _urlString;
}

-(void)setContentData:(NSData *)data {
	[data retain];
	[_contentData release];
	_contentData = data;
}
-(NSData *)contentData { return _contentData; }

-(void)setHeaders:(NSDictionary *)dic {
	[_headers release];
	_headers = [dic retain];
}
-(NSDictionary *)headers { return _headers; }

-(id)headerForKey:(id)key {
	return [_headers objectForKey:key];
}

-(void)setCode:(int)code { _code = code; }
-(int)code { return _code; }


-(NSString *)charsetName {
	NSString *contentType = [_headers objectForKey:@"Content-Type"];
	if (!contentType) return nil;
	NSRange foundRange = [contentType rangeOfString:@"charset="];
	if (foundRange.location == NSNotFound) return nil;
	
	return [contentType substringFromIndex:foundRange.location+foundRange.length];
}
-(NSString *)decodedString {
	NSString *encodingName = [self charsetName];
	NSStringEncoding encoding = 0;
	if (encodingName) {
		encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)encodingName));
	}
	if (encoding == 0) encoding = NSShiftJISStringEncoding;
	
	return [NSString stringUsingIconvWithData:_contentData encoding:encoding];
}

-(NSDate *)lastModified {
	NSString *dateString = [_headers objectForKey:@"Last-Modified"];
	if (dateString) return [NSCalendarDate dateWithRFC1123String:dateString];
	return nil;
}
@end
