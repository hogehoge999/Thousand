//
//  T2PreferenceItem.m
//  Thousand
//
//  Created by R. Natori on 05/09/30.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "T2PreferenceItem.h"
#import "T2ListPreferenceItem.h"
#import "T2ViewPreferenceItem.h"
#import "T2ActionPreferenceItem.h"


@implementation T2PreferenceItem
#pragma mark Factory
+(id)stringItemWithKey:(NSString *)key title:(NSString *)title info:(NSString *)info {
	return [[[self alloc] initWithType:T2PrefStringItem sizeType:T2PrefMiddleSize
								   key:key title:title info:info] autorelease];
}

+(id)longStringItemWithKey:(NSString *)key title:(NSString *)title info:(NSString *)info {
	return [[[self alloc] initWithType:T2PrefLongStringItem sizeType:T2PrefFullSize
								   key:key title:title info:info] autorelease];
}
+(id)stringComboItemWithKey:(NSString *)key title:(NSString *)title info:(NSString *)info
								  listItems:(NSArray *)listItems {
	T2ListPreferenceItem *prefItem = [[[T2ListPreferenceItem alloc] initWithType:T2PrefStringComboItem sizeType:T2PrefSmallSize
																			 key:key title:title info:info] autorelease];
	[prefItem setListItems:listItems];
	return prefItem;
}
+(id)stringPopUpItemWithKey:(NSString *)key title:(NSString *)title info:(NSString *)info
								  listItems:(NSArray *)listItems {
	T2ListPreferenceItem *prefItem = [[[T2ListPreferenceItem alloc] initWithType:T2PrefStringPopUpItem sizeType:T2PrefSmallSize
																			 key:key title:title info:info] autorelease];
	[prefItem setListItems:listItems];
	return prefItem;
}

+(id)numberItemWithKey:(NSString *)key title:(NSString *)title info:(NSString *)info {
	return [[[self alloc] initWithType:T2PrefNumberItem sizeType:T2PrefSmallSize
								   key:key title:title info:info] autorelease];
}
+(id)numberPopUpItemWithKey:(NSString *)key title:(NSString *)title info:(NSString *)info
								  listItems:(NSArray *)listItems {
	T2ListPreferenceItem *prefItem = [[[T2ListPreferenceItem alloc] initWithType:T2PrefNumberPopUpItem sizeType:T2PrefSmallSize
																			 key:key title:title info:info] autorelease];
	[prefItem setListItems:listItems];
	return prefItem;
}

+(id)boolItemWithKey:(NSString *)key title:(NSString *)title info:(NSString *)info {
	return [[[self alloc] initWithType:T2PrefBoolItem sizeType:T2PrefSmallSize
								   key:key title:title info:info] autorelease];
}

+(id)buttonItemWithAction:(SEL)action target:(id)target title:(NSString *)title info:(NSString *)info {
	T2ActionPreferenceItem *prefItem = [[[T2ActionPreferenceItem alloc] initWithType:T2PrefButtonItem sizeType:T2PrefSmallSize
																				 key:nil title:title info:info] autorelease];
	[prefItem setAction:action];
	[prefItem setTarget:target];
	return prefItem;
}

+(id)labelItemWithKey:(NSString *)key {
	return [[[self alloc] initWithType:T2PrefLabelItem sizeType:T2PrefFullSize
								   key:key title:nil info:nil] autorelease];
}
+(id)longDescriptionItemItemWithKey:(NSString *)key title:(NSString *)title {
	return [[[self alloc] initWithType:T2PrefLongDescriptionItem sizeType:T2PrefFullSize
								   key:key title:title info:nil] autorelease];
}

+(id)separateLineItem {
	return [[[self alloc] initWithType:T2PrefSeparateLineItem sizeType:T2PrefFullSize
								   key:nil title:nil info:nil] autorelease];
}

+(id)topTitleItemWithTitle:(NSString *)title info:(NSString *)info {
	return [[[self alloc] initWithType:T2PrefTopTitleItem sizeType:T2PrefFullSize
								   key:nil title:title info:info] autorelease];
}
+(id)customViewItemWithView:(NSView *)view {
	T2ViewPreferenceItem *prefItem = [[[T2ViewPreferenceItem alloc] initWithType:T2PrefCustomViewItem sizeType:T2PrefFullSize
																			 key:nil title:nil info:nil] autorelease];
	[prefItem setView:view];
	return prefItem;
}

-(id)initWithType:(T2PrefItemType)type sizeType:(T2PrefItemSizeType)sizeType key:(NSString *)key title:(NSString *)title
			 info:(NSString *)info {
	self = [self init];
	_type = type;
	_sizeType = sizeType;
	_key = [key retain];
	_title = [title retain];
	_info = [info retain];
	return self;
}

-(void)dealloc {
	[_key release];
	[_title release];
	[_info release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark T2DictionaryConverting
// keys for saving
-(NSArray *)dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use {
	return [NSArray arrayWithObjects:@"type", @"sizeType", @"key", @"title", @"info", nil];
}


#pragma mark Accessors
-(void)setType:(int)type { _type = type; }
-(int)type { return _type; }
-(void)setSizeType:(int)sizeType { _sizeType = sizeType; }
-(int)sizeType { return _sizeType; }

-(void)setKey:(NSString *)key { setObjectWithRetain(_key, key); }
-(NSString *)key { return _key; }
-(void)setTitle:(NSString *)title { setObjectWithRetain(_title, title); }
-(NSString *)title { return _title; }
-(void)setInfo:(NSString *)info { setObjectWithRetain(_info, info); }
-(NSString *)info { return _info; }


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
		case T2PrefStringItem:
			keyView = [T2PreferenceItem inputStyleTextField];
			bindTo = @"value";
			break;
		case T2PrefLongStringItem:
			bindTo = @"value";
			keyView = [T2PreferenceItem textViewEditable:YES];
			startLoc = 0;  endLoc = 3;
			if (_key && bindTo) {
				NSString *keyPath = [NSString stringWithFormat:@"%@.%@", basePath, _key];
				[[(NSScrollView *)keyView documentView]  bind:bindTo toObject:controller withKeyPath:keyPath options:nil];
				bindTo = nil;
			}
				break;
		case T2PrefNumberItem:
			keyView = [T2PreferenceItem inputStyleTextField];
			bindTo = @"value";
			break;
		case T2PrefBoolItem:
			keyView = [T2PreferenceItem checkBoxWithTitle:_title];
			bindTo = @"value";
			startLoc = 0;
			break;
		case T2PrefLabelItem:
			keyView = [T2PreferenceItem labelStyleTextFieldWithString:@"Untitled"];
			bindTo = @"value";
			startLoc = 0;  endLoc = 3;
			break;
		case T2PrefLongDescriptionItem:
			bindTo = @"value";
			keyView = [T2PreferenceItem textViewEditable:NO];
			startLoc = 0;  endLoc = 3;
			if (_key && bindTo) {
				NSString *keyPath = [NSString stringWithFormat:@"%@.%@", basePath, _key];
				[[(NSScrollView *)keyView documentView]  bind:bindTo toObject:controller withKeyPath:keyPath options:nil];
				bindTo = nil;
			}
			break;
		case T2PrefSeparateLineItem:
			keyView = [T2PreferenceItem separateLine];
			startLoc = 0;  endLoc = 3;
			break;
		case T2PrefTopTitleItem:
			if (titleView) {
				[(NSTextField *)titleView setFont:[NSFont boldSystemFontOfSize:12.0]];
			}
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

+(NSTextField *)labelStyleTextFieldWithString:(NSString *)string {
	NSTextField *textField = [[[NSTextField alloc] initWithFrame:NSMakeRect(0,0,100,17)] autorelease];
	[textField setEditable:NO];
	[textField setSelectable:NO];
	[textField setBordered:NO];
	[textField setDrawsBackground:NO];
	[textField setStringValue:string];
	return textField;
}
+(NSTextField *)smallTextStyleTextFieldWithString:(NSString *)string {
	NSTextField *textField = [[[NSTextField alloc] initWithFrame:NSMakeRect(0,0,100,14)] autorelease];
	[textField setEditable:NO];
	[textField setSelectable:NO];
	[textField setBordered:NO];
	[textField setDrawsBackground:NO];
	
	[textField setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
	
	[textField setStringValue:string];
	return textField;
}
+(NSTextField *)inputStyleTextField {
	NSTextField *textField = [[[NSTextField alloc] initWithFrame:NSMakeRect(0,0,100,22)] autorelease];
	[textField setEditable:YES];
	[textField setSelectable:YES];
	[textField setBordered:YES];
	[textField setBezeled:YES];
	return textField;
}

+(NSComboBox *)comboBoxWithListItems:(NSArray *)listItems {
	NSEnumerator *itemsEnumerator = [listItems objectEnumerator];
	id listItem;
	NSComboBox *comboBox = [[[NSComboBox alloc] initWithFrame:NSMakeRect(0,0,100,26)] autorelease];
	[comboBox removeAllItems];
	while (listItem = [itemsEnumerator nextObject])
		[comboBox addItemWithObjectValue:listItem];
	[comboBox setNumberOfVisibleItems:[listItems count]];
	return comboBox;
}

+(NSButton *)checkBoxWithTitle:(NSString *)string {
	NSButton *button = [[[NSButton alloc] initWithFrame:NSMakeRect(0,0,100,18)] autorelease];
	[button setButtonType:NSSwitchButton];
	NSSize frameSize = [button frame].size;
	frameSize.height = 18;
	[button setFrameSize:frameSize];
	[button setTitle:string];
	return button;
}

+(NSPopUpButton *)popUpButtonWithListItems:(NSArray *)listItems {
	NSPopUpButton *popUpButton = [[[NSPopUpButton alloc] initWithFrame:NSMakeRect(0,0,100,26)] autorelease];
	[popUpButton removeAllItems];
	[popUpButton addItemsWithTitles:listItems];
	return popUpButton;
}

+(NSButton *)pushButtonWithTitle:(NSString *)string {
	NSButton *button = [[[NSButton alloc] initWithFrame:NSMakeRect(0,0,100,32)] autorelease];
	[button setButtonType:NSMomentaryPushButton];
	[button setBezelStyle:NSRoundedBezelStyle];
	[button setTitle:string];
	return button;
}

+(NSScrollView *)textViewEditable:(BOOL)editable {
	NSTextView *textView = [[[NSTextView alloc] initWithFrame:NSMakeRect(0,0,100,80)] autorelease];
	[textView setEditable:editable];
	[textView setRichText:NO];
	
	NSScrollView *scrollView = [[[NSScrollView alloc] initWithFrame:NSMakeRect(0,0,100,80)] autorelease];
	[scrollView setHasHorizontalScroller:NO];
	[scrollView setHasVerticalScroller:YES];
	[scrollView setAutohidesScrollers:YES];
	[scrollView setDocumentView:textView];
	return scrollView;
}
+(NSBox *)separateLine {
	NSBox *box = [[[NSBox alloc] initWithFrame:NSMakeRect(0,0,100,5)] autorelease];
	[box setBoxType:NSBoxSeparator];
	return box;
}
@end

@implementation NSView (T2PreferenceViewCategory)
-(void)setViewWidthFrom:(int)startLoc to:(int)endLoc superViewWidth:(float)superViewWidth {
	NSRect frame = [self frame];
	frame.origin.x = (superViewWidth/3.0) * (float)startLoc + 8;
	if (startLoc == 0) frame.origin.x+=10;
	frame.size.width = (superViewWidth/3.0) * (float)(endLoc - startLoc) -16;
	if (endLoc == 3) frame.size.width-=20;
	[self setFrame:frame];
	
	unsigned int resizeMask = NSViewWidthSizable;
	if (startLoc > 0) resizeMask = resizeMask | NSViewMinXMargin;
	if (endLoc < 3) resizeMask = resizeMask | NSViewMaxXMargin;
	[self setAutoresizingMask:resizeMask];
}

-(void)setViewVerticalCenter:(float)locY {
	NSRect frame = [self frame];
	if (frame.size.height > 32)
		frame.origin.y = locY - 16;
	else
		frame.origin.y = locY - ((int)(frame.size.height) / 2);
	[self setFrame:frame];
}
@end
