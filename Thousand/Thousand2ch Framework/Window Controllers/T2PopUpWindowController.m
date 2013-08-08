//
//  T2PopUpWindowController.m
//  Thousand
//
//  Created by R. Natori on 06/07/07.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "T2PopUpWindowController.h"

static float				__cursorOffset = 8;
static float				__heightOffset = 20;
static float				__resPopUpWindowWidth = 300;
static NSMutableArray *__allPopUpWindowControllers = nil;

static BOOL __makePopUpWindowKey = YES;

@implementation T2PopUpWindowController


#pragma mark -
#pragma mark Class Method
+(void)initialize {
	if (__allPopUpWindowControllers) return;
	__allPopUpWindowControllers = [[NSMutableArray mutableArrayWithoutRetainingObjects] retain];
	SInt32 MacVersion;
	if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr){
		if (MacVersion >= 0x1050){ // Leopard and later
			__makePopUpWindowKey = NO;
		}
	}
}

+(void)setClassResPopUpWindowWidth:(float)width { __resPopUpWindowWidth = width; }
+(float)classResPopUpWindowWidth { return __resPopUpWindowWidth; }


#pragma mark -
#pragma mark Init Method
+(id)popUpWindowControllerWithURLString:(NSString *)urlString inThread:(T2Thread *)thread {
	return [[[self alloc] initWithURLString:urlString
								   inThread:thread] autorelease];
}
-(id)initWithURLString:(NSString *)urlString inThread:(T2Thread *)thread {
	
	self = [self initWithWindowNibName:@"T2PopUpWindow"];
	[__allPopUpWindowControllers addObject:self];
	
	NSSize minSize = NSMakeSize(128, 128);
	NSWindow *window = [self window];
	NSRect windowFrame = [window frame];
	NSRect screenVisibleFrame = [[window screen] visibleFrame];
	NSPoint mouseLoc = [NSEvent mouseLocation];
	BOOL showImmediately = NO;
	NSURL *baseURL = nil;
	NSString *resultHTML;
	
	[_threadView setThousandDefaultAttributes];
	[_threadView setIsPopup:YES];
	[_threadView setThread:thread];
	[_threadView setFrameLoadDelegate:self];
	
	if ([urlString hasPrefix:@"internal://"]) {
		windowFrame.size = NSMakeSize(__resPopUpWindowWidth,32);
		
		[_threadView setResExtractPath:urlString];
	} else {
		showImmediately = YES;
		T2PluginManager *pluginManager = [T2PluginManager sharedManager];
		NSString *htmlString = [pluginManager partialHTMLforPreviewingURLString:urlString
																		   type:T2PreviewInPopUp
																		minSize:&minSize];
		if (!htmlString) {
			[self autorelease];
			return nil;
		}
		windowFrame.size = minSize;
		resultHTML = [thread HTMLWithOtherInsertion:htmlString
											  baseURL:&baseURL forPopUp:YES];
		
		[[_threadView mainFrame] loadHTMLString:resultHTML baseURL:baseURL];
	}
	
	float rightSidedOriginX = mouseLoc.x + __cursorOffset;
	float leftSidedOriginX = windowFrame.origin.x = mouseLoc.x - __cursorOffset - windowFrame.size.width;
	float rightSidedOffset = rightSidedOriginX + windowFrame.size.width - screenVisibleFrame.size.width;
	
	if (rightSidedOffset > 0) {
		if (leftSidedOriginX > 0) {
			windowFrame.origin.x = leftSidedOriginX;
		} else {
			windowFrame.origin.x = rightSidedOriginX - rightSidedOffset;
		}
	} else {
		windowFrame.origin.x = rightSidedOriginX;
	}
	windowFrame.origin.y = mouseLoc.y-__heightOffset;
	
	[window setFrame:windowFrame display:NO];
	
	[self setTracking:YES];
	
	if (showImmediately)
		[window orderFront:nil];
	 
	
	//showImmediately = YES;
	
	
	//[self showWindow:nil];
	//[window orderFront:nil];
	
	return self;	
}
-(void)dealloc {
	
	
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors
-(T2ThreadView *)threadView { return _threadView; }

#pragma mark -
#pragma mark Delegate method and Observing
- (void)windowDidResize:(NSNotification *)aNotification {
	if (_tracking) {
		[_threadView removeTrackingRect:_trackingRectTag];
		_trackingRectTag = [_threadView addTrackingRect:[_threadView bounds]
												  owner:self
											   userData:NULL
										   assumeInside:NO];
	}
}


- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	
	//NSRect webViewFrame = [_threadView frame];
	NSArray *subViews = [[[_threadView mainFrame] frameView] subviews];
	if (subViews && [subViews count]>0) {
		NSView *subView = [subViews objectAtIndex:0];
		if ([subView isKindOfClass:[NSScrollView class]]) {
			NSWindow *window = [self window];
			NSRect windowFrame = [window frame];
			NSRect screenVisibleFrame = [[window screen] visibleFrame];
			NSRect contentViewFrame = [[(NSScrollView *)subView documentView] frame];
			//NSSize resultSize = contentViewFrame.size;
			
			if (contentViewFrame.size.height > screenVisibleFrame.size.height-20) {
				contentViewFrame.size.height = screenVisibleFrame.size.height-20;
			}
			windowFrame.size.height = contentViewFrame.size.height;
			if (windowFrame.origin.y + windowFrame.size.height >
				screenVisibleFrame.origin.y + screenVisibleFrame.size.height) {
				windowFrame.origin.y -= ((windowFrame.origin.y + windowFrame.size.height)
										 - (screenVisibleFrame.origin.y + screenVisibleFrame.size.height));
			}
			[window setFrame:windowFrame display:YES];
			if (![_threadView resExtractPath]) [window setContentSize:contentViewFrame.size];
			
		
			if (NSPointInRect([NSEvent mouseLocation], [window frame])) {
				[self mouseEntered:nil];
			}
			[window orderFront:nil];
			//[[[_threadView internalDelegate] parentInternalDelegate] makeThreadViewToFirstResponder];
		}
	}
	[[_threadView internalDelegate] webView:sender didFinishLoadForFrame:frame];

}


	
#pragma mark -
#pragma mark Enter and Exit

-(void)setTracking:(BOOL)tracking {
	if (_tracking && !tracking) {
		[_threadView removeTrackingRect:_trackingRectTag];
		_tracking = NO;
	} else if (!_tracking && tracking) {
		_trackingRectTag = [_threadView addTrackingRect:[_threadView bounds]
												  owner:self
											   userData:NULL
										   assumeInside:NO];
		_tracking = YES;
	}
}
-(BOOL)tracking { return _tracking; }
	
- (void)mouseEntered:(NSEvent *)theEvent {
	if (_entered) return;
	_entered = YES;
	[[_threadView internalDelegate] popUpRetain];
	T2ThreadViewInternalDelegate *parentInternalDelegate = [[_threadView internalDelegate] parentInternalDelegate];
	
	if (__makePopUpWindowKey) {
		[parentInternalDelegate registerHoveredAnchorElement:nil modifierFlags:0];
		[[self window] makeKeyAndOrderFront:nil];
	} else {
		
		if ([[parentInternalDelegate threadView] isPopup])
			[parentInternalDelegate registerHoveredAnchorElement:nil modifierFlags:0];
		
		[[self window] orderFront:nil];
	}
	
	[[self window] setAcceptsMouseMovedEvents:YES];
}
- (void)mouseExited:(NSEvent *)theEvent {
	_entered = NO;
	
	[[self window] setAcceptsMouseMovedEvents:NO];
	[[_threadView internalDelegate] popUpReleaseWithDelay];
}

- (void)windowWillClose:(NSNotification *)aNotification {
	/*
	NSMutableArray *events = [NSMutableArray array];
	NSWindow *window = [self window];
	NSEvent *event;
	while (event = [window nextEventMatchingMask:NSAnyEventMask]) {
		[events addObject:event];
	}
	NSLog(@"%@", events);
	 */
	
	[[self window] discardEventsMatchingMask:NSMouseMovedMask beforeEvent:nil];
	@synchronized (__allPopUpWindowControllers) {
		[__allPopUpWindowControllers removeObject:self];
	}
	[[[_threadView internalDelegate] parentInternalDelegate] childWindowWillClose];
	[_threadView stopLoading:nil];
	[_threadView setDelegate:nil];
	[_threadView setThread:nil];
	[_threadView setInternalDelegate:nil];
	
	[self setTracking:NO];
	[self autorelease];
}

-(void)closePopUp {
	
	[[self window] setAcceptsMouseMovedEvents:NO];
	[[_threadView internalDelegate] popUpClose];
}


+(void)closeAllPopUp {
	NSArray *array = [[__allPopUpWindowControllers copy] autorelease];
	[array makeObjectsPerformSelector:@selector(closePopUp)];
}

@end
