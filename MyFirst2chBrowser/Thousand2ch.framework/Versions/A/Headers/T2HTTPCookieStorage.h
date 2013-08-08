//
//  T2HTTPCookieStorage.h
//  Thousand
//
//  Created by R. Natori on 08/12/02.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "T2NSObjectAdditions.h"

extern NSString *T2HTTPCookieManagerCookiesChangedNotification;

@interface T2HTTPCookieStorage : NSObject <T2DictionaryConverting>{
	NSSet *_topLevelDomainSet;
	NSMutableDictionary *_cookiesDictionary;
}

+ (T2HTTPCookieStorage *)sharedHTTPCookieStorage ;

-(void)setCookiesDictionary:(NSDictionary *)cookiesDictionary ;
-(NSDictionary *)cookiesDictionary ;

- (NSArray *)cookies ;
- (NSArray *)cookiesForURL:(NSURL *)theURL ;

- (void)deleteCookie:(NSHTTPCookie *)aCookie ;
- (void)setCookie:(NSHTTPCookie *)aCookie ;

-(void)setCookiesInURLResponse:(NSHTTPURLResponse *)URLResponse ;
-(void)addCookiesToMutableURLRequest:(NSMutableURLRequest *)mutableURLRequest ;

-(void)deleteExpiredCookies ;
@end


@interface NSHTTPCookie (T2NSHTTPCookieAdditions) <NSCoding>
- (id)initWithCoder:(NSCoder *)decoder ;
- (void)encodeWithCoder:(NSCoder *)encoder ;
@end