//
//  T2PreferenceItem.h
//  Thousand
//
//  Created by R. Natori on 05/09/30.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "T2PluginProtocols.h"
#import "T2UtilityHeader.h"

typedef enum {
	T2PrefNullItem = 0,
	T2PrefStringItem = 1,
	T2PrefStringComboItem,
	T2PrefStringPopUpItem,
	T2PrefLongStringItem,
	T2PrefNumberItem = 11,
	T2PrefNumberPopUpItem,
	T2PrefBoolItem = 21,
	T2PrefButtonItem = 31,
	T2PrefLabelItem = 41,
	T2PrefLongDescriptionItem,
	T2PrefSeparateLineItem,
	T2PrefTopTitleItem,
	T2PrefCustomViewItem = 101
} T2PrefItemType;

typedef enum {
	T2PrefFullSize = 1,
	T2PrefMiddleSize,
	T2PrefSmallSize
} T2PrefItemSizeType;

@interface T2PreferenceItem : NSObject <T2DictionaryConverting> {
	int _type;
	int _sizeType;
	NSString *_key;
	NSString *_title;
	NSString *_info;
	
}

// Factory
+(id)stringItemWithKey:(NSString *)key title:(NSString *)title info:(NSString *)info ;
+(id)longStringItemWithKey:(NSString *)key title:(NSString *)title info:(NSString *)info ;
+(id)stringComboItemWithKey:(NSString *)key title:(NSString *)title info:(NSString *)info
								  listItems:(NSArray *)listItems;
+(id)stringPopUpItemWithKey:(NSString *)key title:(NSString *)title info:(NSString *)info
								  listItems:(NSArray *)listItems;

+(id)numberItemWithKey:(NSString *)key title:(NSString *)title info:(NSString *)info ;
+(id)numberPopUpItemWithKey:(NSString *)key title:(NSString *)title info:(NSString *)info
								  listItems:(NSArray *)listItems;

+(id)boolItemWithKey:(NSString *)key title:(NSString *)title info:(NSString *)info ;

+(id)buttonItemWithAction:(SEL)action target:(id)target title:(NSString *)title info:(NSString *)info ;

+(id)labelItemWithKey:(NSString *)key ;
+(id)longDescriptionItemItemWithKey:(NSString *)key title:(NSString *)title ;

+(id)separateLineItem ;
+(id)topTitleItemWithTitle:(NSString *)title info:(NSString *)info ;
+(id)customViewItemWithView:(NSView *)view ;

-(id)initWithType:(T2PrefItemType)type sizeType:(T2PrefItemSizeType)sizeType key:(NSString *)key
			title:(NSString *)title info:(NSString *)info ;

// Accessors
-(void)setType:(int)type ;
-(int)type ;
-(void)setSizeType:(int)sizeType ;
-(int)sizeType ;

-(void)setKey:(NSString *)key ;
-(NSString *)key ;
-(void)setTitle:(NSString *)title ;
-(NSString *)title ;
-(void)setInfo:(NSString *)info ;
-(NSString *)info ;

// View Creation
-(NSArray *)boundViewsWithBasePath:(NSString *)basePath controller:(id)controller superViewWidth:(float)superViewWidth;

+(NSTextField *)labelStyleTextFieldWithString:(NSString *)string ;
+(NSTextField *)smallTextStyleTextFieldWithString:(NSString *)string ;
+(NSTextField *)inputStyleTextField ;
+(NSComboBox *)comboBoxWithListItems:(NSArray *)listItems ;
+(NSButton *)checkBoxWithTitle:(NSString *)string ;
+(NSPopUpButton *)popUpButtonWithListItems:(NSArray *)listItems ;
+(NSButton *)pushButtonWithTitle:(NSString *)string ;
+(NSScrollView *)textViewEditable:(BOOL)editable ;
+(NSBox *)separateLine ;
@end

@interface NSView (T2PreferenceViewCategory)
-(void)setViewWidthFrom:(int)startLoc to:(int)endLoc superViewWidth:(float)superViewWidth;
-(void)setViewVerticalCenter:(float)locY;
@end
