//
//  T2PopUpWindowController.h
//  Thousand
//
//  Created by R. Natori on 06/07/07.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <Thousand2ch/Thousand2ch.h>

@interface T2PopUpWindowController : NSWindowController {
	BOOL _tracking;
	NSTrackingRectTag _trackingRectTag;
	BOOL _entered;
	
	IBOutlet T2ThreadView *_threadView;
}

#pragma mark -
#pragma mark Class Method
+(void)setClassResPopUpWindowWidth:(float)width ;
+(float)classResPopUpWindowWidth ;

#pragma mark -
#pragma mark PopUp Control
+(void)initialize ;

#pragma mark -
#pragma mark Factory and Init
+(id)popUpWindowControllerWithURLString:(NSString *)urlString inThread:(T2Thread *)thread ;
-(id)initWithURLString:(NSString *)urlString inThread:(T2Thread *)thread ;
-(void)dealloc ;


#pragma mark -
#pragma mark Accessors
-(T2ThreadView *)threadView ;

#pragma mark -
#pragma mark Enter and Exit

-(void)setTracking:(BOOL)tracking ;
-(BOOL)tracking ;
	
- (void)mouseEntered:(NSEvent *)theEvent ;
- (void)mouseExited:(NSEvent *)theEvent ;

-(void)closePopUp ;
+(void)closeAllPopUp ;
@end
