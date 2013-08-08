//
//  T2ViewPreferenceItem.m
//  Thousand
//
//  Created by R. Natori on 06/10/20.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "T2ViewPreferenceItem.h"


@implementation T2ViewPreferenceItem

-(void)dealloc {
	[_view release];
	[super dealloc];
}

-(void)setView:(NSView *)view { setObjectWithRetain(_view, view); }
-(NSView *)view { return _view; }

-(NSArray *)boundViewsWithBasePath:(NSString *)basePath controller:(id)controller superViewWidth:(float)superViewWidth {
	if (_view) {
		return [NSArray arrayWithObject:_view];
	}
	return nil;
}
@end
