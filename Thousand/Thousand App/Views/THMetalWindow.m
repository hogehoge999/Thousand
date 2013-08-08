//
//  THMetalWindow.m
//  Thousand
//
//  Created by R. Natori on 06/05/21.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "THMetalWindow.h"

static BOOL __texturedBackground;


@implementation THMetalWindow
+(void)setClassTexturedBackground:(BOOL)aBool {
	__texturedBackground = aBool;
}
+(BOOL)classTexturedBackground {
	return __texturedBackground;
}

- (id)initWithContentRect:(NSRect)contentRect
				styleMask:(unsigned int)styleMask
				  backing:(NSBackingStoreType)bufferingType
					defer:(BOOL)deferCreation {
	if (__texturedBackground) {
		styleMask = styleMask | NSTexturedBackgroundWindowMask;
	} else {
		styleMask = styleMask ^ NSTexturedBackgroundWindowMask;
	}

	return [super initWithContentRect:contentRect
							styleMask:styleMask
							  backing:bufferingType
								defer:deferCreation];
}
/*
- (id)initWithContentRect:(NSRect)contentRect
				styleMask:(unsigned int)styleMask
				  backing:(NSBackingStoreType)bufferingType
					defer:(BOOL)deferCreation
				   screen:(NSScreen *)screen {
	if (__texturedBackground) {
		styleMask = styleMask | NSTexturedBackgroundWindowMask;
	} else {
		styleMask = styleMask ^ NSTexturedBackgroundWindowMask;
	}
	return [super initWithContentRect:contentRect
							styleMask:styleMask
							  backing:bufferingType
								defer:deferCreation
							   screen:screen];
}
*/
/*
- (void)keyDown:(NSEvent *)theEvent {
	
}
 */
@end
