//
//  THCookiesWindowController.h
//  Thousand
//
//  Created by R. Natori on 08/12/03.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>

@interface THCookiesWindowController : NSWindowController {
	NSArray *_cookies;
	IBOutlet NSArrayController *_cookiesController;
	IBOutlet T2TableView *_tableView;
}
+(id)sharedCookiesWindowController ;
+(void)releaseSharedCookiesWindowController ;
-(id)initCookiesWindowController ;

-(void)setCookies:(NSArray *)cookies ;
-(NSArray *)cookies;

-(IBAction)remove:(id)sender ;
-(IBAction)removeAll:(id)sender ;
@end
