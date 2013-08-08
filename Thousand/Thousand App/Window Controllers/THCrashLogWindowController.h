//
//  THCrashLogWindowController.h
//  Thousand
//
//  Created by R. Natori on 08/06/15.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>


@interface THCrashLogWindowController : NSWindowController {
	NSString *_result;
	NSString *_crashLogFilePath;
	
	IBOutlet NSTextView *_textView;
}
+(id)sharedCrashLogWindowController ;
-(id)initCrashLogWindowController ;

-(IBAction)revealCrashLogFileInFinder:(id)sender ;
-(IBAction)createMailForReporting:(id)sender ;
@end
