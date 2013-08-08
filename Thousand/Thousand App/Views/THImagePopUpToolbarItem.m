//
//  THImagePopUpToolbarItem.m
//  Thousand
//
//  Created by R. Natori on 平成21/09/19.
//  Copyright 2009 R. Natori. All rights reserved.
//

#import "THImagePopUpToolbarItem.h"


@implementation THImagePopUpToolbarItem
-(NSSize)minSize {
	NSToolbar *toolbar = [self toolbar];
	NSSize minSize = [super minSize];
	if ([toolbar sizeMode] == NSToolbarSizeModeSmall) {
		minSize.height = 24.0;
	} else {
		minSize.height = 32.0;
	}
	return minSize;
}
@end
