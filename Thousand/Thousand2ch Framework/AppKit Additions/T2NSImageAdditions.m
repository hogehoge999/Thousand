//
//  T2NSImageAdditions.m
//  Thousand
//
//  Created by R. Natori on 08/05/18.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "T2NSImageAdditions.h"


@implementation NSImage (T2NSImageAdditions)
+(id)imageNamed:(NSString *)name orInBundle:(NSBundle *)bundle {
	NSImage *image = [self imageNamed:name];
	if (!image) {
		NSString *path = [bundle pathForImageResource:name];
		if (path) {
			image = [[[NSImage alloc] initByReferencingFile:path] autorelease];
			if (image) {
				[image setName:name];
			}
		}
	}
	return image;
}
@end
