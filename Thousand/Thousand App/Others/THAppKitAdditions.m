//
//  THAppKitAdditions.m
//  Thousand
//
//  Created by R. Natori on  07/09/24.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "THAppKitAdditions.h"


@implementation NSWindow (THAppKitAdditions)
- (BOOL)writeWindowImageToJPEGFile:(NSString *)filepath compressionFactor:(float)compressionFactor {
	NSRect rect = [self frame];
	NSWindow *window;
    NSBitmapImageRep *rep;
    NSImage *image;
	
    window = [[NSWindow alloc] initWithContentRect:rect styleMask:NSBorderlessWindowMask
										   backing:NSBackingStoreNonretained defer:NO];
    [window setBackgroundColor:[NSColor clearColor]];
    [window setLevel:NSScreenSaverWindowLevel + 1];
    [window setHasShadow:NO];
    [window setAlphaValue:0.0];
    [window orderFront:self];
    [window setContentView:[[[NSView alloc] initWithFrame:rect] autorelease]];
    [[window contentView] lockFocus];
    rep = [[[NSBitmapImageRep alloc] initWithFocusedViewRect:[[window contentView] bounds]] autorelease];
    [[window contentView] unlockFocus];
    [window orderOut:self];
    [window close];
	
	NSDictionary *compressionFactorDic = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithFloat:compressionFactor],
		NSImageCompressionFactor,
		nil];
	
    NSData *jpegData = [rep representationUsingType:NSJPEGFileType
													properties:compressionFactorDic];
	
    return [jpegData writeToFile:filepath atomically:YES];
}
@end
