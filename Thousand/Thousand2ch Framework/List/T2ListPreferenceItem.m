//
//  T2ListPreferenceItem.m
//  Thousand
//
//  Created by R. Natori on 06/10/20.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "T2ListPreferenceItem.h"


@implementation T2ListPreferenceItem

-(void)dealloc {
	[_listItems release];
	[super dealloc];
}

-(void)setListItems:(NSArray *)listItems { setObjectWithRetain(_listItems, listItems); }
-(NSArray *)listItems { return _listItems; }

#pragma mark View Creation
-(NSArray *)boundViewsWithBasePath:(NSString *)basePath controller:(id)controller superViewWidth:(float)superViewWidth {
	NSMutableArray *boundViews = [NSMutableArray array];
	float verticalLoc = 0.0;
	NSView *titleView = nil;
	if (_title && !(_type == T2PrefBoolItem)) {
		titleView = [T2PreferenceItem labelStyleTextFieldWithString:_title];
		[titleView setViewVerticalCenter:verticalLoc];
		if (_sizeType == T2PrefFullSize) {
			[titleView setViewWidthFrom:0 to:3 superViewWidth:superViewWidth];
			verticalLoc += 30;
		}
		else {
			[titleView setViewWidthFrom:0 to:1 superViewWidth:superViewWidth];
		}
		[boundViews addObject:titleView];
	}
	
	NSString *bindTo = nil;
	NSView *keyView = nil; int startLoc = 1; int endLoc = 3;
	if (_sizeType == T2PrefSmallSize) endLoc = 2;
	switch (_type) {
		case T2PrefStringComboItem:
			if (_listItems)
				keyView = [T2PreferenceItem comboBoxWithListItems:_listItems];
			bindTo = @"value";
			break;
		case T2PrefStringPopUpItem:
			if (_listItems)
				keyView = [T2PreferenceItem popUpButtonWithListItems:_listItems];
			bindTo = @"selectedValue";
			break;
		case T2PrefNumberPopUpItem:
			if (_listItems)
				keyView = [T2PreferenceItem popUpButtonWithListItems:_listItems];
			bindTo = @"selectedIndex";
			break;
		default:
			break;
	}
	
	if (_key && bindTo) {
		NSString *keyPath = [NSString stringWithFormat:@"%@.%@", basePath, _key];
		[keyView bind:bindTo toObject:controller withKeyPath:keyPath options:nil];
	}
	
	if (keyView) {
		[keyView setViewWidthFrom:startLoc to:endLoc superViewWidth:superViewWidth];
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
