//
//  T2PopUpWindow.m
//  Thousand
//
//  Created by R. Natori on 06/08/03.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "T2PopUpWindow.h"


@implementation T2PopUpWindow
- (id)initWithContentRect:(NSRect)contentRect
				styleMask:(unsigned int)styleMask
				  backing:(NSBackingStoreType)bufferingType
					defer:(BOOL)deferCreation {
	self = [super initWithContentRect:contentRect
							styleMask:(styleMask ^ NSTitledWindowMask)
							  backing:bufferingType
								defer:deferCreation];
	[self setLevel:NSFloatingWindowLevel];
	return self;
}

- (BOOL)canBecomeKeyWindow { return YES; }
- (BOOL)canBecomeMainWindow { return NO; }
- (BOOL)becomesKeyOnlyIfNeeded { return YES; }


- (void)sendEvent:(NSEvent *)event {
	NSEventType eventType = [event type];
	if (eventType == NSLeftMouseDown
		|| eventType == NSRightMouseDown) {
		if (![self isKeyWindow]) {
			[self makeKeyWindow];
		}
	}
	[super sendEvent:(NSEvent *)event];
}
@end

