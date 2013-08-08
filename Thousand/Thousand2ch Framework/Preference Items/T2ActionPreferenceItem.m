//
//  T2ActionPreferenceItem.m
//  Thousand
//
//  Created by R. Natori on 06/10/21.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "T2ActionPreferenceItem.h"


@implementation T2ActionPreferenceItem

-(void)setAction:(SEL)selector { _action = selector; }
-(SEL)action { return _action; }
-(void)setTarget:(id)object { _target = object; }
-(id)target { return _target; }


#pragma mark View Creation
-(NSArray *)boundViewsWithBasePath:(NSString *)basePath controller:(id)controller superViewWidth:(float)superViewWidth {
	NSMutableArray *boundViews = [NSMutableArray array];
	float verticalLoc = 0.0;
	
	NSView *keyView = nil; int startLoc = 1; int endLoc = 3;
	if (_sizeType == T2PrefSmallSize) endLoc = 2;
	switch (_type) {
		case T2PrefButtonItem:
			keyView = [T2PreferenceItem pushButtonWithTitle:_title];
			[(NSButton *)keyView setAction:_action];
			[(NSButton *)keyView setTarget:_target];
			[keyView setViewWidthFrom:startLoc to:endLoc superViewWidth:superViewWidth];
			[(NSButton *)keyView sizeToFit];
			break;
		default:
			break;
	}
	
	if (keyView) {
		[keyView setViewVerticalCenter:verticalLoc];
		verticalLoc += 30;
		[boundViews addObject:keyView];
	}
	
	
	if (_info) {
		NSView *infoView = [T2PreferenceItem smallTextStyleTextFieldWithString:_info];
		[infoView setViewWidthFrom:0 to:3 superViewWidth:superViewWidth];
		[infoView setViewVerticalCenter:verticalLoc];
		[boundViews addObject:infoView];
	}
	
	return boundViews;
}
@end
