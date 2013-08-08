//
//  THProgressIndicator.m
//  Thousand
//
//  Created by R. Natori on 06/02/12.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "THProgressIndicator.h"


@implementation THProgressIndicator
-(void)awakeFromNib {
	_isLoaded = YES;
}


- (void)setHidden:(BOOL)flag {
	if (_isLoaded) {
		if (flag) {
			if (_infoTextField) {
				[_infoTextField setHidden:YES];
				NSPoint origin = [_infoTextField frame].origin;
				origin.x = [self frame].origin.x;
				[_infoTextField setFrameOrigin:origin];
				[_infoTextField setHidden:NO];
			}
			[self stopAnimation:nil];
		}
		else {
			if (_infoTextField) {
				[_infoTextField setHidden:YES];
				NSPoint origin = [_infoTextField frame].origin;
				NSRect myFrame = [self frame];
				origin.x = myFrame.origin.x + myFrame.size.width + 8;
				[_infoTextField setFrameOrigin:origin];
				[_infoTextField setHidden:NO];
			}
			[self startAnimation:nil];
		}
	}
	[super setHidden:flag];
}
@end
