//
//  T2HTTPCookieStorage.m
//  Thousand
//
//  Created by R. Natori on 08/12/02.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import "T2HTTPCookieStorage.h"

NSString *T2HTTPCookieManagerCookiesChangedNotification = @"T2HTTPCookieManagerCookiesChangedNotification";
static T2HTTPCookieStorage *__sharedHTTPCookieStorage = nil;

@implementation T2HTTPCookieStorage


-(NSArray *)dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use {
	return [NSArray arrayWithObjects:@"cookiesDictionary", nil];
}

+ (T2HTTPCookieStorage *)sharedHTTPCookieStorage {
	if (__sharedHTTPCookieStorage) return __sharedHTTPCookieStorage;
	return [[self alloc] init];
}
-(id)init {
	@synchronized([self class]) {
		if (__sharedHTTPCookieStorage) {
			[self autorelease];
			return __sharedHTTPCookieStorage;
		}
		self = [super init];
		__sharedHTTPCookieStorage = self;
		_topLevelDomainSet = [[NSSet alloc] initWithArray:
							  [NSArray arrayWithObjects:@"com", @"net", @"org", @"edu", @"mil", @"gov", @"int", nil]];
		_cookiesDictionary = [[NSMutableDictionary alloc] init];
	}
	return self;
}
-(oneway void)release {
}

-(void)setCookiesDictionary:(NSDictionary *)cookiesDictionary {
	@synchronized(self) {
		[_cookiesDictionary release];
		_cookiesDictionary = [[NSMutableDictionary alloc] init];
		
		NSEnumerator *keyEnumerator = [cookiesDictionary keyEnumerator];
		NSString *key;
		while (key = [keyEnumerator nextObject]) {
			NSDictionary *dic = [cookiesDictionary objectForKey:key];
			[_cookiesDictionary setObject:[[dic mutableCopy] autorelease]
								   forKey:key];
		}
	}
}
-(NSDictionary *)cookiesDictionary {
	return _cookiesDictionary;
}

- (NSArray *)cookies {
	NSMutableArray *resultArray = [NSMutableArray array];
	NSArray *allPathDic = [_cookiesDictionary allValues];
	NSEnumerator *pathDicEnumerator = [allPathDic objectEnumerator];
	NSDictionary *pathDic;
	while (pathDic = [pathDicEnumerator nextObject]) {
		NSArray *allNameDic = [pathDic allValues];
		NSEnumerator *nameDicEnumerator = [allNameDic objectEnumerator];
		NSDictionary *nameDic;
		while (nameDic = [nameDicEnumerator nextObject]) {
			[resultArray addObjectsFromArray:[nameDic allValues]];
		}
	}
	return [[resultArray copy] autorelease];
}

- (NSArray *)cookiesForURL:(NSURL *)theURL {
	NSString *urlDomain = [theURL host];
	if (!urlDomain) return nil;
	
	NSArray *urlDomainParts = [urlDomain componentsSeparatedByString:@"."];
	unsigned urlDomainPartsCount = [urlDomainParts count];
	unsigned urlDomainMinCount = 3;
	if ([_topLevelDomainSet containsObject:[urlDomainParts lastObject]])
		urlDomainMinCount = 2;
	
	NSMutableArray *resultCookies = [NSMutableArray array];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	@synchronized(self) {
		
		while (_cookiesDictionary) {
			urlDomain = [@"." stringByAppendingString:[urlDomainParts componentsJoinedByString:@"."]];
			NSDictionary *nameDicForPathDic = [_cookiesDictionary objectForKey:urlDomain];
			NSString *urlPath = [theURL path];
			NSMutableDictionary *resultCookieForName = [NSMutableDictionary dictionary];
			
			while (nameDicForPathDic) {
				NSDictionary *cookieForNameDic = [nameDicForPathDic objectForKey:urlPath];
				NSEnumerator *nameEnumerator = [cookieForNameDic keyEnumerator];
				NSString *name;
				while (name = [nameEnumerator nextObject]) {
					NSHTTPCookie *cookie = [cookieForNameDic objectForKey:name];
					
					if ([[cookie expiresDate] timeIntervalSinceNow] > 0) {
						if (![cookie isSecure] || ([cookie isSecure] && [[theURL scheme] isEqualToString:@"https"])) {
							if (![resultCookieForName objectForKey:name]) {
								[resultCookieForName setObject:cookie forKey:name];
							}
						}
					}
				}
				if ([[urlPath lastPathComponent] isEqualToString:urlPath])
					break;
				urlPath = [urlPath stringByDeletingLastPathComponent];
			}
			if ([resultCookieForName count] > 0) {
				[resultCookies addObjectsFromArray:[resultCookieForName allValues]];
			}
			
			if (urlDomainPartsCount <= urlDomainMinCount)
				break;
			
			urlDomainParts = [urlDomainParts subarrayWithRange:NSMakeRange(1, --urlDomainPartsCount)];
		}
	}
	
	[pool release];
	//NSLog(@"%@", resultCookies);
	return [[resultCookies copy] autorelease];
}

- (void)deleteCookie:(NSHTTPCookie *)aCookie {
	NSString *cookieDomain = [aCookie domain];
	NSString *cookiePath = [aCookie path];
	NSString *cookieName = [aCookie name];
	if (!cookieDomain || !cookiePath || !cookieName) return;
	if (![cookieDomain hasPrefix:@"."]) {
		cookieDomain = [@"." stringByAppendingString:cookieDomain];
	}
	
	@synchronized(self) {
		NSMutableDictionary *nameDicForPathDic = [_cookiesDictionary objectForKey:cookieDomain];
		NSMutableDictionary *cookieForNameDic = [nameDicForPathDic objectForKey:cookiePath];
		[cookieForNameDic removeObjectForKey:cookieName];
		if ([cookieForNameDic count] == 0) {
			[nameDicForPathDic removeObjectForKey:cookiePath];
		}
		if ([nameDicForPathDic count] == 0) {
			[_cookiesDictionary removeObjectForKey:cookieDomain];
		}
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:T2HTTPCookieManagerCookiesChangedNotification
														object:self];
}
- (void)setCookie:(NSHTTPCookie *)aCookie {
	NSString *cookieDomain = [aCookie domain];
	NSString *cookiePath = [aCookie path];
	NSString *cookieName = [aCookie name];
	if (!cookieDomain || !cookiePath) return;
	if (![cookieDomain hasPrefix:@"."]) {
		cookieDomain = [@"." stringByAppendingString:cookieDomain];
	}
	
	@synchronized(self) {
		NSMutableDictionary *nameDicForPathDic = [_cookiesDictionary objectForKey:cookieDomain];
		if (!nameDicForPathDic) {
			nameDicForPathDic = [NSMutableDictionary dictionary];
			[_cookiesDictionary setObject:nameDicForPathDic forKey:cookieDomain];
		}
		NSMutableDictionary *cookieForNameDic = [nameDicForPathDic objectForKey:cookiePath];
		if (!cookieForNameDic) {
			cookieForNameDic = [NSMutableDictionary dictionary];
			[nameDicForPathDic setObject:cookieForNameDic forKey:cookiePath];
		}
		if ([[aCookie expiresDate] timeIntervalSinceNow] > 0) { 
			[cookieForNameDic setObject:aCookie forKey:cookieName];
		} else {
			[cookieForNameDic removeObjectForKey:cookieName];
		}
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:T2HTTPCookieManagerCookiesChangedNotification
														object:self];
}

-(void)setCookiesInURLResponse:(NSHTTPURLResponse *)URLResponse {
	NSURL *url = [URLResponse URL];
	NSDictionary *allHeaderFields = [URLResponse allHeaderFields];
	
	NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:allHeaderFields forURL:url];
	NSEnumerator *cookieEnumerator = [cookies objectEnumerator];
	NSHTTPCookie *cookie;
	while (cookie = [cookieEnumerator nextObject]) {
		[self setCookie:cookie];
	}
}
-(void)addCookiesToMutableURLRequest:(NSMutableURLRequest *)mutableURLRequest {
	NSURL *url = [mutableURLRequest URL];
	NSArray *cookies = [self cookiesForURL:url];
	if (!cookies) return;
	NSDictionary *requestHeaderFields = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
	NSEnumerator *keyEnumerator = [requestHeaderFields keyEnumerator];
	NSString *key;
	while (key = [keyEnumerator nextObject]) {
		[mutableURLRequest setValue:[requestHeaderFields objectForKey:key] forHTTPHeaderField:key];
	}
}

-(void)deleteExpiredCookies {
	NSArray *cookies = [self cookies];
	NSHTTPCookie *cookie;
	NSEnumerator *cookieEnumerator = [cookies objectEnumerator];
	while (cookie = [cookieEnumerator nextObject]) {
		NSDate *expireDate = [cookie expiresDate];
		if (!expireDate || [expireDate timeIntervalSinceNow] < 0) {
			[self deleteCookie:cookie];
		}
	}
}
@end


@implementation NSHTTPCookie (T2NSHTTPCookieAdditions)
- (id)initWithCoder:(NSCoder *)decoder {
	NSDictionary *properties = [decoder decodeObjectForKey:@"properties"];
	self = [self initWithProperties:properties];
	return self;
}
- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:[self properties] forKey:@"properties"];
}
@end