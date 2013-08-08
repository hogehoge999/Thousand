//
//  THCookiesWindowController.m
//  Thousand
//
//  Created by R. Natori on 08/12/03.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import "THCookiesWindowController.h"

static id __sharedCookiesWindowController;

@implementation THCookiesWindowController
+(id)sharedCookiesWindowController {
	if (!__sharedCookiesWindowController)
		__sharedCookiesWindowController = [[self alloc] initCookiesWindowController];
	return __sharedCookiesWindowController;
}
+(void)releaseSharedCookiesWindowController {
	//[__sharedCookiesWindowController saveAllPrefs];
	[__sharedCookiesWindowController release];
	__sharedCookiesWindowController = nil;
}
-(id)initCookiesWindowController {
	
	if (__sharedCookiesWindowController) {
		[self autorelease];
		return __sharedCookiesWindowController;
	}
	self = [self initWithWindowNibName:@"THCookiesWindow"];
	[self setWindowFrameAutosaveName:@"cookiesWindow"];
	
	[self setCookies:[[T2HTTPCookieStorage sharedHTTPCookieStorage] cookies]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cookiesDidChange:) name:T2HTTPCookieManagerCookiesChangedNotification
											   object:nil];
	
	return self;
}

-(void)awakeFromNib {
	[_tableView setTarget:self];
	[_tableView setDeleteKeyAction:@selector(remove:)];
}

-(oneway void)release {
}
-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:T2HTTPCookieManagerCookiesChangedNotification object:nil];
	[super dealloc];
}


-(void)setCookies:(NSArray *)cookies {
	setObjectWithCopy(_cookies, cookies);
}
-(NSArray *)cookies {
	return _cookies;
}

-(void)cookiesDidChange:(NSNotification *)notification {
	[self setCookies:[[T2HTTPCookieStorage sharedHTTPCookieStorage] cookies]];
}

-(IBAction)remove:(id)sender {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:T2HTTPCookieManagerCookiesChangedNotification object:nil];
	
	NSArray *cookies = [[_cookiesController selectedObjects] copy];
	NSEnumerator *cookieEnumerator = [cookies objectEnumerator];
	NSHTTPCookie *cookie;
	T2HTTPCookieStorage *cookieStorage = [T2HTTPCookieStorage sharedHTTPCookieStorage];
	while (cookie = [cookieEnumerator nextObject]) {
		[cookieStorage deleteCookie:cookie];
	}
	
	[cookies release];
	[self setCookies:[cookieStorage cookies]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cookiesDidChange:) name:T2HTTPCookieManagerCookiesChangedNotification
											   object:nil];
}
-(IBAction)removeAll:(id)sender {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:T2HTTPCookieManagerCookiesChangedNotification object:nil];
	
	NSArray *cookies = [_cookies copy];
	NSEnumerator *cookieEnumerator = [cookies objectEnumerator];
	NSHTTPCookie *cookie;
	T2HTTPCookieStorage *cookieStorage = [T2HTTPCookieStorage sharedHTTPCookieStorage];
	while (cookie = [cookieEnumerator nextObject]) {
		[cookieStorage deleteCookie:cookie];
	}
	
	[cookies release];
	[self setCookies:[cookieStorage cookies]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cookiesDidChange:) name:T2HTTPCookieManagerCookiesChangedNotification
											   object:nil];
	
}
@end
